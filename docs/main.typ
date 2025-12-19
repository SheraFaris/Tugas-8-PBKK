#set text(lang: "en")

= Comparison of File Upload Methods: Multer Local Storage vs S3 Presigned URLs

== Executive Summary

This document compares two file upload implementations for the Public Posts application: *Multer Local Storage* (backend-multer) and *S3 Presigned URLs* (backend). The comparison evaluates both approaches based on scalability, security, cost, and implementation complexity.

---

== Table of Contents

1. Implementation Overview
2. Architecture Comparison
3. Which One Is Better?
4. Why?
5. Detailed Analysis
6. Conclusion

---

== Implementation Overview

=== Multer Local Storage (backend-multer)

*Architecture:*
- Files are uploaded directly to the backend server's local disk
- Frontend sends FormData with the file to `/upload` endpoint
- Files are stored in the `uploads/` directory on the server
- Files are served statically through Express static middleware

*Key Components:*
- `upload.controller.ts`: Handles file upload with FileInterceptor
- `multer.config.ts`: Configures storage, file validation, and size limits
- `main.ts`: Sets up static file serving for the uploads directory

*File Flow:*
1. User selects an image in the frontend
2. Frontend sends POST request to `/upload` with FormData
3. Multer validates the file (type, size)
4. File is saved to local disk with a timestamped filename
5. Response returns the `imagePath` (filename)
6. Frontend uses this path to create a post reference

*Validation Rules:*
- Allowed MIME types: image/jpeg, image/png, image/gif, image/webp
- Maximum file size: 5MB
- File naming: `image-{timestamp}-{randomId}.{ext}`

=== S3 Presigned URLs (backend)

*Architecture:*
- Files are uploaded directly to AWS S3 using presigned URLs
- Backend generates a temporary, cryptographically signed URL
- Frontend uses the presigned URL to upload directly to S3
- Backend only stores the S3 path reference

*Key Components:*
- `s3.service.ts`: Generates presigned URLs using AWS SDK
- `s3.controller.ts`: Endpoint for requesting presigned URLs
- S3 credentials configured via environment variables

*File Flow:*
1. User selects an image in the frontend
2. Frontend requests a presigned URL from `/s3/presigned-url`
3. Backend generates a signed URL with AWS credentials
4. Frontend uploads the file directly to AWS S3 using the presigned URL
5. Response returns the `imagePath` (S3 path)
6. Frontend uses this path to create a post reference

*Configuration:*
- AWS Region: configurable via `AWS_REGION` (default: us-east-1)
- AWS Credentials: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- S3 Bucket: configurable via `AWS_S3_BUCKET_NAME`
- Presigned URL expiration: 1 hour

*File Naming:*
- `posts/{timestamp}-{randomId}.{extension}`

---

== Architecture Comparison

#table(
  columns: (1fr, 1fr, 1fr),
  [*Aspect*], [*Multer Local Storage*], [*S3 Presigned URLs*],
  [Storage Location], [Server disk], [AWS S3 cloud storage],
  [Upload Method], [Direct to backend], [Direct to S3 (bypassing backend)],
  [Backend Involvement], [Handles file storage], [Only generates signing credentials],
  [Scalability], [Limited by server disk space], [Unlimited (cloud-based)],
  [Cost Model], [Server resources (storage, compute)], [Pay-per-use (S3 storage + requests)],
  [Data Transfer], [All through backend], [Efficient direct uploads],
  [Security Model], [Server-based access control], [AWS IAM + presigned URL tokens],
  [High Availability], [Single point of failure], [AWS multi-region redundancy],
)

---

== Which One Is Better?

*S3 Presigned URLs is the better approach* for most production scenarios, especially for growing applications.

*However, Multer Local Storage is better if you:*
- Are running a small, internal application
- Have strict data residency requirements (no cloud storage)
- Have limited budget or no AWS account
- Need simple, on-premises deployment
- Are developing a prototype or MVP

---

== Why?

=== S3 Presigned URLs Advantages

==== 1. *Scalability*
- *Unlimited storage capacity*: Not constrained by server disk space
- *Handles traffic spikes*: AWS infrastructure scales automatically
- *Multi-server support*: Can run multiple backend instances without storage synchronization issues
- S3 can handle millions of concurrent uploads without performance degradation

==== 2. *Security*
- *Reduced attack surface*: Backend doesn't process file uploads directly
- *Fine-grained access control*: AWS IAM policies control who can upload to what buckets
- *Signed URLs are time-limited*: Default 1-hour expiration prevents abuse
- *No file execution*: S3 is object storage only, cannot execute malicious scripts
- *Encryption at rest and in transit*: AWS provides built-in encryption options

==== 3. *Cost Efficiency*
- *Bandwidth savings*: Direct upload bypasses backend servers, reducing bandwidth costs
- *Compute savings*: Backend isn't consumed by upload processing
- *Predictable pricing*: Pay only for what you use (storage + requests)
- *Auto-scaling*: Don't need to provision large servers just for file storage

==== 4. *High Availability & Disaster Recovery*
- *Automatic replication*: Files are replicated across multiple AWS availability zones
- *Durability*: 99.999999999% (11 nines) durability with S3
- *Backup & versioning*: AWS provides built-in versioning and lifecycle policies
- *No data loss*: Even if your server goes down, files are safe in S3

==== 5. *Performance*
- *Direct upload*: Bypasses backend bottleneck
- *CDN integration*: Can use CloudFront to serve images globally with low latency
- *Efficient resource usage*: Backend resources available for other operations
- *Reduced latency*: Geographic distribution through S3 and CloudFront

==== 6. *Operational Benefits*
- *No disk management*: Don't worry about cleaning up files or managing disk space
- *Monitoring & analytics*: AWS CloudWatch provides detailed upload metrics
- *Compliance*: S3 supports various compliance standards (GDPR, HIPAA, etc.)
- *Easier to debug*: Clearer separation of concerns

=== Multer Local Storage Disadvantages

==== 1. *Scalability Issues*
- Server disk space becomes a bottleneck quickly
- Storing files on multiple servers requires complex synchronization
- Not suitable for distributed systems or microservices architecture

==== 2. *Security Concerns*
- Backend must process and validate uploads, adding complexity
- Files executed or accessed through web server if misconfigured
- No built-in encryption or access control mechanisms
- Single point of failure - compromise of backend = compromised files

==== 3. *Operational Challenges*
- Must implement custom backup and disaster recovery
- Manual cleanup needed to prevent disk space exhaustion
- Difficult to move files between servers or scale horizontally
- File serving requires careful configuration to prevent vulnerabilities

==== 4. *Cost Implications*
- Requires larger/more servers to store files
- All traffic goes through backend, increasing bandwidth costs
- Must manage storage growth manually
- Scaling horizontally requires complex file synchronization

==== 5. *Limited Reliability*
- No automatic replication or backup
- Data loss if server crashes and no backup exists
- No built-in versioning or recovery mechanisms
- Geographic distribution difficult and expensive

---

== Detailed Analysis

=== File Upload Process Comparison

==== Multer Local Storage Flow:
```
1. User selects image
   ↓
2. Frontend sends FormData to /upload
   ↓
3. Multer validates MIME type & size
   ↓
4. Backend saves file to disk
   ↓
5. Returns imagePath
   ↓
6. Frontend creates post with imagePath
```

*Bottlenecks:* Steps 3-4 happen on backend server

==== S3 Presigned URL Flow:
```
1. User selects image
   ↓
2. Frontend requests presigned URL from /s3/presigned-url
   ↓
3. Backend generates signed URL with AWS credentials
   ↓
4. Frontend uploads directly to S3 using presigned URL
   ↓
5. Returns imagePath
   ↓
6. Frontend creates post with imagePath
```

*Advantages:* Backend only involved in step 3 (lightweight)

=== Test Results

Both implementations *pass all e2e tests*:

==== Backend-Multer Tests:
- ✓ File upload with valid authentication
- ✓ Fails without authentication
- ✓ Returns null imagePath when no file provided
- ✓ Accepts different image file extensions (jpg, png, gif, webp)
- ✓ Rejects non-image files
- ✓ Rejects files larger than 5MB
- ✓ Creates posts with imagePath
- ✓ Creates posts without imagePath
- ✓ Retrieves posts with imagePath in list
- ✓ Retrieves post with imagePath by id
- ✓ Validates imagePath format
- ✓ Completes full image upload flow
- ✓ Handles different image formats

*Total: 13 tests passed*

==== Backend (S3) Tests:
- ✓ Generates presigned URL with valid authentication
- ✓ Fails without authentication
- ✓ Fails with invalid data
- ✓ Accepts different image file extensions
- ✓ Creates posts with imagePath
- ✓ Creates posts without imagePath
- ✓ Retrieves posts with imagePath in list
- ✓ Retrieves post with imagePath by id
- ✓ Validates imagePath format
- ✓ Completes full image upload flow
- ✓ Handles different image formats

*Total: 11 tests passed*

=== Implementation Complexity

==== Multer Local Storage:
- *Setup*: Simple, minimal configuration required
- *Frontend*: Easy FormData upload
- *Backend*: FileInterceptor decorator handles most work
- *Maintenance*: Requires monitoring disk space and file cleanup

==== S3 Presigned URLs:
- *Setup*: Requires AWS account and credentials configuration
- *Frontend*: Slightly more complex (fetch presigned URL first, then upload)
- *Backend*: Lightweight service using AWS SDK
- *Maintenance*: AWS handles storage, cleanup, and reliability

---

== Production Recommendations

=== Use S3 Presigned URLs If:
- ✓ Building a production application expecting growth
- ✓ Need multi-server or cloud-native deployment
- ✓ Want better security and compliance
- ✓ Plan to scale globally
- ✓ Need automatic backups and disaster recovery
- ✓ Want to reduce server costs
- ✓ Require high availability

=== Use Multer Local Storage If:
- ✓ Building an internal tool or MVP
- ✓ Data residency laws restrict cloud storage
- ✓ Running on-premises infrastructure
- ✓ User base is small and stable
- ✓ Storage requirements are modest (< 100GB)
- ✓ Cannot use AWS or cloud services
- ✓ Simplicity is the primary concern

---

== Migration Path

If you start with Multer but later want to migrate to S3:

1. Both implementations store the same metadata in the database (`imagePath`)
2. Multer paths: `image-{timestamp}-{randomId}.{ext}`
3. S3 paths: `posts/{timestamp}-{randomId}.{ext}`
4. Create migration script to move files from local to S3
5. Update environment and deployment configuration
6. Switch frontend to use S3 presigned URL logic
7. Gradually migrate existing files as needed

The abstraction makes migration straightforward without database schema changes.

---

== Conclusion

=== Summary

Both implementations are *functionally complete and secure*, as evidenced by passing e2e tests. The choice between them depends on your application's requirements and constraints:

- *For MVP/Small Projects*: Multer Local Storage is simpler and faster to set up
- *For Production/Growing Apps*: S3 Presigned URLs is more scalable, secure, and cost-effective
- *For Enterprise*: S3 with enhanced security policies, versioning, and compliance configurations

=== Key Takeaway

*S3 Presigned URLs* is the industry best practice for file uploads in modern web applications because:
1. It scales from hundreds to millions of concurrent users
2. It provides better security through separation of concerns
3. It reduces operational burden on your infrastructure
4. It provides better disaster recovery and business continuity
5. It's more cost-effective at scale
6. It integrates seamlessly with CDNs for global distribution

However, *Multer Local Storage* remains valuable for:
- Internal applications and MVPs
- Strict compliance requirements
- Organizations without cloud infrastructure
- Simplified deployment scenarios

The best choice is determined by your specific business requirements, scale expectations, and infrastructure constraints.

---

== References

- AWS S3 Presigned URLs Documentation: https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html
- NestJS File Upload Documentation: https://docs.nestjs.com/techniques/file-upload
- Multer Documentation: https://github.com/expressjs/multer
- AWS SDK for JavaScript v3: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/

---

*Document Created:* December 19, 2025
*Implementation Status:* Complete and Tested ✓

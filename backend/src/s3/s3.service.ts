import { Injectable } from '@nestjs/common';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class S3Service {
  private s3Client: S3Client;

  constructor() {
    this.s3Client = new S3Client({
      region: process.env.AWS_REGION || 'us-east-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
      },
    });
  }

  async generatePresignedUrl(
    fileExtension: string,
    contentType: string,
  ): Promise<{ uploadUrl: string; imagePath: string }> {
    const timestamp = Date.now();
    const randomId = Math.random().toString(36).substring(2, 9);
    const fileName = `${timestamp}-${randomId}.${fileExtension}`;
    const imagePath = `posts/${fileName}`;
    const bucketName = process.env.AWS_S3_BUCKET_NAME || 'my-bucket';

    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: imagePath,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, {
      expiresIn: 3600, // 1 hour
    });

    return {
      uploadUrl,
      imagePath,
    };
  }
}

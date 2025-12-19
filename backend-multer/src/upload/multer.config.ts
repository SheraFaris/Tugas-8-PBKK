import { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';
import { diskStorage } from 'multer';
import { BadRequestException } from '@nestjs/common';
import { join } from 'path';
import { existsSync, mkdirSync } from 'fs';

const uploadsDir = join(process.cwd(), 'uploads');

// Create uploads directory if it doesn't exist
if (!existsSync(uploadsDir)) {
  mkdirSync(uploadsDir, { recursive: true });
}

export const multerOptions: MulterOptions = {
  storage: diskStorage({
    destination: (req, file, cb) => {
      cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
      const timestamp = Date.now();
      const randomId = Math.random().toString(36).substring(2, 9);
      const ext = file.originalname.split('.').pop();
      cb(null, `image-${timestamp}-${randomId}.${ext}`);
    },
  }),
  fileFilter: (req, file, cb) => {
    // Check file type
    const allowedMimes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ];

    if (!allowedMimes.includes(file.mimetype)) {
      cb(
        new BadRequestException(
          'Only image files are allowed (jpeg, png, gif, webp)',
        ),
        false,
      );
    } else {
      cb(null, true);
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
};

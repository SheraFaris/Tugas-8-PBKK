import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  PayloadTooLargeException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { multerOptions } from './multer.config';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('upload')
export class UploadController {
  @Post()
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('image', multerOptions))
  uploadFile(@UploadedFile() file?: Express.Multer.File) {
    if (!file) {
      return { imagePath: null };
    }

    return { imagePath: file.filename };
  }
}

import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create test user
  const hashedPassword = await bcrypt.hash('test123', 10);
  
  const user = await prisma.user.create({
    data: {
      username: 'ananda.farisgr@gmail.com',
      password: hashedPassword,
    },
  });

  console.log('Test user created:', user.username);
  console.log('Password: test123');

  // Create some sample posts
  const post1 = await prisma.post.create({
    data: {
      content: 'Hello! This is my first post.',
      authorId: user.username,
    },
  });

  const post2 = await prisma.post.create({
    data: {
      content: 'Check out this amazing feature!',
      imagePath: 'image-1702986000000-abc123.jpg',
      authorId: user.username,
    },
  });

  console.log('Sample posts created');
  console.log('Post 1:', post1.id);
  console.log('Post 2:', post2.id);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });

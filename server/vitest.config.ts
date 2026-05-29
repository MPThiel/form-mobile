import { defineConfig } from 'vitest/config';

// Provide a stub DATABASE_URL so PrismaClient can instantiate in unit / smoke
// tests that don't actually hit Postgres. Tests that need a real DB should
// override this in their own setup.
process.env.DATABASE_URL ??= 'postgresql://test:test@localhost:5432/test';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    include: ['test/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
    },
  },
});

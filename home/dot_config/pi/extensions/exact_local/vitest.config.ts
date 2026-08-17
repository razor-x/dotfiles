import { defineConfig } from 'vitest/config'

export default defineConfig({
  resolve: {
    alias: {
      '@/': new URL('./src/lib', import.meta.url).pathname,
      test: new URL('./test', import.meta.url).pathname,
    },
  },
  test: {
    include: ['src/**/*.test.ts', 'test/**/*.test.ts'],
  },
})

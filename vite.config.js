import { defineConfig } from 'vite';

export default defineConfig({
  base: process.env.NODE_ENV === 'production' ? '/hoozmo/' : '/',
  // allow overriding public dir via env var so we can use a temporary folder during CI/build
  publicDir: process.env.PUBLIC_DIR || 'public',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsInlineLimit: 0,
  },
  server: {
    port: 3000,
    open: true,
  },
  // include Ruby files as assets so they can be copied/served if referenced
  assetsInclude: ['**/*.rb']
});

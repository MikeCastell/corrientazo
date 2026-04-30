import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0', // Permite conexiones en red local
    cors: true,      // Evita bloqueos de CORS
    allowedHosts: true, // Para evitar problemas de host con ngrok
  }
})

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { keycloakify } from 'keycloakify/vite-plugin'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    keycloakify({
      accountThemeImplementation: "none"
    })
  ],
})

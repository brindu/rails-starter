import { defineConfig } from "vite";
import rails from "rails-vite-plugin";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [rails({ sourceDir: "app/frontend" }), tailwindcss()],
});

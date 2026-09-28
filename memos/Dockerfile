FROM node:22-alpine AS frontend
WORKDIR /app
RUN npm install -g pnpm
COPY src/web/package.json src/web/pnpm-lock.yaml ./
RUN pnpm install
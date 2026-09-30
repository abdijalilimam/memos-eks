FROM node:22-alpine AS frontend
WORKDIR /app
RUN npm install -g pnpm
COPY web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml ./
COPY web/patches ./patches
RUN pnpm install --frozen-lockfile
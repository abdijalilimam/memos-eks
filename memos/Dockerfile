FROM node:22-alpine AS frontend
RUN apk add --no-cache libc6-compat && npm install -g pnpm
WORKDIR /web
COPY web/ .
RUN pnpm install --frozen-lockfile && pnpm release

FROM golang:1.27-alpine AS backend
WORKDIR /app
COPY . .
COPY --from=frontend /server/frontend/dist ./server/frontend/dist
RUN CGO_ENABLED=0 go build -o memos ./cmd/memos

FROM alpine:3.21
RUN adduser -D -u 1001 nonroot && mkdir -p /var/opt/memos && chown nonroot /var/opt/memos
COPY --from=backend /app/memos /usr/local/bin/memos
USER nonroot
WORKDIR /var/opt/memos
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/memos"]
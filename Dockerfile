FROM --platform=linux/amd64 node:24-bookworm-slim

ENV NODE_ENV=production
ENV PORT=3000
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src/ ./src/
COPY bin/ ./bin/

RUN chmod 755 ./bin/*

USER node

EXPOSE 3000

CMD ["node", "src/000.js"]
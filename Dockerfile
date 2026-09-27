FROM --platform=linux/amd64 node:24-bookworm-slim

ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src/ ./src/
COPY bin/ ./bin/

RUN chmod 755 ./bin/*

USER node

EXPOSE 3000

CMD ["npm", "start"]
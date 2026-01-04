FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app

ARG VERSION=unknown
ARG BUILD_DATE=unknown
ENV VERSION=$VERSION
ENV BUILD_DATE=$BUILD_DATE

COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER node
EXPOSE 3000
CMD ["npm", "start"]

FROM node:18-alpine
WORKDIR /app
ARG VERSION=1.0.0
ENV VERSION=$VERSION
COPY package*.json ./
RUN npm install --production
COPY . .
USER node
EXPOSE 3000
CMD ["npm", "start"]

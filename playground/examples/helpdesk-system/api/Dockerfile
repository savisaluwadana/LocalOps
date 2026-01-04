FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
USER node
EXPOSE 8000
CMD ["npm", "start"]

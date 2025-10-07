FROM node:20-alpine
WORKDIR /app
COPY package.json package.json
COPY package-lock.json package-lock.json
RUN npm ci --only=production || true
COPY . .
RUN npm run build
EXPOSE 4001
CMD ["node","dist/index.js"]

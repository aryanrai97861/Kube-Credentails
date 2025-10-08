FROM node:20-alpine
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Remove devDependencies to reduce image size
RUN npm ci --only=production && npm cache clean --force

# Create directory for shared database
RUN mkdir -p /app/shared

EXPOSE 4001
CMD ["node", "dist/index.js"]

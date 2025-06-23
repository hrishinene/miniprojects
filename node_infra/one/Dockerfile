# 1. Use official Node.js image
FROM node:18

# 2. Set working directory
WORKDIR /app

# 3. Copy dependencies and install
COPY package*.json ./
RUN npm install

# 4. Copy the rest of the app
COPY . .

# 5. Build TypeScript
RUN npm run build

# 6. Expose port
EXPOSE 3000

# 7. Run the app
CMD ["npm", "start"]


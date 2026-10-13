# 1. Base Image nhẹ nền tảng Alpine Linux
FROM node:18-alpine

# 2. Khai báo thư mục làm việc trong container
WORKDIR /app

# 3. Khai báo biến môi trường PORT
ENV PORT=3000

# 4. Sao chép tệp định nghĩa dependencies để tận dụng Docker layer cache
COPY package*.json ./

# 5. Cài đặt các gói phụ thuộc
RUN npm install

# 6. Sao chép toàn bộ mã nguồn ứng dụng vào container
COPY . .

# 7. Khai báo cổng lắng nghe của container
EXPOSE 3000

# 8. Lệnh khởi chạy ứng dụng dưới dạng exec form
CMD ["node", "server.js"]

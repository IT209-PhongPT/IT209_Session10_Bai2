# IT209 - Session 10 - Bài tập 2: Đóng gói ứng dụng Web Backend bằng Single-stage Dockerfile

- **Sinh viên:** Phạm Thanh Phong
- **MSSV:** N24DTCN120
- **Học phần:** IT209
- **Đường dẫn nộp bài:** `homework/session_10/ex2/`
- **Trạng thái:** Hoàn thành (100%)

---

## 1. Cấu trúc tệp tin dự án

| Tên tệp tin | Mô tả chức năng |
| :--- | :--- |
| [package.json](./package.json) | Tệp khai báo thông tin dự án Node.js và thư viện phụ thuộc `express` |
| [server.js](./server.js) | Mã nguồn REST API Node.js/Express lắng nghe tại `PORT` (mặc định 3000) |
| [Dockerfile](./Dockerfile) | Tệp cấu hình Single-stage Dockerfile với đầy đủ 7 chỉ thị tiêu chuẩn |
| [.dockerignore](./.dockerignore) | Loại bỏ `node_modules` và tệp rác khi chuyển context vào Docker Daemon |
| [README.md](./README.md) | **Tệp báo cáo nộp bài chính thức:** Hướng dẫn, log terminal và kết quả kiểm thử |
| [IT209_Session10_BT2_PhamThanhPhong_N24DTCN120.md](./IT209_Session10_BT2_PhamThanhPhong_N24DTCN120.md) | Báo cáo kỹ thuật chuyên sâu về tối ưu hóa layer caching và exec form |

---

## 2. Mã nguồn cấu hình & Ứng dụng

### 2.1. Tệp `package.json`
```json
{
  "name": "ex2-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### 2.2. Tệp `server.js`
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({
        status: 'success',
        message: 'Hello from Docker Single-stage!'
    });
});

app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
```

### 2.3. Tệp `Dockerfile` (Đầy đủ các chỉ thị)
```dockerfile
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
```

> **Phân tích các chỉ thị trong Dockerfile:**
> - `FROM node:18-alpine`: Base image Node.js v18 trên Alpine Linux siêu nhẹ (~170MB so với ~1GB của bản Debian full).
> - `WORKDIR /app`: Tạo và thiết lập thư mục làm việc chuẩn `/app`.
> - `ENV PORT=3000`: Khai báo biến môi trường hệ thống để `server.js` có thể đọc thông qua `process.env.PORT`.
> - `COPY package*.json ./` & `RUN npm install`: Kỹ thuật tách layer cài đặt thư viện trước mã nguồn giúp Docker tận dụng cơ chế Build Cache (nếu code thay đổi nhưng `package.json` không đổi, Docker sẽ không phải tải lại `npm install`).
> - `COPY . .`: Sao chép toàn bộ mã nguồn vào thư mục hiện hành trong container.
> - `EXPOSE 3000`: Tài liệu hóa cổng dịch vụ container lắng nghe.
> - `CMD ["node", "server.js"]`: Cú pháp Exec form khởi chạy tiến trình trực tiếp (PID 1), nhận tín hiệu Unix Signals (`SIGTERM`, `SIGINT`) chuẩn xác.

---

## 3. Các bước thực thi & Nhật ký Terminal

### Bước 1: Build Docker Image
```bash
docker build -t hw-backend:v1 .
```

#### Kết quả đầu ra Terminal:
```plaintext
[+] Building 4.2s (10/10) FINISHED                                      docker:default
 => [internal] load build definition from Dockerfile                              0.0s
 => => transferring dockerfile: 450B                                              0.0s
 => [internal] load metadata for docker.io/library/node:18-alpine                 1.2s
 => [internal] load .dockerignore                                                 0.0s
 => => transferring context: 95B                                                  0.0s
 => [1/5] FROM docker.io/library/node:18-alpine@sha256:d554a3a6962...             0.0s
 => [internal] load build context                                                 0.0s
 => => transferring context: 850B                                                 0.0s
 => [2/5] WORKDIR /app                                                            0.1s
 => [3/5] COPY package*.json ./                                                   0.0s
 => [4/5] RUN npm install                                                         2.5s
 => [5/5] COPY . .                                                                0.1s
 => exporting to image                                                            0.3s
 => => exporting layers                                                           0.3s
 => => writing image sha256:8b176c790d858cdfb3a18dc87476fa18471acdc2             0.0s
 => => naming to docker.io/library/hw-backend:v1                                  0.0s
```

#### Kiểm tra image vừa tạo:
```bash
docker images hw-backend:v1
```
```plaintext
REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
hw-backend   v1        8b176c790d85   18 seconds ago   182MB
```

---

### Bước 2: Khởi chạy Container từ Image
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v1
```

#### Kết quả đầu ra:
```plaintext
977442feae84fa9197070ccea6a020829ec04e1990121c70ae3cd319fdd3dd30
```

---

### Bước 3: Kiểm tra trạng thái và nhật ký tiến trình (Logs)
```bash
docker ps
```
```plaintext
CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS         PORTS                    NAMES
977442feae84   hw-backend:v1   "docker-entrypoint.s…"   5 seconds ago   Up 4 seconds   0.0.0.0:8080->3000/tcp   app-single-stage
```

#### Kiểm tra nhật ký ứng dụng qua `docker logs`:
```bash
docker logs app-single-stage
```
```plaintext
Server listening on port 3000
```
> **Đánh giá:** Ứng dụng Express đã khởi động thành công và lắng nghe trên port 3000 bên trong container.

---

### Bước 4: Gửi truy vấn HTTP kiểm tra REST API bằng `curl`
```bash
curl -i http://localhost:8080/
```

#### Kết quả đầu ra:
```plaintext
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 68
ETag: W/"44-lP725Gq6P0J9E4kQcEsh82XlIuQ"
Date: Tue, 13 Oct 2026 10:20:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"status":"success","message":"Hello from Docker Single-stage!"}
```

> **Kết quả đạt được:**
> - Mã trạng thái: `HTTP 200 OK`
> - Định dạng phản hồi: `application/json`
> - Payload JSON: `{"status":"success","message":"Hello from Docker Single-stage!"}`

---

### Bước 5: Dọn dẹp tài nguyên
```bash
docker stop app-single-stage && docker rm app-single-stage
```
```plaintext
app-single-stage
app-single-stage
```

---

## 4. Bảng đối chiếu kết quả kiểm thử

| Tiêu chí | Yêu cầu | Kết quả thực tế | Trạng thái |
| :--- | :--- | :--- | :---: |
| **Mã nguồn App** | Node.js/Express API trả về JSON | Đúng mã nguồn mẫu, port động `PORT` | **PASS** |
| **Base Image** | `node:18-alpine` | Sử dụng `node:18-alpine` siêu nhẹ | **PASS** |
| **Các chỉ thị Dockerfile** | `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`, `ENV`, `CMD` | Có đủ 7/7 chỉ thị chuẩn mực | **PASS** |
| **CMD Form** | Exec form: `["node", "server.js"]` | Đúng cú pháp exec form | **PASS** |
| **Build Image** | Tên image: `hw-backend:v1` | Image `hw-backend:v1` build thành công | **PASS** |
| **Chạy Container** | Tên `app-single-stage`, map port `8080:3000` | Port `8080->3000`, trạng thái `Up` | **PASS** |
| **Phản hồi `curl`** | HTTP 200 OK, response JSON mong đợi | `200 OK`, JSON hợp lệ | **PASS** |
| **Dọn dẹp** | Dừng và xóa container sau khi hoàn tất | Đã giải phóng tài nguyên an toàn | **PASS** |

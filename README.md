
## README for Deployment

### 1. Cài đặt Docker và Docker Compose

#### Windows

1. Tải Docker Desktop từ [docker.com](https://www.docker.com/products/docker-desktop).
2. Chạy file cài đặt và làm theo hướng dẫn.
3. Sau khi cài đặt, khởi động Docker Desktop và đảm bảo Docker đang chạy.

#### Ubuntu

1. Cài đặt Docker:
   ```sh
   sudo apt-get update
   sudo apt-get install -y \
       apt-transport-https \
       ca-certificates \
       curl \
       software-properties-common
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
       $(lsb_release -cs) \
       stable"
   sudo apt-get update
   sudo apt-get install -y docker-ce
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. Cài đặt Docker Compose:
   ```sh
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Kiểm tra cài đặt:
   ```sh
   docker --version
   docker-compose --version
   ```

#### CentOS

1. Cài đặt Docker:
   ```sh
   sudo yum install -y yum-utils
   sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   sudo yum install -y docker-ce docker-ce-cli containerd.io
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. Cài đặt Docker Compose:
   ```sh
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

3. Kiểm tra cài đặt:
   ```sh
   docker --version
   docker-compose --version
   ```

### 2. Hướng dẫn chạy lệnh `make deploy-prod` để build Docker

1. Đảm bảo bạn đã cài đặt `make` trên hệ thống của bạn. Nếu chưa có, cài đặt `make`:
   - **Ubuntu/CentOS**:
     ```sh
     sudo apt-get install make
     ```
   - **CentOS**:
     ```sh
     sudo yum install make
     ```

2. Tạo file `Makefile` với nội dung sau:
   ```makefile
   deploy-prod:
       docker-compose -f docker-compose.yml up --build -d
   ```

3. Chạy lệnh:
   ```sh
   make deploy-prod
   ```

### 3. Hướng dẫn tạo file .env từ .env-sample

1. Tạo một bản sao của file `.env-sample` và đặt tên là `.env`:
   ```sh
   cp .env-sample .env
   ```

2. Mở file `.env` và cập nhật các giá trị cấu hình theo yêu cầu của bạn. Ví dụ:
   ```env
   PROFILE_ENV=prod

   #Postgres Config
   POSTGRES_DB=sign.pro
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=postgres
   POSTGRES_PORT=5435

   #PGADMIN
   PGADMIN_DEFAULT_EMAIL=app.vimesjsc@gmail.com
   PGADMIN_DEFAULT_PASSWORD=12345678x@X
   PGADMIN_DEFAULT_PORT=8080

   #SIGN_API
   API_PORT=8081
   SIGNATURE_API_DB_HOST=pgdatabase
   SIGNATURE_API_DB_PORT=5432
   SIGNATURE_API_DB_USER=postgres
   SIGNATURE_API_DB_PASSWORD=postgres
   SIGNATURE_API_DB_NAME=sign.pro
   ASPNETCORE_ENVIRONMENT=Production

   #BCY
   TERMINAL_BASE_URL=https://mpki2.ca.gov.vn/mpki/v2/
   TERMINAL_RELYING_PARTY=MPKI_BV_108
   TERMINAL_RELYING_PARTY_USER=MPKI_BV_108
   TERMINAL_RELYING_PARTY_PASSWORD=1aMx5OtN
   TERMINAL_RELYING_PARTY_SIGNATURE=b5CICL23CqAteAc+wypDmb3k4xsjMZ/gdOQfEEGwIENMf6DmYpbt/bN5GovF12R4SwbNvlFQX3DCOCwLmU6OLoqm/67zMpqFaSTxLupx2qJZ4reowLTRtSJS/8Vt40ObTei4g+C3KKMS3gD8rGImheM1GG8HPtRBwc/19a1INuggK1wfuj199egtrTD4VvMJNIwPzjyQI1liguODXpwntsiS1GjnkSDLE3b6JJDx2Wtn8SyWfK47/FuHl2OmJchv1jV2lqIm4cf+aHv+zaRfGTHYWdgqXDpwQAcqxmKU8ADIvwrUiUjF6L9PtCwBAMNef4rSKxFhm4r5fNy0VGPyCg==
   TERMINAL_RELYING_PARTY_KEY_STORE=MPKI_BV_108.p12
   TERMINAL_RELYING_PARTY_KEY_STORE_PASSWORD=HV9kNXNP

   #Config connect to Key API
   INTERNAL_BASE_URL=http://116.101.69.142:8001/

   #Config get sign id
   INTERNAL_BASE_HIS_URL=http://vimes.xyz:8005/
   INTERNAL_GET_KEY_URL=key
   INTERNAL_GET_SIGN_ID=api/v1/GetSignID
   INTERNAL_IS_DEBUG_MODE=true

   #GRPC Config
   GPRC_BASE_URL=http://vimes.xyz:55051/
   GPRC_BASE_URL_V1=http://vimes.xyz:50000/
   GPRC_TOKEN=612e1391b4f4144d120eeb9d0fc7da8e
   GPRC_CLIENT_ID=VIMES
   GPRC_USER_ID=vimes
   GPRC_PASSWORD=vimesjsc@2009
   GPRC_DB_NAME=vimes_bacninh1

   #MySign Config
   MYSIGN_BASE_URL=https://remotesigning.viettel.vn
   MYSIGN_PROFILE_ID=adss:ras:profile:001
   MYSIGN_CLIENT_ID=his_vimes_0101609630
   MYSIGN_CLIENT_SECRET=78ed61a849c4ec0ed7e4c71fae0e4379871e1312
   ```

3. Sau khi cập nhật xong, bạn có thể chạy lệnh `make deploy-prod` để build và deploy các dịch vụ Docker.

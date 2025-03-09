# 1️⃣ 基于 OpenResty 官方的 Alpine 镜像
FROM openresty/openresty:alpine

# 2️⃣ 设置环境变量（可根据需要调整版本）
ENV CRS_VERSION=3.3.4

# 3️⃣ 修改 APK 仓库为 Alpine 3.18 的稳定源，并安装依赖
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      git \
      curl \
      bash \
      tzdata && \
    rm -rf /var/cache/apk/*

# 4️⃣ 下载 OWASP Core Rule Set (CRS)
RUN git clone --depth 1 --branch v${CRS_VERSION} \
    https://github.com/coreruleset/coreruleset.git \
    /etc/nginx/modsecurity-crs && \
    mv /etc/nginx/modsecurity-crs/crs-setup.conf.example \
       /etc/nginx/modsecurity-crs/crs-setup.conf

# 5️⃣ 拷贝 ModSecurity 配置文件（你需要在构建上下文中提供 modsecurity.conf 文件）
COPY modsecurity.conf /etc/nginx/modsecurity.conf

# 6️⃣ 拷贝 OpenResty Nginx 配置文件（确保配置中启用了 ModSecurity）
COPY nginx.conf /etc/nginx/nginx.conf

# 7️⃣ 公开 HTTP 端口
EXPOSE 80

# 8️⃣ 启动 OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

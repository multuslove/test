# 1️⃣ 基于 OpenResty 官方的 Alpine 镜像（最新版）
FROM openresty/openresty:alpine

# 2️⃣ 设置版本变量（ModSecurity 与 CRS 版本）
ENV MODSEC_VERSION=3.0.11
ENV CRS_VERSION=3.3.4

# 3️⃣ 覆盖默认 apk 仓库，使用 Alpine 3.18 的稳定源，并安装依赖
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      libmodsecurity \
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

# 5️⃣ 拷贝 ModSecurity 和 Nginx 配置文件
# 确保 modsecurity.conf 和 nginx.conf 文件位于 Dockerfile 同级目录
COPY modsecurity.conf /etc/nginx/modsecurity.conf
COPY nginx.conf /etc/nginx/nginx.conf

# 6️⃣ 公开端口
EXPOSE 80

# 7️⃣ 启动 OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

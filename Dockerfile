# 1️⃣  基于 Alpine
FROM alpine:latest

# 2️⃣  环境变量
ENV MODSEC_VERSION=3.0.11
ENV CRS_VERSION=3.3.4
ENV OPENRESTY_VERSION=1.21.4.1

# 3️⃣  安装基本依赖
RUN apk update && apk add --no-cache \
    openresty \
    openresty-resty \
    openresty-openssl \
    openresty-pcre \
    openresty-zlib \
    libmodsecurity \
    git \
    curl \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# 4️⃣  下载 OWASP Core Rule Set (CRS)
RUN git clone --depth 1 --branch v${CRS_VERSION} https://github.com/coreruleset/coreruleset.git /etc/nginx/modsecurity-crs \
    && mv /etc/nginx/modsecurity-crs/crs-setup.conf.example /etc/nginx/modsecurity-crs/crs-setup.conf

# 5️⃣  下载 OpenResty ModSecurity 模块
RUN git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git /tmp/headers-more-nginx-module && \
    git clone --depth 1 https://github.com/openresty/lua-nginx-module.git /tmp/lua-nginx-module

# 6️⃣  配置 ModSecurity 规则文件
COPY modsecurity.conf /etc/nginx/modsecurity.conf
COPY nginx.conf /etc/nginx/nginx.conf

# 7️⃣  公开端口
EXPOSE 80

# 8️⃣  启动 OpenResty
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

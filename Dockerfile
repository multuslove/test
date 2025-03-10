# 使用OpenResty官方Alpine基础镜像
FROM openresty/openresty:alpine-fat AS builder

# 构建参数
ARG MODSEC_VERSION="3.0.12"
ARG CRS_VERSION="4.0.0-rc1"
ARG LMDB_VERSION="0.9.34"

# 安装编译依赖
RUN apk add --no-cache --virtual .build-deps \
    alpine-sdk \
    automake \
    cmake \
    curl \
    git \
    libtool \
    linux-headers \
    pcre2-dev \
    yajl-dev \
    libxml2-dev \
    libmaxminddb-dev \
    ssdeep-dev

# 编译LMDB
RUN git clone https://github.com/LMDB/lmdb --branch LMDB_${LMDB_VERSION} --depth 1 && \
    make -C lmdb/libraries/liblmdb install && \
    strip /usr/local/lib/liblmdb.so*

# 编译ModSecurity
RUN git clone https://github.com/owasp-modsecurity/ModSecurity --branch "v${MODSEC_VERSION}" --depth 1 --recursive && \
    cd ModSecurity && \
    ./build.sh && \
    ./configure \
        --with-yajl \
        --with-ssdeep \
        --with-pcre2 \
        --with-maxmind \
        --enable-standalone-module && \
    make -j$(nproc) install && \
    strip /usr/local/modsecurity/lib/libmodsecurity.so*

# 最终镜像
FROM openresty/openresty:alpine

# 运行时依赖
RUN apk add --no-cache \
    yajl \
    libmaxminddb \
    pcre2 \
    ssdeep \
    libstdc++ \
    bash

# 复制编译产物
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /usr/local/lib/liblmdb.so* /usr/local/lib/

# 配置ModSecurity
RUN mkdir -p /etc/modsecurity/{data,upload,tmp} && \
    chmod -R 777 /etc/modsecurity && \
    curl -sSL https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/v3/master/unicode.mapping \
        -o /etc/modsecurity/unicode.mapping

# 下载OWASP CRS规则
RUN mkdir -p /opt/owasp-crs && \
    curl -sSL https://github.com/coreruleset/coreruleset/archive/refs/tags/v${CRS_VERSION}.tar.gz | \
    tar -xz --strip-components=1 -C /opt/owasp-crs && \
    mv /opt/owasp-crs/crs-setup.conf.example /opt/owasp-crs/crs-setup.conf

# 内置配置文件
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY modsecurity.conf /etc/modsecurity/

# 启用ModSecurity模块
RUN echo "load_module /usr/local/modsecurity/lib/libmodsecurity.so;" \
    > /usr/local/openresty/nginx/conf/modules/modsecurity.conf

# 暴露端口
EXPOSE 80 443

# 直接运行OpenResty
CMD ["openresty", "-g", "daemon off;"]

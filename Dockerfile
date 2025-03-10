# 修正后的Dockerfile

# 使用更稳定的基础镜像
FROM openresty/openresty:alpine-fat AS builder

# 构建参数
ARG MODSEC_VERSION="3.0.12"
ARG CRS_VERSION="3.3.4"  # 改用稳定版CRS
ARG LMDB_VERSION="0.9.34"

# 配置Alpine镜像源
RUN echo "https://mirrors.aliyun.com/alpine/v3.18/main/" > /etc/apk/repositories && \
    echo "https://mirrors.aliyun.com/alpine/v3.18/community/" >> /etc/apk/repositories

# 安装编译依赖（修正版）
RUN apk update && \
    apk add --no-cache --virtual .build-deps \
    alpine-sdk \
    automake \
    autoconf \
    cmake \
    curl \
    git \
    libtool \
    linux-headers \
    pcre2-dev \
    yajl-dev \
    libxml2-dev \
    libmaxminddb-dev \
    ssdeep-dev \
    g++ \
    make \
    flex \
    bison \
    ragel

# 编译LMDB（添加清理步骤）
RUN git clone https://github.com/LMDB/lmdb --branch LMDB_${LMDB_VERSION} --depth 1 && \
    make -C lmdb/libraries/liblmdb install && \
    strip /usr/local/lib/liblmdb.so* && \
    rm -rf lmdb

# 编译ModSecurity（优化构建步骤）
RUN git clone https://github.com/owasp-modsecurity/ModSecurity --branch "v${MODSEC_VERSION}" --depth 1 --recursive && \
    cd ModSecurity && \
    ./build.sh && \
    ./configure \
        --prefix=/usr/local/modsecurity \
        --with-yajl \
        --with-ssdeep \
        --with-pcre2 \
        --with-maxmind \
        --enable-standalone-module && \
    make -j$(nproc) && \
    make install && \
    strip /usr/local/modsecurity/lib/libmodsecurity.so* && \
    cd .. && \
    rm -rf ModSecurity

# 最终镜像
FROM openresty/openresty:alpine

# 配置运行时环境
RUN echo "https://mirrors.aliyun.com/alpine/v3.18/main/" > /etc/apk/repositories && \
    echo "https://mirrors.aliyun.com/alpine/v3.18/community/" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
    yajl \
    libmaxminddb \
    pcre2 \
    ssdeep \
    libstdc++ \
    bash \
    tzdata

# 剩余部分保持不变...

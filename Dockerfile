# 基于OpenResty官方镜像构建
FROM openresty/openresty:alpine AS builder

# 构建参数
ARG MODSEC_VERSION="3.0.11"
ARG CRS_VERSION="4.0.0-rc1"
ARG LMDB_VERSION="0.9.34"
ARG LUAJIT_VERSION="2.1-20240510"

# 第一阶段：编译ModSecurity和相关组件
RUN set -eux; \
    apk add --no-cache \
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
        ssdeep-dev \
        lua${LUAJIT_VERSION}-dev; \
    \
    # 编译LMDB
    git clone https://github.com/LMDB/lmdb --branch LMDB_${LMDB_VERSION} --depth 1; \
    make -C lmdb/libraries/liblmdb install; \
    \
    # 编译ModSecurity
    git clone https://github.com/owasp-modsecurity/ModSecurity --branch "v${MODSEC_VERSION}" --depth 1 --recursive; \
    cd ModSecurity; \
    ./build.sh; \
    ./configure \
        --with-yajl \
        --with-ssdeep \
        --with-pcre2 \
        --with-maxmind \
        --enable-standalone-module; \
    make -j$(nproc) install; \
    strip /usr/local/modsecurity/lib/libmodsecurity.so*

# 第二阶段：构建OpenResty集成
FROM openresty/openresty:alpine

# 运行时依赖
RUN apk add --no-cache \
        yajl \
        libmaxminddb \
        pcre2 \
        ssdeep \
        libstdc++; \
    ln -s /usr/local/openresty/luajit/bin/luajit-2.1.0-beta3 /usr/local/bin/luajit

# 复制编译产物
COPY --from=builder /usr/local/modsecurity /usr/local/modsecurity
COPY --from=builder /usr/local/lib/liblmdb.so* /usr/local/lib/

# 配置ModSecurity
RUN set -eux; \
    mkdir -p /etc/modsecurity/{data,upload,tmp}; \
    chmod -R 777 /etc/modsecurity; \
    curl -sSL https://raw.githubusercontent.com/owasp-modsecurity/ModSecurity/v3/master/unicode.mapping \
        -o /etc/modsecurity/unicode.mapping

# 下载OWASP CRS规则
RUN set -eux; \
    mkdir -p /opt/owasp-crs; \
    curl -sSL https://github.com/coreruleset/coreruleset/archive/refs/tags/v${CRS_VERSION}.tar.gz | \
    tar -xz --strip-components=1 -C /opt/owasp-crs; \
    mv /opt/owasp-crs/crs-setup.conf.example /opt/owasp-crs/crs-setup.conf

# 配置OpenResty
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY modsecurity.conf /etc/modsecurity/modsecurity.conf

# 动态模块配置
RUN echo "load_module /usr/local/modsecurity/lib/libmodsecurity.so;" \
    > /usr/local/openresty/nginx/conf/modules/modsecurity.conf

# 启动脚本
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 环境变量
ENV MODSEC_RULE_ENGINE=On \
    MODSEC_AUDIT_ENGINE=RelevantOnly \
    PATH=/usr/local/openresty/nginx/sbin:$PATH

# 暴露端口
EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openresty", "-g", "daemon off;"]

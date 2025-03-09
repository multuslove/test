# 1️⃣ 使用更新的 Alpine 版本
FROM openresty/openresty:alpine

# 2️⃣ 设置环境变量
ENV CRS_VERSION=3.3.4 \
    MODSEC_DIR=/etc/nginx/modsecurity.d

# 3️⃣ 创建目录结构
RUN mkdir -p ${MODSEC_DIR}/crs ${MODSEC_DIR}/rules ${MODSEC_DIR}/conf

# 4️⃣ 修正的依赖安装步骤
RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      git \
      # 修正的 ModSecurity 包名
      modsecurity \
      modsecurity-nginx \
      yajl \
      lmdb \
      libstdc++ \
      # 新增必要依赖
      libgcc \
      openssl \
      pcre \
      geoip \
      && rm -rf /var/cache/apk/*

# 5️⃣ 下载CRS核心规则集
RUN git clone --depth 1 --branch v${CRS_VERSION} \
    https://github.com/coreruleset/coreruleset.git \
    ${MODSEC_DIR}/crs && \
    mv ${MODSEC_DIR}/crs/crs-setup.conf.example ${MODSEC_DIR}/crs/crs-setup.conf && \
    ln -s ${MODSEC_DIR}/crs/rules/ ${MODSEC_DIR}/rules

# 6️⃣ 生成CRS配置
RUN echo "Include /etc/nginx/modsecurity.d/crs/crs-setup.conf" > ${MODSEC_DIR}/conf/crs.conf && \
    echo "Include /etc/nginx/modsecurity.d/crs/rules/*.conf" >> ${MODSEC_DIR}/conf/crs.conf

# 7️⃣ 拷贝配置文件
COPY modsecurity.conf ${MODSEC_DIR}/modsecurity.conf
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

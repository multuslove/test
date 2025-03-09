# 1️⃣ 基于 OpenResty 的 Alpine 镜像
FROM openresty/openresty:alpine

# 2️⃣ 设置环境变量
ENV CRS_VERSION=3.3.4 \
    MODSEC_DIR=/etc/nginx/modsecurity.d

# 3️⃣ 创建目录结构
RUN mkdir -p ${MODSEC_DIR}/crs ${MODSEC_DIR}/rules ${MODSEC_DIR}/conf

# 4️⃣ 安装依赖（修复关键步骤）
RUN apk update && \
    apk add --no-cache \
      git \
      modsecurity \
      yajl \
      lmdb \
      libstdc++ \
      libgcc \
      openssl \
      pcre \
      bash && \
    rm -rf /var/cache/apk/*

# 5️⃣ 下载CRS核心规则集
RUN git clone --depth 1 --branch v${CRS_VERSION} \
    https://github.com/coreruleset/coreruleset.git \
    ${MODSEC_DIR}/crs && \
    mv ${MODSEC_DIR}/crs/crs-setup.conf.example ${MODSEC_DIR}/crs/crs-setup.conf && \
    ln -s ${MODSEC_DIR}/crs/rules/ ${MODSEC_DIR}/rules

# 6️⃣ 配置ModSecurity（自动生成配置文件）
RUN echo "Include /etc/nginx/modsecurity.d/crs/crs-setup.conf" > ${MODSEC_DIR}/conf/crs.conf && \
    echo "Include /etc/nginx/modsecurity.d/crs/rules/*.conf" >> ${MODSEC_DIR}/conf/crs.conf

# 7️⃣ 拷贝核心配置
COPY modsecurity.conf ${MODSEC_DIR}/modsecurity.conf

# 8️⃣ 拷贝Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 9️⃣ 暴露端口
EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

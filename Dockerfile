# 1️⃣ 基于 OpenResty 的 Alpine 镜像
FROM openresty/openresty:alpine

# 2️⃣ 设置环境变量
ENV CRS_VERSION=3.3.4 \
    MODSEC_DIR=/etc/nginx/modsecurity.d

# 3️⃣ 创建目录结构
RUN mkdir -p ${MODSEC_DIR}/crs ${MODSEC_DIR}/rules ${MODSEC_DIR}/conf

# 4️⃣ 安装依赖
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      git \
      libmodsecurity \
      yajl \
      lmdb \
      libstdc++ && \
    rm -rf /var/cache/apk/*

# 5️⃣ 下载CRS核心规则集
RUN git clone --depth 1 --branch v${CRS_VERSION} \
    https://github.com/coreruleset/coreruleset.git \
    ${MODSEC_DIR}/crs && \
    mv ${MODSEC_DIR}/crs/crs-setup.conf.example ${MODSEC_DIR}/crs/crs-setup.conf && \
    ln -s ${MODSEC_DIR}/crs/rules/ ${MODSEC_DIR}/rules

# 6️⃣ 配置ModSecurity（自动生成crs.conf）
RUN echo "Include /etc/nginx/modsecurity.d/crs/crs-setup.conf" > ${MODSEC_DIR}/conf/crs.conf && \
    echo "Include /etc/nginx/modsecurity.d/crs/rules/*.conf" >> ${MODSEC_DIR}/conf/crs.conf && \
    echo "SecRuleUpdateTargetById 932130 \"!ARGS:search_query\"" >> ${MODSEC_DIR}/conf/crs.conf && \
    echo "SecRuleUpdateTargetById 942100 \"!ARGS:json_payload\"" >> ${MODSEC_DIR}/conf/crs.conf

# 7️⃣ 拷贝核心配置文件
COPY modsecurity.conf ${MODSEC_DIR}/modsecurity.conf

# 8️⃣ 拷贝Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 9️⃣ 暴露端口
EXPOSE 80

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

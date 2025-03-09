# 1️⃣ 基于 OpenResty 官方的 Alpine 镜像
FROM openresty/openresty:alpine

# 2️⃣ 设置环境变量（可根据需要调整版本）
ENV CRS_VERSION=3.3.4 \
    MODSEC_LOG_DIR=/var/log/modsecurity

# 🎯 3️⃣ 创建必要的日志目录
RUN mkdir -p ${MODSEC_LOG_DIR} && \
    chmod -R 755 ${MODSEC_LOG_DIR}

# 4️⃣ 修改 APK 仓库并安装依赖
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
      git \
      curl \
      bash \
      tzdata \
      # 🎯 新增ModSecurity依赖
      libmodsecurity \
      modsecurity-crs \
      yajl && \
    rm -rf /var/cache/apk/*

# 5️⃣ 下载 OWASP Core Rule Set (CRS)
RUN git clone --depth 1 --branch v${CRS_VERSION} \
    https://github.com/coreruleset/coreruleset.git \
    /etc/nginx/modsecurity-crs && \
    mv /etc/nginx/modsecurity-crs/crs-setup.conf.example \
       /etc/nginx/modsecurity-crs/crs-setup.conf

# 🎯 6️⃣ 配置CRS规则集
RUN sed -i 's/SecDefaultAction "phase:1,log,auditlog,pass"/SecDefaultAction "phase:1,log,auditlog,deny,status:403"/g' \
    /etc/nginx/modsecurity-crs/crs-setup.conf && \
    sed -i 's/SecDefaultAction "phase:2,log,auditlog,pass"/SecDefaultAction "phase:2,log,auditlog,deny,status:403"/g' \
    /etc/nginx/modsecurity-crs/crs-setup.conf

# 7️⃣ 拷贝ModSecurity配置文件
COPY modsecurity.conf /etc/nginx/modsecurity.conf

# 🎯 8️⃣ 创建规则加载配置文件
RUN echo "Include /etc/nginx/modsecurity-crs/crs-setup.conf" > /etc/nginx/modsecurity.conf.d/crs.conf && \
    echo "Include /etc/nginx/modsecurity-crs/rules/*.conf" >> /etc/nginx/modsecurity.conf.d/crs.conf

# 9️⃣ 拷贝Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 🔟 暴露端口
EXPOSE 80

# 🎯 启动前验证配置
CMD ["sh", "-c", \
    "/usr/local/openresty/bin/openresty -t && \
    /usr/local/openresty/bin/openresty -g 'daemon off;'"]

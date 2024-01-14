FROM ubuntu:20.04 as builder
ENV LUAJIT_LIB=/usr/local/lib/lua/5.1
ENV LUAJIT_INC=/usr/local/include/luajit-2.1
RUN apt update && apt install -y \
   wget \
   git \
   ca-certificates \
   make \
   build-essential \
   libpcre++-dev \
   libssl-dev \
   zlib1g-dev && \
   export LUAJIT_INC=/usr/local/include/luajit-2.1 && \
   export LUAJIT_LIB=/usr/local/lib/lua/5.1 && \
   mkdir /build && \
   mkdir -p  /var/cache/nginx/client_temp/ && \
   cd /build && \
   git clone https://github.com/chobits/ngx_http_proxy_connect_module && \
   git clone https://github.com/openresty/lua-nginx-module && \
   git clone https://github.com/vision5/ngx_devel_kit && \
   git clone https://github.com/openresty/luajit2 && \
   git clone https://github.com/openresty/lua-resty-core && \
   git clone https://github.com/openresty/lua-resty-lrucache && \
   wget https://nginx.org/download/nginx-1.21.6.tar.gz && \
   tar -xzf nginx-1.21.6.tar.gz
RUN cd /build && cd nginx-1.21.6 && \
   export LUAJIT_INC=/usr/local/include/luajit-2.1 && \
   export LUAJIT_LIB=/usr/local/lib/lua/5.1 && \
   patch -p1 < /build/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_102101.patch && \
   cd - && \
   cd luajit2 && make && make install && \
   cd - && \
   cd lua-resty-core && \
   make && \
   make install && \
   cd - && \
   cd lua-resty-lrucache && \
   make && \
   make install && \
   cd - && \
   cp /usr/local/lib/libluajit-5.1.* /usr/local/lib/lua/5.1/
RUN cd /build/nginx-1.21.6 && \
   export LUAJIT_INC=/usr/local/include/luajit-2.1 && \
   export LUAJIT_LIB=/usr/local/lib/lua/5.1 && \
   ./configure --add-module=/build/ngx_devel_kit \
   --add-module=/build/ngx_http_proxy_connect_module \
   --add-module=/build/lua-nginx-module \
   --prefix=/etc/nginx \
   --sbin-path=/usr/sbin/nginx \
   --modules-path=/usr/lib/nginx/modules \
   --conf-path=/etc/nginx/nginx.conf \
   --error-log-path=/var/log/nginx/error.log \
   --http-log-path=/var/log/nginx/access.log \
   --pid-path=/var/run/nginx.pid \
   --lock-path=/var/run/nginx.lock \
   --http-client-body-temp-path=/var/cache/nginx/client_temp \
   --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
   --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
   --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
   --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
   --user=nginx \
   --without-http_fastcgi_module ${NGINX_DEBUG:+--debug} \
   --with-ld-opt="-Wl,-rpath,/usr/local/lib/lua/5.1" \
   --group=nginx \
   --with-compat \
   --with-file-aio \
   --with-threads \
   --with-http_addition_module \
   --with-http_auth_request_module \
   --with-http_dav_module \
   --with-http_flv_module \
   --with-http_gunzip_module \
   --with-http_gzip_static_module \
   --with-http_mp4_module \
   --with-http_random_index_module \
   --with-http_realip_module \
   --with-http_secure_link_module \
   --with-http_slice_module \
   --with-http_ssl_module \
   --with-http_stub_status_module \
   --with-http_sub_module \
   --with-http_v2_module \
   --with-mail \
   --with-mail_ssl_module \
   --with-stream \
   --with-stream_realip_module \
   --with-stream_ssl_module \
   --with-stream_ssl_preread_module && \
   make && make install && \
   cd / && rm -rf /build

FROM nginx:1.21.6
COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY ./nginx.conf_file /etc/nginx/nginx.conf
COPY ./rewrite_lua_auth /etc/nginx/rewrite_lua.lua

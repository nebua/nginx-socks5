FROM ubuntu:18.04 AS nginx-build

ENV NGINX_VERSION 1.18.0

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    autoconf \
    automake \
    build-essential \
    libtool \
    pkgconf \
    wget \
    git \
    zlib1g-dev \
    libssl-dev \
    libpcre3-dev \
    libxml2-dev \
    libyajl-dev \
    lua5.2-dev \
    libgeoip-dev \
    libcurl4-openssl-dev \
    openssl

WORKDIR /build

RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    gunzip -c nginx-${NGINX_VERSION}.tar.gz | tar xvf -

RUN git clone https://github.com/AgrawalAmey/socks-nginx-module /build/socks-nginx-module && cd /build/socks-nginx-module && git checkout a10091b2ca6a3f5ffd1c6d6228859376bbd2d1b0

WORKDIR /build/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/nginx/nginx \
    --modules-path=/usr/local/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --user=www-data \
    --group=www-data \
    --with-pcre-jit \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_sub_module \
    --with-http_stub_status_module \
    --with-http_v2_module \
    --with-http_secure_link_module \
    --with-stream \
    --with-stream_realip_module \
    --add-module=/build/socks-nginx-module \
    --with-cc-opt='-g -O2 -specs=/usr/share/dpkg/no-pie-compile.specs -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    --with-ld-opt='-specs=/usr/share/dpkg/no-pie-link.specs -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
    --with-http_dav_module
RUN make && \ 
    make install && \
    make modules

FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    libcurl4-openssl-dev  \
    libyajl-dev \
    lua5.2-dev \
    libgeoip-dev \
    vim \
    libxml2 \
    wget && \
    rm -r /var/lib/apt/lists/*

COPY --from=nginx-build /usr/local/nginx/nginx /usr/local/nginx/nginx
COPY --from=nginx-build /etc/nginx /etc/nginx
COPY --from=nginx-build /usr/local/nginx/html /usr/local/nginx/html

RUN mkdir -p /var/log/nginx/ && \
    touch /var/log/nginx/access.log && \
    touch /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/

ENTRYPOINT [ "/usr/local/nginx/nginx", "-g", "daemon off;" ]
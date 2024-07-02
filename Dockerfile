# Stage 1: Build environment
FROM ubuntu:20.04 AS build-env

# Set environment variables to prevent interactive timezone configuration
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Install necessary build dependencies
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    wget \
    git \
    libyajl-dev \
    lua5.2-dev \
    libgeoip-dev \
    libcurl4-openssl-dev \
    build-essential \
    zlib1g-dev \
    libssl-dev \
    libpcre3-dev \
    libxml2-dev \
    vim \
    openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone socks-nginx-module
WORKDIR /build
RUN git clone https://github.com/AgrawalAmey/socks-nginx-module /build/socks-nginx-module && \
    cd /build/socks-nginx-module && \
    git checkout a10091b2ca6a3f5ffd1c6d6228859376bbd2d1b0

# Stage 2: Final image with nginx and required dependencies
FROM ubuntu:20.04

# Set environment variables to prevent interactive timezone configuration
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Install nginx and necessary runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    nginx \
    libcurl4-openssl-dev \
    libyajl-dev \
    lua5.2-dev \
    libgeoip-dev \
    vim \
    libxml2 \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the socks-nginx-module to the final image
COPY --from=build-env /build/socks-nginx-module /usr/local/nginx/socks-nginx-module

# Create nginx configuration directory
RUN mkdir -p /etc/nginx/modules

# Configure nginx to load socks-nginx-module
RUN echo 'load_module "/usr/local/nginx/socks-nginx-module/ngx_http_socks_module.so";' > /etc/nginx/modules/socks_nginx_module.conf

# Create log directory and files
RUN mkdir -p /var/log/nginx/ && \
    touch /var/log/nginx/access.log && \
    touch /var/log/nginx/error.log

# Expose port 80
EXPOSE 80

# Set stop signal and copy nginx configuration files
STOPSIGNAL SIGTERM
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/

# Set nginx as entrypoint
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]

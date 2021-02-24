FROM alpine:3.11

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-mysqli php7-pdo_mysql php7-sqlite3 php7-pdo_sqlite php7-json php7-openssl php7-curl \
    php7-gd php7-gettext php7-zip php7-json php7-zlib php7-phar php7-intl php7-dom php7-xml php7-simplexml php7-ctype \
    php7-session php7-mbstring php7-tokenizer php-xmlwriter php7-iconv php7-redis \
    nginx supervisor curl bash tzdata git gnu-libiconv

ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Set timezone
RUN cp /usr/share/zoneinfo/America/Campo_Grande /etc/localtime \
	&& echo "America/Campo_Grande" >  /etc/timezone \
	&& apk del tzdata

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/php.ini
ENV SESSION_TYPE=files

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Dir application
WORKDIR /var/www/html

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping

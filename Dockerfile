#
# PHP-FPM Dockerfile
#

# Pull base image.
FROM linxlad/docker-nginx

MAINTAINER Nathan Daly <nathand@openobjects.com>

# No tty
ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list
RUN echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list

RUN wget https://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg

RUN apt-get update && \
    apt-get -y install python-software-properties && \
    apt-get update

# Install PHP
RUN apt-get -y --force-yes install php7.0-fpm php7.0-dev php7.0-mcrypt php7.0-mbstring \
    php7.0-gd php7.0-bz2 php7.0-xml php7.0-common php7.0-mysql php-pear

# Install xdebug
RUN pecl install xdebug

RUN echo "zend_extension=xdebug.so" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini
RUN echo "xdebug.remote_enable=1" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini
RUN echo "xdebug.remote_host=localhost" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini
RUN echo "xdebug.remote_port=9108" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini
RUN echo "xdebug.remote_handler=\"dbgp\"" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini
RUN echo "xdebug.remote_connect_back=1" >> /etc/php/7.0/fpm/conf.d/40-xdebug.ini

RUN sed -i '/daemonize /c \
daemonize = no' /etc/php/7.0/fpm/php-fpm.conf

# tweak php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/user = www-data/user = web/g" /etc/php/7.0/fpm/pool.d/www.conf && \
sed -i -e "s/group = www-data/group = staff/g" /etc/php/7.0/fpm/pool.d/www.conf && \
echo "date.timezone = \"Europe/London\"" >> /etc/php/7.0/fpm/php.ini

# fix ownership of sock file for php-fpm
RUN sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf && \
find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN sed -i '/^listen /c \
listen = 9000' /etc/php/7.0/fpm/pool.d/www.conf

RUN sed -i 's/^listen.allowed_clients/;listen.allowed_clients/' /etc/php/7.0/fpm/pool.d/www.conf

EXPOSE 9000

VOLUME ["/etc/php-fpm.d", "/var/log/php-fpm", "/var/www/html"]

ENTRYPOINT ["php-fpm7.0"]

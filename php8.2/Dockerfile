FROM php:8.2.4-fpm

LABEL maintainer="wzc"

ENV DEBIAN_FRONTEND noninteractive

RUN set -ux && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' >/etc/timezone && \
    apt-get install -y --no-install-recommends apt-transport-https ca-certificates && \
    mv /etc/apt/sources.list /etc/apt/sources.list.bak     && \
    touch /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list     && \
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list     && \
    echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list     && \
    echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list     && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list     && \
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list     && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list     && \
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list     && \
    cat /etc/apt/sources.list
RUN docker-php-source extract
RUN apt-get update -y && apt-get install --assume-yes apt-utils && \
    apt-get upgrade -y && \
    mkdir /server && \
    pecl channel-update pecl.php.net && \
    apt-get install -y \
      iputils-ping \
      net-tools \
      telnet \
      curl \
      gnupg \
      openssl \
      xz-utils \
      wget \
      git \
      supervisor \
      alien \
      vim \
      lrzsz \
      ghostscript \
      wkhtmltopdf \
      gnupg2 \
      unixodbc-dev zlib1g-dev \
      libmcrypt-dev \
      libzip-dev zip unzip \
      bzip2 libbz2-dev && \
    docker-php-ext-configure zip && \
    # Install the zip extension
    docker-php-ext-install zip && \
    php -m | grep -q 'zip' && \
    ###########################################################################
    # PHP REDIS EXTENSION
    ###########################################################################
    pecl install redis && \
    pecl install mongodb && \
    pecl install swoole && \
    pecl install igbinary && \
    apt-get -y install imagemagick libmagick++-dev && \
    pecl install imagick && \
    apt-get install libssl-dev && \
    pecl install stomp && \
    pecl install mcrypt && \
    apt-get -y install librabbitmq-dev && \
    pecl install amqp && \
    pecl install xhprof && \
    docker-php-ext-enable redis && \
    docker-php-ext-enable mongodb && \
    docker-php-ext-enable swoole && \
    docker-php-ext-enable imagick && \
    docker-php-ext-enable stomp && \
    docker-php-ext-enable igbinary && \
    docker-php-ext-enable mcrypt && \
    docker-php-ext-enable amqp && \
    docker-php-ext-enable xhprof && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd  && \
    ###########################################################################
    # PHP COMPOSER
    ###########################################################################
    php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
    # 跟换镜像源
#    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer && \
    composer config -g repo.packagist composer https://packagist.org && \
    ###########################################################################
    # PHP EXTEND bcmath
    ###########################################################################
    docker-php-ext-install bcmath && \
    docker-php-ext-install calendar && \
    docker-php-ext-install exif && \
    docker-php-ext-install gettext && \
    docker-php-ext-install sockets && \
    docker-php-ext-install dba && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install pcntl && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install shmop && \
    docker-php-ext-install sysvmsg && \
    docker-php-ext-install sysvsem && \
    docker-php-ext-install sysvshm && \
    docker-php-ext-install soap && \
    sed -i 's/TLSv1.2/TLSv1.0/g' /etc/ssl/openssl.cnf && \
    docker-php-source delete

WORKDIR /server

EXPOSE 9000

CMD ["php-fpm"]


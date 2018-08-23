FROM ubuntu:latest

# prevent interactions with command line
ARG DEBIAN_FRONTEND=noninteractive

# Set the locale
RUN apt-get clean && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN locale-gen fr_FR.UTF-8 \
  && export LANG=fr_FR.UTF-8 \
  && apt-get update \
  && apt-get -y install apache2

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log
RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

VOLUME [ "/var/www/html" ]
WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT [ "/usr/sbin/apache2" ]
CMD ["-D", "FOREGROUND"]

# Change www-data group id for write permission inside the container
RUN sed -ri 's/^www-data:x:33:33:/www-data:x:1000:1000:/' /etc/passwd

RUN apt-get update && \
	apt-get -y install libapache2-mod-php7.2 php7.2 php7.2-cli php7.2-zip php-xdebug php7.2-mbstring sqlite3 php7.2-mysql php-imagick php-memcached php-pear curl imagemagick php7.2-dev php7.2-phpdbg php7.2-gd npm php7.2-json php7.2-curl php7.2-sqlite3 php7.2-intl apache2 vim git-core wget libsasl2-dev libssl-dev libcurl4-openssl-dev autoconf g++ make openssl libssl-dev libcurl4-openssl-dev pkg-config libsasl2-dev libpcre3-dev \
	&& a2enmod headers \
	&& a2enmod rewrite

# Edit some PHP constants
# COPY php.ini /etc/php/7.1/fpm/php.ini (can be a workaround)
RUN sed -e 's/max_execution_time = 30/max_execution_time = 240/' -i /etc/php/7.2/apache2/php.ini
RUN sed -e 's/; max_input_vars = 1000/max_input_vars = 1500/' -i /etc/php/7.2/apache2/php.ini

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y libmcrypt-dev \
    mysql-client libmagickwand-dev --no-install-recommends \
    && pecl install imagick

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libfreetype6-dev \
	curl \
    git \
    zip \
    unzip \
 	libpng-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ======= composer =======
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Define composer cache directory
RUN mkdir -p /tmp/composer && chmod 777 /tmp/composer
ENV COMPOSER_CACHE_DIR=/tmp/composer
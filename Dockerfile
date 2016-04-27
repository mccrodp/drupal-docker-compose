FROM php:5-fpm
MAINTAINER Paul McCrodden <paul.mccrodden@x-team.com>

# Install the PHP extensions we need. *taken from docker-library/drupal Dockerfile*
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libpq-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

# Install packages.
RUN apt-get update && apt-get install -y \
	vim \
	git \
	php5-cli \
	php5-xdebug \
	mysql-client \
	wget \
	iputils-ping \
	unzip \
	libicu-dev \
	libssl-dev
RUN apt-get clean

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install Drush via composer.
RUN composer global require drush/drush:dev-master

# Configure composer bin path for drush inside container and from exec.
RUN echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> /root/.bashrc
ENV PATH /root/.composer/vendor/bin:$PATH

# Setup Nginx
COPY ./config/nginx-docker.conf /etc/nginx/conf.d/default.conf

# Setup PHP.
COPY ./config/php-docker.ini /usr/local/etc/php/conf.d/
COPY ./config/php-docker.ini /etc/php5/cli/conf.d/

# Setup XDebug.
COPY ./config/xdebug-docker.ini /usr/local/etc/php/conf.d/
RUN echo "zend_extension = '$(find / -name xdebug.so 2> /dev/null)'\n$(cat /usr/local/etc/php/conf.d/xdebug-docker.ini)" > /usr/local/etc/php/conf.d/xdebug-docker.ini
RUN cp /usr/local/etc/php/conf.d/xdebug-docker.ini /etc/php5/cli/conf.d/

# Map directory ownership (docker-machine-nfs setup).
RUN usermod -u 501 www-data
RUN usermod -G dialout www-data

# Map directory ownership (standard setup).
#RUN usermod -u 1000 www-data
#RUN usermod -G staff www-data

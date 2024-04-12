FROM php:7.4-fpm

ARG WEB_HOST=$WEB_HOST
ARG WEB_NAME=$WEB_NAME
ARG DB_HOST=$DB_HOST
ARG DB_NAME=$DB_NAME
ARG DB_USER=$DB_USER
ARG DB_PASS=$DB_PASS
ARG WEB_ADMIN_FIRSTNAME=$WEB_ADMIN_FIRSTNAME
ARG WEB_ADMIN_LASTNAME=$WEB_ADMIN_LASTNAME
ARG WEB_ADMIN_EMAIL=$WEB_ADMIN_EMAIL
ARG WEB_ADMIN_USERNAME=$WEB_ADMIN_USERNAME
ARG WEB_ADMIN_PASSWORD=$WEB_ADMIN_PASSWORD
ARG WEB_BASE_CURRENCY=$WEB_BASE_CURRENCY
ARG WEB_CRYPT_KEY=$WEB_CRYPT_KEY
ARG WEB_TIMEZONE=$WEB_TIMEZONE
ARG WEB_SEARCH_ENGINE=$WEB_SEARCH_ENGINE
ARG WEB_ELASTICSEARCH_HOST=$WEB_ELASTICSEARCH_HOST
ARG WEB_ELASTICSEARCH_PORT=$WEB_ELASTICSEARCH_PORT
ARG WEB_ADMIN_URI=$WEB_ADMIN_URI
ARG ENV_TYPE=$ENV_TYPE

RUN echo ${WEB_HOST}

RUN apt-get update -y && apt-get install -y nginx

# PHP_CPPFLAGS are used by the docker-php-ext-* scripts
ENV PHP_CPPFLAGS="$PHP_CPPFLAGS -std=c++11"

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

RUN apt-get update && apt-get install -y \
  cron \
  git \
  gzip \
  libbz2-dev \
  libfreetype6-dev \
  libicu-dev \
  libjpeg62-turbo-dev \
  libmcrypt-dev \
  libonig-dev \
  libpng-dev \
  libsodium-dev \
  libssh2-1-dev \
  libxslt1-dev \
  libzip-dev \
  lsof \
  default-mysql-client \
  rsync \
  nano \
  vim \
  zip \
  procps

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install \
  bcmath \
  bz2 \
  calendar \
  exif \
  gd \
  gettext \
  intl \
  mbstring \
  mysqli \
  opcache \
  pcntl \
  pdo_mysql \
  soap \
  sockets \
  sodium \
  sysvmsg \
  sysvsem \
  sysvshm \
  xsl \
  zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
--install-dir=/usr/local/bin --filename=composer

#copy web directory to /var/www/html
COPY --chown=www-data:www-data ./web/ /var/www/html

COPY nginx-site.conf /etc/nginx/sites-enabled/default

RUN sed -i "s/WEB_NAME/${WEB_NAME}/g" /etc/nginx/sites-enabled/default

#copy custom docker-php.ini to /usr/local/etc/php/conf.d/
COPY docker-php.ini /usr/local/etc/php/conf.d/docker-php.ini

# set workdir to /var/www/html
WORKDIR /var/www/html

RUN ls -la

#for local implementations only.
RUN mkdir -p /var/www/html/pub/media-azure

# ssh
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "$SSH_PASSWD" | chpasswd 

COPY sshd_config /etc/ssh/

COPY init.sh /usr/local/bin/

RUN chmod u+x /usr/local/bin/init.sh

COPY media-rsync.sh /usr/local/bin/

RUN chmod u+x /usr/local/bin/media-rsync.sh

#Robots.txt added for SEO
COPY robots.txt /var/www/html

RUN chown -R www-data:www-data /var/www/html/robots.txt

RUN chmod 777 /var/www/html/robots.txt

#Composer install
RUN composer install

RUN find . -name '.user.ini' -exec sed -i 's/756M/2048M/g' {} + && \
find . -name '.user.ini' -exec sed -i 's/768M/2048M/g' {} +

RUN find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + \
    && find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + \
    && chown -R :www-data . && chmod u+x bin/magento

RUN chmod 777 -R var/ generated/ pub/

#Apply patches
#RUN patch -p1 < MDVA-43395_EE_2.4.3-p1_COMPOSER_v1.patch
#RUN patch -p1 < MDVA-43443_EE_2.4.3-p1_COMPOSER_v1.patch

RUN if [ "$ENV_TYPE" = "INITIAL" ]; then \
    php -d memory_limit=8G bin/magento \
    setup:install \
    --base-url=${WEB_HOST} \ 
    --db-host=${DB_HOST} \
    --db-name=${DB_NAME} \
    --db-user=${DB_USER} \
    --db-password=${DB_PASS} \
    --admin-firstname=${WEB_ADMIN_FIRSTNAME} \
    --admin-lastname=${WEB_ADMIN_LASTNAME} \
    --admin-email=${WEB_ADMIN_EMAIL} \
    --admin-user=${WEB_ADMIN_USERNAME} \
    --admin-password=${WEB_ADMIN_PASSWORD} \
    --language=en_US \
    --currency=${WEB_BASE_CURRENCY} \
    --timezone=${WEB_TIMEZONE} \
    --backend-frontname=${WEB_ADMIN_URI} \
    --key=${WEB_CRYPT_KEY} \
    --search-engine=${WEB_SEARCH_ENGINE} \
    --elasticsearch-host=${WEB_ELASTICSEARCH_HOST} \
    --elasticsearch-port=${WEB_ELASTICSEARCH_PORT} \
    --use-rewrites=1; \
  else \
    sed -i "s/WEB_ADMIN_URI/${WEB_ADMIN_URI}/g" app/etc/env-deploy.php \ 
    && sed -i "s/WEB_CRYPT_KEY/${WEB_CRYPT_KEY}/g" app/etc/env-deploy.php \ 
    && sed -i "s/DB_HOST/${DB_HOST}/g" app/etc/env-deploy.php \ 
    && sed -i "s/DB_NAME/${DB_NAME}/g" app/etc/env-deploy.php \ 
    && sed -i "s/DB_USER/${DB_USER}/g" app/etc/env-deploy.php \ 
    && sed -i "s/DB_PASS/${DB_PASS}/g" app/etc/env-deploy.php \ 
    && mv app/etc/env-deploy.php app/etc/env.php; \
  fi

RUN rm -rf var/di/* var/generation/* var/cache/* var/page_cache/* var/view_preprocessed/* var/composer_home/cache/*

RUN chmod 777 -R var/ generated/ pub/

RUN php -d memory_limit=8G bin/magento maintenance:enable \ 
    && php -d memory_limit=8G bin/magento cache:clean \
    && php -d memory_limit=8G bin/magento setup:upgrade \
    && php -d memory_limit=8G bin/magento setup:di:compile \
    && php -d memory_limit=8G bin/magento setup:static-content:deploy -f \
    && php -d memory_limit=8G bin/magento indexer:reindex \
    && php -d memory_limit=8G bin/magento cache:flush \
    && php -d memory_limit=8G bin/magento cron:install --force \
    && php -d memory_limit=8G bin/magento maintenance:disable

#To disable Full page cache and Magento_Csp module on production.
RUN if [ "$ENV_TYPE" = "PROD" ]; then \
    php -d memory_limit=8G bin/magento cache:disable full_page \
    && php -d memory_limit=8G bin/magento cache:flush; \
  fi

RUN chmod 777 -R var/ generated/ pub/

EXPOSE 80 443 2222 8000

ENTRYPOINT ["sh", "/usr/local/bin/init.sh"]
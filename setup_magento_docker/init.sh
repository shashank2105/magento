#!/bin/bash

service ssh start
crontab -r
(crontab -l 2>/dev/null || true; echo "0 * * * * /usr/local/bin/php /var/www/html/bin/magento cron:run 2>&1 | grep -v 'Ran jobs by schedule' >> /var/www/html/var/log/magento.cron.log") | crontab -
(crontab -l 2>/dev/null || true; echo "0 4 * * * /usr/local/bin/php /var/www/html/bin/magento indexer:reindex >> /var/log/cron.log 2>&1") | crontab -
(crontab -l 2>/dev/null || true; echo "*/5 * * * * /usr/local/bin/media-rsync.sh >> /var/log/cron.log 2>&1") | crontab -
(crontab -l 2>/dev/null || true; echo "*/30 * * * * /usr/bin/rsync -avh /var/www/html/pub/media/* /var/www/html/pub/media-azure/ >> /var/log/cron.log 2>&1") | crontab -
service cron restart
php-fpm -D
nginx -g 'daemon off;'
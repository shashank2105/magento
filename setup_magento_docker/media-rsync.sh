#!/bin/sh

if [ ! -f /var/www/html/pub/media/media-found.txt ]
then
   /usr/bin/rsync -avh /var/www/html/pub/media-azure/* /var/www/html/pub/media/
fi
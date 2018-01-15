FROM centos:7
MAINTAINER Aleksandr Lykhouzov <lykhouzov@gmail.com>
ENV PHP_VERSION=72 XDEBUG_VERSION=2.6.0beta1 IONCUBE_VERSION=7.2 PHPREDIS_VERSION=3.1.6
ENV MAGE_ROOT=/var/www/html/magento MAGE_CRON_EXPR="*/10 * * * *" HOSTNAME=magento.loc SERVER_LISTEN_PORT=80 TERM=xterm
COPY ./docker-entrypoint.sh /
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7;\
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm; \
rpm --import https://mirror.webtatic.com/yum/RPM-GPG-KEY-webtatic-el7;\
yum -y swap -- remove fakesystemd -- install systemd systemd-libs; \
yum -y update;\
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;\
yum install -y --enablerepo=webtatic-testing re2c crontabs which logrotate rsyslog rsyslog-elasticsearch \
php${PHP_VERSION}w-fpm php${PHP_VERSION}w-devel php${PHP_VERSION}w-ftp php${PHP_VERSION}w-opcache php${PHP_VERSION}w-imap php${PHP_VERSION}w-mysql \
php${PHP_VERSION}w-curl php${PHP_VERSION}w-gd php${PHP_VERSION}w-mcrypt php${PHP_VERSION}w-xmlrpc \
php${PHP_VERSION}w-xsl php${PHP_VERSION}w-pear php${PHP_VERSION}w-phar php${PHP_VERSION}w-posix php${PHP_VERSION}w-mbstring \
php${PHP_VERSION}w-soap php${PHP_VERSION}w-xmlreader php${PHP_VERSION}w-xmlwriter \
php${PHP_VERSION}w-zlib php${PHP_VERSION}w-zip php${PHP_VERSION}w-dom \
php${PHP_VERSION}w-tokenizer php${PHP_VERSION}w-ctype php${PHP_VERSION}w-intl \
g++ make gcc gcc-c++ sqlite-devel \
&& pecl channel-update pecl.php.net \
&& /usr/bin/yum clean all \
#Xdebug setup
&& curl -O https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz \
&& tar -zxvf xdebug-${XDEBUG_VERSION}.tgz && rm -f xdebug-${XDEBUG_VERSION}.tgz \
&& cd xdebug-${XDEBUG_VERSION} && phpize \
&& ./configure && make && make install \
&& echo 'zend_extension=xdebug.so;' >>  /etc/php.d/xdebug.ini \
&& echo 'xdebug.remote_enable=1;' >>  /etc/php.d/xdebug.ini \
&& echo 'xdebug.remote_host=127.0.0.1;' >> /etc/php.d/xdebug.ini \
&& echo 'xdebug.remote_connect_back=1 # Not safe for production servers;' >> /etc/php.d/xdebug.ini\
&& echo 'xdebug.remote_port=9900;' >> /etc/php.d/xdebug.ini\
&& echo 'xdebug.remote_handler=dbgp;' >> /etc/php.d/xdebug.ini\
&& echo 'xdebug.remote_mode=req;' >> /etc/php.d/xdebug.ini\
&& echo 'xdebug.remote_autostart=0;' >> /etc/php.d/xdebug.ini\
&& cd ../ && rm -rf  xdebug-${XDEBUG_VERSION} \
&& sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;error_log = \/var\/log\/php-fpm\/error.log/error_log = syslog/g' /etc/php-fpm.conf \
&& sed -i 's/max_execution_time = 30/max_execution_time = 60/g' /etc/php.ini \
&& sed -i 's/;error_log = syslog/error_log = syslog/g' /etc/php.ini \
&& sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php.ini \
&& sed -i 's/listen.allowed_clients = 127.0.0.1/;listen.allowed_clients = 127.0.0.1/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;php_flag\[display_errors\] = off/php_flag\[display_errors\] = on/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;php_admin_flag\[log_errors\] = on/php_admin_flag\[log_errors\] = on/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;access.log = \/var\/log\/php-fpm\/$pool.access.log/access.log = \/var\/log\/php-fpm\/$pool.access.log/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;access.format = "%p %P %R - %u %t \\"%m %{HTTP_HOST}%{REQUEST_URI}e\\" %s %f %{mili}d %{kilo}M %C%%"/access.format = "%p %P %R - %u %t \\"%m %{HTTP_HOST}%{REQUEST_URI}e\\" %s %f %{mili}d %{kilo}M %C%%"/g' /etc/php-fpm.d/www.conf \
&& sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 30/g' /etc/php-fpm.d/www.conf \
# Install ioncube
&& curl -O http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
&& tar -zxvf ioncube_loaders_lin_x86-64.tar.gz \
&& cp ioncube/ioncube_loader_lin_${IONCUBE_VERSION}.so ioncube/ioncube_loader_lin_${IONCUBE_VERSION}_ts.so /usr/lib64/php/modules/ \
&& rm -rf ioncube ioncube_loaders_lin_x86-64.tar.gz \
&& echo "zend_extension=ioncube_loader_lin_${IONCUBE_VERSION}.so" > /etc/php.d/ioncube.ini \
# forward request and error logs to docker log collector
&& rm -f /var/log/php-fpm/www-error.log \
&& ln -sf /dev/stdout  /var/log/php-fpm/www-error.log \
&& systemctl enable php-fpm.service \
&& chown root:root /docker-entrypoint.sh && chmod 777 /docker-entrypoint.sh \
&& curl http://files.magerun.net/n98-magerun-latest.phar -o /usr/bin/magerun \
&& chmod +x /usr/bin/magerun \
#PHPREDIS
&& curl -L -O https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz \
&& tar -zxvf ${PHPREDIS_VERSION}.tar.gz \
&& cd phpredis-${PHPREDIS_VERSION} \
&& /usr/bin/phpize \
&& ./configure && make && make install \
&& cp ./modules/redis.so /usr/lib64/php/modules/ \
&& echo 'extension=redis.so' > /etc/php.d/redis.ini \
&& cd ../ && rm -rf phpredis-${PHPREDIS_VERSION} ${PHPREDIS_VERSION}.tar.gz \
### logrotate repo
&& echo $'compress\n\
"/var/www/html/magento/var/log/*.log"{\n\
    rotate 15\n\
    size 5M\n\
    daily\n\
    missingok\n\
    notifempty\n\
    sharedscripts\n\
    olddir archive/\n\
}\n\
' | tee /etc/logrotate.d/magento;\
systemctl enable rsyslog
VOLUME [ "/sys/fs/cgroup" ]
EXPOSE 9000 9900
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/init"]

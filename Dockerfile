FROM centos:7.3.1611

ENV LD_LIBRARY_PATH /usr/lib/oracle/12.1/client64/lib
ENV ORACLE_HOME /usr/lib/oracle/12.1/client64/lib

RUN mkdir /tmp/oracle

ADD ./oracle /tmp/oracle

RUN rpm -i /tmp/oracle/epel-release-7-10.noarch.rpm
RUN rpm -i /tmp/oracle/remi-release-7.rpm
RUN rpm -i /tmp/oracle/libaio-0.3.109-13.el7.x86_64.rpm
RUN rpm -i /tmp/oracle/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
RUN rpm -i /tmp/oracle/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

RUN yum install -y php56-php-cli

RUN ln -s /usr/bin/php56 /usr/bin/php

RUN yum install -y \
	mc \
	php56-php-pecl-mongodb \
	php56-php-pecl-mongo \
	php56-php-pecl-redis \
	php56-php-pecl-zip \
	php56-php-pear \
	php56-php-mcrypt \
	php56-php-common \
	php56-php-pecl-event \
	php56-php-mbstring \
	php56-php-xml \
	php56-php-soap \
	php56-runtime \
	php56-php-pecl-igbinary \
	php56-php-bcmath \
	php56-php-fpm \
	php56-php-gd \
	php56-php-devel \
	php56-php-smbclient \
	php56-php-pecl-xdebug \
	php56-php-pdo \
	php56-php-process \
	php56-php-pecl-jsonc \
	php56-php-pecl-jsonc \
	php56-php-pecl-eio \
	php56-php-intl \
	php56-php-oci8 \
	iproute

RUN mkdir -p /opt/remi/php56/root/etc/php-fpm.d
RUN echo "env[ORACLE_HOME] = /usr/lib/oracle/12.1/client64/lib" >> /opt/remi/php56/root/etc/php-fpm.d/www.conf
RUN echo "env[LD_LIBRARY_PATH] = /usr/lib/oracle/12.1/client64/lib" >> /opt/remi/php56/root/etc/php-fpm.d/www.conf

RUN sed -i -e 's/\s*;\s*date.timezone\s*=/date\.timezone = Europe\/Kiev/g' /opt/remi/php56/root/etc/php.ini
RUN sed -i -e 's/memory_limit\s*=.*/memory_limit = 256M/g' /opt/remi/php56/root/etc/php.ini

# add interbase, firebird support for php
RUN yum -y --enablerepo=remi-test install php-interbase

RUN cp /etc/php.d/20-interbase.ini /opt/remi/php56/root/etc/php.d/ && \
    cp /etc/php.d/30-pdo_firebird.ini /opt/remi/php56/root/etc/php.d/ && \
    cp /usr/lib64/php/modules/interbase.so /opt/remi/php56/root/lib64/php/modules && \
    cp /usr/lib64/php/modules/pdo_firebird.so /opt/remi/php56/root/lib64/php/modules

CMD ["/opt/remi/php56/root/usr/sbin/php-fpm", "-F"]

EXPOSE 9000

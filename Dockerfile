FROM php:7.1.8-apache

RUN apt-get update

# pdo
RUN a2enmod rewrite \
	&& apt-get install -y libpq-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
	&& docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
	&& docker-php-ext-install pdo pdo_mysql pgsql pdo_pgsql \
	&& docker-php-ext-install -j$(nproc) iconv mcrypt \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# redis and xdebug 2.5
RUN pecl install redis-3.1.3 \
    && pecl install xdebug-2.5.5 \
    && docker-php-ext-enable redis xdebug

# mssql pdo
RUN apt-get install -y whiptail unixodbc libgss3 odbcinst devscripts debhelper dh-exec dh-autoreconf libreadline-dev libltdl-dev \
		&& dget -u -x http://http.debian.net/debian/pool/main/u/unixodbc/unixodbc_2.3.1-3.dsc \
        && cd unixodbc-*/ \
        && dpkg-buildpackage -d -uc -us -B \
        && cp -v ./exe/odbc_config /usr/local/bin/

RUN printf '#!/bin/bash\nif [ "$*" == "-p" ]; then echo "x86_64"; else /bin/uname "$@"; fi' \
        | tee /usr/local/bin/uname \
        && chmod +x /usr/local/bin/uname

RUN apt-get install -y wget \
        && wget -nv -O msodbcsql-13.0.0.0.tar.gz \
        "https://meetsstorenew.blob.core.windows.net/contianerhd/Ubuntu%2013.0%20Tar/msodbcsql-13.0.0.0.tar.gz?st=2016-10-18T17%3A29%3A00Z&se=2022-10-19T17%3A29%3A00Z&sp=rl&sv=2015-04-05&sr=b&sig=cDwPfrouVeIQf0vi%2BnKt%2BzX8Z8caIYvRCmicDL5oknY%3D" \
        && tar -xf msodbcsql-13.0.0.0.tar.gz \
        && cd msodbcsql-*/ \
        && ldd lib64/libmsodbcsql-13.0.so.0.0 \
        && ./install.sh install --accept-license \
        && ls -l /opt/microsoft/msodbcsql/ \
        && odbcinst -q -d -n "ODBC Driver 13 for SQL Server"

RUN apt-get install -y apt-transport-https lsb-release ca-certificates \
        && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
        && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
        && apt-get update

RUN apt-get install -y unixodbc-dev php7.1-dev php-pear \
        && pecl channel-update pecl.php.net \
        && pecl install pdo_sqlsrv-4.3.0 \
        && printf "; priority=20\nextension=/usr/lib/php/20160303/pdo_sqlsrv.so" | tee /etc/php/7.1/mods-available/pdo_sqlsrv.ini \
        && echo "extension=pdo_sqlsrv.so" > /usr/local/etc/php/conf.d/pdo_sqlsrv.ini

# locales
RUN apt-get install -y locales \
	&& echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
	&& locale-gen

# install mhsendmail
RUN apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail

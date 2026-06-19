FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	php \
	php-fpm \
	php-mysql \
	php-curl \
	php-gd \
	php-mbstring \
	php-xml \
	php-zip \
	wget \
	mariadb-client \
	&& rm -rf /var/lib/apt/lists/*

# Installer wp-cli
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Creer le dossier WordPress
RUN mkdir -p /var/www/wordpress

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init_wp.sh /usr/local/bin/init_wp.sh

RUN chmod +x /usr/local/bin/init_wp.sh

EXPOSE 9000

ENTRYPOINT ["init_wp.sh"]

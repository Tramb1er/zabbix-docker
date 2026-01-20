FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget curl gnupg2 \
    php php-fpm php-pgsql \
    nginx \
    supervisor \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Добавляем репозиторий Zabbix
RUN wget -q https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb && \
    dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb && \
    rm zabbix-release_7.0-1+ubuntu24.04_all.deb && \
    apt-get update

# Устанавливаем Zabbix
RUN apt-get install -y \
    zabbix-server-pgsql \
    zabbix-frontend-php \
    zabbix-nginx-conf \
    zabbix-sql-scripts \
    zabbix-agent \
    && rm -rf /var/lib/apt/lists/*

# Копируем supervisor конфиг
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Копируем entrypoint скрипт
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Создаём директории
RUN mkdir -p /etc/zabbix/web && \
    chown -R www-data:www-data /etc/zabbix/web

# Настройка PHP FPM
RUN sed -i 's|;date.timezone =|date.timezone = Europe/Moscow|' /etc/php/8.3/fpm/php.ini && \
    sed -i 's|post_max_size = .*|post_max_size = 16M|' /etc/php/8.3/fpm/php.ini && \
    sed -i 's|upload_max_filesize = .*|upload_max_filesize = 2M|' /etc/php/8.3/fpm/php.ini && \
    sed -i 's|max_execution_time = .*|max_execution_time = 300|' /etc/php/8.3/fpm/php.ini && \
    sed -i 's|max_input_time = .*|max_input_time = 300|' /etc/php/8.3/fpm/php.ini

# Настройка nginx
RUN sed -i 's|#\s*listen\s*80;|listen 80;|' /etc/zabbix/nginx.conf && \
    sed -i 's|#\s*server_name\s*example.com;|server_name _;|' /etc/zabbix/nginx.conf && \
    ln -sf /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/zabbix.conf && \
    rm -f /etc/nginx/sites-enabled/default

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

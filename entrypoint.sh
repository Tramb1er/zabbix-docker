#!/bin/bash
set -e

echo "Ожидаем доступности PostgreSQL на $DB_SERVER_HOST:$DB_SERVER_PORT..."

# Расширенный timeout для pg_isready
TIMEOUT=60
ATTEMPT=0

while [ $ATTEMPT -lt $((TIMEOUT / 2)) ]; do
  if pg_isready -h "$DB_SERVER_HOST" -p "$DB_SERVER_PORT" -U "$DB_USER" 2>/dev/null; then
    echo "✓ PostgreSQL доступна!"
    break
  fi
  
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -eq 1 ]; then
    echo "PostgreSQL недоступна, пытаемся подключиться... (попытка $ATTEMPT)"
  else
    echo "PostgreSQL недоступна, ожидаем... (попытка $ATTEMPT из $((TIMEOUT / 2)))"
  fi
  sleep 2
done

if [ $ATTEMPT -eq $((TIMEOUT / 2)) ]; then
  echo "❌ Ошибка: PostgreSQL не доступна после $TIMEOUT секунд"
  exit 1
fi

echo "✓ PostgreSQL доступна!"

# Проверяем, инициализирована ли уже БД
TABLES=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_SERVER_HOST" -U "$DB_USER" -d "$DB_DATABASE" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null || echo "0")

if [ "$TABLES" -eq 0 ]; then
  echo "Инициализируем базу данных Zabbix..."
  zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | \
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_SERVER_HOST" -U "$DB_USER" -d "$DB_DATABASE"
  echo "✓ БД инициализирована успешно"
else
  echo "✓ БД уже инициализирована ($TABLES таблиц)"
fi

# Создаем конфиг Zabbix
ZBX_WEB_CONF="/etc/zabbix/web/zabbix.conf.php"

cat > "$ZBX_WEB_CONF" <<EOF
<?php
// Zabbix GUI configuration file.

\$DB['TYPE'] = 'POSTGRESQL';
\$DB['SERVER'] = '$DB_SERVER_HOST';
\$DB['PORT'] = '$DB_SERVER_PORT';
\$DB['DATABASE'] = '$DB_DATABASE';
\$DB['USER'] = '$DB_USER';
\$DB['PASSWORD'] = '$DB_PASSWORD';

\$ZBX_SERVER = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$ZBX_SERVER_NAME';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOF

chown www-data:www-data "$ZBX_WEB_CONF"

# Создаем директории логов если их нет
mkdir -p /var/log/zabbix
mkdir -p /var/log/nginx
mkdir -p /var/log/supervisor
chown -R zabbix:zabbix /var/log/zabbix

echo "Контейнер готов к запуску!"

exec "$@"

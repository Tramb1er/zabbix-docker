# Zabbix в Docker

## Запуск

```bash
cd zabbix-docker
docker-compose up -d
```

## Доступ

Откройте в браузере: **http://localhost**

**Логин:** Admin  
**Пароль:** zabbix

## Остановка

```bash
docker-compose down
```

## Остановка с удалением данных

```bash
docker-compose down -v
```

## Просмотр логов

```bash
# Все логи
docker-compose logs -f

# Только Zabbix Server
docker-compose logs -f zabbix-server

# Только PostgreSQL
docker-compose logs -f postgres
```

## Файлы структуры

- `Dockerfile` - образ Zabbix с PostgreSQL поддержкой
- `docker-compose.yml` - оркестрировка контейнеров
- `supervisord.conf` - управление процессами в контейнере
- `entrypoint.sh` - инициализация при запуске

## Преимущества Docker версии

✅ Нет `systemctl` - работает везде  
✅ Изолированная БД  
✅ Легко масштабировать  
✅ Простой откат  
✅ Подходит для CI/CD  

## Порты

- **80** - Nginx (Zabbix web)
- **10051** - Zabbix Server
- **5432** - PostgreSQL (внутри контейнера)

## Переменные окружения

В `docker-compose.yml` можно изменить:
- `POSTGRES_PASSWORD` - пароль PostgreSQL
- `DB_PASSWORD` - пароль пользователя Zabbix
- Таймзона `TZ` (если нужна)

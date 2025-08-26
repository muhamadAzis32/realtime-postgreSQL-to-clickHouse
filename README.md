# 🚀 Real-Time PostgreSQL to ClickHouse Sync

Real-time data replication dari PostgreSQL ke ClickHouse menggunakan Kafka dan Debezium untuk analytics dan reporting.

## 🏗️ Architecture

```
PostgreSQL → Debezium → Kafka → ClickHouse Kafka Engine → ClickHouse MergeTree
```

## ⚡ Quick Start

### Prerequisites
- Docker & Docker Compose
- Git
- 8GB+ RAM recommended

### 1. Clone Repository
```bash
git clone https://github.com/muhamadAzis32/realtime-postgreSQL-to-clickHouse.git
cd realtime-postgreSQL-to-clickHouse
```

### 2. Start All Services
```bash
# Start semua services dalam background
docker-compose up -d

# Check status semua services
docker-compose ps
```

### 3. Wait for Services (2-3 minutes)
```bash
# Monitor logs untuk memastikan semua services ready
docker-compose logs -f
```

### 4. Insert Data ke PostgreSQL
```bash

    CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    updated_at TIMESTAMP DEFAULT timezone('UTC', CURRENT_TIMESTAMP),
    created_at TIMESTAMP DEFAULT timezone('UTC', CURRENT_TIMESTAMP)
    );

    INSERT INTO users (username, account_type) VALUES
    ('user1', 'Bronze'),
    ('user2', 'Silver'),
    ('user3', 'Gold');

    ALTER SYSTEM SET wal_level = 'logical';

# Restart PostgreSQL
```

### 5. Setup Debezium Connector
```bash
# Tunggu sampai Kafka Connect ready, lalu jalankan:
curl --location --request POST 'http://localhost:8083/connectors' \
--header 'Content-Type: application/json' \
--data-raw '{
    "name": "shop-connector",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.dbname": "postgres",
        "database.hostname": "postgres",
        "database.password": "postgres",
        "database.port": "5432",
        "database.server.name": "postgres",
        "database.user": "postgres",
        "name": "shop-connector",
        "plugin.name": "pgoutput",
        "table.include.list": "public.users",
        "tasks.max": "1",
        "topic.creation.default.cleanup.policy": "delete",
        "topic.creation.default.partitions": "1",
        "topic.creation.default.replication.factor": "1",
        "topic.creation.default.retention.ms": "604800000",
        "topic.creation.enable": "true",
        "topic.prefix": "shop",
        "database.history.skip.unparseable.ddl": "true",
        "value.converter": "io.confluent.connect.avro.AvroConverter",
        "key.converter": "io.confluent.connect.avro.AvroConverter",
        "value.converter.schema.registry.url": "http://schema-registry:8081",
        "key.converter.schema.registry.url": "http://schema-registry:8081",
        "transforms": "unwrap",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState"

    }
}'
```

### 6. Verify Setup
```bash
# Check kafka UI
http://localhost:8080

# Check data di ClickHouse
docker exec -it clickhouse clickhouse-client

show databases
```

### 7. Database Schemas

**ClickHouse (Target):**
```sql

CREATE DATABASE kafka;

CREATE TABLE kafka.users
(
    user_id UInt32,
    username String,
    account_type String,
    updated_at DateTime,
    created_at DateTime,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
)ENGINE = ReplacingMergeTree(kafka_offset)
ORDER BY (user_id, updated_at)
SETTINGS index_granularity = 8192;

CREATE TABLE kafka.kafka__users
(
    user_id UInt32,
    username String,
    account_type String,
    updated_at UInt64,
    created_at UInt64
)ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:29092',
kafka_topic_list = 'postgres.public.users',
kafka_group_name = 'clickhouse_users',
kafka_format = 'AvroConfluent',
format_avro_schema_registry_url='http://schema-registry:8081';

CREATE MATERIALIZED VIEW kafka.consumer__users TO kafka.users
(
    user_id UInt32,
    username String,
    account_type String,
    updated_at DateTime,
    created_at DateTime,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
) AS
SELECT
    user_id,
    username,
    account_type,
    toDateTime(updated_at / 1000000) AS updated_at,
    toDateTime(created_at / 1000000) AS created_at,
    _timestamp AS kafka_time,
    _offset AS kafka_offset
FROM kafka.kafka__users;

SELECT * FROM kafka.users

OPTIMIZE TABLE kafka.users FINAL;
```

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Kafka UI** | http://localhost:8080 | - |
| **ClickHouse Web UI** | http://localhost:8123/play | - |
| **Kafka Connect API** | http://localhost:8083 | - |
| **PostgreSQL** | localhost:5432 | postgres/postgres |
| **ClickHouse Client** | localhost:9000 | - |


## 📊 Services Overview

### Core Services
- **PostgreSQL**: Source database dengan sample data
- **ClickHouse**: Target analytical database
- **Kafka**: Message streaming platform
- **Zookeeper**: Kafka coordination service
- **Debezium (Kafka Connect)**: Change Data Capture

### Monitoring & UI
- **Kafka UI**: Web interface untuk monitor Kafka topics & messages
- **ClickHouse Web UI**: Query interface untuk ClickHouse

## 🛠️ Troubleshooting

### Services Not Starting
```bash
# Check logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]

# Clean restart
docker-compose down
docker-compose up -d
```
<!--
## 📚 Additional Resources

- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Debezium PostgreSQL Connector](https://debezium.io/documentation/reference/connectors/postgresql.html)
- [Kafka Connect Documentation](https://kafka.apache.org/documentation/#connect)
- [Docker Compose Reference](https://docs.docker.com/compose/)
-->

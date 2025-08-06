

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
kafka_group_name = 'clickhouse',
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




===================


CREATE TABLE users3
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


CREATE TABLE kafka__users3
(
    user_id UInt32,
    username String,
    account_type String,
    updated_at UInt64,
    created_at UInt64,
    __op String
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:29092',
         kafka_topic_list = 'postgres.public.users',
         kafka_group_name = 'clickhouse3',
         kafka_format = 'AvroConfluent',
         format_avro_schema_registry_url = 'http://schema-registry:8081';



CREATE MATERIALIZED VIEW consumer__users3 TO users3
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
FROM kafka__users3
WHERE __op IN ('c', 'u'); 










==== 
Testing


DROP TABLE IF EXISTS kafka.kafka__users;

CREATE TABLE kafka.kafka__users
(
    user_id UInt32,
    username String,
    account_type String,
    updated_at Nullable(UInt64),
    created_at Nullable(UInt64)
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:29092',
         kafka_topic_list = 'postgres.public.users',
         kafka_group_name = 'clickhouse_group',
         kafka_format = 'AvroConfluent',
         format_avro_schema_registry_url = 'http://schema-registry:8081';


=== test

CREATE TABLE kafka__users
(
    user_id UInt32,
    username String,
    account_type String
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'kafka:29092',
         kafka_topic_list = 'postgres.public.users',
         kafka_group_name = 'clickhouse_group',
         kafka_format = 'AvroConfluent',
         format_avro_schema_registry_url = 'http://schema-registry:8081';


CREATE TABLE users
(
    user_id UInt32,
    username String,
    account_type String,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
)ENGINE = ReplacingMergeTree
ORDER BY (user_id)
SETTINGS index_granularity = 8192;


CREATE MATERIALIZED VIEW consumer__users TO users
(
    user_id UInt32,
    username String,
    account_type String,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
) AS
SELECT user_id, username, account_type,  _timestamp AS kafka_time, _offset AS kafka_offset FROM kafka__users



==== contoh berhasil 
CREATE TABLE local_users
(
    user_id String,
    username String,
    account_type String,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
)
ENGINE = Log;

INSERT INTO local_users
SELECT user_id, username, account_type, _timestamp AS kafka_time, _offset AS kafka_offset
FROM kafka__users
LIMIT 10;



CREATE MATERIALIZED VIEW consumer__local_users TO local_users
(
    user_id UInt32,
    username String,
    account_type String,
    kafka_time Nullable(DateTime),
    kafka_offset UInt64
) AS
SELECT user_id, username, account_type,  _timestamp AS kafka_time, _offset AS kafka_offset FROM kafka__users


-- Tags: no-parallel

DROP TABLE IF EXISTS 03717_table;
CREATE TABLE 03717_table
(
    id UInt32
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/03717_table', '1')
ORDER BY id
SETTINGS min_bytes_for_wide_part = 10000, min_rows_for_wide_part = 10000, serialization_info_version = 'basic', string_serialization_version = 'with_size_stream';

SYSTEM STOP MERGES 03717_table;


DROP TABLE IF EXISTS 03717_mv_table_odd;
CREATE TABLE 03717_mv_table_odd
(
    value UInt32,
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/03717_mv_table_odd', '1')
ORDER BY value
SETTINGS min_bytes_for_wide_part = 10000, min_rows_for_wide_part = 10000, serialization_info_version = 'basic', string_serialization_version = 'with_size_stream';

SYSTEM STOP MERGES 03717_mv_table_odd;

DROP TABLE IF EXISTS 03717_mv_odd;
CREATE MATERIALIZED VIEW 03717_mv_odd
TO 03717_mv_table_odd AS
SELECT count() as value FROM 03717_table where id % 2 = 1;


DROP TABLE IF EXISTS 03717_mv_table_even;
CREATE TABLE 03717_mv_table_even
(
    value UInt32,
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/03717_mv_table_even', '1')
ORDER BY value
SETTINGS min_bytes_for_wide_part = 10000, min_rows_for_wide_part = 10000, serialization_info_version = 'basic', string_serialization_version = 'with_size_stream';

SYSTEM STOP MERGES 03717_mv_table_even;

DROP TABLE IF EXISTS 03717_mv_even;
CREATE MATERIALIZED VIEW 03717_mv_even
TO 03717_mv_table_even AS
SELECT count() as value FROM 03717_table where id % 2 = 0;


DROP TABLE IF EXISTS 03717_mv_table_all;
CREATE TABLE 03717_mv_table_all
(
    value UInt32,
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/03717_mv_table_all', '1')
ORDER BY value
SETTINGS min_bytes_for_wide_part = 10000, min_rows_for_wide_part = 10000, serialization_info_version = 'basic', string_serialization_version = 'with_size_stream';

SYSTEM STOP MERGES 03717_mv_table_all;

DROP TABLE IF EXISTS 03717_mv_all;
CREATE MATERIALIZED VIEW 03717_mv_all
TO 03717_mv_table_all AS
SELECT count() as value FROM 03717_table;


SET throw_if_deduplication_in_dependent_materialized_views_enabled_with_async_insert=0;
SET deduplicate_blocks_in_dependent_materialized_views=1;

SET async_insert=1;
SET wait_for_async_insert=0;

SET insert_deduplicate = 1;
SET async_insert_deduplicate = 1;

SET max_block_size=1;
SET max_insert_block_size=1;
SET min_insert_block_size_rows=0;
SET min_insert_block_size_bytes=0;

INSERT INTO 03717_table VALUES (1);
INSERT INTO 03717_table VALUES (2);
INSERT INTO 03717_table VALUES (3);
INSERT INTO 03717_table VALUES (4);

SYSTEM FLUSH ASYNC INSERT QUEUE 03717_table;

INSERT INTO 03717_table VALUES (1);
INSERT INTO 03717_table VALUES (3);
INSERT INTO 03717_table VALUES (5);

SYSTEM FLUSH ASYNC INSERT QUEUE 03717_table;

select '03717_table', * from 03717_table order by all;
select '03717_mv_table_odd', * from 03717_mv_table_odd order by all;
select '03717_mv_table_even', * from 03717_mv_table_even order by all;
select '03717_mv_table_all', * from 03717_mv_table_all order by all;


-- deduplication_block_ids depends on database name, so we cannot have stable expected results here with rundon database
-- SYSTEM FLUSH LOGS part_log;

-- SELECT table, name, argMax(part_type, event_time_microseconds), argMax(deduplication_block_ids, event_time_microseconds) FROM system.part_log
-- WHERE
--     table IN ['03717_table', '03717_mv_table_odd', '03717_mv_table_even', '03717_mv_table_all']
--     AND database = currentDatabase()
-- group BY database, table, name
-- ORDER BY ALL;

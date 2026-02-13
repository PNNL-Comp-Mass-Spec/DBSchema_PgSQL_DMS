SELECT tag_schema, tag_table_full_name, table_size_b, total_relation_size_b,
       round(seconds_since_last_analyze / 60.0 / 60, 1) AS hours_since_last_analyze,
       round(seconds_since_last_vacuum  / 60.0 / 60, 1) AS hours_since_last_vacuum,
       tx_freeze_age
FROM v_pgwatch_table_stats
ORDER BY seconds_since_last_analyze DESC;

SELECT tag_schema, tag_table_full_name, table_size_b, total_relation_size_b,
       round(seconds_since_last_analyze / 60.0 / 60, 1) AS hours_since_last_analyze,
       round(seconds_since_last_vacuum  / 60.0 / 60, 1) AS hours_since_last_vacuum,
       tx_freeze_age
FROM v_pgwatch_table_stats
ORDER BY seconds_since_last_vacuum DESC;

SELECT tag_schema, tag_table_full_name, table_size_b, total_relation_size_b,
       round(seconds_since_last_analyze / 60.0 / 60, 1) AS hours_since_last_analyze,
       round(seconds_since_last_vacuum  / 60.0 / 60, 1) AS hours_since_last_vacuum,
       tx_freeze_age
FROM v_pgwatch_table_stats
ORDER BY tx_freeze_age DESC;
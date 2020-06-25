--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
-- Dumped by pg_dump version 12.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: all_distinct_dbname_metrics; Type: TABLE DATA; Schema: admin; Owner: pgwatch2
--

COPY admin.all_distinct_dbname_metrics (dbname, metric, created_on) FROM stdin;
DMS_PrismWeb3	server_log_event_counts	2020-05-12 11:43:35.545947-07
DMS_PrismWeb3	index_stats	2020-05-12 11:43:35.547106-07
DMS_PrismWeb3	cpu_load	2020-05-12 11:43:35.547835-07
DMS_PrismWeb3	psutil_disk	2020-05-12 11:43:35.548498-07
DMS_PrismWeb3	backends	2020-05-12 11:43:35.549109-07
DMS_PrismWeb3	table_stats	2020-05-12 11:43:35.54972-07
DMS_PrismWeb3	psutil_mem	2020-05-12 11:43:35.550358-07
DMS_PrismWeb3	stat_statements_calls	2020-05-12 11:43:35.550957-07
DMS_PrismWeb3	wal_size	2020-05-12 11:43:35.552083-07
DMS_PrismWeb3	settings	2020-05-12 11:43:35.552653-07
DMS_PrismWeb3	table_io_stats	2020-05-12 11:43:35.55321-07
DMS_PrismWeb3	stat_ssl	2020-05-12 11:43:35.554793-07
DMS_PrismWeb3	recommendations	2020-05-12 11:43:35.556687-07
DMS_PrismWeb3	wal	2020-05-12 11:43:35.557399-07
DMS_PrismWeb3	archiver	2020-05-12 11:43:35.558018-07
DMS_PrismWeb3	bgwriter	2020-05-12 11:43:35.558621-07
DMS_PrismWeb3	db_stats	2020-05-12 11:43:35.559877-07
DMS_PrismWeb3	table_bloat_approx_summary_sql	2020-05-12 11:43:35.560541-07
DMS_PrismWeb3	kpi	2020-05-12 11:43:35.561167-07
DMS_PrismWeb3	psutil_cpu	2020-05-12 11:43:35.561767-07
DMS_PrismWeb3	stat_statements	2020-05-12 11:43:35.561865-07
DMS_PrismWeb3	locks	2020-05-12 11:43:35.562454-07
DMS_PrismWeb3	db_size	2020-05-12 11:43:35.563627-07
DMS_PrismWeb3	locks_mode	2020-05-12 11:43:35.56476-07
DMS_PrismWeb3	psutil_disk_io_total	2020-05-12 11:43:35.566517-07
DMS_PrismWeb3	backup_age_pgbackrest	2020-05-12 12:43:15.068505-07
DMS_PrismWeb3	configuration_changes	2020-05-12 23:42:19.43765-07
DMS_PrismWeb3	configured_dbs	2020-05-12 23:42:19.439743-07
DMS_PrismWeb3	object_changes	2020-05-12 23:42:19.456712-07
DMS_PrismWeb3	psutil_disk_io_total_per_disk	2020-05-13 19:13:52.113185-07
DMS_PrismWeb3	table_changes	2020-06-23 16:08:09.295168-07
DMS_PrismDB1	server_log_event_counts	2020-06-23 16:36:04.624322-07
DMS_PrismDB1	recommendations	2020-06-23 16:36:04.625543-07
DMS_PrismDB1	psutil_mem	2020-06-23 16:36:04.626274-07
DMS_PrismDB1	table_bloat_approx_summary_sql	2020-06-23 16:36:04.626889-07
DMS_PrismDB1	db_size	2020-06-23 16:36:04.628659-07
DMS_PrismDB1	locks	2020-06-23 16:36:04.629305-07
DMS_PrismDB1	stat_statements	2020-06-23 16:36:04.630611-07
DMS_PrismDB1	psutil_disk_io_total	2020-06-23 16:36:04.631841-07
DMS_PrismDB1	index_stats	2020-06-23 16:36:04.632416-07
DMS_PrismDB1	psutil_disk	2020-06-23 16:36:04.631754-07
DMS_PrismDB1	wal	2020-06-23 16:36:04.633028-07
DMS_PrismDB1	psutil_cpu	2020-06-23 16:36:04.633524-07
DMS_PrismDB1	stat_statements_calls	2020-06-23 16:36:04.633581-07
DMS_PrismDB1	backends	2020-06-23 16:36:04.634163-07
DMS_PrismDB1	table_stats	2020-06-23 16:36:04.634182-07
DMS_PrismDB1	cpu_load	2020-06-23 16:36:04.63476-07
DMS_PrismDB1	settings	2020-06-23 16:36:04.634777-07
DMS_PrismDB1	locks_mode	2020-06-23 16:36:04.635333-07
DMS_PrismDB1	stat_ssl	2020-06-23 16:36:04.635363-07
DMS_PrismDB1	table_io_stats	2020-06-23 16:36:04.63644-07
DMS_PrismDB1	db_stats	2020-06-23 16:36:04.637586-07
DMS_PrismDB1	archiver	2020-06-23 16:36:04.638121-07
DMS_PrismDB1	psutil_disk_io_total_per_disk	2020-06-23 16:36:04.6393-07
DMS_PrismDB1	kpi	2020-06-23 16:36:04.639876-07
DMS_PrismDB1	backup_age_pgbackrest	2020-06-23 16:36:04.640402-07
DMS_PrismDB1	wal_size	2020-06-23 16:36:04.640957-07
DMS_PrismDB1	bgwriter	2020-06-23 16:36:04.641452-07
DMS_PrismDB1	configuration_changes	2020-06-23 23:24:47.331795-07
DMS_PrismDB1	configured_dbs	2020-06-23 23:24:47.336094-07
DMS_PrismDB1	object_changes	2020-06-23 23:24:47.367206-07
DMS_PrismDB1	sproc_changes	2020-06-24 21:09:24.119357-07
DMS_PrismWeb3	sproc_changes	2020-06-24 21:09:24.119357-07
DMS_PrismWeb3	index_changes	2020-06-25 11:40:51.872335-07
DMS_PrismDB1	index_changes	2020-06-25 11:41:03.954748-07
DMS_PrismDB1	wal_receiver	2020-06-25 11:41:48.692716-07
DMS_PrismDB1	logical_subscriptions	2020-06-25 11:41:48.694359-07
DMS_PrismDB1	show_plans_realtime	2020-06-25 11:41:48.695381-07
DMS_PrismDB1	replication_slots	2020-06-25 11:41:48.699464-07
DMS_PrismDB1	sproc_stats	2020-06-25 11:41:48.700073-07
DMS_PrismDB1	change_events	2020-06-25 11:41:48.702231-07
DMS_PrismDB1	replication	2020-06-25 11:41:48.703354-07
DMS_PrismWeb3	sproc_stats	2020-06-25 11:41:48.810028-07
DMS_PrismWeb3	change_events	2020-06-25 11:41:48.81568-07
DMS_PrismWeb3	show_plans_realtime	2020-06-25 11:41:48.821046-07
DMS_PrismWeb3	wal_receiver	2020-06-25 11:41:48.82171-07
DMS_PrismWeb3	replication	2020-06-25 11:41:48.822272-07
DMS_PrismWeb3	logical_subscriptions	2020-06-25 11:41:48.823145-07
DMS_PrismWeb3	replication_slots	2020-06-25 11:41:48.823364-07
\.


--
-- PostgreSQL database dump complete
--


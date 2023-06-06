--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3
-- Dumped by pg_dump version 15.1

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
DMS_PrismWeb3	wal_size	2020-05-12 11:43:35.552083-07
DMS_PrismWeb3	settings	2020-05-12 11:43:35.552653-07
DMS_PrismWeb3	table_io_stats	2020-05-12 11:43:35.55321-07
DMS_PrismWeb3	stat_ssl	2020-05-12 11:43:35.554793-07
DMS_PrismWeb3	recommendations	2020-05-12 11:43:35.556687-07
DMS_PrismWeb3	wal	2020-05-12 11:43:35.557399-07
DMS_PrismWeb3	archiver	2020-05-12 11:43:35.558018-07
DMS_PrismWeb3	bgwriter	2020-05-12 11:43:35.558621-07
DMS_PrismWeb3	table_bloat_approx_summary_sql	2020-05-12 11:43:35.560541-07
DMS_PrismWeb3	kpi	2020-05-12 11:43:35.561167-07
DMS_PrismWeb3	psutil_cpu	2020-05-12 11:43:35.561767-07
DMS_PrismWeb3	locks	2020-05-12 11:43:35.562454-07
DMS_PrismWeb3	db_size	2020-05-12 11:43:35.563627-07
DMS_PrismWeb3	locks_mode	2020-05-12 11:43:35.56476-07
DMS_PrismWeb3	psutil_disk_io_total	2020-05-12 11:43:35.566517-07
DMS_PrismWeb3	backup_age_pgbackrest	2020-05-12 12:43:15.068505-07
DMS_PrismWeb3	configured_dbs	2020-05-12 23:42:19.439743-07
DMS_PrismDB1	index_changes	2023-01-31 16:16:06.836682-08
DMS_PrismDB1	configuration_changes	2023-04-27 17:38:25.540179-07
DMS_PrismWeb3	psutil_disk_io_total_per_disk	2020-05-13 19:13:52.113185-07
DMS_PrismWeb3	configuration_changes	2023-05-16 04:08:29.626919-07
DMS_PrismWeb3	object_changes	2023-05-16 04:18:29.690654-07
DMS_PrismDB1	server_log_event_counts	2020-06-23 16:36:04.624322-07
DMS_PrismDB1	recommendations	2020-06-23 16:36:04.625543-07
DMS_PrismDB1	psutil_mem	2020-06-23 16:36:04.626274-07
DMS_PrismDB1	table_bloat_approx_summary_sql	2020-06-23 16:36:04.626889-07
DMS_PrismDB1	object_changes	2022-02-23 20:30:24.96799-08
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
DMS_PrismDB1	archiver	2020-06-23 16:36:04.638121-07
DMS_PrismDB1	psutil_disk_io_total_per_disk	2020-06-23 16:36:04.6393-07
DMS_PrismDB1	kpi	2020-06-23 16:36:04.639876-07
DMS_PrismDB1	backup_age_pgbackrest	2020-06-23 16:36:04.640402-07
DMS_PrismDB1	wal_size	2020-06-23 16:36:04.640957-07
DMS_PrismDB1	bgwriter	2020-06-23 16:36:04.641452-07
DMS_PrismDB1	configured_dbs	2020-06-23 23:24:47.336094-07
DMS_PrismWeb3	stat_statements	2022-03-04 13:34:25.863519-08
DMS_PrismWeb3	stat_statements_calls	2022-03-04 13:34:25.876602-08
DMS_PrismDB1	sequence_health	2022-03-04 15:12:28.986326-08
DMS_PrismDB1	instance_up	2022-03-04 15:12:28.99984-08
DMS_PrismWeb3	sequence_health	2022-03-04 15:12:29.00544-08
DMS_PrismWeb3	instance_up	2022-03-04 15:12:29.011733-08
DMS_PrismDB1	privilege_changes	2022-03-05 18:16:44.158301-08
DMS_PrismDB1	table_changes	2022-03-29 08:47:49.3182-07
DMS_PrismDB1	sproc_changes	2022-05-31 21:52:04.133405-07
\.


--
-- PostgreSQL database dump complete
--


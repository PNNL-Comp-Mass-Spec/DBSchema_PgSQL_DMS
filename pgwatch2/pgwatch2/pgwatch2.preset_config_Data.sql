--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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
-- Data for Name: preset_config; Type: TABLE DATA; Schema: pgwatch2; Owner: pgwatch2
--

COPY pgwatch2.preset_config (pc_name, pc_description, pc_config, pc_last_modified_on) FROM stdin;
minimal	single "Key Performance Indicators" query for fast cluster/db overview	{"kpi": 60}	2019-10-04 22:09:29.424883-07
basic	only the most important metrics - WAL, DB-level statistics (size, tx and backend counts)	{"wal": 60, "db_size": 300, "db_stats": 60}	2019-10-04 22:09:29.424883-07
standard	"basic" level + table, index, stat_statements stats	{"wal": 60, "db_size": 300, "cpu_load": 60, "db_stats": 60, "index_stats": 900, "sproc_stats": 180, "table_stats": 300, "stat_statements": 180}	2019-10-04 22:09:29.424883-07
pgbouncer	per DB stats	{"pgbouncer_stats": 60}	2019-10-04 22:09:29.424883-07
exhaustive	all important metrics for a deeper performance understanding	{"wal": 60, "locks": 60, "db_size": 300, "archiver": 60, "backends": 60, "bgwriter": 60, "cpu_load": 60, "db_stats": 60, "settings": 7200, "wal_size": 300, "locks_mode": 60, "index_stats": 900, "replication": 120, "sproc_stats": 180, "table_stats": 300, "wal_receiver": 120, "change_events": 300, "table_io_stats": 600, "stat_statements": 180, "replication_slots": 120, "stat_statements_calls": 60, "table_bloat_approx_summary_sql": 7200}	2019-10-04 22:09:29.424883-07
full	almost all available metrics for a even deeper performance understanding	{"kpi": 120, "wal": 60, "locks": 60, "db_size": 300, "archiver": 60, "backends": 60, "bgwriter": 60, "cpu_load": 60, "db_stats": 60, "settings": 7200, "stat_ssl": 120, "wal_size": 120, "locks_mode": 60, "psutil_cpu": 120, "psutil_mem": 120, "index_stats": 900, "psutil_disk": 120, "replication": 120, "sproc_stats": 180, "table_stats": 300, "wal_receiver": 120, "change_events": 300, "table_io_stats": 600, "stat_statements": 180, "replication_slots": 120, "psutil_disk_io_total": 120, "stat_statements_calls": 60, "table_bloat_approx_summary_sql": 7200}	2019-10-04 22:09:29.424883-07
unprivileged	no wrappers + only pg_stat_statements extension expected (developer mode)	{"wal": 60, "locks": 60, "db_size": 300, "archiver": 60, "bgwriter": 60, "db_stats": 60, "settings": 7200, "locks_mode": 60, "index_stats": 900, "replication": 120, "sproc_stats": 180, "table_stats": 300, "change_events": 300, "table_io_stats": 600, "replication_slots": 120, "stat_statements_calls": 60}	2019-10-04 22:09:29.424883-07
prometheus	similar to "exhaustive" but without some possibly longer-running metrics and those keeping state	{"wal": 1, "db_size": 1, "archiver": 1, "backends": 1, "bgwriter": 1, "cpu_load": 1, "db_stats": 1, "locks_mode": 1, "replication": 1, "sproc_stats": 1, "table_stats": 1, "wal_receiver": 1, "replication_slots": 1, "stat_statements_calls": 1}	2019-10-04 22:09:29.424883-07
superuser_no_python	like exhaustive, but no PL/Python helpers	{"wal": 60, "locks": 60, "db_size": 300, "archiver": 60, "backends": 60, "bgwriter": 60, "db_stats": 60, "settings": 7200, "wal_size": 300, "locks_mode": 60, "index_stats": 900, "replication": 120, "sproc_stats": 180, "table_stats": 300, "wal_receiver": 120, "change_events": 300, "table_io_stats": 600, "stat_statements": 180, "replication_slots": 120, "stat_statements_calls": 60, "table_bloat_approx_summary_sql": 7200}	2019-10-04 22:09:29.424883-07
\.


--
-- PostgreSQL database dump complete
--


--
-- PostgreSQL manual dump
--

SELECT *
FROM pg_roles
ORDER BY rolname;

rolname	rolsuper	rolinherit	rolcreaterole	rolcreatedb	rolcanlogin	rolreplication	rolconnlimit	rolpassword	rolvaliduntil	rolbypassrls	rolconfig	oid
d3l243	true	true	true	true	true	false	-1	********	[NULL]	false	NULL	16,493
dmsreader	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	24,853
dmswebuser	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	24,854
gibb166	true	true	true	true	true	false	-1	********	[NULL]	false	NULL	27,704
lcmsnetuser	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	39,210,810
pceditor	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	49,609,081
pg_checkpoint	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,544
pg_create_subscription	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	6,304
pg_database_owner	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	6,171
pg_execute_server_program	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,571
pg_maintain	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	6,337
pg_monitor	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	3,373
pg_read_all_data	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	6,181
pg_read_all_settings	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	3,374
pg_read_all_stats	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	3,375
pg_read_server_files	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,569
pg_signal_backend	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,200
pg_stat_scan_tables	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	3,377
pg_use_reserved_connections	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,550
pg_write_all_data	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	6,182
pg_write_server_files	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	4,570
pgdms	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	27,702
pgwatch2	false	true	false	false	true	false	50	********	[NULL]	false	NULL	27,703
postgres	true	true	true	true	true	true	-1	********	[NULL]	true	NULL	10
readaccess	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	68,551
svc-dms	false	true	false	false	true	false	-1	********	[NULL]	false	NULL	24,855
writeaccess	false	true	false	false	false	false	-1	********	[NULL]	false	NULL	68,552

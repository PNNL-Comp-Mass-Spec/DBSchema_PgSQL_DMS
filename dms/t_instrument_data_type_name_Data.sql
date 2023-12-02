--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 16.1

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
-- Data for Name: t_instrument_data_type_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_instrument_data_type_name (raw_data_type_id, raw_data_type_name, is_folder, required_file_extension, comment) FROM stdin;
1	dot_raw_files	0	.Raw	\N
2	dot_wiff_files	0	.Wiff	\N
3	dot_uimf_files	0	.UIMF	\N
4	zipped_s_folders	1		\N
5	biospec_folder	1		\N
6	dot_raw_folder	1		\N
7	dot_d_folders	1		\N
8	bruker_ft	1		.D directory that has a .BAF files and ser file
9	bruker_maldi_spot	1		Directory has a .EMF file and a single sub-folder that has an acque file and fid file
10	bruker_maldi_imaging	1		Dataset directory has a series of zip files with names like 0_R00X329.zip; each .Zip file has a series of subfolders with names like 0_R00X329Y309
11	sciex_wiff_files	0	.Wiff	Each dataset has a .wiff file and a .wiff.scan file
12	bruker_tof_baf	1		.D directory from Maxis instrument
13	data_folders	1		Used for miscellaneous data files
15	dot_mzml_files	0	.mzML	.mzML file
16	ab_sequencing_folder	1		\N
17	illumina_folder	1		\N
18	dot_qgd_files	0	.qgd	\N
19	bruker_tof_tdf	1	.tdf	.D directory with a .tdf file and a .tdf_bin file
\.


--
-- Name: t_instrument_data_type_name_raw_data_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_instrument_data_type_name_raw_data_type_id_seq', 19, true);


--
-- PostgreSQL database dump complete
--


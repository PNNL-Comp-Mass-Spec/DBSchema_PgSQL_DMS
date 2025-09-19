--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: t_dataset_rating_name; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_rating_name (dataset_rating_id, dataset_rating, comment) FROM stdin;
-10	Unreviewed	Quality of data has not yet been determined
-7	Rerun (Superseded)	Data acquisition issue, either for this sample or for another sample in the batch
-6	Rerun (Good Data)	Successful sample analysis, but the sample will be re-analyzed, typically because other samples in a batch had an issue
-5	Not Released	Instrument acquisition issue, no usable data; not service center eligible; cannot create analysis jobs
-4	Not Released (allow analysis)	Instrument acquisition issue, but allow data analysis; not service center eligible
-2	Data Files Missing	Missing data files; not service center eligible; cannot create analysis jobs
-1	No Data (Blank/Bad)	No usable data (Blank / Bad); not service center eligible; cannot create analysis jobs
1	No Interest	Legacy dataset rating; rarely used
2	Unknown	Legacy dataset rating; rarely used
3	Interest	Legacy dataset rating; last used in 2013
5	Released	Successful sample analysis
6	Exclude From Service Center	Successful sample analysis, but should not be billed to the service center
7	Method Development	Method development analysis, and should not be billed to the service center
\.


--
-- PostgreSQL database dump complete
--


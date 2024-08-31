--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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
-- Data for Name: t_analysis_tool_allowed_dataset_type; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_analysis_tool_allowed_dataset_type (analysis_tool_id, dataset_type, comment) FROM stdin;
1	DIA-HMS-HCD-HMSn	
1	HMS-CID/ETD-HMSn	
1	HMS-CID/ETD-MSn	
1	HMS-ETD-HMSn	
1	HMS-ETD-MSn	
1	HMS-ETciD-EThcD-HMSn	
1	HMS-ETciD-EThcD-MSn	
1	HMS-ETciD-HMSn	
1	HMS-ETciD-MSn	
1	HMS-EThcD-HMSn	
1	HMS-EThcD-MSn	
1	HMS-HCD-CID-HMSn	
1	HMS-HCD-CID-MSn	
1	HMS-HCD-CID/ETD-HMSn	
1	HMS-HCD-CID/ETD-MSn	
1	HMS-HCD-ETD-HMSn	
1	HMS-HCD-ETD-MSn	
1	HMS-HCD-HMSn	
1	HMS-HCD-MSn	
1	HMS-HMSn	
1	HMS-MSn	
1	HMS-PQD-CID/ETD-MSn	
1	HMS-PQD-ETD-MSn	
1	MS-CID/ETD-MSn	
1	MS-ETD-MSn	
1	MS-MSn	
2	DIA-HMS-HCD-HMSn	
2	HMS	
2	HMS-CID/ETD-HMSn	
2	HMS-CID/ETD-MSn	
2	HMS-ETD-HMSn	
2	HMS-ETD-MSn	
2	HMS-HCD-CID-HMSn	
2	HMS-HCD-CID-MSn	
2	HMS-HCD-CID/ETD-HMSn	
2	HMS-HCD-CID/ETD-MSn	
2	HMS-HCD-ETD-HMSn	
2	HMS-HCD-ETD-MSn	
2	HMS-HCD-HMSn	
2	HMS-HCD-MSn	
2	HMS-HMSn	
2	HMS-MSn	
2	HMS-PQD-CID/ETD-MSn	
2	HMS-PQD-ETD-MSn	
2	MS	
2	MS-CID/ETD-MSn	
2	MS-ETD-MSn	
2	MS-MSn	
3	DIA-HMS-HCD-HMSn	
3	HMS-ETD-HMSn	
3	HMS-ETD-MSn	
3	HMS-HCD-CID-HMSn	
3	HMS-HCD-CID-MSn	
3	HMS-HCD-CID/ETD-HMSn	
3	HMS-HCD-CID/ETD-MSn	
3	HMS-HCD-ETD-HMSn	
3	HMS-HCD-ETD-MSn	
3	HMS-HCD-HMSn	
3	HMS-HCD-MSn	
3	HMS-HMSn	
3	HMS-MSn	
3	HMS-PQD-CID/ETD-MSn	
3	HMS-PQD-ETD-MSn	
3	MS-CID/ETD-MSn	
3	MS-ETD-MSn	
3	MS-MSn	
4	DIA-HMS-HCD-HMSn	
4	HMS	
4	HMS-ETD-HMSn	
4	HMS-ETD-MSn	
4	HMS-HCD-CID-HMSn	
4	HMS-HCD-CID-MSn	
4	HMS-HCD-CID/ETD-HMSn	
4	HMS-HCD-CID/ETD-MSn	
4	HMS-HCD-ETD-HMSn	
4	HMS-HCD-ETD-MSn	
4	HMS-HCD-HMSn	
4	HMS-HCD-MSn	
4	HMS-HMSn	
4	HMS-MSn	
4	HMS-PQD-CID/ETD-MSn	
4	HMS-PQD-ETD-MSn	
4	MS	
4	MS-CID/ETD-MSn	
4	MS-ETD-MSn	
4	MS-MSn	
5	DIA-HMS-HCD-HMSn	
5	HMS	
5	HMS-ETD-HMSn	
5	HMS-ETD-MSn	
5	HMS-HCD-CID-HMSn	
5	HMS-HCD-CID-MSn	
5	HMS-HCD-CID/ETD-HMSn	
5	HMS-HCD-CID/ETD-MSn	
5	HMS-HCD-ETD-HMSn	
5	HMS-HCD-ETD-MSn	
5	HMS-HCD-HMSn	
5	HMS-HCD-MSn	
5	HMS-HMSn	
5	HMS-MSn	
5	HMS-PQD-CID/ETD-MSn	
5	HMS-PQD-ETD-MSn	
5	MS	
5	MS-CID/ETD-MSn	
5	MS-ETD-MSn	
5	MS-MSn	
6	DIA-HMS-HCD-HMSn	
6	HMS-ETD-HMSn	
6	HMS-ETD-MSn	
6	HMS-HCD-CID-HMSn	
6	HMS-HCD-CID-MSn	
6	HMS-HCD-CID/ETD-HMSn	
6	HMS-HCD-CID/ETD-MSn	
6	HMS-HCD-ETD-HMSn	
6	HMS-HCD-ETD-MSn	
6	HMS-HCD-HMSn	
6	HMS-HCD-MSn	
6	HMS-HMSn	
6	HMS-MSn	
6	HMS-PQD-CID/ETD-MSn	
6	HMS-PQD-ETD-MSn	
6	MS-CID/ETD-MSn	
6	MS-ETD-MSn	
6	MS-MSn	
7	HMS	
7	HMS-HMSn	
7	HMS-MSn	
8	DIA-HMS-HCD-HMSn	
8	HMS-ETD-HMSn	
8	HMS-ETD-MSn	
8	HMS-HCD-CID-HMSn	
8	HMS-HCD-CID-MSn	
8	HMS-HCD-CID/ETD-HMSn	
8	HMS-HCD-CID/ETD-MSn	
8	HMS-HCD-ETD-HMSn	
8	HMS-HCD-ETD-MSn	
8	HMS-HCD-HMSn	
8	HMS-HCD-MSn	
8	HMS-HMSn	
8	HMS-MSn	
8	HMS-PQD-CID/ETD-MSn	
8	HMS-PQD-ETD-MSn	
8	MS-CID/ETD-MSn	
8	MS-ETD-MSn	
8	MS-MSn	
9	DIA-HMS-HCD-HMSn	
9	HMS-ETD-HMSn	
9	HMS-ETD-MSn	
9	HMS-HCD-CID-HMSn	
9	HMS-HCD-CID-MSn	
9	HMS-HCD-CID/ETD-HMSn	
9	HMS-HCD-CID/ETD-MSn	
9	HMS-HCD-ETD-HMSn	
9	HMS-HCD-ETD-MSn	
9	HMS-HCD-HMSn	
9	HMS-HCD-MSn	
9	HMS-HMSn	
9	HMS-MSn	
9	HMS-PQD-CID/ETD-MSn	
9	HMS-PQD-ETD-MSn	
9	MS-CID/ETD-MSn	
9	MS-ETD-MSn	
9	MS-MSn	
10	HMS	
10	HMS-HMSn	
10	HMS-MSn	
11	HMS	
12	DIA-HMS-HCD-HMSn	
12	HMS	
12	HMS-CID/ETD-HMSn	
12	HMS-CID/ETD-MSn	
12	HMS-ETD-HMSn	
12	HMS-ETD-MSn	
12	HMS-HCD-CID-HMSn	
12	HMS-HCD-CID-MSn	
12	HMS-HCD-CID/ETD-HMSn	
12	HMS-HCD-CID/ETD-MSn	
12	HMS-HCD-ETD-HMSn	
12	HMS-HCD-ETD-MSn	
12	HMS-HCD-HMSn	
12	HMS-HCD-MSn	
12	HMS-HMSn	
12	HMS-MSn	
12	HMS-PQD-CID/ETD-MSn	
12	HMS-PQD-ETD-MSn	
12	MS	
12	MS-CID/ETD-MSn	
12	MS-ETD-MSn	
12	MS-MSn	
13	C60-SIMS-HMS	
13	DIA-HMS-HCD-HMSn	
13	HMS	
13	HMS-CID/ETD-HMSn	
13	HMS-CID/ETD-MSn	
13	HMS-ETD-HMSn	
13	HMS-ETD-MSn	
13	HMS-ETciD-EThcD-HMSn	
13	HMS-ETciD-EThcD-MSn	
13	HMS-ETciD-HMSn	
13	HMS-ETciD-MSn	
13	HMS-EThcD-HMSn	
13	HMS-EThcD-MSn	
13	HMS-HCD-CID-HMSn	
13	HMS-HCD-CID-MSn	
13	HMS-HCD-CID/ETD-HMSn	
13	HMS-HCD-CID/ETD-MSn	
13	HMS-HCD-ETD-HMSn	
13	HMS-HCD-ETD-MSn	
13	HMS-HCD-HMSn	
13	HMS-HCD-MSn	
13	HMS-HMSn	
13	HMS-MSn	
13	HMS-PQD-CID/ETD-MSn	
13	HMS-PQD-ETD-MSn	
13	MALDI-HMS	
13	MRM	
13	MS	
13	MS-CID/ETD-MSn	
13	MS-ETD-MSn	
13	MS-MSn	
14	DIA-HMS-HCD-HMSn	
14	HMS	
14	HMS-ETD-HMSn	
14	HMS-ETD-MSn	
14	HMS-HCD-CID-HMSn	
14	HMS-HCD-CID-MSn	
14	HMS-HCD-CID/ETD-HMSn	
14	HMS-HCD-CID/ETD-MSn	
14	HMS-HCD-ETD-HMSn	
14	HMS-HCD-ETD-MSn	
14	HMS-HCD-HMSn	
14	HMS-HCD-MSn	
14	HMS-HMSn	
14	HMS-MSn	
14	HMS-PQD-CID/ETD-MSn	
14	HMS-PQD-ETD-MSn	
14	MRM	
14	MS	
14	MS-CID/ETD-MSn	
14	MS-ETD-MSn	
14	MS-MSn	
15	DIA-HMS-HCD-HMSn	
15	HMS-CID/ETD-HMSn	
15	HMS-CID/ETD-MSn	
15	HMS-ETD-HMSn	
15	HMS-ETD-MSn	
15	HMS-ETciD-EThcD-HMSn	
15	HMS-ETciD-EThcD-MSn	
15	HMS-ETciD-HMSn	
15	HMS-ETciD-MSn	
15	HMS-EThcD-HMSn	
15	HMS-EThcD-MSn	
15	HMS-HCD-CID-HMSn	
15	HMS-HCD-CID-MSn	
15	HMS-HCD-CID/ETD-HMSn	
15	HMS-HCD-CID/ETD-MSn	
15	HMS-HCD-ETD-HMSn	
15	HMS-HCD-ETD-MSn	
15	HMS-HCD-HMSn	
15	HMS-HCD-MSn	
15	HMS-HMSn	
15	HMS-MSn	
15	HMS-PQD-CID/ETD-MSn	
15	HMS-PQD-ETD-MSn	
15	MS-CID/ETD-MSn	
15	MS-ETD-MSn	
15	MS-MSn	
16	DIA-HMS-HCD-HMSn	
16	HMS	
16	HMS-CID/ETD-HMSn	
16	HMS-CID/ETD-MSn	
16	HMS-ETD-HMSn	
16	HMS-ETD-MSn	
16	HMS-HCD-CID-HMSn	
16	HMS-HCD-CID-MSn	
16	HMS-HCD-CID/ETD-HMSn	
16	HMS-HCD-CID/ETD-MSn	
16	HMS-HCD-ETD-HMSn	
16	HMS-HCD-ETD-MSn	
16	HMS-HCD-HMSn	
16	HMS-HCD-MSn	
16	HMS-HMSn	
16	HMS-MSn	
16	HMS-PQD-CID/ETD-MSn	
16	HMS-PQD-ETD-MSn	
16	IMS-HMS	
16	IMS-HMS-HMSn	
16	IMS-HMS-MSn	
16	MS	
16	MS-CID/ETD-MSn	
16	MS-ETD-MSn	
16	MS-MSn	
17	DIA-HMS-HCD-HMSn	
17	HMS	
17	HMS-CID/ETD-HMSn	
17	HMS-CID/ETD-MSn	
17	HMS-ETD-HMSn	
17	HMS-ETD-MSn	
17	HMS-HCD-CID-HMSn	
17	HMS-HCD-CID-MSn	
17	HMS-HCD-CID/ETD-HMSn	
17	HMS-HCD-CID/ETD-MSn	
17	HMS-HCD-ETD-HMSn	
17	HMS-HCD-ETD-MSn	
17	HMS-HCD-HMSn	
17	HMS-HCD-MSn	
17	HMS-HMSn	
17	HMS-MSn	
17	HMS-PQD-CID/ETD-MSn	
17	HMS-PQD-ETD-MSn	
17	IMS-HMS	
17	IMS-HMS-HMSn	
17	IMS-HMS-MSn	
17	MS	
17	MS-CID/ETD-MSn	
17	MS-ETD-MSn	
17	MS-MSn	
18	DIA-HMS-HCD-HMSn	
18	HMS	
18	HMS-CID/ETD-HMSn	
18	HMS-CID/ETD-MSn	
18	HMS-ETD-HMSn	
18	HMS-ETD-MSn	
18	HMS-HCD-CID-HMSn	
18	HMS-HCD-CID-MSn	
18	HMS-HCD-CID/ETD-HMSn	
18	HMS-HCD-CID/ETD-MSn	
18	HMS-HCD-ETD-HMSn	
18	HMS-HCD-ETD-MSn	
18	HMS-HCD-HMSn	
18	HMS-HCD-MSn	
18	HMS-HMSn	
18	HMS-MSn	
18	HMS-PQD-CID/ETD-MSn	
18	HMS-PQD-ETD-MSn	
18	MS	
18	MS-CID/ETD-MSn	
18	MS-ETD-MSn	
18	MS-MSn	
19	DIA-HMS-HCD-HMSn	
19	HMS	
19	HMS-CID/ETD-HMSn	
19	HMS-CID/ETD-MSn	
19	HMS-ETD-HMSn	
19	HMS-ETD-MSn	
19	HMS-HCD-CID-HMSn	
19	HMS-HCD-CID-MSn	
19	HMS-HCD-CID/ETD-HMSn	
19	HMS-HCD-CID/ETD-MSn	
19	HMS-HCD-ETD-HMSn	
19	HMS-HCD-ETD-MSn	
19	HMS-HCD-HMSn	
19	HMS-HCD-MSn	
19	HMS-HMSn	
19	HMS-MSn	
19	HMS-PQD-CID/ETD-MSn	
19	HMS-PQD-ETD-MSn	
19	MS	
19	MS-CID/ETD-MSn	
19	MS-ETD-MSn	
19	MS-MSn	
20	DIA-HMS-HCD-HMSn	
20	HMS-CID/ETD-HMSn	
20	HMS-CID/ETD-MSn	
20	HMS-ETD-HMSn	
20	HMS-ETD-MSn	
20	HMS-HCD-CID-HMSn	
20	HMS-HCD-CID-MSn	
20	HMS-HCD-CID/ETD-HMSn	
20	HMS-HCD-CID/ETD-MSn	
20	HMS-HCD-ETD-HMSn	
20	HMS-HCD-ETD-MSn	
20	HMS-HCD-HMSn	
20	HMS-HCD-MSn	
20	HMS-HMSn	
20	HMS-MSn	
20	HMS-PQD-CID/ETD-MSn	
20	HMS-PQD-ETD-MSn	
20	MS-CID/ETD-MSn	
20	MS-ETD-MSn	
20	MS-MSn	
21	DIA-HMS-HCD-HMSn	
21	HMS	
21	HMS-CID/ETD-HMSn	
21	HMS-CID/ETD-MSn	
21	HMS-ETD-HMSn	
21	HMS-ETD-MSn	
21	HMS-ETciD-EThcD-HMSn	
21	HMS-ETciD-EThcD-MSn	
21	HMS-ETciD-HMSn	
21	HMS-ETciD-MSn	
21	HMS-EThcD-HMSn	
21	HMS-EThcD-MSn	
21	HMS-HCD-CID-HMSn	
21	HMS-HCD-CID-MSn	
21	HMS-HCD-CID/ETD-HMSn	
21	HMS-HCD-CID/ETD-MSn	
21	HMS-HCD-ETD-HMSn	
21	HMS-HCD-ETD-MSn	
21	HMS-HCD-HMSn	
21	HMS-HCD-MSn	
21	HMS-HMSn	
21	HMS-MSn	
21	HMS-PQD-CID/ETD-MSn	
21	HMS-PQD-ETD-MSn	
21	IMS-HMS	
21	IMS-HMS-HMSn	
21	IMS-HMS-MSn	
21	MRM	
21	MS	
21	MS-CID/ETD-MSn	
21	MS-ETD-MSn	
21	MS-MSn	
22	DIA-HMS-HCD-HMSn	
22	HMS-CID/ETD-HMSn	
22	HMS-CID/ETD-MSn	
22	HMS-ETD-HMSn	
22	HMS-ETD-MSn	
22	HMS-HCD-CID-HMSn	
22	HMS-HCD-CID-MSn	
22	HMS-HCD-CID/ETD-HMSn	
22	HMS-HCD-CID/ETD-MSn	
22	HMS-HCD-ETD-HMSn	
22	HMS-HCD-ETD-MSn	
22	HMS-HCD-HMSn	
22	HMS-HCD-MSn	
22	HMS-HMSn	
22	HMS-MSn	
22	HMS-PQD-CID/ETD-MSn	
22	HMS-PQD-ETD-MSn	
22	MS-CID/ETD-MSn	
22	MS-ETD-MSn	
22	MS-MSn	
23	DIA-HMS-HCD-HMSn	
23	HMS-CID/ETD-HMSn	
23	HMS-CID/ETD-MSn	
23	HMS-ETD-HMSn	
23	HMS-ETD-MSn	
23	HMS-HCD-CID-HMSn	
23	HMS-HCD-CID-MSn	
23	HMS-HCD-CID/ETD-HMSn	
23	HMS-HCD-CID/ETD-MSn	
23	HMS-HCD-ETD-HMSn	
23	HMS-HCD-ETD-MSn	
23	HMS-HCD-HMSn	
23	HMS-HCD-MSn	
23	HMS-HMSn	
23	HMS-MSn	
23	HMS-PQD-CID/ETD-MSn	
23	HMS-PQD-ETD-MSn	
23	MS-CID/ETD-MSn	
23	MS-ETD-MSn	
23	MS-MSn	
24	DIA-HMS-HCD-HMSn	
24	HMS-CID/ETD-HMSn	
24	HMS-CID/ETD-MSn	
24	HMS-ETD-HMSn	
24	HMS-ETD-MSn	
24	HMS-HCD-CID-HMSn	
24	HMS-HCD-CID-MSn	
24	HMS-HCD-CID/ETD-HMSn	
24	HMS-HCD-CID/ETD-MSn	
24	HMS-HCD-ETD-HMSn	
24	HMS-HCD-ETD-MSn	
24	HMS-HCD-HMSn	
24	HMS-HCD-MSn	
24	HMS-HMSn	
24	HMS-MSn	
24	HMS-PQD-CID/ETD-MSn	
24	HMS-PQD-ETD-MSn	
24	MS-ETD-MSn	
24	MS-MSn	
25	DIA-HMS-HCD-HMSn	
25	HMS-ETD-HMSn	
25	HMS-ETD-MSn	
25	HMS-HCD-CID-HMSn	
25	HMS-HCD-CID-MSn	
25	HMS-HCD-CID/ETD-HMSn	
25	HMS-HCD-CID/ETD-MSn	
25	HMS-HCD-ETD-HMSn	
25	HMS-HCD-ETD-MSn	
25	HMS-HCD-HMSn	
25	HMS-HCD-MSn	
25	HMS-HMSn	
25	HMS-MSn	
25	HMS-PQD-CID/ETD-MSn	
25	HMS-PQD-ETD-MSn	
25	MS-CID/ETD-MSn	
25	MS-ETD-MSn	
25	MS-MSn	
26	DIA-HMS-HCD-HMSn	
26	HMS-CID/ETD-HMSn	
26	HMS-CID/ETD-MSn	
26	HMS-ETD-HMSn	
26	HMS-ETD-MSn	
26	HMS-HCD-CID-HMSn	
26	HMS-HCD-CID-MSn	
26	HMS-HCD-CID/ETD-HMSn	
26	HMS-HCD-CID/ETD-MSn	
26	HMS-HCD-ETD-HMSn	
26	HMS-HCD-ETD-MSn	
26	HMS-HCD-HMSn	
26	HMS-HCD-MSn	
26	HMS-HMSn	
26	HMS-MSn	
26	HMS-PQD-CID/ETD-MSn	
26	HMS-PQD-ETD-MSn	
26	MS-CID/ETD-MSn	
26	MS-ETD-MSn	
26	MS-MSn	
27	DIA-HMS-HCD-HMSn	
27	GC-MS	
27	HMS	
27	HMS-CID/ETD-HMSn	
27	HMS-CID/ETD-MSn	
27	HMS-ETD-HMSn	
27	HMS-ETD-MSn	
27	HMS-ETciD-EThcD-HMSn	
27	HMS-ETciD-EThcD-MSn	
27	HMS-ETciD-HMSn	
27	HMS-ETciD-MSn	
27	HMS-EThcD-HMSn	
27	HMS-EThcD-MSn	
27	HMS-HCD-CID-HMSn	
27	HMS-HCD-CID-MSn	
27	HMS-HCD-CID/ETD-HMSn	
27	HMS-HCD-CID/ETD-MSn	
27	HMS-HCD-ETD-HMSn	
27	HMS-HCD-ETD-MSn	
27	HMS-HCD-HMSn	
27	HMS-HCD-MSn	
27	HMS-HMSn	
27	HMS-MSn	
27	HMS-PQD-CID/ETD-MSn	
27	HMS-PQD-ETD-MSn	
27	IMS-HMS	
27	IMS-HMS-HMSn	
27	IMS-HMS-MSn	
27	MALDI-HMS	
27	MS	
27	MS-CID/ETD-MSn	
27	MS-ETD-MSn	
27	MS-MSn	
28	DIA-HMS-HCD-HMSn	
28	HMS-CID/ETD-HMSn	
28	HMS-CID/ETD-MSn	
28	HMS-ETD-HMSn	
28	HMS-ETD-MSn	
28	HMS-HCD-CID-HMSn	
28	HMS-HCD-CID-MSn	
28	HMS-HCD-CID/ETD-HMSn	
28	HMS-HCD-CID/ETD-MSn	
28	HMS-HCD-ETD-HMSn	
28	HMS-HCD-ETD-MSn	
28	HMS-HCD-HMSn	
28	HMS-HCD-MSn	
28	HMS-HMSn	
28	HMS-MSn	
28	HMS-PQD-CID/ETD-MSn	
28	HMS-PQD-ETD-MSn	
28	MS-CID/ETD-MSn	
28	MS-ETD-MSn	
28	MS-MSn	
29	DIA-HMS-HCD-HMSn	
29	HMS-CID/ETD-HMSn	
29	HMS-CID/ETD-MSn	
29	HMS-ETD-HMSn	
29	HMS-ETD-MSn	
29	HMS-ETciD-EThcD-HMSn	
29	HMS-ETciD-EThcD-MSn	
29	HMS-ETciD-HMSn	
29	HMS-ETciD-MSn	
29	HMS-EThcD-HMSn	
29	HMS-EThcD-MSn	
29	HMS-HCD-CID-HMSn	
29	HMS-HCD-CID-MSn	
29	HMS-HCD-CID/ETD-HMSn	
29	HMS-HCD-CID/ETD-MSn	
29	HMS-HCD-ETD-HMSn	
29	HMS-HCD-ETD-MSn	
29	HMS-HCD-HMSn	
29	HMS-HCD-MSn	
29	HMS-HMSn	
29	HMS-MSn	
29	HMS-PQD-CID/ETD-MSn	
29	HMS-PQD-ETD-MSn	
30	DIA-HMS-HCD-HMSn	
30	HMS-CID/ETD-HMSn	
30	HMS-CID/ETD-MSn	
30	HMS-ETD-HMSn	
30	HMS-ETD-MSn	
30	HMS-HCD-CID-HMSn	
30	HMS-HCD-CID-MSn	
30	HMS-HCD-CID/ETD-HMSn	
30	HMS-HCD-CID/ETD-MSn	
30	HMS-HCD-ETD-HMSn	
30	HMS-HCD-ETD-MSn	
30	HMS-HCD-HMSn	
30	HMS-HCD-MSn	
30	HMS-HMSn	
30	HMS-MSn	
30	HMS-PQD-CID/ETD-MSn	
30	HMS-PQD-ETD-MSn	
30	MS-CID/ETD-MSn	
30	MS-ETD-MSn	
30	MS-MSn	
31	DIA-HMS-HCD-HMSn	
31	HMS-CID/ETD-HMSn	
31	HMS-CID/ETD-MSn	
31	HMS-ETD-HMSn	
31	HMS-ETD-MSn	
31	HMS-HCD-CID-HMSn	
31	HMS-HCD-CID-MSn	
31	HMS-HCD-CID/ETD-HMSn	
31	HMS-HCD-CID/ETD-MSn	
31	HMS-HCD-ETD-HMSn	
31	HMS-HCD-ETD-MSn	
31	HMS-HCD-HMSn	
31	HMS-HCD-MSn	
31	HMS-HMSn	
31	HMS-MSn	
31	HMS-PQD-CID/ETD-MSn	
31	HMS-PQD-ETD-MSn	
31	MS-CID/ETD-MSn	
31	MS-ETD-MSn	
31	MS-MSn	
33	DIA-HMS-HCD-HMSn	
33	GC-MS	
33	HMS	
33	HMS-CID/ETD-HMSn	
33	HMS-CID/ETD-MSn	
33	HMS-ETD-HMSn	
33	HMS-ETD-MSn	
33	HMS-HCD-CID-HMSn	
33	HMS-HCD-CID-MSn	
33	HMS-HCD-CID/ETD-HMSn	
33	HMS-HCD-CID/ETD-MSn	
33	HMS-HCD-ETD-HMSn	
33	HMS-HCD-ETD-MSn	
33	HMS-HCD-HMSn	
33	HMS-HCD-MSn	
33	HMS-HMSn	
33	HMS-MSn	
33	HMS-PQD-CID/ETD-MSn	
33	HMS-PQD-ETD-MSn	
33	IMS-HMS	
33	IMS-HMS-HMSn	
33	IMS-HMS-MSn	
33	MS	
33	MS-CID/ETD-MSn	
33	MS-ETD-MSn	
33	MS-MSn	
34	HMS	
34	HMS-ETciD-EThcD-HMSn	
34	HMS-ETciD-EThcD-MSn	
34	HMS-ETciD-HMSn	
34	HMS-ETciD-MSn	
34	HMS-EThcD-HMSn	
34	HMS-EThcD-MSn	
34	HMS-HMSn	
34	HMS-MSn	
34	MALDI-HMS	
35	DIA-HMS-HCD-HMSn	
35	GC-MS	
35	HMS	
35	HMS-CID/ETD-HMSn	
35	HMS-CID/ETD-MSn	
35	HMS-ETD-HMSn	
35	HMS-ETD-MSn	
35	HMS-HCD-CID-HMSn	
35	HMS-HCD-CID-MSn	
35	HMS-HCD-CID/ETD-HMSn	
35	HMS-HCD-CID/ETD-MSn	
35	HMS-HCD-ETD-HMSn	
35	HMS-HCD-ETD-MSn	
35	HMS-HCD-HMSn	
35	HMS-HCD-MSn	
35	HMS-HMSn	
35	HMS-MSn	
35	HMS-PQD-CID/ETD-MSn	
35	HMS-PQD-ETD-MSn	
35	IMS-HMS	
35	IMS-HMS-HMSn	
35	IMS-HMS-MSn	
35	MS	
35	MS-CID/ETD-MSn	
35	MS-ETD-MSn	
35	MS-MSn	
36	C60-SIMS-HMS	
36	DIA-HMS-HCD-HMSn	
36	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
36	HMS-CID/ETD-MSn	
36	HMS-ETD-HMSn	Must be centroided HMSn spectra
36	HMS-ETD-MSn	
36	HMS-ETciD-EThcD-HMSn	
36	HMS-ETciD-EThcD-MSn	
36	HMS-ETciD-HMSn	
36	HMS-ETciD-MSn	
36	HMS-EThcD-HMSn	
36	HMS-EThcD-MSn	
36	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
36	HMS-HCD-CID-MSn	
36	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
36	HMS-HCD-CID/ETD-MSn	
36	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
36	HMS-HCD-ETD-MSn	
36	HMS-HCD-HMSn	Must be centroided HMSn spectra
36	HMS-HCD-MSn	
36	HMS-HMSn	Must be centroided HMSn spectra
36	HMS-MSn	
36	HMS-PQD-CID/ETD-MSn	
36	HMS-PQD-ETD-MSn	
36	IMS-HMS-HMSn	
36	MALDI-HMS	
36	MS-CID/ETD-MSn	
36	MS-ETD-MSn	
36	MS-MSn	
37	DIA-HMS-HCD-HMSn	
37	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
37	HMS-CID/ETD-MSn	
37	HMS-ETD-HMSn	Must be centroided HMSn spectra
37	HMS-ETD-MSn	
37	HMS-ETciD-EThcD-HMSn	
37	HMS-ETciD-EThcD-MSn	
37	HMS-ETciD-HMSn	
37	HMS-ETciD-MSn	
37	HMS-EThcD-HMSn	
37	HMS-EThcD-MSn	
37	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
37	HMS-HCD-CID-MSn	
37	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
37	HMS-HCD-CID/ETD-MSn	
37	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
37	HMS-HCD-ETD-MSn	
37	HMS-HCD-HMSn	Must be centroided HMSn spectra
37	HMS-HCD-MSn	
37	HMS-HMSn	Must be centroided HMSn spectra
37	HMS-MSn	
37	HMS-PQD-CID/ETD-MSn	
37	HMS-PQD-ETD-MSn	
37	MS-CID/ETD-MSn	
37	MS-ETD-MSn	
37	MS-MSn	
38	DIA-HMS-HCD-HMSn	
38	HMS-CID/ETD-HMSn	
38	HMS-CID/ETD-MSn	
38	HMS-ETD-HMSn	
38	HMS-ETD-MSn	
38	HMS-ETciD-EThcD-HMSn	
38	HMS-ETciD-EThcD-MSn	
38	HMS-ETciD-HMSn	
38	HMS-ETciD-MSn	
38	HMS-EThcD-HMSn	
38	HMS-EThcD-MSn	
38	HMS-HCD-CID-HMSn	
38	HMS-HCD-CID-MSn	
38	HMS-HCD-CID/ETD-HMSn	
38	HMS-HCD-CID/ETD-MSn	
38	HMS-HCD-ETD-HMSn	
38	HMS-HCD-ETD-MSn	
38	HMS-HCD-HMSn	
38	HMS-HCD-MSn	
38	HMS-HMSn	
38	HMS-MSn	
38	HMS-PQD-CID/ETD-MSn	
38	HMS-PQD-ETD-MSn	
38	MS-CID/ETD-MSn	
38	MS-ETD-MSn	
38	MS-MSn	
39	DIA-HMS-HCD-HMSn	
39	HMS-CID/ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-CID/ETD-MSn	
39	HMS-ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-ETD-MSn	
39	HMS-HCD-CID-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-HCD-CID-MSn	
39	HMS-HCD-CID/ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-HCD-CID/ETD-MSn	
39	HMS-HCD-ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-HCD-ETD-MSn	
39	HMS-HCD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-HCD-MSn	
39	HMS-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	HMS-MSn	
39	HMS-PQD-CID/ETD-MSn	
39	HMS-PQD-ETD-MSn	
39	IMS-HMS-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
39	MS-CID/ETD-MSn	
39	MS-ETD-MSn	
39	MS-MSn	
40	HMS	
40	HMS-HMSn	
41	DIA-HMS-HCD-HMSn	
41	HMS	
41	HMS-CID/ETD-HMSn	
41	HMS-CID/ETD-MSn	
41	HMS-ETD-HMSn	
41	HMS-ETD-MSn	
41	HMS-ETciD-EThcD-HMSn	
41	HMS-ETciD-EThcD-MSn	
41	HMS-ETciD-HMSn	
41	HMS-ETciD-MSn	
41	HMS-EThcD-HMSn	
41	HMS-EThcD-MSn	
41	HMS-HCD-CID-HMSn	
41	HMS-HCD-CID-MSn	
41	HMS-HCD-CID/ETD-HMSn	
41	HMS-HCD-CID/ETD-MSn	
41	HMS-HCD-ETD-HMSn	
41	HMS-HCD-ETD-MSn	
41	HMS-HCD-HMSn	
41	HMS-HCD-MSn	
41	HMS-HMSn	
41	HMS-MSn	
41	HMS-PQD-CID/ETD-MSn	
41	HMS-PQD-ETD-MSn	
41	IMS-HMS	
41	IMS-HMS-HMSn	
41	IMS-HMS-MSn	
41	MRM	
41	MS	
41	MS-CID/ETD-MSn	
41	MS-ETD-MSn	
41	MS-MSn	
47	HMS	
47	HMS-HMSn	
48	HMS-HMSn	
48	MS-CID/ETD-MSn	
48	MS-ETD-MSn	
48	MS-MSn	
51	DIA-HMS-HCD-HMSn	
51	HMS-HCD-CID-HMSn	
51	HMS-HCD-CID-MSn	
51	HMS-HCD-HMSn	
51	HMS-HCD-MSn	
51	HMS-HMSn	
51	HMS-MSn	
52	IMS-HMS-HMSn	
52	IMS-HMS-MSn	
53	DIA-HMS-HCD-HMSn	
53	HMS-CID/ETD-HMSn	
53	HMS-CID/ETD-MSn	
53	HMS-ETD-HMSn	
53	HMS-ETD-MSn	
53	HMS-HCD-CID-HMSn	
53	HMS-HCD-CID-MSn	
53	HMS-HCD-CID/ETD-HMSn	
53	HMS-HCD-CID/ETD-MSn	
53	HMS-HCD-ETD-HMSn	
53	HMS-HCD-ETD-MSn	
53	HMS-HCD-HMSn	
53	HMS-HCD-MSn	
53	HMS-HMSn	
53	HMS-MSn	
53	MS-CID/ETD-MSn	
53	MS-ETD-MSn	
53	MS-MSn	
59	DIA-HMS-HCD-HMSn	
59	HMS-CID/ETD-HMSn	
59	HMS-CID/ETD-MSn	
59	HMS-ETD-HMSn	
59	HMS-ETD-MSn	
59	HMS-HCD-CID-HMSn	
59	HMS-HCD-CID-MSn	
59	HMS-HCD-CID/ETD-HMSn	
59	HMS-HCD-CID/ETD-MSn	
59	HMS-HCD-ETD-HMSn	
59	HMS-HCD-ETD-MSn	
59	HMS-HCD-HMSn	
59	HMS-HCD-MSn	
59	HMS-HMSn	
59	HMS-MSn	
59	HMS-PQD-CID/ETD-MSn	
59	HMS-PQD-ETD-MSn	
59	MS-CID/ETD-MSn	
59	MS-ETD-MSn	
59	MS-MSn	
60	DIA-HMS-HCD-HMSn	
60	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
60	HMS-CID/ETD-MSn	
60	HMS-ETD-HMSn	Must be centroided HMSn spectra
60	HMS-ETD-MSn	
60	HMS-ETciD-EThcD-HMSn	
60	HMS-ETciD-EThcD-MSn	
60	HMS-ETciD-HMSn	
60	HMS-ETciD-MSn	
60	HMS-EThcD-HMSn	
60	HMS-EThcD-MSn	
60	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
60	HMS-HCD-CID-MSn	
60	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
60	HMS-HCD-CID/ETD-MSn	
60	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
60	HMS-HCD-ETD-MSn	
60	HMS-HCD-HMSn	Must be centroided HMSn spectra
60	HMS-HCD-MSn	
60	HMS-HMSn	Must be centroided HMSn spectra
60	HMS-MSn	
60	HMS-PQD-CID/ETD-MSn	
60	HMS-PQD-ETD-MSn	
60	MS-CID/ETD-MSn	
60	MS-ETD-MSn	
60	MS-MSn	
61	DIA-HMS-HCD-HMSn	
61	HMS	
61	HMS-CID/ETD-HMSn	
61	HMS-CID/ETD-MSn	
61	HMS-ETD-HMSn	
61	HMS-ETD-MSn	
61	HMS-HCD-CID-HMSn	
61	HMS-HCD-CID-MSn	
61	HMS-HCD-CID/ETD-HMSn	
61	HMS-HCD-CID/ETD-MSn	
61	HMS-HCD-ETD-HMSn	
61	HMS-HCD-ETD-MSn	
61	HMS-HCD-HMSn	
61	HMS-HCD-MSn	
61	HMS-HMSn	
61	HMS-MSn	
61	HMS-PQD-CID/ETD-MSn	
61	HMS-PQD-ETD-MSn	
63	DIA-HMS-HCD-HMSn	
63	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
63	HMS-CID/ETD-MSn	
63	HMS-ETD-HMSn	Must be centroided HMSn spectra
63	HMS-ETD-MSn	
63	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
63	HMS-HCD-CID-MSn	
63	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
63	HMS-HCD-CID/ETD-MSn	
63	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
63	HMS-HCD-ETD-MSn	
63	HMS-HCD-HMSn	Must be centroided HMSn spectra
63	HMS-HCD-MSn	
63	HMS-HMSn	Must be centroided HMSn spectra
63	HMS-MSn	
63	HMS-PQD-CID/ETD-MSn	
63	HMS-PQD-ETD-MSn	
63	MS-CID/ETD-MSn	
63	MS-ETD-MSn	
63	MS-MSn	
64	DIA-HMS-HCD-HMSn	
64	HMS-CID/ETD-HMSn	
64	HMS-CID/ETD-MSn	
64	HMS-ETD-HMSn	
64	HMS-ETD-MSn	
64	HMS-ETciD-EThcD-HMSn	
64	HMS-ETciD-EThcD-MSn	
64	HMS-ETciD-HMSn	
64	HMS-ETciD-MSn	
64	HMS-EThcD-HMSn	
64	HMS-EThcD-MSn	
64	HMS-HCD-CID-HMSn	
64	HMS-HCD-CID-MSn	
64	HMS-HCD-CID/ETD-HMSn	
64	HMS-HCD-CID/ETD-MSn	
64	HMS-HCD-ETD-HMSn	
64	HMS-HCD-ETD-MSn	
64	HMS-HCD-HMSn	
64	HMS-HCD-MSn	
64	HMS-HMSn	
64	HMS-MSn	
64	HMS-PQD-CID/ETD-MSn	
64	HMS-PQD-ETD-MSn	
64	MS-CID/ETD-MSn	
64	MS-ETD-MSn	
64	MS-MSn	
65	DIA-HMS-HCD-HMSn	
65	HMS-CID/ETD-HMSn	
65	HMS-CID/ETD-MSn	
65	HMS-ETD-HMSn	
65	HMS-ETD-MSn	
65	HMS-ETciD-EThcD-HMSn	
65	HMS-ETciD-EThcD-MSn	
65	HMS-ETciD-HMSn	
65	HMS-ETciD-MSn	
65	HMS-EThcD-HMSn	
65	HMS-EThcD-MSn	
65	HMS-HCD-CID-HMSn	
65	HMS-HCD-CID-MSn	
65	HMS-HCD-CID/ETD-HMSn	
65	HMS-HCD-CID/ETD-MSn	
65	HMS-HCD-ETD-HMSn	
65	HMS-HCD-ETD-MSn	
65	HMS-HCD-HMSn	
65	HMS-HCD-MSn	
65	HMS-HMSn	
65	HMS-MSn	
65	HMS-PQD-CID/ETD-MSn	
65	HMS-PQD-ETD-MSn	
65	MS-CID/ETD-MSn	
65	MS-ETD-MSn	
65	MS-MSn	
66	HMS	
66	HMS-HMSn	
66	HMS-MSn	
67	DIA-HMS-HCD-HMSn	
67	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
67	HMS-CID/ETD-MSn	
67	HMS-ETD-HMSn	Must be centroided HMSn spectra
67	HMS-ETD-MSn	
67	HMS-ETciD-EThcD-HMSn	
67	HMS-ETciD-EThcD-MSn	
67	HMS-ETciD-HMSn	
67	HMS-ETciD-MSn	
67	HMS-EThcD-HMSn	
67	HMS-EThcD-MSn	
67	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
67	HMS-HCD-CID-MSn	
67	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
67	HMS-HCD-CID/ETD-MSn	
67	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
67	HMS-HCD-ETD-MSn	
67	HMS-HCD-HMSn	Must be centroided HMSn spectra
67	HMS-HCD-MSn	
67	HMS-HMSn	Must be centroided HMSn spectra
67	HMS-MSn	
67	HMS-PQD-CID/ETD-MSn	
67	HMS-PQD-ETD-MSn	
67	MS-CID/ETD-MSn	
67	MS-ETD-MSn	
67	MS-MSn	
68	C60-SIMS-HMS	
68	DIA-HMS-HCD-HMSn	
68	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
68	HMS-CID/ETD-MSn	
68	HMS-ETD-HMSn	Must be centroided HMSn spectra
68	HMS-ETD-MSn	
68	HMS-ETciD-EThcD-HMSn	
68	HMS-ETciD-EThcD-MSn	
68	HMS-ETciD-HMSn	
68	HMS-ETciD-MSn	
68	HMS-EThcD-HMSn	
68	HMS-EThcD-MSn	
68	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
68	HMS-HCD-CID-MSn	
68	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
68	HMS-HCD-CID/ETD-MSn	
68	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
68	HMS-HCD-ETD-MSn	
68	HMS-HCD-HMSn	Must be centroided HMSn spectra
68	HMS-HCD-MSn	
68	HMS-HMSn	Must be centroided HMSn spectra
68	HMS-MSn	
68	HMS-PQD-CID/ETD-MSn	
68	HMS-PQD-ETD-MSn	
68	IMS-HMS	
68	IMS-HMS-HMSn	
68	IMS-HMS-MSn	
68	MALDI-HMS	
68	MS-CID/ETD-MSn	
68	MS-ETD-MSn	
68	MS-MSn	
69	C60-SIMS-HMS	
69	DIA-HMS-HCD-HMSn	
69	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
69	HMS-CID/ETD-MSn	
69	HMS-ETD-HMSn	Must be centroided HMSn spectra
69	HMS-ETD-MSn	
69	HMS-ETciD-EThcD-HMSn	
69	HMS-ETciD-EThcD-MSn	
69	HMS-ETciD-HMSn	
69	HMS-ETciD-MSn	
69	HMS-EThcD-HMSn	
69	HMS-EThcD-MSn	
69	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
69	HMS-HCD-CID-MSn	
69	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
69	HMS-HCD-CID/ETD-MSn	
69	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
69	HMS-HCD-ETD-MSn	
69	HMS-HCD-HMSn	Must be centroided HMSn spectra
69	HMS-HCD-MSn	
69	HMS-HMSn	Must be centroided HMSn spectra
69	HMS-MSn	
69	HMS-PQD-CID/ETD-MSn	
69	HMS-PQD-ETD-MSn	
69	IMS-HMS	
69	IMS-HMS-HMSn	
69	IMS-HMS-MSn	
69	MALDI-HMS	
69	MS-CID/ETD-MSn	
69	MS-ETD-MSn	
69	MS-MSn	
70	DIA-HMS-HCD-HMSn	
70	HMS	
70	HMS-CID/ETD-HMSn	
70	HMS-CID/ETD-MSn	
70	HMS-ETD-HMSn	
70	HMS-ETD-MSn	
70	HMS-ETciD-EThcD-HMSn	
70	HMS-ETciD-EThcD-MSn	
70	HMS-ETciD-HMSn	
70	HMS-ETciD-MSn	
70	HMS-EThcD-HMSn	
70	HMS-EThcD-MSn	
70	HMS-HCD-CID-HMSn	
70	HMS-HCD-CID-MSn	
70	HMS-HCD-CID/ETD-HMSn	
70	HMS-HCD-CID/ETD-MSn	
70	HMS-HCD-ETD-HMSn	
70	HMS-HCD-ETD-MSn	
70	HMS-HCD-HMSn	
70	HMS-HCD-MSn	
70	HMS-HMSn	
70	HMS-MSn	
70	HMS-PQD-CID/ETD-MSn	
70	HMS-PQD-ETD-MSn	
70	MS	
70	MS-CID/ETD-MSn	
70	MS-ETD-MSn	
70	MS-MSn	
71	HMS	
71	HMS-HMSn	
71	HMS-MSn	
72	HMS	
72	HMS-HMSn	
73	DIA-HMS-HCD-HMSn	
73	HMS-CID/ETD-HMSn	
73	HMS-CID/ETD-MSn	
73	HMS-ETD-HMSn	
73	HMS-ETD-MSn	
73	HMS-ETciD-EThcD-HMSn	
73	HMS-ETciD-EThcD-MSn	
73	HMS-ETciD-HMSn	
73	HMS-ETciD-MSn	
73	HMS-EThcD-HMSn	
73	HMS-EThcD-MSn	
73	HMS-HCD-CID-HMSn	
73	HMS-HCD-CID-MSn	
73	HMS-HCD-CID/ETD-HMSn	
73	HMS-HCD-CID/ETD-MSn	
73	HMS-HCD-ETD-HMSn	
73	HMS-HCD-ETD-MSn	
73	HMS-HCD-HMSn	
73	HMS-HCD-MSn	
73	HMS-HMSn	
73	HMS-MSn	
73	HMS-PQD-CID/ETD-MSn	
73	HMS-PQD-ETD-MSn	
73	MS-CID/ETD-MSn	
73	MS-ETD-MSn	
73	MS-MSn	
74	DIA-HMS-HCD-HMSn	
74	HMS-CID/ETD-HMSn	
74	HMS-CID/ETD-MSn	
74	HMS-ETD-HMSn	
74	HMS-ETD-MSn	
74	HMS-ETciD-EThcD-HMSn	
74	HMS-ETciD-EThcD-MSn	
74	HMS-ETciD-HMSn	
74	HMS-ETciD-MSn	
74	HMS-EThcD-HMSn	
74	HMS-EThcD-MSn	
74	HMS-HCD-CID-HMSn	
74	HMS-HCD-CID-MSn	
74	HMS-HCD-CID/ETD-HMSn	
74	HMS-HCD-CID/ETD-MSn	
74	HMS-HCD-ETD-HMSn	
74	HMS-HCD-ETD-MSn	
74	HMS-HCD-HMSn	
74	HMS-HCD-MSn	
74	HMS-HMSn	
74	HMS-MSn	
74	HMS-PQD-CID/ETD-MSn	
74	HMS-PQD-ETD-MSn	
74	MS-CID/ETD-MSn	
74	MS-ETD-MSn	
74	MS-MSn	
75	DIA-HMS-HCD-HMSn	
75	HMS	
75	HMS-CID/ETD-HMSn	
75	HMS-CID/ETD-MSn	
75	HMS-ETD-HMSn	
75	HMS-ETD-MSn	
75	HMS-ETciD-EThcD-HMSn	
75	HMS-ETciD-EThcD-MSn	
75	HMS-ETciD-HMSn	
75	HMS-ETciD-MSn	
75	HMS-EThcD-HMSn	
75	HMS-EThcD-MSn	
75	HMS-HCD-CID-HMSn	
75	HMS-HCD-CID-MSn	
75	HMS-HCD-CID/ETD-HMSn	
75	HMS-HCD-CID/ETD-MSn	
75	HMS-HCD-ETD-HMSn	
75	HMS-HCD-ETD-MSn	
75	HMS-HCD-HMSn	
75	HMS-HCD-MSn	
75	HMS-HMSn	
75	HMS-MSn	
75	HMS-PQD-CID/ETD-MSn	
75	HMS-PQD-ETD-MSn	
75	MRM	
75	MS	
75	MS-CID/ETD-MSn	
75	MS-ETD-MSn	
75	MS-MSn	
76	DIA-HMS-HCD-HMSn	
76	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
76	HMS-CID/ETD-MSn	
76	HMS-ETD-HMSn	Must be centroided HMSn spectra
76	HMS-ETD-MSn	
76	HMS-ETciD-EThcD-HMSn	
76	HMS-ETciD-EThcD-MSn	
76	HMS-ETciD-HMSn	
76	HMS-ETciD-MSn	
76	HMS-EThcD-HMSn	
76	HMS-EThcD-MSn	
76	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
76	HMS-HCD-CID-MSn	
76	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
76	HMS-HCD-CID/ETD-MSn	
76	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
76	HMS-HCD-ETD-MSn	
76	HMS-HCD-HMSn	Must be centroided HMSn spectra
76	HMS-HCD-MSn	
76	HMS-HMSn	Must be centroided HMSn spectra
76	HMS-MSn	
76	HMS-PQD-CID/ETD-MSn	
76	HMS-PQD-ETD-MSn	
76	MS-CID/ETD-MSn	
76	MS-ETD-MSn	
76	MS-MSn	
77	HMS	
78	DIA-HMS-HCD-HMSn	
78	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
78	HMS-CID/ETD-MSn	
78	HMS-ETD-HMSn	Must be centroided HMSn spectra
78	HMS-ETD-MSn	
78	HMS-ETciD-EThcD-HMSn	
78	HMS-ETciD-EThcD-MSn	
78	HMS-ETciD-HMSn	
78	HMS-ETciD-MSn	
78	HMS-EThcD-HMSn	
78	HMS-EThcD-MSn	
78	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
78	HMS-HCD-CID-MSn	
78	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
78	HMS-HCD-CID/ETD-MSn	
78	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
78	HMS-HCD-ETD-MSn	
78	HMS-HCD-HMSn	Must be centroided HMSn spectra
78	HMS-HCD-MSn	
78	HMS-HMSn	Must be centroided HMSn spectra
78	HMS-MSn	
78	HMS-PQD-CID/ETD-MSn	
78	HMS-PQD-ETD-MSn	
78	MS-CID/ETD-MSn	
78	MS-ETD-MSn	
78	MS-MSn	
79	C60-SIMS-HMS	
79	DIA-HMS-HCD-HMSn	
79	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
79	HMS-CID/ETD-MSn	
79	HMS-ETD-HMSn	Must be centroided HMSn spectra
79	HMS-ETD-MSn	
79	HMS-ETciD-EThcD-HMSn	
79	HMS-ETciD-EThcD-MSn	
79	HMS-ETciD-HMSn	
79	HMS-ETciD-MSn	
79	HMS-EThcD-HMSn	
79	HMS-EThcD-MSn	
79	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
79	HMS-HCD-CID-MSn	
79	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
79	HMS-HCD-CID/ETD-MSn	
79	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
79	HMS-HCD-ETD-MSn	
79	HMS-HCD-HMSn	Must be centroided HMSn spectra
79	HMS-HCD-MSn	
79	HMS-HMSn	Must be centroided HMSn spectra
79	HMS-MSn	
79	HMS-PQD-CID/ETD-MSn	
79	HMS-PQD-ETD-MSn	
79	IMS-HMS	
79	IMS-HMS-HMSn	
79	IMS-HMS-MSn	
79	MALDI-HMS	
79	MS-CID/ETD-MSn	
79	MS-ETD-MSn	
79	MS-MSn	
81	HMS	
81	HMS-HMSn	
83	DIA-HMS-HCD-HMSn	
83	HMS-CID/ETD-HMSn	
83	HMS-CID/ETD-MSn	
83	HMS-ETD-HMSn	
83	HMS-ETD-MSn	
83	HMS-ETciD-EThcD-HMSn	
83	HMS-ETciD-EThcD-MSn	
83	HMS-ETciD-HMSn	
83	HMS-ETciD-MSn	
83	HMS-EThcD-HMSn	
83	HMS-EThcD-MSn	
83	HMS-HCD-CID-HMSn	
83	HMS-HCD-CID-MSn	
83	HMS-HCD-CID/ETD-HMSn	
83	HMS-HCD-CID/ETD-MSn	
83	HMS-HCD-ETD-HMSn	
83	HMS-HCD-ETD-MSn	
83	HMS-HCD-HMSn	
83	HMS-HCD-MSn	
83	HMS-HMSn	
83	HMS-MSn	
83	HMS-PQD-CID/ETD-MSn	
83	HMS-PQD-ETD-MSn	
83	MS-CID/ETD-MSn	
83	MS-ETD-MSn	
83	MS-MSn	
85	HMS	
85	HMS-HMSn	
86	DIA-HMS-HCD-HMSn	
86	HMS-CID/ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-CID/ETD-MSn	
86	HMS-ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-ETD-MSn	
86	HMS-HCD-CID-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-HCD-CID-MSn	
86	HMS-HCD-CID/ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-HCD-CID/ETD-MSn	
86	HMS-HCD-ETD-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-HCD-ETD-MSn	
86	HMS-HCD-HMSn	MzML creation step should centroid the spectra (MS-GF+ requirement)
86	HMS-HCD-MSn	
86	HMS-HMSn	MzML creation step should centroid the spectra (MSGF+ requirement)
86	HMS-MSn	
86	HMS-PQD-CID/ETD-MSn	
86	HMS-PQD-ETD-MSn	
86	IMS-HMS	
86	IMS-HMS-HMSn	
86	IMS-HMS-MSn	
86	MS-CID/ETD-MSn	
86	MS-ETD-MSn	
86	MS-MSn	
87	HMS	
87	HMS-HMSn	
88	DIA-HMS-HCD-HMSn	
88	HMS-CID/ETD-HMSn	
88	HMS-CID/ETD-MSn	
88	HMS-ETD-HMSn	
88	HMS-ETD-MSn	
88	HMS-ETciD-EThcD-HMSn	
88	HMS-ETciD-EThcD-MSn	
88	HMS-ETciD-HMSn	
88	HMS-ETciD-MSn	
88	HMS-EThcD-HMSn	
88	HMS-EThcD-MSn	
88	HMS-HCD-CID-HMSn	
88	HMS-HCD-CID-MSn	
88	HMS-HCD-CID/ETD-HMSn	
88	HMS-HCD-CID/ETD-MSn	
88	HMS-HCD-ETD-HMSn	
88	HMS-HCD-ETD-MSn	
88	HMS-HCD-HMSn	
88	HMS-HCD-MSn	
88	HMS-HMSn	
88	HMS-MSn	
88	HMS-PQD-CID/ETD-MSn	
88	HMS-PQD-ETD-MSn	
88	MS-CID/ETD-MSn	
88	MS-ETD-MSn	
88	MS-MSn	
90	C60-SIMS-HMS	
90	DIA-HMS-HCD-HMSn	
90	HMS-CID/ETD-HMSn	Must be centroided HMSn spectra
90	HMS-CID/ETD-MSn	
90	HMS-ETD-HMSn	Must be centroided HMSn spectra
90	HMS-ETD-MSn	
90	HMS-ETciD-EThcD-HMSn	
90	HMS-ETciD-EThcD-MSn	
90	HMS-ETciD-HMSn	
90	HMS-ETciD-MSn	
90	HMS-EThcD-HMSn	
90	HMS-EThcD-MSn	
90	HMS-HCD-CID-HMSn	Must be centroided HMSn spectra
90	HMS-HCD-CID-MSn	
90	HMS-HCD-CID/ETD-HMSn	Must be centroided HMSn spectra
90	HMS-HCD-CID/ETD-MSn	
90	HMS-HCD-ETD-HMSn	Must be centroided HMSn spectra
90	HMS-HCD-ETD-MSn	
90	HMS-HCD-HMSn	Must be centroided HMSn spectra
90	HMS-HCD-MSn	
90	HMS-HMSn	Must be centroided HMSn spectra
90	HMS-MSn	
90	HMS-PQD-CID/ETD-MSn	
90	HMS-PQD-ETD-MSn	
90	IMS-HMS	
90	IMS-HMS-HMSn	
90	IMS-HMS-MSn	
90	MALDI-HMS	
90	MS-CID/ETD-MSn	
90	MS-ETD-MSn	
90	MS-MSn	
91	DIA-HMS-HCD-HMSn	
91	HMS-CID/ETD-HMSn	
91	HMS-CID/ETD-MSn	
91	HMS-ETD-HMSn	
91	HMS-ETD-MSn	
91	HMS-ETciD-EThcD-HMSn	
91	HMS-ETciD-EThcD-MSn	
91	HMS-ETciD-HMSn	
91	HMS-ETciD-MSn	
91	HMS-EThcD-HMSn	
91	HMS-EThcD-MSn	
91	HMS-HCD-CID-HMSn	
91	HMS-HCD-CID-MSn	
91	HMS-HCD-CID/ETD-HMSn	
91	HMS-HCD-CID/ETD-MSn	
91	HMS-HCD-ETD-HMSn	
91	HMS-HCD-ETD-MSn	
91	HMS-HCD-HMSn	
91	HMS-HCD-MSn	
91	HMS-HMSn	
91	HMS-MSn	
91	HMS-PQD-CID/ETD-MSn	
91	HMS-PQD-ETD-MSn	
91	MS-CID/ETD-MSn	
91	MS-ETD-MSn	
91	MS-MSn	
92	DIA-HMS-HCD-HMSn	
92	HMS-CID/ETD-HMSn	
92	HMS-CID/ETD-MSn	
92	HMS-ETD-HMSn	
92	HMS-ETD-MSn	
92	HMS-ETciD-EThcD-HMSn	
92	HMS-ETciD-EThcD-MSn	
92	HMS-ETciD-HMSn	
92	HMS-ETciD-MSn	
92	HMS-EThcD-HMSn	
92	HMS-EThcD-MSn	
92	HMS-HCD-CID-HMSn	
92	HMS-HCD-CID-MSn	
92	HMS-HCD-CID/ETD-HMSn	
92	HMS-HCD-CID/ETD-MSn	
92	HMS-HCD-ETD-HMSn	
92	HMS-HCD-ETD-MSn	
92	HMS-HCD-HMSn	
92	HMS-HCD-MSn	
92	HMS-HMSn	
92	HMS-MSn	
92	HMS-PQD-CID/ETD-MSn	
92	HMS-PQD-ETD-MSn	
92	MS-CID/ETD-MSn	
92	MS-ETD-MSn	
92	MS-MSn	
\.


--
-- PostgreSQL database dump complete
--


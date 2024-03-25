--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
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
-- Data for Name: t_aux_info_subcategory; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_aux_info_subcategory (aux_subcategory_id, aux_subcategory, aux_category_id, sequence) FROM stdin;
244	General	1011	1
245	Starter Conditions	1011	2
246	Growth Conditions	1011	3
247	Isolation	1011	4
248	Procedure	1013	0
249	Bead Beating	1000	1
250	Enzymatic Digest	1000	2
251	Freeze/Thaw	1000	3
252	French Press	1000	4
253	Sonication	1000	5
254	Centrifugation	1004	1
255	Membrane Procedure	1004	2
256	Protein Separation	1004	3
257	Inorganic Reagent	1001	1
258	Organic Reagent	1001	2
259	Surfactant	1001	3
260	Reagents	1002	1
261	Alkylation	1003	2
262	Labeling	1003	1
263	Buffer	1005	1
264	Desalt	1005	2
265	Enzyme	1005	3
266	Purification	1007	0
267	SPE	1006	1
268	Dialysis	1006	2
269	Conditions	1008	0
270	Location	1009	0
271	General	1014	0
275	Size Exclusion	1006	3
276	Avidin	1006	4
277	Thermal	1001	4
278	Funding	1016	1
279	Ultracentrifuge	1008	1
280	Location	1017	1
281	MCDL Sample Descriptions	1011	5
282	Fractionation	1007	1
283	Location	1018	1
284	BSL2	1019	1
285	Homogenization	1000	6
286	Well Plate	1009	1
287	Barocycler	1000	7
288	Depletion	1004	4
293	Sample Relationships	1020	1
\.


--
-- Name: t_aux_info_subcategory_aux_subcategory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_aux_info_subcategory_aux_subcategory_id_seq', 293, true);


--
-- PostgreSQL database dump complete
--


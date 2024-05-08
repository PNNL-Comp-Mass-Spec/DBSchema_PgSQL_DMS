--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

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
-- Data for Name: t_filter_sets; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_filter_sets (filter_set_id, filter_type_id, filter_set_name, filter_set_description, date_created, date_modified) FROM stdin;
100	3	Yates custom 1, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.9 if seen >= 2 times, no cleavage rules, min length 4	2004-03-27 13:59:48	2004-08-19 14:21:10
101	3	Yates custom 2, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once or twice, XCorr >= 1.9 if seen >= 3 times, no cleavage rules, min length 4	2004-03-27 13:59:48	2004-08-19 14:21:10
102	3	Yates custom 3, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+, no cleavage rules, min length 4	2004-03-27 13:59:48	2004-08-19 14:21:10
103	3	Yates custom 4, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 0 if seen >= 2 times, no cleavage rules, min length 4	2004-03-27 17:10:00	2004-08-19 14:21:10
104	1	None (accept all)	no rules	2004-03-31 14:02:39	2004-08-19 14:21:10
105	3	Yates custom 5, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.9 if seen >= 2 times, Log_EValue <= -2, no cleavage rules, min length 6	2004-04-13 07:35:14	2004-08-19 14:21:10
106	3	High confidence 1	XCorr >= 3.0, 3.6, or 4.0 for 1+, 2+, or >=3+, Log_EValue <= -4, partially or fully tryptic, min length 6, obs count >= 3	2004-05-11 11:49:08	2004-08-19 14:21:10
107	3	Washburn/Yates, partially tryptic, 1% XTandem FDR	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -2, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2004-07-06 16:19:52	2005-03-27 17:49:00
108	3	Kim Hixson custom 1	XCorr >= 1.9, 2.2, or 3.0 for 1+, 2+, or 3+ fully tryptic, and >= 2.7, 3.1, and 3.7 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2004-07-23 12:17:00	2005-03-27 17:49:00
109	3	Weijun Qian custom 2 (human plasma criteria)	XCorr >= 2.0, 2.4, or 3.7 for 1+, 2+, or 3+ fully tryptic, and >= 3.0, 3.5, and 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2004-07-15 19:27:55	2005-03-26 14:20:00
110	3	Weijun Qian custom 1 (human cell line criteria)	XCorr >= 1.5, 1.9, or 2.9 for 1+, 2+, or 3+ fully tryptic, and >= 3.1, 3.8, and 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2004-07-15 19:28:02	2005-03-26 14:20:00
111	3	Ruihua custom 1	XCorr >= 1.9, 1.9, or 3.2 for 1+, 2+, or 3+, partially or fully tryptic, min length 6	2004-07-20 14:04:05	2004-08-19 14:21:10
112	3	Washburn/Yates, no cleavage rules	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, no cleavage rules, min length 6	2004-07-21 16:15:52	2004-08-19 14:21:10
113	3	Yates custom 6, no cleavage rules	XCorr >= 1.9, 2.2, or 3.0 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.9 if seen >= 2 times, no cleavage rules, min length 4	2004-07-23 12:14:00	2004-08-19 14:21:10
114	3	Weijun Qian custom 3	XCorr >= 1.5, 1.8, or 2.8 for 1+, 2+, or 3+ fully tryptic, and >= 2.1, 2.7, or 3.9 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2004-07-23 13:08:00	2005-03-26 14:20:00
115	3	Weijun Qian custom 4	XCorr >= 1.5, 1.5, or 2.4 for 1+, 2+, or 3+ fully tryptic, and >= 2.5, 3.5, or 4.0 for partially tryptic or non-tryptic protein terminal peptide, min length 6, Max DelCn 0.05	2004-08-02 22:16:20	2005-03-26 14:20:00
116	3	Weijun Qian custom 5	XCorr >= 1.5, 1.9, or 2.9 for 1+, 2+, or 3+ fully tryptic, and >= 3.1, 3.8, or 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6, Max DelCn 0.05	2004-08-02 22:17:30	2005-03-26 14:20:00
117	2	Partially or fully tryptic	no XCorr or analysis count filters, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2004-08-07 12:13:52	2005-03-27 17:49:00
118	2	Fully tryptic	fully tryptic only, accept all XCorr, lengths, etc.	2004-08-12 14:39:05	2004-08-19 14:21:10
119	1	Peptide DB minima 1	XCorr >= 1.5 if mass < 1000, XCorr >= 2.0 if mass > 1000, DeltaCn <= 0.1	2004-08-24 11:50:13	2004-08-24 11:50:13
120	1	Peptide DB minima 2	XCorr >= 1.5 if mass < 1000, XCorr >= 2.0 if mass > 1000, DeltaCn <= 0.1; Hyperscore >= 1 and LogEValue <=0; alternatively, Discriminant_Initial_Filter >= 1 for all peptides with XCorr >= 1	2004-09-10 08:57:01	2004-09-10 08:57:20
122	3	Tao Liu custom 1 (for LTQ)	XCorr >= 1.5, 2.2, or 2.9 for 1+, 2+, or 3+ fully tryptic, and >= 100, 4.0, or 4.6 for partially tryptic or non-tryptic protein terminal peptide, min length 6, Max DelCn 0.05	2004-09-29 15:16:09	2005-03-26 14:20:00
124	1	DelCn <=0.1 Only	no XCorr rules, DeltaCN <= 0.1	2004-11-04 16:19:28	2004-11-04 16:19:28
125	2	DelCn =0 Only	no XCorr rules, DeltaCN = 0; this will give the top scoring match for each spectrum (equivalent to RankScore = 1 aka RankXC = 1)	2004-11-08 15:09:10	2004-11-08 15:09:10
126	1	Peptide DB minima 3	XCorr >= 1.5 if mass < 1000, XCorr >= 2.0 if mass > 1000, partially or fully tryptic or non-tryptic protein terminal peptide, DeltaCn <= 0.1; alternatively, Discriminant_Initial_Filter >= 1 for all peptides with XCorr >= 1	2004-11-08 15:24:04	2005-03-27 17:49:00
127	3	Yates custom 6, no cleavage rules	XCorr >= 2.0, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.8, 2.0, or 3.2 for 1+, 2+, or >=3+ if seen >= 2 times, no cleavage rules, min length 6	2004-12-13 17:04:55	2004-12-13 18:49:00
128	3	Yates custom 7, no cleavage rules	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.7, 1.9, or 2.9 for 1+, 2+, or >=3+ if seen >= 2 times, no cleavage rules, min length 6	2004-12-13 20:22:35	2004-12-13 20:22:35
129	2	Minimum length 6 only	no XCorr or analysis count filters, any tryptic state, min length 6	2004-12-28 11:54:00	2004-12-28 11:54:00
130	3	Washburn/Yates, partially tryptic, top hit only	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6, DelCn = 0, DelCn2 >= 0.08	2005-01-19 16:31:53	2005-03-27 17:49:00
131	3	Yates custom 8, no cleavage rules	XCorr >= 2.0, 2.5, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.8, 2.2, or 3.2 for 1+, 2+, or >=3+ if seen >= 2 times, no cleavage rules, min length 6	2005-03-02 19:45:00	2005-03-02 19:45:00
132	1	Peptide DB reverse search minima 1	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or 3+, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6, DelCn = 0, DelCn2 >= 0.1	2005-03-09 18:46:00	2005-03-27 17:49:00
133	3	Weijun Qian custom 6	XCorr >= 1.5, 1.9, or 2.3 for 1+, 2+, or 3+ fully tryptic, and >= 2.5, 3.1, or 3.8 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DeltaCn <= 0.05	2005-03-14 08:54:41	2005-03-26 14:20:00
134	3	Weijun Qian custom 7	XCorr >= 1.5, 2.7, or 3.3 for 1+, 2+, or 3+ fully tryptic, and >= 3.0, 3.7, or 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DeltaCn <= 0.05	2005-03-14 08:54:45	2005-03-26 14:20:00
137	2	Minimum length 6, DeltaCn <= 0.05 only	no XCorr, analysis count, discriminant or NET filters, min length 6, DeltaCn <= 0.05	2005-04-29 11:13:48	2005-04-29 11:13:48
138	3	Tao Liu custom 2	XCorr >= 1.5, 2.1, or 3.0 for 1+, 2+, or 3+ fully tryptic, and >= 3.1, 3.6, or 4.1 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2005-04-29 11:48:17	2005-04-29 11:48:17
139	3	Strict Washburn/Yates MudPIT	XCorr >= 1.9 for 1+ (fully tryptic), XCorr >= 2.2 or 3.75 for 2+ or 3+ (full or partial tryptic), or XCorr >=3.0 for 2+ (fully tryptic), DelCN2 >= 0.1	2005-05-31 18:04:55	2005-05-31 18:04:55
140	1	Peptide DB minima 4	XCorr >= 1.5 if mass < 1000, XCorr >= 2.0 if mass > 1000, DeltaCn = 0 (top hit only); alternatively, Discriminant_Initial_Filter >= 1 for all peptides with XCorr >= 1 and DeltaCN = 0	2005-08-16 12:39:38	2005-08-16 12:39:38
141	3	Yates custom 9	XCorr >= 1.9, 2.2, or 3.0 for 1+, 2+, or >=3+, Hyperscore >= 20, 15, or 27 for 1+, 2+, or >=3+, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2005-09-28 18:51:33	2005-09-28 18:51:33
142	1	Peptide DB minima 5	XCorr >= 5 for 1+, XCorr >= 1.0 for 2+, 3+, partially tryptic	2005-10-21 13:48:24	2005-10-21 13:48:24
143	3	Tom Metz custom 1	XCorr >= 1.5, 1.5, or 2.4 for 1+, 2+, or >=3+ fully tryptic, and >= 2.5, 3.1, or 3.8 for partially tryptic or non-tryptic protein terminal peptide, min length 6, Max DelCn 0.05	2005-11-01 13:57:22	2005-11-01 13:57:22
144	3	Tom Metz custom 2	XCorr >= 1.5, 1.9, or 2.9 for 1+, 2+, or >=3+ fully tryptic, and >= 3.0, 3.7, or 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6, Max DelCn 0.05	2005-11-01 13:58:25	2005-11-01 13:58:25
145	3	Nathan Manes custom 1	XCorr >= 2.35 for 1+, 2.64 for 2+, 3.24 for 3+, 3.91 for 4+, and 4.26 for 5+, no cleavage rules, min length 6, Protein_Count = 1	2005-11-29 11:22:00	2005-11-29 11:22:00
146	3	Feng Yang custom 1	XCorr >= 1.5, 2.0, or 2.6 for 1+, 2+, or 3+ fully tryptic, and >= 100, 2.5, or 3.0 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2005-12-28 11:32:05	2005-12-28 11:32:05
147	3	Feng Yang custom 2	XCorr >= 1.5, 2.2, or 2.9 for 1+, 2+, or 3+ fully tryptic, and >= 100, 4.0, or 4.6 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2005-12-28 11:58:53	2005-12-28 11:58:53
148	3	Nathan Manes custom 2	XCorr & DeltaCn2 >=1.8 & 0.21 for 1+, 2.14 & 0.20 for 2+, 2.68 & 0.235 for 3+, no cleavage rules, min length 6	2006-01-12 20:46:22	2006-01-12 20:46:22
149	1	Peptide DB minima 6	XCorr >= 1.5 for 1+ or 2+, XCorr >= 2.5 for >=3+, partially/fully tryptic or protein terminal; DeltaCn <= 0.1; XCorr >= 3 for 1+ non-tryptic; XCorr >= 4 for >= 2+ non-tryptic; alternatively, Discriminant_Initial_Filter >= 1 for all partially/fully tryptic	2006-01-24 18:30:00	2006-01-24 18:30:00
151	3	Deep Jaitly custom 1	XCorr >= 2.3337, 3.0997, or 3.6633 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:14:20	2006-02-17 12:14:20
152	3	Deep Jaitly custom 2	XCorr >= 2.5777, 3.3415, or 3.8764 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:21:16	2006-02-17 12:21:16
153	3	Deep Jaitly custom 3	XCorr >= 2.7159, 3.5434, or 4.0365 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:21:18	2006-02-17 12:21:18
154	3	Deep Jaitly custom 4	XCorr >= 2.8772, 3.7936, or 4.2007 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:21:20	2006-02-17 12:21:20
155	3	Deep Jaitly custom 5	XCorr >= 3.0525, 3.9440, or 4.3809 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:21:22	2006-02-17 12:21:22
156	3	Deep Jaitly custom 6	XCorr >= 3.1321, 4.0918, or 4.4704 for 1+, 2+, or >=3+ fully tryptic	2006-02-17 12:21:24	2006-02-17 12:21:24
157	3	Shi-Jian Custom 1	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, fully tryptic, DelCn=0, DelCn2>=0.1, minimum length = 6	2006-02-20 16:17:37	2006-02-20 16:17:37
158	3	Xiuxia custom 1	XCorr >= 1.5, 1.9, or 2.4 for 1+, 2+, or >=3+, no tryptic rules	2006-03-15 14:47:21	2006-03-15 14:47:21
159	3	Washburn/Yates, partially tryptic, 5% XTandem FDR	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -1.3, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2006-04-11 15:26:00	2006-04-12 10:35:00
160	3	Vlad Petyuk custom 1	XCorr >= 2.5, 2.2, or 3.1 for 1+, 2+, or >=3+ fully tryptic, and >= 100, 4.4, or 4.9 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DeltaCn <= 0.05, RankXC <= 3 (ignored)	2006-08-25 16:19:00	2006-08-25 16:19:00
161	3	Vlad Petyuk custom 2	XCorr >= 2.5, 2.2, or 3.1 for 1+, 2+, or >=3+ fully tryptic, and >= 100, 4.4, or 4.9 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DeltaCn2 >= 0.1, RankXC = 1	2006-08-25 16:27:22	2006-08-25 16:27:23
162	3	Washburn/Yates, discriminant score min 0.5, PepProphet 0.9	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -1.3, discriminant >=0.5, PepProphet >=0.9, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2006-10-02 00:00:00	2006-10-02 00:00:00
163	3	Tom Metz custom 3	XCorr >= 1.6, 2.4, or 3.2 for 1+, 2+, or >=3+ fully tryptic, and >= 100, 4.3, or 4.7 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DelCn2 >= 0.1	2006-11-20 14:15:52	2006-11-20 14:15:51
164	3	Bryan Ham custom 1	XCorr >= 1.4, 2.0, or 2.2 for 1+, 2+, or >=3+, no tryptic rules	2007-02-08 17:39:16	2007-02-08 17:39:16
165	3	Bryan Ham custom 2	XCorr >= 1.4, 2.4, or 3.3 for 1+, 2+, or >=3+, DelCn2 >= 0.13, no tryptic rules	2007-02-21 11:33:26	2007-02-21 11:33:26
166	1	RankXc=1 only	RankXc = 1, no other filters; this will give the top scoring match for each spectrum	2007-02-27 11:30:55	2007-02-27 11:30:55
167	3	Bryan Ham custom 3	XCorr >= 3.0 for 2+, 3+ or 4+,DelCn2 >=0.09, no tryptic rules	2007-04-17 10:06:50	2007-04-17 10:06:50
168	3	Jon Jacobs Custom 1	XCorr >= 1.5, 2.3, or 3.1 for 1+, 2+, or 3+ fully tryptic, and >= 3.0, 3.7, or 4.4 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DeltaCn <= 0.05	2007-10-11 18:17:53	2007-10-11 18:17:53
169	3	Bryan Ham custom 4	XCorr >= 1.4, 2.2, 2.7, or 2.6 for 1+, 2+, 3+, >=4+, DelCn2 >= 0.13, no tryptic rules	2007-10-22 16:41:57	2007-10-22 16:41:57
170	3	Yates custom 10	XCorr >= 1.9, 2.2, or 3.0 for 1+, 2+, or >=3+, Log_EValue <= -2, observation count >= 10, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2008-03-01 23:40:22	2008-03-01 23:40:22
171	3	Washburn/Yates, discriminant score min 0.5, PepProphet 0.9, obs count >= 10	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -1.3, discriminant >=0.5, PepProphet >=0.9, observation count >= 10, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6	2008-03-02 20:33:40	2008-03-02 20:33:40
173	1	Peptide DB minima 7	XCorr >= 1.5, no cleavage filters	2008-06-11 18:06:00	2008-06-11 18:06:00
174	1	Peptide DB minima 8	XCorr >= 1.5, partially or fully tryptic	2008-08-18 13:33:36	2008-08-18 13:33:36
175	3	Tom Metz custom 4	XCorr >= 2.5, 3.2, 4.0 for 1+, 2+, or 3+ fully tryptic, and >= 3.2, 3.9, or 4.8 for partially tryptic, DelCn2 >= 0.1, min length 6	2009-01-21 21:27:57	2009-01-21 21:27:57
177	3	Vlad Petyuk custom 3, 10% FDR	XCorr >= 1.6, 2.1, or 2.8 and DeltaCN2 >= 0.11, 0.19, or 0.21 for 1+, 2+, or >=3+ partially tryptic or non-tryptic protein terminal peptide	2009-02-02 15:50:10	2009-02-02 15:50:10
178	3	Vlad Petyuk custom 4, 3.16% FDR	XCorr >= 1.6, 2.4, or 2.9 and DeltaCN2 >= 0.19, 0.22, or 0.26 for 1+, 2+, or >=3+ partially tryptic or non-tryptic protein terminal peptide	2009-02-02 15:58:47	2009-02-02 15:58:47
179	3	Vlad Petyuk custom 5, 1% FDR	XCorr >= 1.9, 2.5, or 2.8 and DeltaCN2 >= 0.21, 0.26, or 0.32 for 1+, 2+, or >=3+ partially tryptic or non-tryptic protein terminal peptide	2009-02-02 15:58:53	2009-02-02 15:58:53
180	3	Vlad Petyuk custom 6, 0.32% FDR	XCorr >= 1.9, 2.8, or 2.8 and DeltaCN2 >= 0.28, 0.27, or 0.35 for 1+, 2+, or >=3+ partially tryptic or non-tryptic protein terminal peptide	2009-02-02 15:58:59	2009-02-02 15:58:59
181	3	Xu Zhang custom 1	XCorr >= 1.5, 1.9, or 2.3 (or XT LogEValue <= -1) for 1+, 2+, or 3+ fully tryptic, and >= 2.5, 3.1, or 3.83 (or XT LogEValue <= -2) for partially tryptic or non-tryptic protein terminal, min length 6, DeltaCn <= 0.05; XCorr's are from Filter Set 133	2009-02-04 12:40:30	2009-02-04 12:40:30
182	3	Xu Zhang custom 2	XCorr >= 1.5, 2.7, or 3.3 (or XT LogEValue <= -1.25)  for 1+, 2+, or 3+ fully tryptic, and >= 3.0, 3.7, or 4.5 (or XT LogEValue <= -2.25) for partially tryptic or non-tryptic protein terminal, min length 6, DeltaCn <= 0.05; XCorr's are from Filter Set 134	2009-02-04 12:40:33	2009-02-04 12:40:33
183	3	Inspect PValue <= .375	Inspect pvalue <= 0.375	2009-07-20 11:57:15	2009-07-20 11:57:15
184	3	Tom Metz custom 5	XCorr >= 2, 2.6, or 3.3 for 1+, 2+, or >=3+ fully tryptic, and >= 100, 3.6, or 4.1 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DelCn2 >= 0.1	2009-10-02 14:01:59	2009-10-02 14:01:59
186	3	Hee Jung Custom 1, 1% FDR	XCorr >= 1.5, 1.75, 1.9, 2.5, etc. and DeltaCN2 >= 0.1, 0.12, 0.15, etc. for charge 1+, 2+, etc. fully tryptic; XCorr >= 2.6, 3.7, 4.15, etc. and DeltaCN2 >= 0.13, 0.01, etc. for 1+, 2+, etc. partially tryptic	2009-11-10 13:12:39	2009-11-10 13:12:39
188	3	Yuexi Wang Custom 1	XCorr >= 1.4, 2, and 2.2 and DeltaCN2 >= 0.05 for 1+, 2+, or 3+ fully tryptic; XCorr >= 2, 2.1, or 3 and DeltaCN2 >= 0.05 for 1+, 2+, or 3+ partially tryptic; XCorr >= 1.5, 1.9, or 2.5 and DeltaCN2 >= 0.1 for 1+, 2+, or 3+ partially tryptic	2009-12-11 18:24:37	2009-12-11 18:24:37
189	3	Varnum Custom 1	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or 3+ fully tryptic, and >= 3.0, 3.7, or 4.5 for partially tryptic or non-tryptic protein terminal peptide, min length 6	2010-01-29 15:31:52	2010-01-29 15:31:52
190	3	Modified Washburn/Yates - Purvine	XCorr >= 1.9, 2.2, or 3.2 for 1+, 2+, or >=3+, for partially tryptic or non-tryptic protein terminal peptide, DelCN2 >= 0.1, Top XCorr data only (first hits), X!Tandem Log_EValue <= -2	2010-02-10 17:15:31	2010-02-10 17:15:31
191	3	Qibin Custom 1	XCorr >= 2.05, 2.6, 3.5, or 4.25 for 2+, 3+, 4+, or 5+ full tryptic, XCorr >= 4.2, 4.5, or 4.55 for 3+, 4+ or 5+ partially tryptic, DelCN2 >= 0.1	2010-02-17 13:57:27	2010-02-17 13:57:27
192	3	Tom Metz custom 6	XCorr >= 2, 2.6, or 3.5 for 1+, 2+, or >=3+ fully tryptic, and >= 2.5, 3.6, or 4.1 for partially tryptic or non-tryptic protein terminal peptide, min length 6, DelCn2 >= 0.1	2010-02-22 15:41:16	2010-02-22 15:41:16
194	3	Modified Washburn/Yates, all filter-passing hits	XCorr >= 1.9, 2.2, or 3.2 for 1+, 2+, or >=3+, Log_EValue <= -2, for partially tryptic or non-tryptic protein terminal peptide	2010-04-13 11:01:33	2010-04-13 11:01:33
195	3	Qibin Custom 2	XCorr >= 1.7, 2.1, 2.7, 3.5, or 4.3 for 1+ 2+, 3+, 4+, or 5+ full tryptic, XCorr >= 2.7, 3.0, 4.0, 4.7, or 5.1 for 1+, 2+, 3+, 4+ or 5+ partially tryptic or non-tryptic protein terminal peptide,  min length 6, DelCN2 >= 0.1; RankXC = 1	2010-06-28 12:05:51	2010-06-28 12:05:51
196	1	Peptide DB minima 9	XCorr >= 1.5 for 1+ or 2+, XCorr >= 2.5 for >=3+, partially/fully tryptic or protein terminal; DeltaCn <= 0.1; XCorr >= 3 for 1+ non-tryptic; XCorr >= 4 for >= 2+ non-tryptic; alternatively, MSGF < 1E-8, regardless of cleavage state or charge state; for MSAlign, requires PValue < 1E-5	2010-07-23 13:06:02	2010-07-23 13:06:02
197	3	Sam Payne Custom 1	XCorr >= 1.9, 2.2, or 3.5 for 1+, 2+, or >=3+ if seen once, XCorr >= 1.9 if seen >= 2 times, Log_EValue <= -2, MSGF <= 1E-9, no cleavage rules, min length 6	2010-11-11 18:30:47	2010-11-11 18:30:47
198	3	Sam Payne Loose	MSGF <= 1E-8, Peptide Prophet >= 0.5, and NET Error <= 0.05	2011-01-11 14:16:21	2011-01-11 14:16:21
199	3	Sam Payne Strict	MSGF <= 1E-10 and Peptide Prophet >= 0.5	2011-01-11 14:17:33	2011-01-11 14:17:33
200	3	Washburn/Yates, 1% XTandem FDR, MSGF <=1E-8	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -2, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6; MSGF <=1E-8	2011-01-21 15:26:13	2011-01-21 15:26:13
201	3	Washburn/Yates, 1% XTandem FDR, MSGF <=1E-10	XCorr >= 1.9, 2.2, or 3.75 for 1+, 2+, or >=3+, Log_EValue <= -2, partially or fully tryptic or non-tryptic protein terminal peptide, min length 6; MSGF <=1E-10	2011-01-21 16:17:02	2011-01-21 16:17:02
202	1	Peptide DB minima 10 with MSGF <= 1E-8	MSGF <= 1E-8; XCorr >= 1.5 for 1+ or 2+, XCorr >= 2.5 for >=3+, partially/fully tryptic or protein terminal; DeltaCn <= 0.1; XCorr >= 3 for 1+ non-tryptic; XCorr >= 4 for >= 2+ non-tryptic	2011-02-01 17:53:40	2011-02-01 17:53:40
203	3	MSGF <= 1E-8, fully tryptic; peptide prophet >= 0.5	MSGF <= 1E-8, fully tryptic; peptide prophet >= 0.5	2011-03-22 22:22:49	2011-03-22 22:22:49
204	3	MSGF <= 1E-8, partially/fully tryptic; peptide prophet >= 0.5	MSGF <= 1E-8, partially/fully tryptic or protein terminal; peptide prophet >= 0.5	2011-03-22 22:23:02	2011-03-22 22:23:02
205	3	MSGF <= 1E-9, fully tryptic; peptide prophet >= 0.5	MSGF <= 1E-9, fully tryptic; peptide prophet >= 0.5	2011-03-22 22:23:09	2011-03-22 22:23:09
206	3	MSGF <= 1E-9, partially/fully tryptic; peptide prophet >= 0.5	MSGF <= 1E-9, partially/fully tryptic or protein terminal; peptide prophet >= 0.5	2011-03-22 22:23:37	2011-03-22 22:23:37
207	3	MSGF <= 1E-10, partially/fully tryptic; peptide prophet >= 0.5	MSGF <= 1E-10, partially/fully tryptic or protein terminal; peptide prophet >= 0.5	2011-03-22 22:24:59	2011-03-22 22:24:59
208	3	MSGF <= 1E-10; peptide prophet >= 0.5	MSGF <= 1E-10, no cleavage rules; peptide prophet >= 0.5	2011-03-22 22:42:08	2011-03-22 22:42:08
209	3	MSGF <= 1E-11; peptide prophet >= 0.5	MSGF <= 1E-11, no cleavage rules; peptide prophet >= 0.5	2011-03-22 22:43:06	2011-03-22 22:43:06
210	3	Josh Alfaro Custom 1, 0.1% FDR	MSGF <= 1E-12 for partial tryptic or 1E-9 for fully tryptic (regardless of DelCN2); when DelCN2 >= 0.1, then MSGF <= 1E-10 for partial tryptic or 5E-9 for fully tryptic	2011-05-05 20:16:10	2011-05-05 20:16:10
211	3	MSGF <= 1E-12; no pep prophet filter	MSGF <= 1E-12, no cleavage rules; no peptide prophet filter; MSAlign PValue < 1E-9	2011-05-06 15:11:26	2011-05-06 15:11:26
212	3	MSGF <= 1E-12; peptide prophet >= 0.5	MSGF <= 1E-12, no cleavage rules; peptide prophet >= 0.5	2011-11-14 18:22:01	2011-11-14 18:22:01
213	3	MS-GF+ FDR <= 10%	MS-GF+ FDR <= 10%, no cleavage rules	2012-01-18 12:31:42	2012-01-18 12:31:42
214	3	MS-GF+ FDR <= 5%, MSAlign < 1E-5	MS-GF+ FDR <= 5%, MSAlign PValue < 1E-5, no cleavage rules	2012-01-18 12:36:25	2012-01-18 12:36:25
215	3	MS-GF+ FDR <= 1%, MSAlign < 1E-6	MS-GF+ FDR <= 1%, MSAlign PValue < 1E-6, no cleavage rules	2012-01-18 12:36:33	2012-01-18 12:36:33
216	3	MS-GF+ FDR <= 0.5%	MS-GF+ FDR <= 0.5%, no cleavage rules	2012-01-18 12:37:48	2012-01-18 12:37:48
217	3	MSGF <= 1E-08, partially/fully tryptic; no pep prophet filter	MSGF <= 1E-08, partially/fully tryptic or protein terminal; no peptide prophet filter; MSAlign PValue < 1E-5	2012-02-27 11:59:43	2012-02-27 11:59:43
218	3	MSGF <= 1E-09, partially/fully tryptic; no pep prophet filter	MSGF <= 1E-09, partially/fully tryptic or protein terminal; no peptide prophet filter; MSAlign PValue < 1E-6	2012-02-27 11:59:49	2012-02-27 11:59:49
219	3	MSGF <= 1E-10, partially/fully tryptic; no pep prophet filter	MSGF <= 1E-10, partially/fully tryptic or protein terminal; no peptide prophet filter; MSAlign PValue < 1E-7	2012-02-27 11:59:55	2012-02-27 11:59:55
220	3	MSGF <= 1E-11; no pep prophet filter	MSGF <= 1E-11, no cleavage rules; no peptide prophet filter; MSAlign PValue < 1E-8	2012-02-27 11:59:59	2012-02-27 11:59:59
221	1	Peptide DB minima 11 with MSGF <= 1E-9 or MSGF+ QValue < 0.1	MSGF <= 1E-9; XCorr >= 1.5 for 1+ or 2+, XCorr >= 2.5 for >=3+, partially/fully tryptic or protein terminal; DeltaCn <= 0.1; XCorr >= 3 for 1+ non-tryptic; XCorr >= 4 for >= 2+ non-tryptic; Alternatively, MSGF+ QValue < 0.1	2012-04-03 10:43:59	2012-04-03 10:43:59
222	3	MSGF <= 2E-9, partially/fully tryptic; peptide prophet >= 0.5	MSGF <= 2E-9, partially/fully tryptic or protein terminal; peptide prophet >= 0.5	2012-06-29 15:14:41	2012-06-29 15:14:41
223	3	MSGF <= 1E-8; no pep prophet filter	MSGF <= 1E-8, no cleavage rules; no peptide prophet filter; MSAlign PValue < 1E-5	2012-12-05 15:07:20	2012-12-05 15:07:20
224	3	MSGF <= 1E-9; no pep prophet filter	MSGF <= 1E-9, no cleavage rules; no peptide prophet filter; MSAlign PValue < 1E-6	2012-12-05 15:07:28	2012-12-05 15:07:28
225	3	MSGF <= 1E-10; no pep prophet filter	MSGF <= 1E-10, no cleavage rules; no peptide prophet filter; MSAlign PValue < 1E-7	2012-12-05 15:07:33	2012-12-05 15:07:33
226	3	MSGF <= 1E-07, partially/fully tryptic; no pep prophet filter	MSGF <= 1E-07, partially/fully tryptic or protein terminal; no peptide prophet filter; MSAlign < 1E-4	2013-03-15 15:27:23	2013-03-15 15:27:23
227	3	MSGF <= 2E-11 for Sequest; MSGFDB FDR <= 1%, MSAlign < 1E-6	MSGF <= 2E-11 for Sequest; MSGFDB FDR <= 1%, MSAlign PValue <= 1E-6 and FDR < 1%, no cleavage rules	2013-04-03 11:40:59	2013-04-03 11:40:59
228	3	MSGF+ PepQValue <= 1%	MSGF+ PepQValue <= 1%, no cleavage rules	2013-05-07 17:23:52	2013-05-07 17:23:52
229	3	MS-GF+ FDR <= 0.1%	MS-GF+ FDR <= 0.1%, no cleavage rules	2013-10-09 14:20:06	2013-10-09 14:20:06
230	3	MS-GF+ FDR <= 0.05%	MS-GF+ FDR <= 0.05%, no cleavage rules	2013-10-09 14:20:11	2013-10-09 14:20:11
231	3	MS-GF+ FDR <= 0.01%	MS-GF+ FDR <= 0.01%, no cleavage rules	2014-03-27 19:07:21	2014-03-27 19:07:21
234	1	Peptide DB minima 12 with MSGF <= 1E-10 or MSGF+ QValue < 0.01	MSGF <= 1E-10; XCorr >= 1.5 for 1+ or 2+, XCorr >= 2.5 for >=3+, partially/fully tryptic or protein terminal; DeltaCn <= 0.1; XCorr >= 3 for 1+ non-tryptic; XCorr >= 4 for >= 2+ non-tryptic; Alternatively, MSGF+ QValue < 0.01	2014-04-03 15:04:06	2014-04-03 15:04:06
235	3	MS-GF+ FDR <= 0.1%, observation count >= 2	MS-GF+ FDR <= 0.1%, obs count >= 2, no cleavage rules	2014-04-07 15:06:38	2014-04-07 15:06:38
236	3	MS-GF+ FDR <= 0.05%, observation count >= 2	MS-GF+ FDR <= 0.05%, obs count >= 2, no cleavage rules	2014-10-27 14:55:49	2014-10-27 14:55:49
237	3	MS-GF+ FDR <= 0.01%, observation count >= 2	MS-GF+ FDR <= 0.01%, obs count >= 2, no cleavage rules	2014-10-27 15:04:49	2014-10-27 15:04:49
238	2	Minimum length 6, FDR < 5%, no cleavage rules	no XCorr or analysis count filters, any tryptic state, min length 6, FDR < 5%	2014-11-06 12:11:28	2014-11-06 12:11:28
239	3	MS-GF+ FDR <= 1%, observation count >= 3	MS-GF+ FDR <= 1%, obs count >= 3, no cleavage rules	2015-11-19 15:22:56	2015-11-19 15:22:56
240	3	MS-GF+ FDR <= 5%, observation count >= 2	MS-GF+ FDR <= 5%, obs count >= 2, no cleavage rules	2015-12-18 15:05:46	2015-12-18 15:05:46
241	3	MS-GF+ FDR <= 1%, observation count >= 2	MS-GF+ FDR <= 1%, obs count >= 2, no cleavage rules	2015-12-18 15:15:34	2015-12-18 15:15:34
242	3	MS-GF+ FDR <= 0.1% and MSGF_SpecProb <= 1E-13	MS-GF+ FDR <= 0.1%, no cleavage rules, MSGF_SpecProb <= 1E-13	2019-06-14 10:50:48	2019-06-14 10:50:48
\.


--
-- Name: t_filter_sets_filter_set_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_filter_sets_filter_set_id_seq', 242, true);


--
-- PostgreSQL database dump complete
--


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
-- Data for Name: t_seq_local_symbols_list; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_seq_local_symbols_list (local_symbol_id, local_symbol, local_symbol_comment) FROM stdin;
0	-	No modification symbol
1	*	First dynamic mod in Sequest
2	#	Second dynamic mod in Sequest
3	@	Third dynamic mod in Sequest
4	$	Fourth dynamic mod in X!Tandem; Sixth dynamic mod in Sequest v.27 (rev. 12)
5	&	Fifth dynamic mod in X!Tandem
6	!	Only used by X!Tandem
7	%	Only used by X!Tandem
8	[	Sequest uses this for peptide C-terminus dynamic mods
9	]	Sequest uses this for peptide N-terminus dynamic mods
10	^	Fourth dynamic mod in Sequest v.27 (rev. 12)
11	~	Fifth dynamic mod in Sequest v.27 (rev. 12)
12	†	Additional dynamic mod supported by PHRP
13	‡	Additional dynamic mod supported by PHRP
14	¤	Additional dynamic mod supported by PHRP
15	º	Additional dynamic mod supported by PHRP
16	`	Additional dynamic mod supported by PHRP
17	×	Additional dynamic mod supported by PHRP
18	÷	Additional dynamic mod supported by PHRP
19	ø	Additional dynamic mod supported by PHRP
20	¢	Additional dynamic mod supported by PHRP
21	=	Additional dynamic mod supported by PHRP
22	+	Additional dynamic mod supported by PHRP
23	_	Additional dynamic mod supported by PHRP
\.


--
-- PostgreSQL database dump complete
--


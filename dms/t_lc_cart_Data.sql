--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
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
-- Data for Name: t_lc_cart; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_lc_cart (cart_id, cart_name, cart_state_id, cart_description, created) FROM stdin;
40	2D_online	10	1st Dimension, HILIC,2nd Dimension, RPLC,20 online fractionation storage loops	2009-06-22 10:58:00
30	Agilent	2	Commercial Agilent 1100 capillary HPLC system outfitted with binary pumps, autosampler, degasser and solvent tray	2006-03-13 12:30:00
74	Alder	2	Being used for online digestion	2013-06-25 10:19:00
11	Andromeda	10	Single emmitter system.	2006-03-10 12:47:00
50	Aragorn	2	#2 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:G10NPB891N;nBSM2:E10NPB862N;nSM:F10NPS739M.	2010-08-23 11:45:00
78	Arwen	2	M Class Waters 2D LC	2014-09-29 12:14:00
96	Aspen	10	Infusion system composed of a PAL autosampler and an Agilent nano pump.	2017-06-16 14:50:00
57	Auto_2D_online	10	Auto version of 2D_online. Fractions from 1st D RPLC are transferred online w/ UV monitoring to 2nd D WCX-HILIC which has 4 SPEs and 4 columns.	2010-12-02 09:07:00
110	Balzac	2	Waters 1D M-Class nano-Acquity	2018-05-10 15:34:00
77	Bane	2	This is the Waters LC specifically for intact protein analysis. Configuration includes two pumps and a sample manager.	2014-01-08 13:57:00
141	Barney	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-04-25 09:56:00
135	Bart	2	Thermo Vanquish Neo system - Autosampler, Binary Pump, Column Compartment	2023-04-24 11:42:00
88	Beech	10	Direct infusion cart capable of 1200 samples per day	2016-03-12 13:34:00
90	Bilbo	2	1D Waters NanoAcquity	2016-09-26 08:37:00
130	Birch	2	Thermo/Dionex pump (800 bar) with Loading Pump .  Long armed pal. LCMSnet controlled	2022-10-04 14:11:00
62	Blue_Spruce	10	Advion Nanomate with LESA upgrade (Infusion, LC Coupling and LSEA tissue)	2012-10-23 08:45:00
93	Brandi	2	Waters H-Class UHPLC	2016-12-05 11:00:00
73	Cedar	3	LCMSnet controlled cart with Waters pumps and ISCO for loading.  Cart reconfigured in IDL to accommodate Waters Pumps	2014-08-27 16:20:00
47	Cheetah	10	4th ARRA Next Gen Platform 3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2010-06-23 17:43:00
120	Cicero	2	Thermo Dionex Ultimate 3000 with autosampler, gradient pump, loading pump, and column heating / trapping compartment	2020-01-16 13:57:00
69	Columbia	10	Eksigent System.  Used to be Andromeda	2013-04-09 11:20:00
46	Cougar	10	3rd ARRA Next Generation LC 3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2010-05-21 18:14:00
131	Crater	2	Thermo Vanquish Flex with two column compartments and a quaternary pump.	2022-10-20 10:08:00
12	Doc	10		2006-03-10 10:28:00
13	Draco	10		2006-03-14 09:07:00
146	Dragonfly	2	BSD NanoPOTS with Vanquish Neo Binary Pump	2025-03-20 17:43:49.137657
35	Eagle	10	Dedicated to IMS capability development 3/9/2010. Configured for extended separations.	2006-09-18 17:01:00
14	Earth	10		2006-03-13 07:36:00
76	Einstein	10	ISCO pumps for Direct Infusion of DOM samples	2013-09-10 10:27:00
94	Elm	2	Thermo/Dionex pump (800 bar) with an ISCO on the low boy.  Short armed pal. LCMSnet controlled.  Small form factor cart, desktop computer	2017-03-03 08:19:00
129	Evosep01	2	Online Desalting LC	2022-08-31 07:08:00
127	Evosep02	2	Online Desalting LC	2022-04-05 05:39:00
27	Falcon	10	LC ISCO Formic, 4 column 10k constant pressure system. The Flagship of our LC fleet.	2006-05-22 08:36:00
116	Fiji	2	Agilent 1260 Infinity II high flow system, Sampler DEAGQ00605, Pump DEAE800647, Column Heater (1100 Series) DE11123368	2019-08-14 14:11:00
85	Fir	2	Smaller cart Agilent pumps from Cougar,	2015-05-06 17:11:00
15	Firefly	2	nanoPOTS autosampler	2006-03-10 16:14:00
53	Frodo	2	#5 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:F10NPB868N;nBSM2:F10NPB869N;nSM:F10NPS743M.	2010-09-14 16:53:00
107	GCQE01	2	Thermo GC Q-Exactive	2017-11-21 14:17:00
49	Gandalf	2	#4 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:F10NPB865N;nBSM2:F10NPB866N;nSM:F10NPS742M.	2010-08-23 11:44:00
52	Gimli	2	#1 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:E10NPB859N;nSM:L10NPS876M.	2010-08-23 11:30:00
123	Glacier	2	Thermo Vanquish System running Thermo SII	2020-10-13 16:17:00
16	Griffin	10		2006-03-20 07:30:00
122	Guam	10	Agilent 1290 Infinity ALS (Autosampler) Model: G1329A Serial: DE64776208, Agilent 1200 Bin Pump Model: G1312A Serial: DE63060488	2020-10-07 14:18:00
48	Harrier	10	4 Column Phospho Cart	2010-09-23 13:51:00
28	Hawk	10		2006-04-18 11:06:00
137	Holly	2	Thermo/Dionex pump (800 bar) with Loading Pump. Long armed pal. LCMSnet controlled. EMSL owned.	2023-08-23 13:27:00
138	Homer	2	Thermo Vanquish Neo system - Autosampler, Binary Pump, Column Compartment	2023-12-01 16:45:00
86	Hoopty	2	S&S industries HTP cart for multiple and optimal infusion experiments	2015-08-20 14:00:00
64	Iris	10	Manual LC in BSF 1208 for sample prep use	2012-12-10 15:56:00
97	IronMan	2	Dionex Ultimate 3000 nano RSLC for metallomics	2017-08-30 09:18:00
60	Jaguar	10	3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2011-04-13 09:55:00
147	Jolene	2	Waters high flow LC, was in 1215 on benchtop with old instrument, now in use for lipid and metabolite work.	2025-06-11 13:19:25.82875
109	Juniper	10	Thermo/Dionex pump (800 bar). Long armed pal. LCMSnet controlled. Small form factor cart, laptop computer	2018-03-02 17:53:00
36	Kestrel	10	20,000 psi mixers	2008-03-18 16:40:00
82	Kite	10	Formerly called IMAC.  Renamed to reflect style of cart.  Auto version of 2D_online. Fractions from 1st D RPLC are transferred online w/ UV monitoring to 2nd D WCX-HILIC which has 4 SPEs and 4 columns.	2015-01-11 11:29:00
121	Kristin	2	Agilent 1290 LC system	2020-03-18 12:48:00
119	Larch	2	Smaller cart with short armed PAL capacity for 4 valves	2019-12-05 13:16:00
51	Legolas	3	#3 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:E10NPB863N;nSM:F10NPS741M.	2010-08-23 11:44:00
65	Leopard	10	New, used to be Roc	2013-01-15 11:56:00
44	Lion	10	Second Dimension HILIC cart.  Next Generation LC 3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2010-10-21 11:58:00
134	Lisa	2	Thermo Vanquish Neo system - Autosampler, Binary Pump, Column Compartment	2023-04-24 11:42:00
89	Lola	2	Waters H-Class UHPLC	2016-08-30 09:27:00
45	Lynx	3	2nd ARRA Next-Gen 3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2010-04-16 22:17:00
95	Magnolia	2	Micro-flow infusion cart	2017-03-15 12:15:00
136	Maple	2	Thermo/Dionex pump (800 bar) with Loading Pump. Long armed pal. LCMSnet controlled. EMSL owned.	2023-08-23 13:27:00
139	Marge	2	Thermo Vanquish Neo system - Autosampler, Binary Pump, Column Compartment	2024-01-12 12:06:00
42	Mazama	10	Agilent Cart	2009-09-29 16:10:00
72	Merry	2	Waters 2DLC commercial system	2013-03-01 09:15:00
66	Methow	10	Eksigent pumps. Used to be Phoenix	2013-01-15 18:09:00
142	Moe	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-04-25 09:56:00
143	Monty	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-05-30 09:55:00
118	Mosquito	2	Nano-Pots auto-sampler	2019-11-13 14:31:00
111	NanoPots-3	2	Thermo/Dionex pump (800 bar). Manual injection.	2018-08-24 09:45:00
75	Nautilus	10	The Nautilus LC cart is a 1200 series Agilent Nanopump and Auto sampler.	2013-08-13 15:58:00
140	Ned	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-03-01 14:04:00
2	No_Cart	2	An ad hoc or non cart based LC apparatus was used	2006-03-10 10:34:00
79	Oak	2	Thermo/Dionex pump (800 bar) with an ISCO on the low boy.  Short armed pal. LCMSnet controlled	2014-12-01 09:33:00
132	Olympic	2	Thermo Vanquish Flex with two column compartments and a quaternary pump.	2022-10-21 14:30:00
37	Osprey	10	15 Minute Separation	2009-06-16 15:35:00
34	Owl	10		2006-09-06 08:14:00
144	Patty	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-07-01 11:37:00
17	Pegasus	10	Fast Separation	2006-06-20 11:52:00
18	Phoenix	10	Installed Eksigent pumps November 2012.	2006-03-13 15:04:00
63	Pippin	2	NanoAcquity cart acquired from Tox-Refurbished for Global Lipidomics. Serial numbers nBSM:M08NPB528N;nBSM2:A09NPB545N;nSM:A09NPS508M.	2012-11-28 10:53:00
33	Pluto	10	Manual LC cart	2006-04-05 21:32:00
58	Polaroid	2	Constant Flow Waters Nano-Acquity (1d only). Serial numbers nBSM:M10NPB053N;nSM:A11NPS920M.	2011-02-19 12:28:00
81	Precious	2	Waters 1D M-Class nano-Acquity	2015-03-27 14:59:00
31	Protein_RP	10	This is a manual LC system used for intact protein separations. Comprised of 2 10k-psi ISCO pumps and controller, 10k-psi (1/16" fittings) valves with back-side pressure sealing. Valve configurations; 6 port injection valve, 4 port mobile phase select valve, and 4 port column select valve. Home-made mixer for gradient formation. On/off valve for selecting between mixer purge and splitter column.	2006-03-10 17:37:00
115	Rage	2	Waters 1D M-Class nano-Acquity	2019-04-22 16:09:00
80	Rainier	2	Thermo Vanquish System	2015-01-29 17:41:00
87	RapidFire365-01	2	Agilent RapidFire 365 SPE	2015-11-12 09:48:00
19	Raptor	10		2007-06-08 14:17:00
114	Remus	2	Thermo Dionex Ultimate 3000 with autosampler, gradient pump, loading pump, and column heating / trapping compartment	2019-01-29 08:56:00
148	Rio	2	Thermo Vanquish Duo Horizon. With two binary pumps, two column compartments and two injectors. High flow.	2025-10-11 20:02:47.003501
20	Roc	10	Metabolomics Cart	2006-03-10 09:52:00
67	Rogue	2	Used to be Lion, changed naming convention	2013-01-18 11:14:00
113	Romulus	2	Thermo Dionex Ultimate 3000 with autosampler, gradient pump, loading pump, and column heating / trapping compartment	2019-01-29 08:55:00
125	Roxanne	2	Waters High-Flow H-class+ Sample Manager-FTN and Quaternary Solvent Manager	2020-11-16 16:45:00
39	SATURN	10	manual single column LC cart w/ SPE	2009-05-13 13:15:00
61	Samwise	2	NanoAcquity cart acquired from Tox-Refurbished for Global Lipidomics. Serial numbers nBSM:M08NPB528N;nBSM2:A09NPB545N;nSM:A09NPS508M.	2012-08-04 08:46:00
54	Sauron	2	#6 2D Waters NanoAcquity LC, easy conversion to 1D cart.  Serial numbers nBSM:H10NPB926N;nBSM2:F10NPB872N;nSM:F10NPS745M.	2010-08-23 11:25:00
145	Selma	2	Thermo Vanquish Neo system - Autosampler and Binary Pump	2024-07-01 11:38:00
70	Smeagol	2	#1 2D Waters NanoAcquity LC 1D cart.  Serial numbers nBSM:L12NPB418N;nSM:F12NPS111M	2013-02-21 08:42:00
68	Snake	10	Used to be Eagle renamed to reflect Eksigent	2013-01-21 06:04:00
29	Sphinx	10		2006-03-10 17:34:00
124	Stretch	2	Dionex Ultimate 3000 RSLCnano System	2020-10-20 17:34:00
117	Tahiti	2	Agilent 1260 Infinity II, Vialsampler G7129C DEAGQ01116, Bin Pump G7112B DEAB00808, Column Heater DEAED14113	2019-08-14 16:34:00
41	Tambora	10	Agilent cart	2009-10-01 14:24:00
133	Teton	2	Thermo Vanquish Neo system - Autosampler, Binary Pump, Column Compartment	2022-10-21 14:32:00
43	Tiger	2	First ARRA NexGen L 3 Agilent Pumps (2 nano and 1 cap) 8 Two Position Valves and 4 Multi-Position valves, PAL	2010-03-16 12:38:00
126	Titus	2	Thermo Dionex Ultimate 3000 with autosampler, gradient pump, loading pump, and column heating / trapping compartment	2021-09-13 13:25:00
128	Tonga	2	Formerly the NMR fractionation LC.  Agilent 1290 Infinity II Pump, Autosampler, Column Heater, UV detector and Fraction collector	2022-06-10 10:58:00
38	VENUS	10	metal-free, up to 5k psi	2009-02-12 13:00:00
108	ValcoNanoPump	2	This is manual testing configuration for pump from Valco Feb 2018	2018-02-22 13:12:00
84	Wally	10	Waters M-Class 2D nano-Acquity	2016-09-29 10:28:00
98	Yew	10		2017-09-28 12:52:00
32	Yufeng_20k-psi	10	This is an R&D LC system used primarily by Yufeng Shen and is modified routinely for different applications. Revision history will NOT be maintained for this LC system.	2006-05-01 09:09:00
1	unknown	1	Not a valid cart	\N
\.


--
-- Name: t_lc_cart_cart_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_lc_cart_cart_id_seq', 148, true);


--
-- PostgreSQL database dump complete
--


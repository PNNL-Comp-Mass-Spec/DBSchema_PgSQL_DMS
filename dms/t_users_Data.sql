--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Data for Name: t_users; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_users (user_id, username, name, hid, status, email, domain, payroll, active, update, created, comment, last_affected) FROM stdin;
3332	ABNE190	Abney, Kristopher	H3992190	Inactive	kristopher.abney@pnnl.gov	PNL		N	N	2018-12-05 14:55:51		2019-07-08 00:11:10
3324	ACOS408	Acosta, Fransen M	H8972680	Active	fransen.acosta@pnnl.gov	PNL		Y	Y	2018-11-05 10:07:28		2023-03-06 00:11:15
2022	D3G373	Adams, Daniel R	H0097026	Inactive	dan@pnl.gov	PNL	3G373	N	N	2002-01-01 00:00:00		\N
2048	D3K855	Adkins, Josh N	H2188174	Active	Joshua.Adkins@pnnl.gov	PNL	3K855	Y	Y	2001-09-14 00:00:00		2020-02-21 00:11:11
2306	D3X771	Agarwal, Khushbu	H9361223	Active	Khushbu.Agarwal@pnnl.gov	PNL	3X771	Y	Y	2009-07-01 00:00:00		2009-07-01 00:00:00
3648	AGGA719	Aggarwal, Tushar	H7561069	Active	tushar.aggarwal@pnnl.gov	PNL	\N	Y	Y	2025-04-01 09:07:40.39794		2025-04-02 00:12:09.752002
2266	D3X360	Zhou, Jianying	H4573535	Inactive			3X360	N	N	2008-07-01 00:00:00		\N
2241	D3P800	Agron, Ilya AS	H4239824	Inactive			3P800	N	N	2007-02-03 00:00:00		\N
3295	AHKA001	Ahkami, Amir	H2260345	Active	amir.ahkami@pnnl.gov	PNL		Y	Y	2018-05-15 09:55:22		2018-05-16 00:11:11
2062	D3L047	Ahn, Seonghee	H2753951	Inactive			3L047	N	N	2002-05-03 00:00:00		\N
2070	D3L031	Ahram, Mamoun	H1552607	Inactive			3L031	N	N	2002-06-18 00:00:00		\N
3550	ALFA616	Alfaro, Trinidad D	H0527057	Active	trinidad.alfaro@pnnl.gov	PNL	\N	Y	Y	2023-05-11 11:49:43		2023-05-12 00:11:14
3560	ALLE366	Allen, Kyrra	H7307771	Inactive	kyrra.allen@pnnl.gov	PNL	\N	N	N	2023-06-13 08:46:36		2023-07-31 00:11:15
3620	ALTA462	Altavilla, Dex H	H3276462	Active	dex.altavilla@pnnl.gov	PNL	\N	Y	Y	2024-05-22 16:09:15		2024-05-23 00:11:15
3558	ALTA731	Altavilla, Dex H (old)	H3276462_x	Obsolete	dex.altavilla@pnnl.gov	PNL	\N	N	N	2023-06-09 10:55:58		2024-05-21 00:11:15
2001	H5603809	Alving, Kim	H5603809	Inactive	\N	\N	\N	N	N	2000-09-12 00:00:00		\N
2282	D3X700	Zhang, Harry	H3194994	Inactive			3X700	N	N	2009-01-01 00:00:00		\N
4	D3C492	Anderson, David J	H0037152	Inactive			3C492	N	N	2000-05-17 00:00:00		\N
2485	ANDE183	Anderson, Gordon A	H0091183	Inactive	gordo@pnnl.gov	\N	39912	N	N	2014-03-10 12:44:27	\N	2014-03-11 00:11:12
15	D39912	Anderson, Gordon A (retired)	H0091183	Inactive	gordo@pnnl.gov	PNL	39912	N	N	2001-03-01 00:00:00	\N	2016-05-14 17:23:53
2389	D3X989	Anderson, Lindsey N	H8264253	Active	Lindsey.Anderson@pnnl.gov	PNL	3X989	Y	Y	2011-09-07 13:33:40		2016-12-04 00:11:18
3661	DETT541	Dettmann, Makena A	H8638464	Active	makena.dettmann@pnnl.gov	PNL	\N	Y	Y	2025-07-09 15:24:41.221153		2025-07-10 00:11:38.72624
2002	D3K856	Angell, Nicolas H	H1002228	Inactive			3K856	N	N	2001-05-04 00:00:00		\N
2230	D3P636	Ansong, Charles K	H6673865	Inactive	charles.ansong@pnnl.gov	PNL	3P636	N	N	2007-02-22 00:00:00		2020-10-26 00:11:10
3366	ANUB229	., Anubhav	H5715189	Inactive	anubhav@pnnl.gov	PNL		N	N	2019-09-03 13:26:56		2020-04-16 00:11:11
2293	D3X975	Jones, Nathan J	H9960942	Inactive			3X975	N	N	2009-04-01 00:00:00		\N
3662	MAHL006	Mahlich, Yannick	H9211006	Active	yannick.mahlich@pnnl.gov	PNL	\N	Y	Y	2025-07-11 16:33:27.195255		2025-07-12 00:11:40.850254
3223	ATTA556	Attah, Kwame	H9079560	Active	kwame.attah@pnnl.gov	PNL		Y	Y	2016-09-15 11:34:33		2019-09-06 00:11:11
20	D3K974	Auberry, Deanna	H7754753	Active	Deanna.Auberry@pnnl.gov	PNL	3K974	Y	Y	2000-11-06 00:00:00	\N	2020-05-01 00:11:10
3612	AUFR751	Aufrecht, Jayde A	H4190310	Active	jayde.aufrecht@pnnl.gov	PNL	\N	Y	Y	2024-04-04 05:43:55		2024-04-05 00:11:14
2115	H09090911	AutoUser	H09090911	Inactive	\N	\N	\N	N	N	2004-06-18 00:00:00	\N	\N
3403	BADE228	Bade, Jessica L	H2593091	Active	jessica.bade@pnnl.gov	PNL		Y	Y	2020-04-02 10:37:59		2020-04-03 00:11:11
2561	D3K858	Bailey, Vanessa L	H3954588	Active	Vanessa.Bailey@pnnl.gov	PNL	3K858	Y	Y	2015-08-13 11:22:11		2016-05-14 17:23:53
3663	OGBU397	Ogbu, Chinemerem	H6060397	Active	chinemerem.ogbu@pnnl.gov	PNL	\N	Y	Y	2025-07-14 16:19:41.42732		2025-07-15 00:11:44.055272
2207	D3P347	Baker, Erin M	H7138882	Inactive	erin.baker@pnnl.gov	PNL	3P347	N	N	2006-07-01 00:00:00		\N
2491	BAKE113	Baker, Nathan A	H6671887	Inactive	Nathan.Baker@pnnl.gov	PNL	\N	N	N	2014-05-21 05:43:51		2022-10-15 00:11:13
2141	D3M189	Baker, Scott E	H4156076	Active	scott.baker@pnnl.gov	PNL	3M189	Y	Y	2004-09-13 00:00:00		\N
3370	BALA918	Balasubramanian, Vimal Kumar	H2225884	Active	vimalkumar.balasubramanian@pnnl.gov	PNL		Y	Y	2019-09-12 19:22:11		2019-09-13 00:11:11
2294	D3Y013	Alfaro, Joshua F	H0035425	Inactive			3Y013	N	N	2009-04-01 00:00:00		\N
3358	ABDA360	Abdali, Shadan H	H0376732	Inactive	shadan.abdali@pnnl.gov	PNL		N	N	2019-06-26 15:16:28		2021-03-26 00:11:13
3618	ARRA976	Arrambidez, Margo	H5127976	Active	margarita.arrambidez@pnnl.gov	PNL	\N	N	Y	2024-05-21 07:57:31		2025-05-01 00:11:41.025483
3664	BOCI744	Bociu, Ioana	H8548360	Active	ioana.bociu@pnnl.gov	PNL	\N	Y	Y	2025-08-20 10:50:57.843052		2025-08-21 00:11:23.389338
3665	VOOS938	Voos, Kayleigh	H2489938	Active	kayleigh.voos@pnnl.gov	PNL	\N	Y	Y	2025-09-09 11:21:26.632092		2025-09-10 00:11:45.052796
3666	CLIB001	Cliber, Kay	H1177207	Active	kay.cliber@pnnl.gov	PNL	\N	Y	Y	2025-09-10 16:36:57.84659		2025-09-11 00:11:46.253575
2434	ANDE445	Anderton, Christopher R	H9772836	Active	Christopher.Anderton@pnnl.gov	PNL	\N	Y	Y	2013-01-24 14:00:32		2025-12-24 00:11:56.579539
2003	D3K857	Auberry, Kenneth	H1512192	Inactive	Kenneth.Auberry@pnnl.gov	PNL	3K857	N	N	2002-03-02 00:00:00		2025-11-10 00:11:44.526489
3660	RODG011	Rodgers, Jordan	H0287011	Active	jordan.rodgers@pnnl.gov	PNL	\N	N	Y	2025-06-30 19:56:29.399197		2026-02-01 00:11:56.569974
3605	BARG513	Bargar, John R	H2720070	Active	john.bargar@pnnl.gov	PNL	\N	Y	Y	2024-01-16 17:20:34		2024-01-17 00:11:14
2121	D3L280	Barry, Richard C	H9317480	Inactive			3L280	N	N	2003-08-11 00:00:00		\N
2529	BATE833	Batek, Josef	H0172833	Inactive	\N	\N	\N	N	N	2014-11-05 09:39:16		2014-11-05 09:39:16
3668	KILG843	Kilgore, Uriah J	H4467193	Active	uriah.kilgore@pnnl.gov	PNL	3X843	Y	Y	2025-09-30 05:43:38.419798		2025-10-01 00:12:07.076189
2233	DBAXTER	Baxter, Douglas	H7174324	Active	douglas.baxter@pnnl.gov	PNL	3M134	N	Y	2007-03-01 00:00:00		2025-09-04 00:11:38.700571
2460	D3L274	Beliaev, Alex S	H4581050	Active	alex.beliaev@pnnl.gov	PNL	3L274	Y	Y	2013-06-05 15:32:34		2013-06-06 00:11:11
3253	BELL555	Bell, Sheryl L	H0554555	Active	sheryl.bell@pnnl.gov	PNL	\N	Y	Y	2017-05-16 19:17:05	\N	2017-11-14 00:11:11
2004	D3K044	Belov, Mikhail E	H7734306	Inactive			3K044	N	N	2000-05-31 00:00:00	\N	\N
2264	D3X050	Brown, Joseph N	H8280448	Inactive	Joseph.Brown@pnnl.gov	PNL	3X050	N	N	2008-07-01 00:00:00	\N	2013-10-31 00:11:10
3470	BERG465	Berger, Madelyn R	H0862227	Active	madelyn.berger@pnnl.gov	PNL		Y	Y	2021-09-09 11:45:05		2021-09-10 00:11:12
2005	H1784722	Berger, Scott	H1784722	Inactive	\N	\N	\N	N	N	2001-01-01 00:00:00		\N
3288	BHAT570	Bhattacharjee, Arunima	H9514344	Active	arunimab@pnnl.gov	PNL	\N	Y	Y	2018-03-20 13:49:19		2018-03-21 00:11:10
3206	BILB280	Bilbao, Aivett	H2521590	Active	aivett.bilbao@pnnl.gov	PNL	\N	Y	Y	2016-06-10 16:50:05		2022-11-18 00:11:13
3644	BINF571	Binfet, Hannah	H9739420	Active	hannah.binfet@pnnl.gov	PNL	\N	Y	Y	2025-03-03 14:12:52.928465		2025-03-04 00:11:38.911938
3667	BLAC926	Black, Grace	H8538926	Active	grace.black@pnnl.gov	PNL	\N	Y	Y	2025-09-16 16:32:01.209271		2025-09-17 00:11:52.675208
3290	BIRE798	Birer, Caroline	H3225798	Inactive		PNL		N	N	2018-03-29 10:28:55		2018-03-30 00:11:11
2041	D3K861	Blonder, Josip	H3157903	Inactive	\N	\N	3K861	N	N	2001-05-04 00:00:00		\N
2165	D3M651	Blonder, Niksa	H7769038	Inactive			3M651	N	N	2005-01-01 00:00:00		\N
2418	BLOO251	Bloodsworth, Kent J	H1682217	Active	Kent.Bloodsworth@pnnl.gov	PNL	\N	Y	Y	2012-08-09 11:31:12		2012-08-09 11:31:12
2295	D3X206	Jin, Hongjun	H9174602	Inactive			3X206	N	N	2009-04-01 00:00:00		\N
2313	D3Y083	Angel, Thomas E	H4273704	Inactive			3Y083	N	N	2009-08-01 00:00:00		2009-08-01 00:00:00
3394	BODN211	Bodnar, Wendee M	H5907594	Active	wendee.bodnar@pnnl.gov	PNL		Y	Y	2020-02-04 10:10:31		2020-02-05 00:11:10
2055	H1045744	Bogdanov, Bogdan	H1045744	Inactive			\N	N	N	2001-12-27 00:00:00		\N
3521	BOHU794	Bohutskyi, Pavlo	H3122369	Active	pavlo.bohutskyi@pnnl.gov	PNL	\N	Y	Y	2022-09-07 05:42:59		2022-09-08 00:11:13
2324	D3X958	Aryal, Uma K	H8340410	Inactive			3X958	N	N	2009-10-13 11:43:20		2009-10-13 11:43:20
3217	BOIT379	Boiteau, Rene M (old)	H8466795_x	Obsolete	rene.boiteau@pnnl.gov	PNL		N	N	2016-08-02 13:11:24		2018-09-15 00:11:11
3372	BOIT511	Boiteau, Rene (old)	H8466795_x	Obsolete	rene.boiteau@pnnl.gov	PNL	\N	N	N	2019-09-20 10:38:15	This username was active from 2019-09-20 through 2020-01-16	2020-01-17 00:11:11
2076	D3K862	Bollinger, Nikki	H0015760	Inactive			3K862	N	N	2002-07-03 00:00:00		\N
2327	D3J024	Angel, Linda K	H0044228	Inactive			3J024	N	N	2009-10-20 17:41:15		2009-10-20 17:41:15
2006	H8384045	Borisov, Oleg	H8384045	Inactive	\N	\N	\N	N	N	2001-01-01 00:00:00		\N
3362	D3Y093	Bowden, Mark E	H2691669	Active	Mark.Bowden@pnnl.gov	PNL	3Y093	Y	Y	2019-08-06 05:43:00		2019-08-07 00:11:11
2334	KARP554	Karpievitch, Yuliya V	H2039905	Inactive			3Y554	N	N	2010-01-12 11:15:14		2013-06-07 14:16:32
2336	D3Y520	Anderson, Brian J	H3519877	Inactive	Brian.Anderson@pnnl.gov	PNL	3Y520	N	N	2010-01-19 13:18:28		2016-05-14 17:23:53
3271	BRAM489	Bramer, Lisa M	H6641475	Active	Lisa.Bramer@pnnl.gov	PNL	\N	Y	Y	2017-10-30 11:26:44		2017-10-31 00:11:11
2349	ALDR699	Aldrich, Josh	H0785026	Inactive	Joshua.Aldrich@pnnl.gov	PNL	3Y699	N	N	2010-03-18 13:39:32	\N	2016-05-14 17:23:53
3371	BRED247	Bredeweg, Erin L	H1551237	Active	erin.bredeweg@pnnl.gov	PNL	\N	Y	Y	2019-09-17 05:42:58		2019-09-18 00:11:11
3245	BRIS469	Brislawn, Colin J	H2017300	Inactive	colin.brislawn@pnnl.gov	PNL	\N	N	N	2017-02-24 14:46:52		2019-07-29 00:11:11
2392	dmlb2000	Brown, David ML	H8976316	Active	david.brown@pnnl.gov	PNL	3P791	Y	Y	2011-11-08 14:31:39	\N	2013-06-07 14:16:32
2411	CHEN227	Chen, Freddie	H5343213	Inactive	Frederick.Chen@pnnl.gov	PNL	\N	N	N	2012-06-12 17:04:00	Frederick Z. Chen	2016-05-14 17:23:53
2398	BROW950	Brown, Roslyn N	H5546950	Inactive			3X414	N	N	2012-01-06 17:20:10	371-7629	2013-06-07 14:16:32
2271	D3X414	Brown, Roslyn N (old)	H5546950_x	Obsolete			3X414_x	N	N	2008-08-01 00:00:00		\N
2414	KIMS336	Kim, Sangtae	H1520123	Inactive	Sangtae.Kim@pnnl.gov	PNL	\N	N	N	2012-07-09 17:00:26	\N	2016-05-14 17:23:53
2417	HEJI354	He, Jintang	H9187834	Inactive	Jintang.He@pnnl.gov	PNL	\N	N	N	2012-08-08 14:13:21		2016-05-14 17:23:53
2421	ZHAN371	Zhang, Zhaorui	H7379394	Inactive	Zhaorui.Zhang@pnnl.gov	PNL	\N	N	N	2012-09-17 13:58:56	\N	2014-01-31 00:11:11
2077	H0021670	Bruemmer, Megan	H0021670	Inactive			\N	N	N	2002-07-12 00:00:00		\N
2311	BURN764	Burnet, Meagan C	H5443441	Active	Meagan.Burnet@pnnl.gov	PNL	3X764	Y	Y	2009-08-01 00:00:00		2013-08-22 00:11:11
2283	D3X786	Burnum-Johnson, Kristin E	H0096302	Active	kristin.burnum-johnson@pnnl.gov	PNL	3X786	Y	Y	2009-01-01 00:00:00	\N	\N
2057	D3L014	Buschbach, Michael A	H0094476	Inactive	Michael.Buschbach@pnl.gov	PNL	3L014	N	N	2002-08-01 00:00:00		\N
3390	BUTN259	Butner, Ryan S	H1893643	Active	ryan.butner@pnnl.gov	PNL	3X259	Y	Y	2020-01-06 13:52:00		2020-01-07 00:11:10
2547	D3X259	Butner, Ryan S (old)	H1893643_x	Obsolete	ryan.butner@pnnl.gov	PNL	3X259	N	N	2015-04-10 10:20:13		2020-01-06 00:11:11
2223	D3P688	Chowdhury, Saiful M	H7428777	Inactive			3P688	N	N	2006-10-05 00:00:00		\N
3635	CALL458	Call, Daniel	H3434458	Active	daniel.call@pnnl.gov	PNL	\N	Y	Y	2024-11-19 13:49:47.726638		2024-11-20 00:11:28.560007
2127	D3M120	Callister, Stephen J	H3668562	Active	stephen.callister@pnnl.gov	PNL	3M120	Y	Y	2003-10-30 00:00:00		\N
2232	D35222	Campbell, James A	H0018992	Inactive	james.campbell@pnnl.gov	PNL	35222	N	N	2007-03-01 00:00:00		2013-04-02 00:11:10
2280	D3A743	Champion, Boyd L	H0010706	Inactive			3A743	N	N	2009-01-01 00:00:00		\N
2037	D3K865	Camp II, David G	H0036838	Inactive	Dave.Camp@pnnl.gov	PNL	3K865	N	N	2001-03-01 00:00:00	\N	2016-05-14 17:23:53
2007	D3K137	Cannon, Bill	H8711509	Active	William.Cannon@pnnl.gov	PNL	3K137	Y	Y	2001-11-01 00:00:00		\N
2456	CANT215	Cantrell, Kirk J	H0094865	Inactive	kirk.cantrell@pnnl.gov	PNL	3G215	N	N	2013-06-05 15:32:34	Renamed from D3G215 to CANT215 in May 2017	2020-06-01 00:11:11
2445	CARA532	Carado, Anthony J	H6487813	Active	anthony.carado@pnnl.gov	PNL	3Y532	Y	Y	2013-04-23 09:33:27	\N	2016-05-14 17:23:53
3374	CARN612	Carnley, Yessica L	H3036943	Inactive	yessica.carnley@pnnl.gov	PNL		N	N	2019-10-09 11:47:12		2021-08-06 00:11:13
3449	CAVA382	Cavagnaro, Rob	H7248806	Active	robert.cavagnaro@pnnl.gov	PNL	\N	Y	Y	2021-04-08 05:43:00		2021-04-09 00:11:13
2292	D3X939	Chauvigne-Hines, Lacie M	H4675176	Inactive			3X939	N	N	2009-04-10 00:00:00		2013-04-03 00:11:11
2531	CHAC883	Chacon, Stephany	H8680883	Inactive	stephany.chacon@pnnl.gov	PNL	\N	N	N	2014-11-14 14:02:47	\N	2016-12-03 00:11:11
2333	CAOL388	Cao, Li	H0796783	Inactive			3Y388	N	N	2010-01-04 12:03:47	\N	2013-06-07 14:16:32
2375	CHAM566	Chambers, Justin L	H0080733	Inactive	Justin.Chambers@pnnl.gov	PNL	\N	N	N	2011-01-24 13:50:11	\N	2011-01-24 13:50:11
3669	NIUS206	Niu, Sining	H0317206	Active	sining.niu@pnnl.gov	PNL	\N	Y	Y	2025-10-03 11:41:43.89349		2025-10-04 00:11:37.930827
3405	CHAN898	Chang, Christine H	H2015898	Active	christine.chang@pnnl.gov	PNL		Y	Y	2020-04-02 13:42:33		2020-04-03 00:11:11
2263	D3P302	Chatterton, Jack	H6300375	Inactive			3P302	N	N	2008-06-15 00:00:00		\N
3674	HAND527	Han, 	H1439527	Active	hdh03@snu.ac.kr	PNL	\N	Y	Y	2025-12-10 14:00:56.089028		2025-12-11 00:11:56.582554
3354	CHEN881	Chen, Chunlong	H9946904	Active	Chunlong.Chen@pnnl.gov	PNL	\N	Y	Y	2019-05-15 05:42:59		2019-05-16 00:11:10
3670	MOKA177	Mo, Kai-For	H0930308	Active	Kai-For.Mo@pnnl.gov	PNL	\N	Y	Y	2025-10-06 15:03:53.923456		2025-10-07 00:11:37.934823
2216	D3P558	Chen, Haobo	H0264926	Inactive	\N	\N	3P558	N	N	2006-07-19 00:00:00		\N
2365	BYER452	Byers, Kristopher R	H0990507	Inactive			\N	N	N	2010-10-01 13:31:33		2010-10-01 13:31:33
3522	CANA323	Canales, Kiersten	H3660865	Active	kiersten.canales@pnnl.gov	PNL	\N	N	Y	2022-09-28 12:34:40		2025-10-09 00:11:37.934232
3466	CHEU757	Cheung, Margaret S	H1009700	Active	margaret.cheung-wyker@pnnl.gov	PNL	\N	Y	Y	2021-08-04 05:42:59		2021-08-05 00:11:13
3315	CHIN665	China, Swarup	H4852744	Active	swarup.china@pnnl.gov	PNL		Y	Y	2018-08-17 11:08:37		2018-08-18 00:11:10
2384	CHAN806	Chang, Ching-Yun	H1137756	Inactive			\N	N	N	2011-06-08 11:43:58		2011-06-08 11:43:58
2189	D3P240	Chornoguz, Olesya Y	H0541319	Inactive	olesya.chornoguz@pnl.gov	PNL	3P240	N	N	2005-12-15 00:00:00		\N
3239	CHOU581	Chouinard, Chris	H4167855	Inactive	christopher.chouinard@pnnl.gov	PNL		N	N	2016-12-19 11:04:25		2018-06-16 00:11:11
2401	CAST598	Castillo, Savanna R	H1448524	Inactive			3Y598	N	N	2012-02-29 20:03:33		2013-06-07 14:16:32
3671	CADY630	Cady, Gwen	H6083630	Active	gwendelen.cady@pnnl.gov	PNL	\N	Y	Y	2025-10-20 15:34:52.209294		2025-10-21 00:11:37.924095
3673	LABO524	LaBonte, Sandy	H4614524	Active	sandra.labonte@pnnl.gov	PNL	\N	Y	Y	2025-12-08 16:12:47.247138		2025-12-09 00:11:56.576165
3677	WANG571	Wang, Huamin	H7644190	Active	Huamin.Wang@pnnl.gov	PNL	\N	Y	Y	2026-03-05 05:43:21.162639		2026-03-06 00:11:49.192903
3675	eustrim	EMSL EUS TRIM Connector	H0000000	Active		\N	\N	Y	N	2026-01-13 10:13:45.561288	Service account managed by Nathan Tenney and used by L7 to access DMS	2026-01-13 10:13:45.561288
3676	chim847	Chimeo, Rocio	H7746847	Active	rocio.chimeo@pnnl.gov	PNL	\N	Y	Y	2026-02-10 16:10:11.487524		2026-02-11 00:11:49.178996
3678	HARR010	Harrison, Andrea	H0663199	Active	andrea.harrison@pnnl.gov	PNL	\N	Y	Y	2026-03-12 14:26:46.548452		2026-03-13 00:11:49.195275
3679	D3H027	Schaef, Herbert T	H0007063	Active	todd.schaef@pnnl.gov	PNL	3H027	Y	Y	2026-03-14 05:43:21.150555		2026-03-15 00:11:49.157752
3531	D3H588	Chrisler, William B	H0015865	Active	william.chrisler@pnnl.gov	PNL	3H588	Y	Y	2022-11-15 11:15:59		2022-11-16 00:11:13
3412	CHUF192	Chu, Fanny	H7865024	Active	fanny.chu@pnnl.gov	PNL		Y	Y	2020-06-10 21:53:03		2020-06-11 00:11:10
2343	CHUR637	Chu, Rosey	H8460393	Active	Rosalie.Chu@pnnl.gov	PNL	3Y637	Y	Y	2010-03-03 08:51:34		2013-06-07 14:16:32
2487	CLAI036	Clair, Geremy C	H9591818	Active	geremy.clair@pnnl.gov	PNL	\N	Y	Y	2014-04-10 17:19:24		2024-01-19 00:11:14
16	D3J408	Clark, Dave	H0023610	Inactive			3J408	N	N	2001-04-20 00:00:00		\N
2150	D3G909	Clauss, Therese RW	H0005162	Inactive	thereserw.clauss@pnnl.gov	PNL	3G909	N	N	2004-05-25 00:00:00	DMS_Instrument_Operation, DMS_Instrument_Tracking, DMS_Ops_Administration	2018-04-13 00:11:11
2257	D3X075	Cleary, John P	H4212148	Inactive			3X075	N	N	2008-02-08 00:00:00		\N
3348	CLEN300	Clendinen, Che S	H3701636	Active	chaevien.clendinen@pnnl.gov	PNL		Y	Y	2019-04-04 14:16:00		2019-04-05 00:11:11
2128	D39224	Daly, Don S	H0081677	Inactive	don.daly@pnnl.gov	PNL	39224	N	N	2004-01-01 00:00:00		2016-10-02 00:11:11
3227	CLOW969	Clowers, Brian	H0888383	Inactive	Brian.Clowers@pnnl.gov	\N	3P483	N	N	2016-10-04 12:16:53	\N	2016-10-04 12:16:53
2242	D3P483	Clowers, Brian H (old)	H0888383_x	Obsolete	brian.clowers@pnnl.gov	PNL	3P483	N	N	2007-05-11 00:00:00		2013-08-04 00:11:11
2611	CLOW383	Clowers, Brian (old2)	H0888383_x2	Obsolete	Brian.Clowers@pnnl.gov	PNL	3P483	N	N	2015-10-29 14:29:30		2016-05-14 17:23:53
3647	COLB713	Colburn, Heather A	H1096871	Active	heather.colburn@pnnl.gov	PNL	3M713	Y	Y	2025-03-21 05:43:28.919446		2025-03-22 00:11:57.995925
2143	D3M025	Culley, David E	H3588057	Inactive	david.culley@pnnl.gov	PNL	3M025	N	N	2004-04-15 00:00:00		2018-02-06 00:11:11
2235	D3P793	Danielson III, Bill	H4994122	Inactive	william.danielson@pnnl.gov	PNL	3P793	N	N	2007-03-01 00:00:00	\N	2013-11-01 00:11:11
2261	D3E719	Colton, Nancy G	H0073252	Inactive	penny.colton@pnnl.gov	PNL	3E719	N	N	2008-06-15 00:00:00		2013-07-02 00:11:11
2328	D3Y513	Crowell, Kevin L	H4167792	Inactive	Kevin.Crowell@pnnl.gov	PNL	3Y513	N	N	2009-10-27 10:30:35	\N	2016-05-14 17:23:53
3293	CONG047	Cong, Yongzheng	H9383547	Inactive	yongzheng.cong@pnnl.gov	PNL		N	N	2018-04-23 13:10:02		2018-10-01 00:11:10
2032	D3C630	Conrads, Thomas	H0031186	Inactive	\N	\N	3C630	N	N	2001-03-01 00:00:00		\N
3356	EBER373	Corilo, Yuri E	H2107561	Active	corilo@pnnl.gov	PNL		Y	Y	2019-06-05 13:51:02		2023-04-01 00:11:15
3672	PERD205	Perdue, Aubrey	H7174205	Active	aubrey.perdue@pnnl.gov	PNL	\N	Y	Y	2025-10-20 15:35:29.866594		2025-10-21 00:11:37.924095
2352	JRCORT	Cort, John R	H0362300	Active	John.Cort@pnnl.gov	PNL	3K671	Y	Y	2010-05-27 08:49:31		2013-06-07 14:16:32
3244	COUV810	Couvillion, Sneha P	H9311108	Active	sneha.couvillion@pnnl.gov	PNL		Y	Y	2017-02-07 15:11:21		2017-02-08 00:11:11
2023	D37313	Cowley, Paula J	H0051130	Inactive			37313	N	N	2002-01-01 00:00:00		\N
3241	COWM555	Cowman, Kelsey	H9673557	Inactive	kelsey.cowman@pnnl.gov	PNL	\N	N	N	2017-01-05 10:15:04	\N	2017-06-18 00:11:14
3275	CUEV395	Cuevas Fernandez, Josh	H4592234	Inactive	josh.cuevas@pnnl.gov	PNL		N	N	2017-11-06 13:35:42		2018-07-16 00:11:12
2335	D3Y465	Coffen, Juandalyn L	H1033684	Inactive			3Y465	N	N	2010-01-14 11:55:51		2010-01-14 11:55:51
2298	D3Y241	Cusack, Michael P	H9582573	Inactive	Michael.Cusack@pnl.gov		3Y241	N	N	2009-04-01 00:00:00		\N
3645	CZAJ603	Czajka, Jeffrey J	H7222097	Active	jeffrey.czajka@pnnl.gov	PNL	\N	Y	Y	2025-03-04 05:43:11.183505		2025-03-05 00:11:40.199761
2300	adabney	Dabney, Alan	H5864579	Inactive	Alan.Dabney@pnl.gov	\N	\N	N	N	2009-05-01 00:00:00		\N
2269	H5864579	Dabney, Alan (old)	H5864579_x	Obsolete	Alan.Dabney@pnl.gov		\N	N	N	2008-08-01 00:00:00		\N
3427	DAKU386	Dakup, Panshak P	H9520444	Active	panshak.dakup@pnnl.gov	PNL		Y	Y	2020-09-18 11:16:54		2020-09-19 00:11:11
3581	DANC808	Danczak, Robert E	H2887808	Active	robert.danczak@pnnl.gov	PNL	\N	Y	Y	2023-09-11 15:50:14		2023-09-12 00:11:14
3327	DANC783	Danczak, Robert E (old)	H2887808_x	Obsolete	robert.danczak@pnnl.gov	PNL		N	N	2018-11-19 11:55:55		2023-09-11 00:11:15
2362	DANN432	Dann, Geoff P	H9038786	Inactive			3X432	N	N	2010-09-16 14:47:07		2013-06-07 14:16:32
2371	DATT736	Datta, Suchitra	H2698845	Inactive			\N	N	N	2010-11-24 20:15:13		2010-11-24 20:15:13
2535	DAUT285	Dautel, Sydney E	H5095945	Inactive	Sydney.Dautel@pnnl.gov	PNL		N	N	2014-12-08 10:43:54		2016-08-14 00:11:15
3582	DAWA726	Dawar, Pranav	H7223030	Active	pranav.dawar@pnnl.gov	PNL	\N	Y	Y	2023-09-12 13:04:49		2023-09-13 00:11:14
3421	ZHAN507	Day, Le Z	H2234660	Active	le.day@pnnl.gov	PNL		Y	Y	2020-08-19 16:38:07	Le Zhang Day	2022-07-07 00:11:13
3418	DAYN515	Day, Nicholas J	H2804790	Active	nicholas.day@pnnl.gov	PNL		Y	Y	2020-08-06 09:53:06		2020-08-07 00:11:10
2481	DEGA126	Degan, Michael G	H6384900	Active	michael.degan@pnnl.gov	PNL	3P126	Y	Y	2014-01-22 14:38:14		2014-01-23 00:11:11
3409	DEGN400	Degnan, David J	H6918835	Active	david.degnan@pnnl.gov	PNL		Y	Y	2020-04-21 11:29:39		2020-04-22 00:11:11
2374	Dekk767	Dekker, Leendert	H5053767	Inactive			\N	N	N	2011-01-12 19:10:35		2011-01-12 19:10:35
2338	D3Y412	Dixon, Brent	H9400121	Inactive			3Y412	N	N	2010-02-05 12:35:53		2010-02-05 12:35:53
3329	DEMI384	Demir, Emek	H2126384	Inactive	demire@ohsu.edu	PNL		N	N	2018-11-21 08:27:35		2018-11-22 00:11:11
3506	DIAZ362	Diaz Ludovico, Ivo	H1435898	Active	ivo.diaz@pnnl.gov	PNL	\N	N	Y	2022-06-01 10:44:56		2025-09-13 00:11:48.446428
2218	D3P627	Deng, Shuang	H7595236	Active	shuang.deng@pnnl.gov	PNL	3P627	Y	Y	2006-08-31 00:00:00		\N
3573	DENI021	Denis, Elizabeth H	H9031500	Active	elizabeth.denis@pnnl.gov	PNL	\N	Y	Y	2023-08-24 05:43:55		2023-08-25 00:11:15
3349	EDER951	Eder, Liz	H3679558	Active	elizabeth.eder@pnnl.gov	PNL		Y	Y	2019-04-15 16:24:01		2025-09-18 00:11:53.566404
2466	DHON338	Dhondt, Ineke	H0538338	Inactive	Ineke.Dhondt@pnnl.gov	PNL	\N	N	N	2013-06-14 11:06:27	\N	2013-06-19 00:11:10
2304	ddiamond	Diamond, Deborah	H0000001	Inactive	\N	\N	\N	N	N	2009-06-01 00:00:00		2009-06-01 00:00:00
2425	D3Y481	Chavez, Francisco T	H5106685	Inactive	Francisco.Chavez@pnnl.gov	PNL	3Y481	N	N	2012-10-31 12:49:42	\N	2013-06-02 00:11:11
2188	D3P114	Ding, Jie	H8272580	Inactive			3P114	N	N	2005-11-11 00:00:00		\N
2164	D3M366	Ding, Shi-Jian	H2265997	Inactive			3M366	N	N	2004-12-14 00:00:00		\N
2337	svc-dms	DMS service account	H0000000	Active	\N	\N	\N	Y	N	2010-02-05 12:26:03		2010-02-05 12:26:03
2427	KANG469	Kang, Jiyun	H0437984	Inactive	Jiyun.Kang@pnnl.gov	PNL	\N	N	N	2012-11-29 16:11:07		2016-05-14 17:23:53
2428	WEIS443	Wei, Siwei	H4180072	Inactive	Siwei.Wei@pnnl.gov	PNL	\N	N	N	2012-12-05 16:24:43	\N	2016-05-14 17:23:53
2435	ROSC384	Johnson, Kristyn	H8029284	Inactive	Kristyn.Roscioli@pnnl.gov	PNL	\N	N	N	2013-01-24 14:00:58		2024-10-24 00:11:48.830584
2440	LINT458	Lin, Tzu-Yung	H1833616	Inactive	Tzu-Yung.Lin@pnnl.gov	PNL	\N	N	N	2013-02-18 15:02:07		2016-05-14 17:23:53
3249	DOUM785	Dou, Maowei	H3744727	Inactive	maowei.dou@pnnl.gov	PNL		N	N	2017-04-07 15:22:40		2019-04-06 00:11:11
3508	DRUC594	Drucker, Ben	H0772169	Active	ben.drucker@pnnl.gov	PNL	\N	Y	Y	2022-06-14 14:27:32		2022-06-15 00:11:13
3551	DING881	Ding, Xinxin	H4355627	Active	xinxin.ding@pnnl.gov	PNL	\N	N	Y	2023-05-15 15:02:39		2025-09-19 00:11:54.792469
2441	COXJ416	Cox, Jonathan T	H0821776	Inactive	Jonathan.Cox@pnnl.gov	PNL	\N	N	N	2013-02-19 10:54:49	\N	2016-05-14 17:23:53
2444	DUTT164	Dutta, Arnab	H1639908	Inactive	\N	\N	\N	N	N	2013-04-16 14:07:02	\N	2013-04-16 14:07:02
2182	D3P019	Du, Xiuxia	H6733068	Inactive	xiuxia.du@pnl.gov		3P019	N	N	2006-03-14 00:00:00		\N
2443	D3L061	Chen, Baowei	H1057212	Inactive	Baowei.Chen@pnnl.gov	PNL	3L061	N	N	2013-03-26 18:05:53		2016-05-14 17:23:53
3345	HANS226	Eder, Josie G	H5495210	Active	josie.eder@pnnl.gov	PNL		Y	Y	2019-03-13 13:15:55		2022-03-03 00:11:13
3413	EDWA533	Edwards, Brian A	H2429119	Active	brian.edwards@pnnl.gov	PNL		Y	Y	2020-06-12 11:23:19		2021-05-25 00:11:14
3276	EGBE290	Egbert, Rob	H8930504	Active	robert.egbert@pnnl.gov	PNL	\N	Y	Y	2017-11-11 13:01:06		2020-07-18 00:11:11
2092	D3L315	Elias, Dwayne A	H6407423	Inactive			3L315	N	N	2003-01-01 00:00:00		\N
2447	DAVI633	Davis, Josh A	H4771050	Inactive	Joshua.Davis@pnnl.gov	PNL	\N	N	N	2013-05-29 13:47:59		2013-08-04 00:11:11
2450	WANG574	Wang, Sheng	H6057963	Inactive	Sheng.Wang@pnnl.gov	PNL	\N	N	N	2013-06-05 14:01:54		2016-09-18 00:11:13
2156	D3J409	Ellis, Edward	H0023981	Inactive	edward.ellis@pnnl.gov	PNL	3J409	Y	N	2005-04-01 00:00:00		\N
3425	ELMO110	Elmore, Joshua R	H6888719	Active	joshua.elmore@pnnl.gov	PNL	\N	Y	Y	2020-09-18 05:42:59		2020-09-19 00:11:11
2144	D3M357	Elshafey, Ahmed	H7214953	Inactive			3M357	N	N	2004-04-16 00:00:00		\N
2505	ELZE936	Elzek, Mohamed	H0549936	Inactive	\N	\N	\N	N	N	2014-08-07 15:55:43	\N	2014-08-07 15:55:43
2276	EMSL1521	EMSL 1521	H0000000	Inactive		\N		N	N	2009-01-01 00:00:00	Service account managed by Heather Brewer	\N
2457	D3J290	Corley, Rick	H0103626	Inactive	rick.corley@pnnl.gov	PNL	3J290	N	N	2013-06-05 15:32:34		2017-02-14 00:11:10
3579	DESO442	Desousa, Kimberly	H7976856	Active	kim.desousa@pnnl.gov	PNL	\N	N	Y	2023-09-07 11:26:51		2025-11-02 00:11:44.517174
2879	ENGB248	Engbrecht, Kristin M	H5565436	Active	kristin.engbrecht@pnnl.gov	PNL	\N	Y	Y	2016-02-11 16:31:20		2016-05-14 17:23:53
2289	D3M261	Engelmann, Heather E	H3920427	Active	heather.engelmann@pnnl.gov	PNL	3M261	Y	Y	2009-03-01 00:00:00	\N	\N
2033	D3A476	Eschbach, Peter	H0006605	Inactive	\N	\N	3A476	N	N	2001-03-01 00:00:00		\N
2543	EVAN078	Evans, James E	H0505302	Active	James.Evans@pnnl.gov	PNL	\N	Y	Y	2015-02-24 05:44:20		2016-05-14 17:23:53
2101	D3M019	Fang, Ruihua	H3930916	Inactive			3M019	N	N	2003-03-01 00:00:00		\N
3210	D3K971	Fansler, Sarah J	H5663930	Active	Sarah.Fansler@pnnl.gov	PNL	3K971	Y	Y	2016-06-14 14:20:25		2016-06-15 00:11:10
2339	GAOX621	Gao, Shelly	H9325909	Inactive			3Y621	N	N	2010-02-05 12:39:20		2013-06-07 14:16:32
2073	D3K994	Feldhaus, Jane M	H2727535	Inactive			3K994	N	N	2002-08-06 00:00:00		\N
2079	D3K763	Feldhaus, Michael	H5580629	Inactive			3K763	N	N	2002-09-01 00:00:00		\N
3495	FENG819	Feng, Ruozhu	H8894199	Active	ruozhu.feng@pnnl.gov	PNL	\N	Y	Y	2022-02-17 13:26:04		2022-02-18 00:11:13
3491	FENG626	Feng, Song	H3664098	Active	song.feng@pnnl.gov	PNL		Y	Y	2022-01-31 12:47:15		2022-02-01 00:11:13
2068	D3L062	Ferguson, Patrick L	H5355249	Inactive			3L062	N	N	2002-12-10 00:00:00		\N
3587	GARA093	Garana, Belinda	H1631420	Active	belinda.garana@pnnl.gov	PNL	\N	N	Y	2023-10-19 12:13:15		2025-10-21 00:11:37.924095
2331	FILL570	Fillmore, Thomas L	H9954281	Active	Thomas.Fillmore@pnnl.gov	PNL	3Y570	Y	Y	2009-12-18 10:14:00	\N	2013-06-07 14:16:32
3609	ESTE316	Estevao, Igor	H3424397	Active	igor.l.estevao@pnnl.gov	PNL	\N	N	Y	2024-02-06 17:04:28		2025-06-29 00:11:26.815616
2380	FORT055	Fortuin, Suereta	H5422055	Inactive			\N	N	N	2011-04-28 14:34:02	\N	2011-04-28 14:34:02
2390	KFOX	Fox, Kevin M	H0516373	Active	kevin.fox@pnnl.gov	PNL	3M351	Y	Y	2011-09-23 20:05:34		2013-06-07 14:16:32
2202	D3M802	Fraga, Carlos G	H0524300	Inactive	carlos.fraga@pnnl.gov	PNL	3M802	N	N	2006-03-01 00:00:00		2022-01-18 00:11:12
2442	FUJI510	Fujimoto, Grant M	H7724289	Active	Grant.Fujimoto@pnnl.gov	PNL	\N	Y	Y	2013-02-19 11:08:59		2013-03-25 20:53:22
3347	FULC267	Fulcher, James M	H9269003	Active	james.fulcher@pnnl.gov	PNL		Y	Y	2019-04-02 14:56:28		2019-04-03 00:11:10
2224	D3P689	Fu, Qiang	H8273642	Inactive			3P689	N	N	2006-10-11 00:00:00		\N
2430	GAFF567	Gaffrey, Matthew J	H2196413	Active	Matthew.Gaffrey@pnnl.gov	PNL	\N	Y	Y	2013-01-08 10:55:46		2013-01-08 10:55:46
2386	FLOY973	Floyd, Erica A	H4016668	Inactive	Erica.Floyd@pnnl.gov	PNL	\N	N	N	2011-07-19 16:39:08	\N	2013-05-02 00:11:11
2454	D3A469	Fredrickson, Jim K	H0006493	Inactive	Jim.Fredrickson@pnnl.gov	PNL	3A469	N	N	2013-06-05 15:32:34		2017-09-23 00:11:11
2180	D3P090	Gao, Amy R	H5365694	Inactive	amy.gao@pnl.gov	PNL	3p090	N	N	2005-10-06 00:00:00		\N
2387	GAOY643	Gao, Yuqian	H5458384	Active	Yuqian.Gao@pnnl.gov	PNL		Y	Y	2011-07-26 10:18:27		2011-07-26 10:18:27
3336	GARA009	Garayburu-Caruso, Vanessa A	H6243544	Active	vanessa.garayburu-caruso@pnnl.gov	PNL		Y	Y	2019-01-10 18:12:20		2019-01-11 00:11:11
3630	GAUT914	Gautam, Tania	H9380914	Active	tania.gautam@pnnl.gov	PNL	\N	N	Y	2024-08-14 14:28:28.559705		2025-08-29 00:11:32.274437
3621	GARC286	Garcia, Marci R	H5470144	Active	marci.garcia@pnnl.gov	PNL	\N	Y	Y	2024-05-28 16:47:31		2024-05-29 00:11:15
3359	GARC160	Garcia, Whitney L (old)	H7373718_x	Obsolete	whitney.garcia@pnnl.gov	PNL		Y	N	2019-07-10 09:47:09		2025-02-03 00:12:07.775471
2533	GARG087	Gargallo Garriga, Albert	H9406087	Inactive	\N	\N	\N	N	N	2014-12-02 15:04:00	\N	2016-05-14 17:23:53
3224	GARG447	Gargano, Andrea	H6937447	Inactive	andrea.gargano@pnnl.gov	PNL	\N	N	N	2016-09-27 10:05:08	\N	2017-02-04 00:11:11
2432	GARI453	Garimella, Sandilya	H7175496	Active	Sandilya.Garimella@pnnl.gov	PNL	\N	Y	Y	2013-01-23 11:07:01	\N	2013-01-23 11:07:01
3437	D3K289	Gaspar, Dan	H6704611	Active	Daniel.Gaspar@pnnl.gov	PNL	3K289	Y	Y	2021-01-29 05:42:59		2024-09-24 00:11:16.773994
3538	GAUT032	Gautam, Tania (old)	H9380914_x	Obsolete	tania.gautam@pnnl.gov	PNL	\N	Y	N	2023-01-24 15:55:45		2024-08-12 00:11:17.51986
2462	D3P838	Konopka, Allan E	H9571324	Inactive	allan.konopka@pnnl.gov	PNL	3P838	N	N	2013-06-05 15:32:34		2016-05-14 17:23:53
2498	GIBB166	Gibbons, Bryson	H3187713	Active	bryson.gibbons@pnnl.gov	PNL	\N	Y	Y	2014-06-24 13:57:41	\N	2020-06-16 00:11:10
3304	FANG730	Fang, Alexander C	H3235706	Inactive	alexander.fang@pnnl.gov	PNL		N	N	2018-06-22 12:43:29		2021-03-18 00:11:13
3373	FOLS904	Folse, Andie N	H0477472	Inactive	andrea.folse@pnnl.gov	PNL		N	N	2019-09-24 15:49:50		2019-11-27 00:11:10
2467	KLIN638	Kline, Paul I	H3857276	Inactive	Paul.Kline@pnnl.gov	PNL	\N	N	N	2013-06-18 10:27:30	\N	2013-08-21 00:11:11
3544	FLOR829	Flores, Javier	H5842699	Active	javier.flores@pnnl.gov	PNL	\N	N	Y	2023-03-29 11:35:28		2025-12-01 00:11:56.585512
3639	GARC718	Garcia, Whitney	H7373718	Active	whitney.garcia@pnnl.gov	PNL	\N	N	Y	2025-02-04 17:06:53.615405		2025-11-12 00:11:44.510405
3221	GIBB713	Gibbons, Bryson C (admin account)	H3187713_x	Active	bryson.gibbons@pnnl.gov	PNL	\N	Y	N	2016-09-12 16:36:32		2016-09-12 16:36:32
3257	GIBE617	Giberson, Cameron M	H0901855	Active	cameron.giberson@pnnl.gov	PNL	\N	Y	Y	2017-07-17 15:34:27	\N	2017-07-18 00:11:11
2147	D3M953	Gilmore, Jason M	H9480505	Inactive	jason.gilmore@pnl.gov	PNL	3M953	N	N	2004-07-01 00:00:00		\N
3553	BOJANA	Ginovska, Bojana	H0699909	Active	bojana.ginovska@pnnl.gov	PNL	3M959	Y	Y	2023-05-19 05:43:53		2023-05-20 00:11:14
2146	D3M176	Glukhova, Veronika A	H5761895	Inactive			3M176	N	N	2004-07-01 00:00:00		\N
2302	D3Y333	Heegel, Robbie A	H4571778	Inactive			3Y333	N	N	2009-05-01 00:00:00		\N
3335	GOME908	Gomez, Lupita G	H5733287	Inactive	lupita.gomez@pnnl.gov	PNL	904908	N	N	2018-12-19 16:28:29		2019-10-09 00:11:11
2187	D3P205	Gonzalez, Rachel M	H2102335	Inactive			3P205	N	N	2005-11-01 00:00:00		\N
2059	D3H251	Gorby, Yuri A	H0010492	Inactive	yuri.gorby@pnl.gov	PNL	3H251	N	N	2002-08-07 00:00:00		\N
3519	GORH221	Gorham, Leo	H2362081	Active	leo.gorham@pnnl.gov	PNL	\N	Y	Y	2022-08-30 17:26:21		2022-08-31 00:11:13
3517	GORM567	Gorman, Brittney L	H3066931	Active	brittney.gorman@pnnl.gov	PNL	\N	Y	Y	2022-08-30 15:11:16		2022-08-31 00:11:13
2346	D3K941	Gorton, Ian (old)	H4674145_x	Obsolete	ian.gorton@pnnl.gov	PNL	3K941	N	N	2010-03-17 14:05:56		2018-11-21 00:11:11
2010	D3K876	Goshe, Michael B	H2742088	Inactive			3K876	N	N	2001-11-13 00:00:00		\N
3396	GOSL241	Gosline, Sara JC	H8264367	Active	sara.gosline@pnnl.gov	PNL		Y	Y	2020-03-03 13:56:43		2020-03-04 00:11:10
3503	GRAH930	Graham, Emily B	H9251893	Active	emily.graham@pnnl.gov	PNL	\N	Y	Y	2022-04-21 05:43:02		2022-04-22 00:11:13
2358	HENG718	Hengel, Shawna M	H4132264	Inactive			\N	N	N	2010-06-28 14:33:00		2010-06-28 14:33:00
2094	H7301210	Griffiths, Megan	H7301210	Inactive	\N	\N	\N	N	N	2003-01-01 00:00:00		\N
2408	GUOJ190	Guo, Jia	H9096212	Inactive	Jia.Guo@pnnl.gov	PNL	\N	N	N	2012-05-31 11:09:06		2016-05-14 17:23:53
2097	D3L365	Gritsenko, Marina A	H9097454	Active	marina.gritsenko@pnnl.gov	PNL	3L365	Y	Y	2003-01-24 00:00:00		\N
3650	GUAG181	Guagenti, Meghan	H7440181	Active	meghan.guagenti@pnnl.gov	PNL	\N	Y	Y	2025-04-02 13:00:14.811235		2025-04-03 00:11:10.650426
2301	zoe	Guillen, Zoe C	H3415797	Active	zoe@pnnl.gov	PNL	3L028	Y	Y	2009-05-01 00:00:00		2013-06-07 14:16:32
2500	GUOX393	Guo, Xuejiang	H4422393	Inactive	\N	\N	\N	N	N	2014-07-02 09:59:21	\N	2014-07-02 09:59:21
2410	HATC294	Hatchell, Kayla E	H0653799	Inactive	Kayla.Hatchell@pnnl.gov	PNL	\N	N	N	2012-06-12 17:03:04		2016-05-14 17:23:53
3269	HALE340	Hale, Keaton P	H7102181	Inactive	keaton.hale@pnnl.gov	PNL		N	N	2017-10-16 16:19:36		2018-07-01 00:11:11
2393	HALL057	Hallaian, Katie A	H5464663	Inactive	Katherine.Hallaian@pnnl.gov	PNL	\N	N	N	2011-11-28 13:50:40	\N	2016-05-14 17:23:53
3584	HALL274	Hall, David	H7008821	Active	david.hall@pnnl.gov	PNL	\N	Y	Y	2023-10-03 15:29:16		2023-10-04 00:11:15
2175	D3M991	Hall, Justin D	H6759865	Inactive			3M991	N	N	2005-06-29 00:00:00		\N
2215	D3P427	Ham, Bryan M	H6290637	Inactive			3P427	N	N	2006-10-01 00:00:00		\N
2521	HAMI300	Hamid, Ahmed M	H4025166	Inactive	ahmed.hamid@pnnl.gov	PNL	\N	N	N	2014-10-03 10:15:29	\N	2016-05-14 17:23:53
2865	HAND991	Handakumbura, Pubudu	H4455809	Active	pubudupinipa.handakumbura@pnnl.gov	PNL	\N	Y	Y	2016-02-05 15:48:11	\N	2016-05-14 17:23:53
3229	HANS227	Hansen, Joshua R	H1985204	Active	joshua.hansen@pnnl.gov	PNL	\N	Y	Y	2016-10-06 13:51:43		2025-03-05 15:48:04.606455
3392	HARR987	Harrilal, Chris P	H3304109	Active	christopher.harrilal@pnnl.gov	PNL		Y	Y	2020-01-15 14:57:44		2020-01-16 00:11:12
2684	D3L008	Heredia-Langner, Alejandro	H0324227	Active	Alejandro.Heredia-Langner@pnnl.gov	PNL	3L008	N	Y	2015-11-11 10:21:37		2025-07-15 00:11:44.055272
3583	HEAL742	Heal, Katherine R	H6239464	Active	katherine.heal@pnnl.gov	PNL	\N	Y	Y	2023-09-19 16:18:48		2023-09-20 00:11:15
2369	HEER846	Heeren, Ronald	H1961846	Inactive	Ronald.Heeren@pnnl.gov	PNL	\N	N	N	2010-11-08 10:40:36	\N	2016-05-14 17:23:53
2239	D3P722	Heibeck, Tyler H	H3387856	Inactive			3P722	N	N	2007-01-31 00:00:00		\N
3361	GONZ720	Gonzalez, Brianna I	H9841311	Inactive	brianna.gonzalez@pnnl.gov	PNL		N	N	2019-07-15 10:09:36		2025-07-03 00:11:31.05725
2249	H5008603	Henne, Kristene	H5008603	Inactive			\N	N	N	2007-06-01 00:00:00		\N
3463	HENR422	Henry, Hayden R	H6337574	Inactive	hayden.henry@pnnl.gov	PNL		N	N	2021-07-01 11:33:46		2021-08-24 00:11:13
3346	HANL116	Hanlon, Zachary J	H3219797	Inactive	zachary.hanlon@pnnl.gov	PNL		N	N	2019-03-28 14:16:47		2021-01-03 00:11:13
2532	GUEN867	Guenther, Alex B	H0043492	Inactive	\N	\N	\N	N	N	2014-12-01 11:51:17		2016-05-14 17:23:53
2286	D3X809	Hossain, Mahmud	H5393713	Inactive			3X809	N	N	2009-02-01 00:00:00		\N
3360	HESS593	Hess, Becky M	H4947183	Active	Becky.Hess@pnnl.gov	PNL	3Y593	Y	Y	2019-07-11 05:42:59		2019-07-12 00:11:11
2342	HUZE256	Hu, Zeping	H8674504	Inactive			3Y256	N	N	2010-02-11 18:06:22	\N	2013-06-07 14:16:32
6	D3J704	Hixson, Kim	H2816000	Inactive	Kim.Hixson@pnnl.gov	PNL	3J704	N	N	2000-07-17 00:00:00		2025-01-04 00:11:36.088684
3632	HODA636	Hodas, Nathan O	H6029636	Active	nathan.hodas@pnnl.gov	PNL	\N	Y	Y	2024-09-10 17:36:00.494957		2024-09-11 00:12:02.641492
3367	HODA048	Hodas, Nathan O (old)	H6029636_x	Obsolete	nathan.hodas@pnnl.gov	PNL	\N	Y	N	2019-09-04 05:43:00		2024-09-09 00:12:00.477973
3236	HOFM890	Hofmockel, Kirsten S	H4624914	Active	kirsten.hofmockel@pnnl.gov	PNL	\N	Y	Y	2016-12-06 10:41:35		2016-12-07 00:11:11
3237	HOFM963	Hofmockel, Michael S	H8865071	Active	michael.hofmockel@pnnl.gov	PNL	\N	Y	Y	2016-12-06 10:42:13		2016-12-07 00:11:11
2140	D3C890	Hofstad, Beth A	H0058580	Active	beth.hofstad@pnnl.gov	PNL	3C890	Y	Y	2004-05-01 00:00:00		\N
2459	D3K642	Holladay, John E	H7085483	Inactive	john.holladay@pnnl.gov	PNL	3K642	N	N	2013-06-05 15:32:34		2021-04-24 00:11:12
2273	D3X542	Hood, Evan C	H5624140	Inactive			3X542	N	N	2009-01-01 00:00:00		\N
2191	D3H446	Hooker, Brian S	H0013584	Inactive			3H446	N	N	2006-12-22 00:00:00		\N
2489	D3E889	Hopkins, Derek F	H0076147	Active	derek.hopkins@pnnl.gov	PNL	3E889	Y	Y	2014-05-02 16:01:46		2016-05-14 17:23:53
10	D3K040	Horner, Julie A	H3067300	Inactive	\N	\N	3K040	N	N	2001-01-01 00:00:00		\N
3307	D3J535	Hoyt, David W	H0102607	Active	david.hoyt@pnnl.gov	PNL	3J535	Y	Y	2018-07-05 05:43:06		2018-07-06 00:11:11
2368	HYUN402	Hyung, Seok-Won	H4534636	Inactive			\N	N	N	2010-10-13 18:10:29	\N	2010-10-13 18:10:29
3305	HUGH833	Hughes, Samantha J	H6182791	Inactive	samantha.hughes@pnnl.gov	PNL		N	N	2018-06-29 10:29:46		2018-06-30 00:11:10
2262	D3K488	Hu, Jian Z	H5654469	Active	Jianzhi.Hu@pnnl.gov	PNL	3K488	Y	Y	2008-06-15 00:00:00		\N
3429	HUNT756	Huntley, Adam P	H0233940	Inactive	adam.huntley@pnnl.gov	PNL		N	N	2020-09-29 14:56:49		2023-11-16 00:11:14
2385	HUTC345	Hutchinson Bunch, Chelsea M	H2842318	Active	chelsea.hutchinson@pnnl.gov	PNL		Y	Y	2011-06-28 15:53:03		2023-08-24 00:11:14
2274	D3X569	Hutson, RaeAnn M	H4082452	Inactive			3X569	N	N	2009-01-01 00:00:00		\N
2248	H5240435	Huttlin, Edward	H5240435	Inactive			\N	N	N	2007-05-01 00:00:00		\N
2361	D3M732	Ibrahim, Yehia M	H2400269	Active	yehia.ibrahim@pnnl.gov	PNL	3M732	Y	Y	2010-09-01 18:04:54	\N	2010-09-01 18:04:54
3446	IJAZ862	Ijaz, Amna	H6972190	Inactive	amna.ijaz@pnnl.gov	PNL		N	N	2021-03-12 15:34:18		2021-08-11 00:11:13
2426	IRAC455	Iracheta, Larissa R	H0522212	Inactive	Larissa.Iracheta@pnnl.gov	PNL	\N	N	N	2012-11-19 11:27:02	\N	2016-05-14 17:23:53
2502	JENS267	Jenson, Sarah	H8335570	Active	sarah.jenson@pnnl.gov	PNL	\N	N	Y	2014-07-14 11:14:44		2025-09-07 00:11:41.767046
3578	IVES435	Ives, Ashley	H5768842	Active	ashley.ives@pnnl.gov	PNL	\N	Y	Y	2023-09-06 15:11:39		2023-09-07 00:11:15
2088	D3L239	Jacobs, Jon M	H9439610	Active	Jon.Jacobs@pnnl.gov	PNL	3L239	Y	Y	2002-10-31 00:00:00		\N
3532	JACO059	Jacobson, Jeremy R	H3410453	Active	jeremy.jacobson@pnnl.gov	PNL	\N	Y	Y	2022-11-21 11:32:01		2022-11-22 00:11:13
2174	H4492479	Jacoby, Michael	H4492479	Inactive	michael.jacoby@pnl.gov		\N	N	N	2005-07-01 00:00:00		\N
2158	D3M419	Jaitly, Navdeep	H9843676	Inactive			3M419	N	N	2005-11-09 00:00:00		\N
2382	JARA627	Jaramillo Riveri, Sebastian I	H1303115	Inactive			3Y627	N	N	2011-05-13 11:44:28	\N	2013-06-07 14:16:32
2388	HUFF042	Huff, Melissa A	H5323922	Inactive			3Y042	N	N	2011-08-17 13:11:13		2013-06-07 14:16:32
2419	JIAN278	Jiang, Yuxuan (Mary)	H1982697	Inactive	mary.jiang@pnnl.gov	PNL	\N	N	N	2012-08-24 12:34:20	\N	2023-07-08 00:11:15
9	D3K026	Jensen, Pamela K	H0626000	Inactive	\N	\N	3K026	N	N	2001-01-01 00:00:00		\N
3569	JERG881	Jerger, Abby	H0507623	Active	abby.jerger@pnnl.gov	PNL	\N	Y	Y	2023-08-15 13:21:18		2023-08-16 00:11:15
2179	D3P099	Jiang, Hongliang	H2411343	Inactive			3P099	N	N	2005-10-03 00:00:00		\N
2420	HUAN400	Huang, Eric L	H7299376	Inactive	Eric.Huang@pnnl.gov	PNL	\N	N	N	2012-09-07 09:26:21	\N	2016-05-14 17:23:53
3326	HOLL970	Hollerbach, Adam	H4851252	Active	adam.hollerbach@pnnl.gov	PNL		N	Y	2018-11-08 12:47:13		2025-11-03 00:11:44.517835
3636	IMAL967	Im, Ally	H5261597	Active	alexandria.im@pnnl.gov	PNL	\N	N	Y	2024-11-22 14:36:09.734468		2026-02-07 00:11:49.180666
3604	JAIN601	Jain, Raghav	H4545479	Active	raghav.jain@pnnl.gov	PNL	\N	N	Y	2024-01-03 12:10:45		2026-02-10 00:11:49.180351
3629	JOOW224	Joo, Wontae	H9028919	Active	wontae.joo@pnnl.gov	PNL	\N	N	Y	2024-08-09 05:42:46.454585		2025-10-07 00:11:37.934823
2221	D3M956	Jin, Shuangshuang	H0261100	Inactive			3M956	N	N	2006-08-01 00:00:00		\N
2117	D3M121	Johnson, Ethan T	H3608251	Inactive			3M121	N	N	2003-09-12 00:00:00		\N
3435	D3Y017	Johnson, Grant E	H9362215	Active	Grant.Johnson@pnnl.gov	PNL	3Y017	Y	Y	2020-12-16 05:43:00		2020-12-17 00:11:13
2129	D3G038	Kangas, Lars J	H0092382	Inactive	lars.kangas@pnnl.gov	PNL	3G038	N	N	2004-01-01 00:00:00		2013-10-21 00:11:10
2246	D3P445	Jones, Eric M	H8396572	Inactive			3P445	N	N	2007-04-30 00:00:00		\N
3528	KELL343	Kelly, Shane S	H9042656	Active	shane.kelly@pnnl.gov	PNL	\N	Y	Y	2022-11-03 12:35:04		2026-02-04 00:11:56.557424
2288	H6053261	Jung, Hee-Jung	H6053261	Inactive	HeeJung.Jung@pnl.gov	PNL	\N	N	N	2009-02-02 00:00:00		\N
2148	D3C797	Johnson, Renee E	H0042133	Inactive			3C797	N	N	2004-08-12 00:00:00		\N
3633	KABZ224	Kabza, Adam	H3940224	Active	adam.kabza@pnnl.gov	PNL	\N	Y	Y	2024-09-12 12:13:44.023778		2024-09-13 00:12:04.81139
2345	DEAT586	Kaiser, Brooke L	H0002368	Active	brooke.kaiser@pnnl.gov	PNL	3Y586	Y	Y	2010-03-12 15:57:35		2024-01-19 00:11:14
2236	D3P723	Kaleta, David T	H2734071	Inactive			3P723	N	N	2006-11-15 00:00:00		\N
2168	D3M617	Kang, Hyuk	H1799449	Inactive			3M617	N	N	2005-01-06 00:00:00		\N
3563	KIMH378	Kim, Hyeyoon	H5309858	Active	hyeyoon.kim@pnnl.gov	PNL	\N	N	Y	2023-06-22 09:00:06		2026-02-05 00:11:56.576423
3219	KEDI661	Kedia, Komal	H8850712	Inactive	komal.kedia@pnnl.gov	PNL		N	N	2016-08-24 10:59:37		2018-09-29 00:11:11
2354	KELL364	Keller, Kimberly	H0788364	Inactive			\N	N	N	2010-06-22 15:32:22		2010-06-22 15:32:22
2244	D3P189	Kelly, Ryan T	H0786509	Inactive	ryan.kelly@pnnl.gov	PNL	3P189	N	N	2007-04-09 00:00:00		\N
3460	KELL656	Kelly, Shane (old)	H9042656_x	Obsolete	shane.kelly@pnnl.gov	PNL		N	N	2021-07-01 08:32:45		2021-07-02 00:11:14
3338	KEWW938	Kew, Will	H5016889	Active	william.kew@pnnl.gov	PNL		Y	Y	2019-01-25 12:25:33		2020-02-28 00:11:12
17	D3J410	Kiebel, Gary R	H0024573	Inactive	grkiebel@pnnl.gov	PNL	3J410	N	N	2000-04-19 00:00:00	\N	2016-09-02 00:11:10
2503	KILL337	Killinger, Bryan J	H8677341	Inactive	bryan.killinger@pnnl.gov	PNL	\N	N	N	2014-08-05 14:55:47		2022-02-07 00:11:13
3642	KIMD999	Kim, Doo Nam	H2166138	Active	doonam.kim@pnnl.gov	PNL	\N	Y	Y	2025-02-27 15:50:07.364118		2025-02-28 00:11:34.656694
2063	D3L064	Kim, Jeongkwon	H0436669	Inactive			3L064	N	N	2002-04-16 00:00:00		\N
2318	D3Y176	Kim, Young-Mo	H9676493	Active	Young-Mo.Kim@pnnl.gov	PNL	3Y176	Y	Y	2009-09-15 00:00:00		2009-09-15 00:00:00
3458	KITA022	Kitata, Reta Birhanu	H2187162	Active	retabirhanu.kitata@pnnl.gov	PNL		Y	Y	2021-06-28 14:32:16		2021-06-29 00:11:12
3430	KLAN457	Klann, Raymond T	H1442457	Active	ray.klann@pnnl.gov	PNL	\N	Y	Y	2020-10-20 05:42:59		2020-10-21 00:11:12
3641	KNIG310	Knight, Bailey G	H0670310	Active	bailey.knight@pnnl.gov	PNL	\N	Y	Y	2025-02-12 09:19:51.652544		2025-02-13 00:11:18.48868
2178	D3L057	Knyushko, Tanya V	H3651967	Inactive			3L057	N	N	2005-08-11 00:00:00		\N
2198	D3M769	Karin, Norm J	H4739807	Inactive			3M769	N	N	2006-03-01 00:00:00		\N
2399	D3P934	Koech, Phillip K	H6240991	Active	phillip.koech@pnnl.gov	PNL	3P934	Y	Y	2012-01-26 13:08:57		2012-01-26 13:08:57
3467	KOMB956	Kombala, Chathuri	H5558956	Active	chathuri.kombala@pnnl.gov	PNL		Y	Y	2021-08-06 16:31:18		2022-08-29 00:11:13
2455	D3C697	Koppenaal, David W	H0040539	Inactive	david.koppenaal@pnnl.gov	PNL	3C697	N	N	2013-06-05 15:32:34		2020-05-01 00:11:10
2192	H8730825	Kowalska, Malgorzata	H8730825	Inactive	malgorzata.kowalska@pnl.gov		\N	N	N	2006-01-01 00:00:00		\N
2200	D3P303	Karagiosis, Sue A	H5430111	Inactive	sue.karagiosis@pnnl.gov	PNL	3P303	N	N	2006-03-01 00:00:00		2016-05-14 17:23:53
3441	KRIS331	Krishnamoorthy, Sankar	H1451264	Active	sankarganesh.krishnamoorthy@pnnl.gov	PNL		Y	Y	2021-02-23 13:52:19		2021-02-24 00:11:13
2279	D3Y456	Kim, Jong Seo	H3218862	Inactive			3Y456	N	N	2009-01-01 00:00:00		\N
3515	LEEJ592	Lee, Jung	H6590519	Active	jungyun.lee@pnnl.gov	PNL	\N	N	Y	2022-08-10 13:14:40	Jung Yun Lee	2025-07-26 00:11:55.888507
2463	KROG976	Krogstad, Eirik J	H9799657	Active	Eirik.Krogstad@pnnl.gov	PNL	\N	Y	Y	2013-06-07 14:44:48		2013-06-07 14:45:29
3552	KROL657	Kroll, Jared O	H1233657	Active	jared.kroll@pnnl.gov	PNL	\N	Y	Y	2023-05-16 12:25:37	Uses Xcalibur on Protoapps	2023-05-17 00:11:14
3363	KUMA889	Kumar, Neeraj	H0923549	Active	Neeraj.Kumar@pnnl.gov	PNL	\N	Y	Y	2019-08-22 05:43:00		2019-08-23 00:11:10
3617	LAIZ097	Lai, Joy	H9865991	Active	joy.lai@pnnl.gov	PNL	\N	N	Y	2024-05-13 14:53:09		2025-08-02 00:12:03.025599
2247	D3M276	Lamarche, Brian L	H0071077	Inactive	brian.lamarche@pnnl.gov	PNL	3M276	N	N	2007-05-01 00:00:00		2016-05-14 17:23:53
3483	KWON421	Kwon, Yu Mi	H3938866	Active	yumi.kwon@pnnl.gov	PNL		Y	Y	2021-11-16 11:27:25		2021-11-17 00:11:13
2424	KYLE447	Kyle, Jennifer E	H9662281	Active	Jennifer.Kyle@pnnl.gov	PNL	\N	Y	Y	2012-10-29 11:49:29		2012-10-29 11:49:29
3566	KUMA839	Kumar, Rashmi	H1821882	Active	rashmi.kumar@pnnl.gov	PNL	\N	Y	Y	2023-06-28 12:22:42		2023-06-29 00:11:15
3471	LALL643	Lalli, Priscila M	H6839816	Active	priscila.lalli@pnnl.gov	PNL		Y	Y	2021-09-09 11:49:57		2023-04-01 00:11:15
3122	HELL316	Lamar, Natalie C	H2189527	Active	natalie.lamar@pnnl.gov	PNL	\N	Y	Y	2016-04-19 15:31:33	\N	2023-02-09 00:11:15
2139	D3M337	Langley, Charley C	H6173297	Inactive			3M337	N	N	2004-05-01 00:00:00		\N
2325	D3K339	Lansing, Carina S	H0049246	Active	Carina.Lansing@pnnl.gov	PNL	3K339	Y	Y	2009-10-15 08:43:30		2016-07-19 00:11:11
2051	D3K913	Larson, Elizabeth R	H1626074	Inactive			3K913	N	N	2002-05-22 00:00:00		\N
2219	D3P160	Larson, Laura R	H3090066	Inactive	laura.larson@pnl.gov	PNL	3P160	N	N	2006-08-01 00:00:00		\N
3376	D3J960	Kukkadapu, Ravi	H0106989	Active	Ravi.Kukkadapu@pnnl.gov	PNL	3J960	N	Y	2019-10-15 05:43:00		2026-03-02 00:11:49.150448
2316	D3Y381	Lea, Andrew S	H4310464	Inactive			3Y381	N	N	2009-08-15 00:00:00		2009-08-15 00:00:00
2740	D3K881	Laskin, Julia (old)	H7381512_x	Obsolete	julia.laskin@pnnl.gov	PNL	3K881	N	N	2015-12-07 10:04:40		2017-09-02 00:11:11
2340	KRON626	Kronewitter, Scott R	H7098308	Inactive	Scott.Kronewitter@pnnl.gov	PNL	3Y626	N	N	2010-02-05 12:40:04	\N	2016-05-14 17:23:53
3643	LEAC176	Leach, Damon T	H4181048	Active	damon.leach@pnnl.gov	PNL	\N	Y	Y	2025-02-27 15:52:54.074738		2025-02-28 00:11:34.656694
2514	LEEJ324	Lee, Joon-Yong	H0261064	Inactive	joonyong.lee@pnnl.gov	PNL	\N	N	N	2014-09-02 16:00:29		2021-12-01 00:11:14
2303	H5254108	Lee, Jung Hwa	H5254108	Inactive			\N	N	N	2009-05-01 00:00:00		\N
2351	KROV934	Krovvidi, Ravi K	H1810805	Inactive			3X934	N	N	2010-05-17 13:28:05		2013-06-07 14:16:32
2285	H6859035	Lee, Sang-Won	H6859035	Inactive	\N	\N	\N	N	N	2009-02-01 00:00:00		\N
19	D3K882	Lee, Sang-Won (old)	H6859035_x	Obsolete	\N	\N	3K882	N	N	2000-08-22 00:00:00		\N
2391	LEAC651	Leach III, Franklin E	H3463552	Inactive	Franklin.Leach@pnnl.gov	PNL	\N	N	N	2011-10-27 11:19:44	\N	2016-05-14 17:23:53
3487	LEIC428	Leichty, Sarah I	H4555539	Active	sarah.leichty@pnnl.gov	PNL		Y	Y	2021-12-14 15:47:56		2021-12-15 00:11:12
3284	LEIS515	Leiser, Owen P	H6238090	Active	owen.leiser@pnnl.gov	PNL	\N	Y	Y	2018-01-15 12:32:35		2018-01-16 00:11:11
2203	D3J996	Lei, Xingye C	H0103739	Inactive			3J996	N	N	2006-03-01 00:00:00		\N
2400	LEWI564	Lewis, Michael P	H1133249	Inactive			\N	N	N	2012-01-26 13:09:21		2012-01-26 13:09:21
2469	DUAN624	Duan, Jicheng	H3275311	Inactive	Jicheng.Duan@pnnl.gov	PNL	\N	N	N	2013-07-10 15:01:38	\N	2017-05-21 00:11:17
2472	CHEN575	Chen, Tsung-Chi	H4752672	Inactive	Tsung-Chi.Chen@pnnl.gov	PNL	\N	N	N	2013-08-01 17:19:32		2016-05-14 17:23:53
3340	LEWI429	Lewis, Trey W	H0648347	Active	frank.lewis@pnnl.gov	PNL	\N	Y	Y	2019-02-20 05:43:07		2019-02-21 00:11:11
2493	D3M778	Baird, Cheryl L	H9679290	Inactive	\N	\N	3M778	N	N	2014-06-11 05:43:53		2016-05-14 17:23:53
2553	D3J427	Lea, Alan	H0065815	Active	scott.lea@pnnl.gov	PNL	3J427	N	Y	2015-06-19 05:43:30		2026-01-17 00:11:56.573713
3258	LIAN976	Liang, Yiran	H6342207	Inactive	yiran.liang@pnnl.gov	PNL		N	N	2017-07-28 15:54:35		2018-08-24 00:11:11
2494	WALT906	Walters, Chris	H8414670	Inactive	\N	\N	\N	N	N	2014-06-12 11:59:38	\N	2016-05-14 17:23:53
3379	LAWR296	Lawrence, Kathy	H9765586	Active	kathleen.lawrence@pnnl.gov	PNL		N	Y	2019-10-28 10:26:46		2026-01-31 00:11:56.591356
2103	D3L222	Lin, Chiann-Tso	H5519799	Inactive			3L222	N	N	2003-04-25 00:00:00		\N
2155	D3M460	Li, Fumin	H6271854	Inactive			3M460	N	N	2005-01-27 00:00:00		\N
2011	H1686148	Li, Lingjun	H1686148	Inactive	\N	\N	\N	N	N	2000-08-08 00:00:00		\N
2486	LINA627	Lin, Andy	H9520461	Active	Andy.Lin@pnnl.gov	PNL	\N	Y	Y	2014-03-18 15:44:01		2016-05-14 17:23:53
2098	D3J462	Markillie, Meng	H0069588	Active	meng.markillie@pnnl.gov	PNL	3J462	Y	Y	2003-01-20 00:00:00		2025-02-12 00:11:17.31286
3611	MANS091	Mansoura, Xena	H5739252	Active	xena.mansoura@pnnl.gov	PNL	\N	N	Y	2024-02-12 16:23:03		2025-07-12 00:11:40.850254
3378	LINT908	Lin, Tai-Tu	H2909011	Active	tai-tu.lin@pnnl.gov	PNL		Y	Y	2019-10-22 17:04:02		2019-10-23 00:11:10
3277	LINV931	Lin, Vivian S	H0786122	Active	vivian.lin@pnnl.gov	PNL	\N	Y	Y	2017-12-15 12:59:09		2017-12-16 00:11:16
2458	ASLIPTON	Lipton, Andrew S	H0067788	Active	as.lipton@pnnl.gov	PNL	3J332	Y	Y	2013-06-05 15:32:34	\N	2013-06-07 14:16:32
3302	LIPT286	Lipton, Anna K	H2604905	Inactive	anna.lipton@pnnl.gov	PNL		N	N	2018-06-22 10:27:34		2021-08-17 00:11:12
7	D3J715	Lipton, Mary S	H0065448	Active	mary.lipton@pnnl.gov	PNL	3J715	Y	Y	2000-05-15 00:00:00	\N	\N
2047	D3K914	Littlefield, Kyle A	H0693075	Inactive			3K914	N	N	2001-09-01 00:00:00		\N
3637	LIUH339	Liu, Sophie	H9809339	Active	sophie.liu@pnnl.gov	PNL	\N	Y	Y	2025-02-03 12:58:55.279745		2025-02-04 00:12:08.741065
2122	D3M202	Liu, Tao	H0713970	Active	tao.liu@pnnl.gov	PNL	3M202	Y	Y	2003-09-12 00:00:00		\N
2130	D3M085	Marshall, Matthew J	H9229691	Inactive	matthew.marshall@pnnl.gov	PNL	3M085	N	N	2004-01-01 00:00:00		2018-05-21 00:11:11
3649	LIUS875	Liu, Sijia	H1825875	Active	lucia.liu@pnnl.gov	PNL	\N	N	Y	2025-04-02 12:59:17.179528		2025-09-27 00:12:02.892395
2116	D3M048	Livesay, Eric A	H6958894	Inactive			3M048	N	N	2003-06-20 00:00:00		\N
2291	D3P750	Liyu, Andrey V	H4367450	Active	andrey.liyu@pnnl.gov	PNL	3P750	Y	Y	2009-03-01 00:00:00		\N
2212	H0333525	Loganantharaja, Rasiah	H0333525	Inactive			\N	N	N	2006-07-01 00:00:00		\N
2238	D3P743	Lopez-Ferrer, Dani	H3833917	Inactive			3P743	N	N	2007-02-26 00:00:00		\N
2177	D3M745	Lourette, Natacha M	H6564003	Inactive			3M745	N	N	2005-07-01 00:00:00		\N
2296	D3M514	Luna, Maria	H0439030	Inactive			3M514	N	N	2009-04-01 00:00:00		\N
3380	KHM	Maier, Kurt	H2694697	Active	khm@pnnl.gov	PNL		N	Y	2019-10-28 15:57:02		2026-02-08 00:11:49.156083
2056	D3K884	Luo, Hai	H6024964	Inactive	\N	\N	3K884	N	N	2001-02-28 00:00:00		\N
2136	D3M282	Luo, Quanzhou	H2322242	Inactive			3M282	N	N	2004-05-17 00:00:00		\N
2270	D3X091	Mabrouki, Ridha B	H1335536	Inactive			3X091	N	N	2008-08-01 00:00:00		\N
2347	D3Y054	Liu, Yan	H5513973	Inactive			3Y054	N	N	2010-03-17 14:06:26		2010-03-17 14:06:26
2402	MAHO765	Mahoney, Christine	H6544018	Inactive	Christine.Mahoney@pnnl.gov	PNL	\N	N	N	2012-03-26 16:47:06		2013-09-08 00:11:11
2488	MAIN013	Main-Smith, Joshua C	H2739202	Inactive	\N	\N	\N	N	N	2014-04-18 10:46:47	\N	2014-04-18 10:46:47
2510	MAJI301	Ma, Jian	H2654110	Inactive	jian.ma@pnnl.gov	PNL		N	N	2014-08-19 10:30:37		2016-07-10 00:11:10
3386	MALA722	Maland, Thilmer J	H1759744	Inactive	thilmer.maland@pnnl.gov	PNL		N	N	2019-12-12 14:49:39		2021-08-26 00:11:13
2170	D3M735	Manes, Nathan P	H8460940	Inactive			3M735	N	N	2005-03-14 00:00:00		\N
3401	MANS365	Mans, Douglas M	H1146134	Active	douglas.mans@pnnl.gov	PNL	\N	Y	Y	2020-03-28 05:43:06		2020-03-29 00:11:11
3319	MAHS128	Mahserejian, Shant	H2317418	Active	shant.mahserejian@pnnl.gov	PNL		N	Y	2018-10-18 12:47:41		2025-10-06 00:11:37.925787
2437	D3P533	Marginean, Nelu	H9217660	Inactive	ioan.marginean@pnnl.gov	PNL	3P533	N	N	2013-02-06 13:39:27		2013-10-01 00:11:10
2524	MART019	Martin, Jessica L	H6587019	Inactive	\N	\N	3Y329	N	N	2014-10-08 17:20:10		2016-05-14 17:23:53
2501	BOAR651	Boaro, Amy A	H4263651	Inactive	amy.boaro@pnnl.gov	PNL	\N	N	N	2014-07-08 13:06:20		2016-05-22 00:11:11
3369	LIXI657	Li, Xiaolu	H7827657	Active	xiaolu.li@pnnl.gov	PNL		Y	Y	2019-09-10 11:40:16		2025-12-01 00:11:56.585512
2320	D3Y329	Martin, Jessica L (old)	H6587019_x	Obsolete			3Y329	N	N	2009-09-28 15:57:23		2016-05-14 17:23:53
2096	D3L299	Mayer-Cumblidge, Uljana	H2868050	Inactive			3L299	N	N	2003-01-16 00:00:00		\N
2031	D3K718	Martinovic, Suzana	H0212104	Inactive			3K718	N	N	2001-02-08 00:00:00		\N
2199	D3M420	Masiello, Lisa M	H7185819	Inactive			3M420	N	N	2006-03-01 00:00:00		\N
14	D3K719	Masselon, Christophe D	H4701071	Inactive			3K719	N	N	2001-02-28 00:00:00		\N
2137	D3L368	Miller, Keith D	H1563235	Inactive			3L368	N	N	2004-02-20 00:00:00		\N
3524	MILL565	Miller, Samantha	H7127096	Active	samantha.miller@pnnl.gov	PNL	\N	Y	Y	2022-10-15 05:42:59		2022-10-16 00:11:13
3388	MILL391	Miller, Patricia S	H9120009	Active	patricia.miller@pnnl.gov	PNL		Y	Y	2019-12-31 10:55:00		2022-03-03 00:11:13
2438	MATZ362	Matzke, Melissa M	H8719365	Inactive	Melissa.Matzke@pnnl.gov	PNL	3M362	N	N	2013-02-11 11:25:41	\N	2013-06-16 00:11:10
3540	MAUP214	Maupin, Mark	H4799888	Active	mark.maupin@pnnl.gov	PNL	\N	Y	Y	2023-02-15 14:15:33		2023-02-16 00:11:15
2258	H9507193	Maxwell, Robert A	H9507193	Inactive			\N	N	N	2008-07-09 00:00:00		\N
2118	D3M146	Maxwell, Robert A (old)	H9507193_x	Obsolete	robert.maxwell@pnl.gov		3M146	N	N	2003-07-17 00:00:00		\N
2195	D3P304	Mayampurath, Anoop M	H2054831	Inactive			3P304	N	N	2007-04-12 00:00:00		\N
2277	D3X506	Mezengie, Giorgis I	H1646944	Inactive			3X506	N	N	2009-01-01 00:00:00		\N
2089	D3L323	McCann, Jason M	H2241799	Inactive	jason.mccann@pnl.gov	PNL	3L323	N	N	2002-10-01 00:00:00		\N
3557	MCCL944	McClure, Ryan S	H5156879	Active	Ryan.Mcclure@pnnl.gov	PNL	\N	Y	Y	2023-05-26 05:43:52		2023-05-27 00:11:14
2372	D3X773	Meka, Divakara (Bhuvan)	H3539416	Inactive			3X773	N	N	2010-12-07 11:06:45	\N	2010-12-07 11:06:45
2204	LEEANN	McCue, Lee Ann	H3192192	Active	leeann.mccue@pnnl.gov	PNL	3P170	Y	Y	2006-03-01 00:00:00		\N
2228	D3P620	McDermott, Jason E	H6495299	Active	jason.mcdermott@pnnl.gov	PNL	3P620	Y	Y	2007-03-01 00:00:00		\N
2376	D3X357	Meyer, Kristen M	H8986531	Inactive			3X357	N	N	2011-02-10 16:43:05	\N	2011-02-10 16:43:05
2060	D3L012	Mclean, Jeffrey S	H0194098	Inactive			3L012	N	N	2002-06-01 00:00:00		\N
2172	D3M864	McLean, Peter F	H1341288	Inactive			3M864	N	N	2005-05-06 00:00:00		\N
3539	MCMI200	Mcmillan, Cameron	H8959798	Inactive	cameron.mcmillan@pnnl.gov	PNL	\N	N	N	2023-01-24 16:10:13		2023-06-25 00:11:15
2027	H9904477	Mcmullen, Hannah	H9904477	Inactive			\N	N	N	2001-01-18 00:00:00		\N
3613	MEDR740	Medrano, Irlanda N	H9558351	Active	irlanda.medrano@pnnl.gov	PNL	\N	Y	Y	2024-04-12 10:46:12		2024-04-13 00:11:15
2020	D3K421	Medvick, Patricia A	H0065552	Inactive	Patricia.Medvick@pnl.gov	PNL	3K421	N	N	2002-01-01 00:00:00		\N
3432	MELC802	Melchior, John T	H4137584	Active	john.melchior@pnnl.gov	PNL		Y	Y	2020-11-30 13:36:39		2020-12-01 00:11:11
3549	MELU925	Meluch, Beata J	H8174389	Active	beata.meluch@pnnl.gov	PNL	\N	Y	Y	2023-04-28 16:17:41		2023-04-29 00:11:15
2556	MEND645	Mendoza, Joshua A	H9117938	Active	joshua.mendoza@pnnl.gov	PNL	\N	Y	Y	2015-06-29 14:12:34		2016-08-30 00:11:11
2329	D3Y485	Meng, Da	H3254428	Inactive	Da.Meng@pnnl.gov	PNL	3Y485	N	N	2009-10-29 16:53:21	\N	2009-10-29 16:53:21
2350	MERK000	Merkley, Eric D	H0016053	Active	Eric.Merkley@pnnl.gov	PNL	3Y000	Y	Y	2010-05-03 14:35:53	\N	2013-06-07 14:16:32
2123	D3M234	Metz, Tom	H5667934	Active	thomas.metz@pnnl.gov	PNL	3M234	Y	Y	2004-01-09 00:00:00		\N
2507	WALK989	Walker, Lawrence R	H5131781	Inactive	lawrence.walker@pnnl.gov	PNL	\N	N	N	2014-08-14 11:55:51	\N	2016-10-02 00:11:11
3607	MINS343	Min, Sehong	H5196098	Active	sehong.min@pnnl.gov	PNL	\N	Y	Y	2024-01-22 15:04:07		2024-01-23 00:11:14
2231	D3M840	Miracle, Ann L	H9765962	Active	ann.miracle@pnnl.gov	PNL	3M840	Y	Y	2007-03-01 00:00:00		\N
3368	MITC633	Mitchell, Hugh D	H1090138	Active	Hugh.Mitchell@pnnl.gov	PNL		Y	Y	2019-09-06 11:38:21		2019-09-07 00:11:12
2078	H5423688	Mitchell, Timothy	H5423688	Inactive			\N	N	N	2002-07-22 00:00:00		\N
2509	KARN956	Karnesky, William E	H7487309	Inactive	\N	\N	3P956	N	N	2014-08-19 10:30:19		2016-05-14 17:23:53
3220	MOGH663	Moghieb, Ahmed M	H1491808	Inactive	ahmed.moghieb@pnnl.gov	PNL		N	N	2016-08-26 10:20:25		2019-01-16 00:11:10
2058	H2883313	Mohan, Deepa	H2883313	Inactive	\N	\N	\N	N	N	2002-02-25 00:00:00		\N
2504	RYAD361	Momotok, Lillian	H7346605	Inactive	lillian.momotok@pnnl.gov	PNL		N	N	2014-08-07 15:54:54		2016-08-17 00:11:11
2086	D3L243	Monroe, Matthew E	H5027449	Active	Matthew.Monroe@pnnl.gov	PNL	3L243	Y	Y	2002-10-01 00:00:00		\N
3640	OLIV179	Monteiro, Lummy	H4492179	Active	lummy.monteiro@pnnl.gov	PNL	\N	Y	Y	2025-02-12 09:09:19.86499		2025-02-13 00:11:18.48868
2050	D3K917	Moon, Douglas E	H1426662	Inactive			3K917	N	N	2002-05-01 00:00:00		\N
2220	D3J572	Moore, Priscilla A	H0168200	Inactive			3J572	N	N	2006-08-16 00:00:00		\N
3576	MOOR952	Moore, Natalie (old)	H7832621_x	Obsolete	natalie.moore@pnnl.gov	PNL	\N	N	N	2023-09-06 11:45:32		2024-07-02 00:11:15
3520	MORA748	Moran, James J	H0412109	Active	james.moran@pnnl.gov	PNL	\N	Y	Y	2022-08-31 15:48:36		2022-09-01 00:11:13
3250	D3X748	Moran, James J (old)	H0412109_x	Obsolete	James.Moran@pnnl.gov	PNL	3X748	N	N	2017-04-11 10:39:53	Superseded by username MORA748	2022-08-27 00:11:13
3651	MORE896	Moreno, Abigail	H9221896	Active	abigail.moreno@pnnl.gov	PNL	\N	Y	Y	2025-04-02 14:47:26.835216		2025-04-03 00:11:10.650426
2034	H1314220	Morris, David	H1314220	Inactive	\N	\N	\N	N	N	2001-03-01 00:00:00		\N
3431	MOST780	Mostoller, Kaitlyn E	H7291998	Inactive	kaitlyn.mostoller@pnnl.gov	PNL		N	N	2020-11-02 12:46:14		2021-05-15 00:11:13
2281	MSDADMIN	MSDADMIN	H0000000	Active	\N	\N	\N	Y	N	2009-01-01 00:00:00		\N
2321	MTSProc	MTSProcessor	MTSProc	Active	\N	PNL	\N	Y	N	2009-09-30 11:20:07		2009-09-30 11:20:07
2405	MUDE619	Mudenda, Lwiindi	H9173619	Inactive	\N		\N	N	N	2012-05-08 10:20:23	\N	2013-04-03 00:11:11
3623	MOOR621	Moore, Natalie	H7832621	Active	n.moore@pnnl.gov	PNL	\N	N	Y	2024-07-02 13:42:39		2025-08-02 00:12:03.025599
3255	MUNO094	Munoz, Nathalie	H3892763	Active	nathalie.munozmunoz@pnnl.gov	PNL		Y	Y	2017-06-09 13:01:03		2017-06-14 00:11:16
2431	NAND211	Nandy, Kajal	H9392475	Inactive			\N	N	N	2013-01-09 17:15:39		2013-03-25 20:28:14
2473	NAND837	Nandhikonda, Premchendar	H2266176	Inactive	Premchendar.Nandhikonda@pnnl.gov	PNL	\N	N	N	2013-08-14 09:48:16	\N	2016-06-22 00:11:10
2341	NAKA439	Nakayasu, Ernesto S	H2052326	Active	ernesto.nakayasu@pnnl.gov	PNL	3Y439	Y	Y	2010-02-05 14:38:36		2016-05-14 17:23:53
3588	NAVA102	Navarro, Annabelle	H1188595	Active	annabelle.navarro@pnnl.gov	PNL	\N	Y	Y	2023-10-21 05:43:54		2023-10-22 00:11:15
2091	D3L123	Negash, Sewite	H8717682	Inactive			3L123	N	N	2002-12-19 00:00:00		\N
2564	NELS329	Nelson, Bill C	H6319272	Active	William.Nelson@pnnl.gov	PNL	\N	Y	Y	2015-08-19 11:37:18		2025-02-28 00:11:34.656694
2016	D3K897	Nelson, Kristina T	H4336985	Inactive			3K897	N	N	2001-01-24 00:00:00		\N
2475	MURP913	Murphree, Taylor A	H2003724	Inactive	Taylor.Murphree@pnnl.gov	PNL	\N	N	N	2013-09-04 14:48:14		2017-09-17 00:11:12
2513	PARK322	Park, Jungkap	H7073261	Inactive	jungkap.park@pnnl.gov	\N	\N	N	N	2014-09-02 15:59:15		2016-05-14 17:23:53
3232	NGUY534	Nguyen, Son N	H4638172	Inactive	son.nguyen@pnnl.gov	PNL		N	N	2016-10-20 14:05:42		2017-08-15 00:11:11
2307	NGUY678	Nguyen, Tran	H0328678	Inactive			H0328678	N	N	2009-07-01 00:00:00		2009-07-01 00:00:00
2085	D3K875	Nicora, Carrie D	H4081279	Active	carrie.nicora@pnnl.gov	PNL	3K875	Y	Y	2002-10-16 00:00:00		\N
3344	NIEL007	Nielson, Felicity F	H2470489	Inactive	felicity.nielson@pnnl.gov	PNL		N	N	2019-03-11 21:50:44		2020-10-16 00:11:10
3608	NIER454	Nierves, Lorenz	H6810029	Active	lorenz.nierves@pnnl.gov	PNL	\N	Y	Y	2024-02-02 18:39:12		2024-02-04 00:11:15
3286	D3H419	Nichols, Jennifer L	H0013166	Active	Jennifer.Nichols@pnnl.gov	PNL	3H419	Y	Y	2018-02-14 14:34:34		2018-02-16 11:06:37
3543	NIET785	Nieto, Nubia	H7447256	Active	nubia.nieto-pereira@pnnl.gov	PNL	\N	Y	Y	2023-03-28 10:52:04		2023-03-29 00:11:15
2213	D3P581	Ni, Shelly	H4342965	Inactive	shelly.ni@pnl.gov	PNL	3P581	N	N	2006-07-13 00:00:00		\N
3547	NITK592	Nitka, Tara A	H0259502	Active	tara.nitka@pnnl.gov	PNL	\N	Y	Y	2023-04-20 11:05:05		2024-01-19 00:11:14
2516	ZHAN122	Zhang, Xing	H3291609	Inactive	\N	\N	\N	N	N	2014-09-10 09:41:59	\N	2016-05-14 17:23:53
2160	D3M580	Norbeck, Angela	H8827318	Active	angela.norbeck@pnnl.gov	PNL	3M580	Y	Y	2004-12-16 00:00:00	\N	2020-04-29 00:11:11
2520	D3Y441	Norheim, Randy	H6759179	Active	Randolph.Norheim@pnnl.gov	PNL	3Y441	Y	Y	2014-09-23 16:27:25		2016-05-14 17:23:53
2519	WHIT040	White III, Richard A	H3742888	Inactive	richard.white@pnnl.gov	PNL	\N	N	N	2014-09-23 10:31:12		2017-08-28 00:11:11
3631	NWOS017	Nwosu, Andi	H2295017	Active	andikan.nwosu@pnnl.gov	PNL	\N	Y	Y	2024-09-05 09:53:32.318363		2024-09-06 00:11:57.139464
3568	OBER845	Obermiller, Samantha A	H4527432	Active	samantha.obermiller@pnnl.gov	PNL	\N	Y	Y	2023-07-12 17:18:51		2023-07-13 00:11:14
3300	OBRY739	O'Bryon, Isabelle	H3946799	Active	isabelle.obryon@pnnl.gov	PNL		Y	Y	2018-06-19 10:21:14		2018-06-20 00:11:11
2153	H4315886	Ocampo, Maria-Victoria	H4315886	Inactive			\N	N	N	2004-07-19 00:00:00		\N
18	D3E154	Moore, Ron J	H0063423	Active	ronald.moore@pnnl.gov	PNL	3E154	Y	Y	2000-07-05 00:00:00		2020-03-12 00:11:10
2525	KTM	Mueller, Karl	H8706363	Active	Karl.Mueller@pnnl.gov	PNL	\N	N	Y	2014-10-16 05:49:11		2025-06-02 00:11:50.952058
2184	OEHMEN	Oehmen, Chris S	H5937237	Active	chris.oehmen@pnnl.gov	PNL	3M130	Y	Y	2005-10-01 00:00:00		2014-01-22 00:11:11
2054	D3K187	Pounds, Joel G	H9235511	Inactive	Joel.Pounds@pnnl.gov	PNL	3K187	N	N	2002-09-01 00:00:00		2013-11-01 00:11:11
3306	OKEE558	O'Keeffe, Amanda	H1838819	Active	amanda.okeeffe@pnnl.gov	PNL		Y	Y	2018-06-29 10:31:28		2018-06-30 00:11:10
3475	OLAR646	Olarte, Mariefel V	H6455484	Active	Mariefel.Olarte@pnnl.gov	PNL		Y	Y	2021-09-28 11:59:33		2021-09-29 00:11:13
2046	D3H534	Olson, Heather M	H0014968	Active	heather.olson@pnnl.gov	PNL	3H534	Y	Y	2001-08-21 00:00:00	previously Heather Brewer	2020-07-16 00:11:10
3259	OROZ595	Orozco, Leonardo R	H3418834	Inactive	leonardo.orozco@pnnl.gov	PNL		N	N	2017-08-01 11:00:17		2021-07-01 00:11:13
2081	D3L171	Page, Jason S	H2841343	Inactive			3L171	N	N	2002-10-01 00:00:00		\N
2173	D3M957	Orton, Danny	H2061546	Active	daniel.orton@pnnl.gov	PNL	3M957	Y	Y	2005-05-24 00:00:00	\N	\N
2546	OXFO639	Oxford, Kristie L	H4368546	Active	kristie.oxford@pnnl.gov	PNL	\N	Y	Y	2015-03-26 16:36:40		2016-05-14 17:23:53
2093	D3L100	Pinchuk, Grigoriy E	H9354970	Inactive			3L100	N	N	2003-01-01 00:00:00		\N
3634	PALA002	Palazzo, Teresa A	H7917002	Active	teresa.palazzo@pnnl.gov	PNL	\N	Y	Y	2024-09-18 21:05:58.706858		2024-09-19 00:11:11.200814
3333	PALA965	Palazzo, Teresa A (Old)	H7917002_x	Obsolete	teresa.palazzo@pnnl.gov	PNL		Y	N	2018-12-06 16:37:56		2024-09-16 00:12:07.85037
2012	D3L378	Panisko, Ellen A	H0038327	Inactive	ellen.panisko@pnnl.gov	PNL	3L378	N	N	2001-03-02 00:00:00		2019-07-13 00:11:10
2042	D3M710	Panther, David J	H7014374	Inactive	david.panther@pnl.gov	PNL	3M710	N	N	2001-06-15 00:00:00		\N
2205	D3J767	Petersen, Catherine E	H0060188	Inactive			3J767	N	N	2006-04-26 00:00:00		\N
5	D3J658	Pasa Tolic, Ljiljana	H0108544	Active	ljiljana.pasatolic@pnnl.gov	PNL	3J658	Y	Y	2001-05-11 00:00:00		\N
3382	PATE212	Patel, Kaizad F	H5757794	Active	kaizad.patel@pnnl.gov	PNL		Y	Y	2019-11-08 13:09:16		2019-11-09 00:11:11
2104	H8903381	Patwardhan, Anil	H8903381	Inactive			\N	N	N	2003-04-17 00:00:00		\N
2446	PAUR784	Paurus, Vanessa L	H6107710	Active	vanessa.paurus@pnnl.gov	PNL		Y	Y	2013-05-20 14:34:14		2017-03-21 00:11:11
3225	PERK564	Perkins, Korina L	H7831982	Inactive	korina.perkins@pnnl.gov	PNL		N	N	2016-09-27 18:15:05		2018-08-25 00:11:10
2196	D3P201	Peters, Jonathan S	H4924161	Inactive			3P201	N	N	2006-02-01 00:00:00		\N
2330	D3Y424	Onsongo, Getiria I	H9581963	Inactive			3Y424	N	N	2009-12-09 16:22:07		2009-12-09 16:22:07
2211	D3P639	Petritis, Brianne O	H9741279	Inactive			3P639	N	N	2006-06-23 00:00:00		\N
2064	D3L140	Petritis, Konstantinos	H9287628	Inactive			3L140	N	N	2002-07-01 00:00:00		\N
2166	D3M629	Petyuk, Vladislav A	H1755802	Active	vladislav.petyuk@pnnl.gov	PNL	3M629	Y	Y	2004-12-20 00:00:00		\N
2323	D3Y453	Piehowski, Paul D	H9749477	Active	Paul.Piehowski@pnnl.gov	PNL	3Y453	Y	Y	2009-10-07 09:55:08	\N	2009-10-07 09:55:08
3200	D3P118	Pike, Bill	H9068357	Active	william.pike@pnnl.gov	PNL	3P118	Y	Y	2016-05-15 05:44:05		2025-03-12 00:11:46.9122
2363	PAYN535	Payne, Sam	H3438993	Inactive	Samuel.Payne@pnnl.gov	PNL	\N	N	N	2010-09-28 10:30:57	\N	2018-08-01 00:11:10
2366	PAKD451	Pak, Dan J	H3479795	Inactive			\N	N	N	2010-10-01 13:32:24		2010-10-01 13:32:24
2377	PARK142	Park, Jea H	H4623588	Inactive	Jea.Park@pnnl.gov	PNL	\N	N	N	2011-02-25 09:50:26		2013-10-25 00:11:11
3442	POLL509	Pollard, Emily	H7179509	Inactive	emily.pollard@pnnl.gov	PNL		N	N	2021-02-24 09:24:26		2021-02-26 00:11:13
2214	D3P519	Polpitiya, Ashoka D	H2272293	Inactive	ashoka.polpitiya@pnl.gov		3P519	N	N	2006-10-01 00:00:00		\N
2540	POMR587	Pomraning, Kyle R	H2171895	Active	Kyle.Pomraning@pnnl.gov	PNL	\N	Y	Y	2014-12-17 14:07:10		2016-05-14 17:23:53
3628	pgdms	PostgresAutoUser	H09090912	Inactive		\N	\N	Y	N	2024-08-07 12:43:32.110438		2024-08-07 12:43:32.110438
2422	PAUL442	Paul, Aaron M	H3484940	Inactive	Aaron.Paul@pnnl.gov	PNL	\N	N	N	2012-10-16 15:12:38	\N	2013-05-10 00:11:11
2497	OVER421	Overall, Christopher C	H9163155	Inactive	Christopher.Overall@pnnl.gov	\N	\N	N	N	2014-06-20 14:47:23		2016-05-14 17:23:53
3571	PETE532	Petersen, William	H1157025	Active	billy.petersen@pnnl.gov	PNL	\N	N	Y	2023-08-23 15:16:46		2026-01-05 00:11:56.571987
3439	POSS982	Posso, Camilo	H3594241	Active	camilo.posso@pnnl.gov	PNL		Y	Y	2021-02-22 13:13:51	Camilo	2021-04-24 00:11:12
3414	POWE385	Powell, Samantha M	H0903739	Active	samantha.powell@pnnl.gov	PNL		Y	Y	2020-06-30 10:40:38		2020-07-01 00:11:10
3	D3A777	Powers, Mary E	H0091580	Inactive			3A777	N	N	2000-04-01 00:00:00		\N
3118	PRAB119	Prabhakaran, Aneesh	H7470058	Inactive	Aneesh.Prabhakaran@pnnl.gov	PNL		N	N	2016-04-18 16:03:41		2016-05-14 17:23:53
2035	D3H640	Romine, Margaret F	H0016703	Inactive	margie.romine@pnnl.gov	PNL	3H640	N	N	2001-03-01 00:00:00		2017-01-22 00:11:11
2332	Proteomics	Proteomics progrunner account	H0000000	Inactive	\N	\N	\N	N	N	2009-12-18 10:42:53		2009-12-18 10:42:53
2305	D3Y311	Rutledge, Alex C	H2663603	Inactive			3Y311	N	N	2009-07-01 00:00:00		2009-07-01 00:00:00
2159	D3M578	Purvine, Samuel O	H0656743	Active	samuel.purvine@pnnl.gov	PNL	3M578	Y	Y	2005-11-17 00:00:00		\N
3443	D3K933	Qafoku, Odeta	H5451216	Active	Odeta.Qafoku@pnnl.gov	PNL	3K933	Y	Y	2021-03-02 05:42:59		2021-03-03 00:11:13
2069	D3L164	Qian, Weijun	H9649398	Active	Weijun.Qian@pnnl.gov	PNL	3L164	Y	Y	2002-06-17 00:00:00	\N	\N
2013	D3K892	Rakov, Vsevolod	H4359800	Inactive	\N	\N	3K892	N	N	2001-01-01 00:00:00		\N
2353	ROBI034	Robinson, Aaron C	H5140499	Inactive	Aaron.Robinson@pnnl.gov	PNL	3Y034	N	N	2010-06-16 13:26:48		2013-06-07 14:16:32
2225	D3P718	Ranslem, Duncan B	H6081888	Inactive			3P718	N	N	2005-06-30 00:00:00		\N
2260	D3X253	Rao, Jaya V	H8542028	Inactive			3X253	N	N	2008-06-11 00:00:00		\N
2278	D3P020	Reardon, Catherine L	H4771636	Inactive			3P020	N	N	2009-01-01 00:00:00		\N
3494	REED094	Reed, David M	H8623488	Active	David.Reed@pnnl.gov	PNL	\N	Y	Y	2022-02-17 13:18:09		2022-02-18 00:11:13
2378	QUYI572	Qu, Yi	H2544539	Inactive	Yi.Qu@pnnl.gov	PNL	\N	N	N	2011-03-09 15:19:00	\N	2016-05-14 17:23:53
2029	H0909090	Retrofit	H0909090	Active	\N	\N	\N	Y	N	2000-06-02 00:00:00		\N
2412	RIVE302	Rivera Ramos, Eugenio	H6162835	Inactive	Eugenio.RiveraRamos@pnnl.gov	PNL	\N	N	N	2012-06-22 09:39:53	\N	2016-05-14 17:23:53
3542	REYN595	Reynolds, Emily	H1118062	Active	emily.reynolds@pnnl.gov	PNL	\N	Y	Y	2023-03-24 11:27:25		2023-03-25 00:11:14
3397	RICH401	Richardson, Rachel E	H6501422	Active	rachel.richardson@pnnl.gov	PNL		Y	Y	2020-03-09 15:53:23		2020-03-10 00:11:11
2163	D3M534	Rinker, Torri E	H8625645	Inactive			3M534	N	N	2004-10-08 00:00:00		\N
2534	RIVA755	Rivas-Ubach, Albert	H7406755	Inactive	albert.rivas.ubach@pnnl.gov	PNL		N	N	2014-12-02 15:05:37		2021-12-03 00:11:13
2193	D3P100	Robinson, Robby	H1998155	Active	errol.robinson@pnnl.gov	PNL	3P100	Y	Y	2006-01-19 00:00:00	\N	\N
3541	D3X847	Rodas, Mildred J	H1439185	Active	mildred.rodas@pnnl.gov	PNL	3X847	Y	Y	2023-03-01 05:43:53		2023-03-02 00:11:14
3514	RODD406	Rodda, Kabrena E	H8085752	Active	kabrena.rodda@pnnl.gov	PNL	\N	Y	Y	2022-08-04 05:42:59		2022-08-05 00:11:13
2448	RODR657	Rodriguez, Larissa M	H0246653	Inactive	Larissa.Rodriguez@pnnl.gov	PNL	\N	N	N	2013-05-29 14:50:56		2016-05-14 17:23:53
2045	H1308634	Rodriguez, Nestor	H1308634	Inactive	\N	\N	\N	N	N	2001-07-01 00:00:00		\N
2151	D3M968	Rommereim, Leah M	H6343444	Inactive	leah.rommereim@pnl.gov	PNL	3M968	N	N	2004-06-01 00:00:00		\N
2209	D3M968_x	Rommereim, Leah M (duplicate)	H6343444_x	Obsolete	leah.rommereim@pnl.gov	\N	3M968_x	N	N	2006-07-01 00:00:00		\N
2453	D35727	Roesijadi, Guri	H5845211	Inactive	g.roesijadi@pnnl.gov	PNL	35727	N	N	2013-06-05 15:32:34		2016-05-14 17:23:53
3457	REMP858	Rempfert, Kaitlin R	H9627744	Active	kaitlin.rempfert@pnnl.gov	PNL		N	Y	2021-06-22 12:50:58		2025-06-07 00:11:56.292331
3485	ROSS200	Ross, Dylan H	H4382440	Active	dylan.ross@pnnl.gov	PNL		Y	Y	2021-12-01 20:36:34		2021-12-02 00:11:13
3530	ROGE082	Rogers, Mickey	H9008735	Active	michaela.rogers@pnnl.gov	PNL	\N	N	Y	2022-11-11 16:00:20		2025-09-02 00:11:36.587411
2482	RAYD032	Ray, Debjit	H8033299	Inactive	debjit.ray@pnnl.gov	PNL	\N	N	N	2014-02-21 14:07:39	\N	2016-05-14 17:23:53
2381	SADL861	Sadler, Natalie C	H7817730	Active	Natalie.Sadler@pnnl.gov	PNL	\N	Y	Y	2011-05-06 08:55:13		2011-05-06 08:55:13
2495	REXU651	Rexus, Tyler M	H8171613	Inactive	\N	\N	\N	N	N	2014-06-12 15:45:13	\N	2016-05-14 17:23:53
3455	PROZ201	Prozapas, Victoria	H5833401	Inactive	victoria.prozapas@pnnl.gov	PNL		N	N	2021-05-20 12:05:58		2025-11-14 00:11:44.514159
2265	D3P993	Salazar, Courtney L	H4959655	Inactive			3P993	N	N	2008-07-01 00:00:00		\N
2415	SANC376	Sanchez, Octavio	H1883393	Inactive	Octavio.Sanchez@pnnl.gov	PNL	\N	N	N	2012-07-13 14:08:14	\N	2016-05-14 17:23:53
2253	D3M480	Sandoval, John D	H0063360	Inactive			3M480	N	N	2007-10-01 00:00:00	\N	\N
2379	SANF417	Sanford, Jim	H2707729	Active	James.Sanford@pnnl.gov	PNL		Y	Y	2011-03-23 14:04:37		2020-08-07 00:11:10
2154	D3K303	Saripalli, Ratna	H5941649	Inactive			3K303	N	N	2005-01-20 00:00:00		\N
3462	SARK224	Sarkar, Soumyadeep	H4587519	Active	soumyadeep.sarkar@pnnl.gov	PNL		Y	Y	2021-07-01 08:34:54	Sam Sarkar	2021-07-02 00:11:14
2512	D3G632	Scheibe, Tim	H0000979	Active	tim.scheibe@pnnl.gov	PNL	3G632	Y	Y	2014-08-28 16:32:54		2020-02-29 00:11:10
2197	D3M765	Schepmoes, Athena A	H4004394	Active	athena.schepmoes@pnnl.gov	PNL	3M765	Y	Y	2006-02-22 00:00:00		\N
2044	H0412915	Scherpelz, Jeffery	H0412915	Inactive	jeffrey.scherpelz@pnl.gov		\N	N	N	2001-07-01 00:00:00		\N
2125	D3L301	Shi, Liang	H1319942	Inactive	Liang.Shi@pnnl.gov	PNL	3L301	N	N	2003-11-10 00:00:00		2016-06-25 00:11:11
2234	D3M174	Scholten, Hans CM	H0961387	Inactive			3M174	N	N	2007-12-06 00:00:00		\N
3407	SCHU231	Schultz, Kate J	H5581719	Active	katherine.schultz@pnnl.gov	PNL		Y	Y	2020-04-02 13:49:10		2020-04-03 00:11:11
2036	D3E081	Schur, Anne	H0062191	Inactive	anne.schur@pnl.gov	PNL	3E081	N	N	2001-03-01 00:00:00		\N
2259	D3M293	Shah, Anuj	H3173368	Inactive			3M293	N	N	2008-06-01 00:00:00		\N
2284	D3X720	Slysz, Gordon W	H3579591	Inactive	Gordon.Slysz@pnnl.gov	PNL	3X720	N	N	2009-01-26 00:00:00		2013-10-31 00:11:10
3440	SAGE980	Sagendorf, Tyler	H2519059	Active	tyler.sagendorf@pnnl.gov	PNL		N	Y	2021-02-22 13:14:18		2025-10-09 00:11:37.934232
2297	D3K970	Shutthanandan, Janani I	H7600330	Inactive			3K970	N	N	2009-04-01 00:00:00		\N
2310	D3X801	Sinha, Malavika	H6259295	Inactive			3X801	N	N	2009-07-21 00:00:00		2009-07-21 00:00:00
2206	D3P545	Shanghavi, Bhairavi	H9294037	Inactive			3P545	N	N	2006-08-01 00:00:00		\N
2152	D3M328	Sharma, Seema	H3672404	Inactive	seema.sharma@pnl.gov	PNL	3M328	N	N	2004-06-14 00:00:00		\N
2477	SHAW921	Shaw, Jared B	H3469762	Inactive	Jared.Shaw@pnnl.gov	PNL		N	N	2013-11-07 15:48:04		2020-01-07 00:11:10
2210	D3P559	Shaw, Jason	H6914656	Inactive	\N	\N	3P559	N	N	2006-07-01 00:00:00		\N
2222	D3H691	Shaw, Wendy J	H0017545	Active	Wendy.Shaw@pnnl.gov	PNL	3H691	Y	Y	2006-09-01 00:00:00		\N
2014	D3K296	Shen, Yufeng	H8508255	Inactive	Yufeng.Shen@pnnl.gov	PNL	3K296	N	N	2002-03-07 00:00:00		2018-03-16 00:11:11
2312	D3M035	Shvartsburg, Alexandre A	H2709738	Inactive	alexandre.shvartsburg@pnnl.gov	PNL	3M035	N	N	2009-08-01 00:00:00		2016-05-14 17:23:53
3624	SHIJ939	Shi, Jessie	H5609939	Active	jessie.shi@pnnl.gov	PNL	\N	Y	Y	2024-07-12 12:05:49		2024-07-13 00:11:15
2087	H3386618	Shin, Dae-Ho	H3386618	Inactive			\N	N	N	2002-09-23 00:00:00		\N
2367	SHTU029	Shi, Tujin	H7698654	Active	Tujin.Shi@pnnl.gov	PNL	\N	Y	Y	2010-10-13 13:58:39	\N	2010-10-13 13:58:39
2138	D3K050	Shukla, Anil K	H3068026	Inactive	Anil.Shukla@pnnl.gov	PNL	3K050	N	N	2004-04-18 00:00:00		2019-01-01 00:11:11
3486	SARK546	Sarkar, Snigdha	H5468486	Active	snigdha.sarkar@pnnl.gov	PNL		N	Y	2021-12-13 13:10:17		2025-11-30 00:11:56.58478
2080	D3K934	Siegel, Robert W	H2088570	Inactive			3K934	N	N	2002-08-06 00:00:00		\N
3572	SIMO603	Simonsen, Caroline G	H4856509	Active	caroline.simonsen@pnnl.gov	PNL	\N	Y	Y	2023-08-23 15:17:05		2023-08-24 00:11:14
2131	D3M010	Simpson, David	H4492003	Inactive	\N	\N	3M010	N	N	2004-01-26 00:00:00		\N
3456	SING247	Singh, Rajhans	H3360943	Inactive	rajhans.singh@pnnl.gov	PNL		N	N	2021-06-04 10:18:49		2021-08-18 00:11:13
2132	D3L052	Smallwood, Heather S	H4932431	Inactive			3L052	N	N	2004-03-01 00:00:00		\N
2383	D3P423	Sego, Landon H	H1872157	Inactive	landon.sego@pnnl.gov	PNL	3P423	N	N	2011-06-02 14:14:51	\N	2017-10-22 00:11:16
2119	D3L370	Smiley, Stephen P	H3974455	Inactive			3L370	N	N	2003-09-01 00:00:00		\N
2526	ROSN264	Rosnow, Josh	H2731439	Inactive	joshua.rosnow@pnnl.gov	PNL	\N	N	N	2014-10-23 12:49:57		2018-01-02 00:11:10
3523	SHOR444	Short, Nora	H9403842	Active	nora.short@pnnl.gov	PNL	\N	N	Y	2022-09-28 12:35:00		2025-05-17 00:11:57.799593
2322	D3K381	Shi, Yan	H2271798	Active	Yan.Shi@pnnl.gov	PNL	3K381	N	Y	2009-10-02 14:56:36		2026-01-31 00:11:56.591356
2406	SMIT376	Smith, Don F	H8149376	Inactive			\N	N	N	2012-05-10 14:29:34	\N	2012-05-10 14:29:34
2370	SMIT739	Smith, Don F (old)	H8149376_x	Obsolete			\N	N	N	2010-11-08 10:55:14		2010-11-08 10:55:14
3265	SMIT436	Smith, Francesca B	H6695882	Inactive	francesca.smith@pnnl.gov	PNL		N	N	2017-09-26 10:17:59		2018-09-08 00:11:10
2474	D3X108	Smith, Jordan N	H3196365	Active	jordan.smith@pnnl.gov	PNL	3X108	Y	Y	2013-08-23 05:43:25		2013-08-24 00:11:11
3381	SMIT684	Smith, Montana L	H9682684	Active	montana.smith@pnnl.gov	PNL		Y	Y	2019-11-04 16:00:34		2019-11-05 00:11:10
3355	SMIT516	Smith, Mylissia R	H4933205	Active	mylissia.smith@pnnl.gov	PNL		Y	Y	2019-05-29 14:41:56		2019-05-30 00:11:11
2024	D3J426	Swanson, Ken	H0106665	Inactive			3J426	N	N	2002-01-01 00:00:00		\N
2227	D3J928	Sofia, Heidi J	H0197455	Inactive			3J928	N	N	2007-02-01 00:00:00		\N
3570	SMIT548	Smith, Saige	H3668732	Active	saige.smith@pnnl.gov	PNL	\N	Y	Y	2023-08-23 15:16:28		2023-08-24 00:11:14
2423	SONT915	Sontag, Ryan L	H8879850	Inactive	Ryan.Sontag@pnnl.gov	PNL		N	N	2012-10-19 09:10:36		2021-06-26 00:11:13
2237	H3688203	Sowell, Sarah	H3688203	Inactive			\N	N	N	2007-03-01 00:00:00		\N
2416	SPEN369	Spence, Christine N	H1254736	Inactive	Christine.Spence@pnnl.gov	PNL		N	N	2012-07-26 11:23:33		2012-07-26 11:23:33
2053	D38405	Springer, David L	H0068408	Inactive			38405	N	N	2002-07-03 00:00:00		\N
2308	H0190421	Stanley, Jeffrey	H0190421	Inactive			\N	N	N	2009-07-01 00:00:00		2009-07-01 00:00:00
2100	D3L041	Squier, Thomas C	H3191061	Inactive	Thomas.Squier@pnnl.gov	PNL	3L041	N	N	2003-03-01 00:00:00		2013-10-01 00:11:10
2183	D3P154	Sorensen, Christina M	H8745396	Inactive	christina.sorensen@pnnl.gov	PNL	3P154	N	N	2007-02-01 00:00:00		2016-05-14 17:23:53
2018	D3A112	Steele, Kerry D	H0000989	Inactive			3A112	N	N	2002-01-01 00:00:00		\N
2403	STEG815	Stegen, James C	H8395809	Active	James.Stegen@pnnl.gov	PNL	\N	Y	Y	2012-03-28 16:08:42		2012-03-28 16:08:42
2245	D3K446	Sowa, Marianne B	H2710959	Inactive	marianne.sowa@pnnl.gov	PNL	3K446	N	N	2007-04-01 00:00:00		2016-05-14 17:23:53
3287	STEP343	Stephens, Dalton J	H8473879	Inactive	dalton.stephens@pnnl.gov	PNL		N	N	2018-02-14 14:34:48		2018-09-29 00:11:11
2344	D3X792	Stolyar, Sergey	H1045702	Inactive			3X792	N	N	2010-03-10 12:10:06		2010-03-10 12:10:06
3610	STON832	Stone, Bram WG	H0908937	Active	bram.stone@pnnl.gov	PNL	\N	Y	Y	2024-02-08 15:34:01		2024-02-09 00:11:15
2268	D3X057	Stordeur, Carrie	H5986018	Inactive	\N	\N	3X057	N	N	2008-08-01 00:00:00		\N
3272	STRA269	Stratton, Kelly G	H9499708	Active	kelly.stratton@pnnl.gov	PNL	3X269	Y	Y	2017-10-30 11:27:38		2017-10-31 00:11:11
2015	D3K895	Strittmatter, Eric F	H2459181	Inactive			3K895	N	N	2001-07-27 00:00:00		\N
2359	SUDI633	Su, Dian	H0681060	Inactive			\N	N	N	2010-06-30 11:19:07		2010-06-30 11:19:07
3233	SUMA767	Sumangala Kumari, Jayasree	H1476856	Inactive	jayasree.sumangalakumari@pnnl.gov	PNL		N	N	2016-11-29 17:07:20		2019-03-01 00:11:10
2071	D3K271	Tang, Keqi	H0104660	Inactive	Keqi.Tang@pnnl.gov	PNL	3K271	N	N	2002-06-24 00:00:00		2018-07-07 00:11:11
3400	TATE589	Tate, Kylee L	H9359693	Active	kylee.tate@pnnl.gov	PNL		Y	Y	2020-03-17 10:33:00		2020-03-18 00:11:12
2267	D3X487	Taverner, Tom	H8354877	Inactive			3X487	N	N	2008-08-01 00:00:00		\N
2254	D3X487_x	Taverner, Tom (old)	H8354877_x	Obsolete	Thomas.Taverner@pnl.gov	PNL	3X487_x	N	N	2007-10-01 00:00:00		\N
2407	TAMU213	Tamura, Kaipo Y	H3650174	Inactive			\N	N	N	2012-05-15 14:31:49	\N	2012-05-15 14:31:49
2409	D3X982	Sun, Xuefei	H4877834	Inactive			3X982	N	N	2012-06-04 13:32:27		2012-06-04 13:32:27
2461	D3M177	Stenoien, David L	H2259755	Inactive	david.stenoien@pnnl.gov	PNL	3M177	N	N	2013-06-05 15:32:34		2017-03-09 00:11:11
3509	STOH153	Stohel, Izabel L	H1461249	Active	izabel.stohel@pnnl.gov	PNL	\N	N	Y	2022-06-21 10:44:26		2025-05-01 00:11:41.025483
3243	SWEN778	Swensen, Adam	H5706634	Active	adam.swensen@pnnl.gov	PNL	\N	N	Y	2017-02-06 10:48:29		2025-07-04 00:11:32.342948
2468	DAVI857	Stevenson, Christina	H0103702	Active	christina.stevenson@pnnl.gov	PNL	\N	N	Y	2013-06-19 16:17:46	\N	2025-05-12 00:11:52.440054
3312	D3K830	Sullivan, Kelly	H4591498	Active	Kelly.Sullivan@pnnl.gov	PNL	3K830	N	Y	2018-08-01 05:43:07		2026-02-07 00:11:49.180666
2019	D3K742	Tolmachev, Aleksey V	H1580800	Inactive	tolmachev@pnnl.gov	PNL	3K742	N	N	2002-04-01 00:00:00		2016-05-14 17:23:53
2483	D3M492	Teeguarden, Justin G	H7536498	Active	jt@pnnl.gov	PNL	3M492	Y	Y	2014-02-27 05:43:19		2014-02-28 00:11:13
3529	REID218	Tennyson, Deseree J	H7878199	Active	deseree.tennyson@pnnl.gov	PNL	\N	Y	Y	2022-11-10 14:27:42		2022-12-01 00:11:13
2314	D3Y315	Teuton, Jeremy R	H6689390	Active	Jeremy.Teuton@pnnl.gov	PNL	3Y315	Y	Y	2009-08-10 00:00:00		2009-08-10 00:00:00
2484	TFAI986	Tfaily, Malak M	H0747963	Inactive	malak.tfaily@pnnl.gov	PNL		N	N	2014-03-05 11:33:38		2018-08-15 00:11:11
2226	D3P601	Thevuthasan, Sindhu	H0530099	Inactive			3P601	N	N	2007-02-01 00:00:00		\N
2157	D3M306	Trimble, Nathan G	H3503866	Inactive			3M306	N	N	2005-04-01 00:00:00		\N
2309	THIE309	Thiel, Cedric N	H4550502	Inactive	Cedric.Thiel@pnnl.gov	PNL	3Y309	N	N	2009-07-15 00:00:00	\N	2013-06-18 13:57:57
2548	THOM040	Thompson, Allison M	H3068005	Inactive	allison.thompson@pnnl.gov	PNL	3Y040	N	N	2015-04-17 09:55:27		2021-10-23 00:11:13
2243	D3H047	Thrall, Brian D	H0007364	Inactive	brian.thrall@pnnl.gov	PNL	3H047	N	N	2007-04-01 00:00:00		2021-09-01 00:11:13
2255	D3M133	Thronas, Aaron	H8023025	Active	aaron.thronas@pnnl.gov	PNL	3M133	Y	Y	2007-10-01 00:00:00		2020-02-25 00:11:11
3646	TING477	Tingey, Scott M	H0001477	Active	scott.tingey@pnnl.gov	PNL	3G666	Y	Y	2025-03-04 17:23:39.901456		2025-03-05 00:11:40.199761
3294	D3G666	Tingey, Scott M (old)	H0001477_x	Obsolete	scott.tingey@pnnl.gov	PNL	3G666	Y	N	2018-04-24 05:43:07		2025-03-03 00:11:38.085503
8	D3J920	Tolic, Nikola	H0833766	Active	Nikola.Tolic@pnnl.gov	PNL	3J920	Y	Y	2004-06-16 00:00:00		\N
3477	TOWN743	Townsend, Andrew T	H1030321	Active	andrew.townsend@pnnl.gov	PNL		Y	Y	2021-10-01 10:40:13		2021-10-02 00:11:14
3214	TOYO995	Toyoda, Jason G	H2108313	Active	Jason.Toyoda@pnnl.gov	PNL		Y	Y	2016-07-13 12:53:33		2016-07-14 00:11:11
3357	TREJ462	Trejo, Jesse B	H2342375	Active	jesse.trejo@pnnl.gov	PNL		Y	Y	2019-06-20 14:52:33		2019-06-21 00:11:11
2272	D3X490	Tian, Michael	H9078154	Inactive			3X490	N	N	2009-01-01 00:00:00		\N
2395	TORR047	Torres, Elizabeth A	H8994946	Inactive			\N	N	N	2011-11-28 13:52:43	\N	2011-11-28 13:52:43
3652	VAND407	Vandyk, Heidi	H8887407	Active	heidi.vandyk@pnnl.gov	PNL	\N	Y	Y	2025-04-02 14:57:23.665866		2025-04-03 00:11:10.650426
2413	TOVA318	Tovar, Lupita	H7660149	Inactive	Guadalupe.Tovar@pnnl.gov	PNL	\N	N	N	2012-06-22 09:40:26		2013-05-02 00:11:11
2404	TURS875	Turse, Josh E	H4293875	Inactive			3P214	N	N	2012-05-08 10:15:54		2013-06-07 14:16:32
2194	D3P214	Turse, Josh E (old)	H4293875_x	Obsolete			3P214_x	N	N	2006-02-10 00:00:00		\N
2102	D39322	Udseth, Harold R	H0083037	Inactive			39322	N	N	2003-03-01 00:00:00		\N
2171	E5164939	Umar, Arzu	H5164939	Inactive	arzu.umar@pnl.gov		\N	N	N	2005-09-14 00:00:00		\N
3342	UWUG950	Uwugiaren, Naomi	H7746950	Inactive	naomi.uwugiaren@pnnl.gov	PNL		N	N	2019-03-03 10:12:11		2020-01-16 00:11:12
3447	VAND942	Vandergrift, Gregory W	H2752338	Active	gregory.vandergrift@pnnl.gov	PNL		Y	Y	2021-03-12 15:34:58		2021-03-13 00:11:13
3511	VANF381	Van Fossen, Elise	H3539899	Active	elise.vanfossen@pnnl.gov	PNL	\N	Y	Y	2022-07-12 12:41:30		2023-03-31 00:11:14
2496	VASD002	Vasdekis, Andreas E	H5516202	Inactive	\N	\N	\N	Y	N	2014-06-17 05:43:19		2023-09-29 00:11:15
2114	D3L340	VanSchoiack, Lindsey R	H7567064	Inactive			3L340	N	N	2003-04-22 00:00:00		\N
3513	D3Y092	Varga, Tamas	H7888336	Active	Tamas.Varga@pnnl.gov	PNL	3Y092	Y	Y	2022-07-21 14:08:52		2022-07-22 00:11:14
3490	VARI341	Varikoti, Rohith A	H0420168	Active	Rohith.Varikoti@pnnl.gov	PNL		Y	Y	2022-01-26 11:10:00		2022-01-27 00:11:13
2527	BEAC437	Beach, Sierra S	H9629249	Inactive	\N	\N	\N	N	N	2014-10-23 14:30:39		2016-05-14 17:23:53
2181	H4341501	Vasilenko, Alexander	H4341501	Inactive	alexander.vasilenko@pnl.gov		\N	N	N	2005-09-22 00:00:00		\N
11	D3K130	Veenstra, Tim D	H4245735	Inactive	\N	\N	3K130	N	N	2001-01-01 00:00:00		\N
3546	HALE078	Vega, Lauren B	H5487785	Active	lauren.vega@pnnl.gov	PNL	\N	Y	Y	2023-04-11 16:13:59		2023-04-12 00:11:15
2530	XUCH460	Xu, Chengdong	H1513028	Inactive	\N	\N	\N	N	N	2014-11-05 11:24:09	Jason	2016-05-14 17:23:53
2536	CASE159	Casey, Cameron P	H3847389	Inactive	cameron.casey@pnnl.gov	PNL	\N	N	N	2014-12-08 10:44:07		2017-06-02 00:11:11
3559	TURN432	Turner, Matthew W	H9635302	Active	matthew.turner@pnnl.gov	PNL	\N	Y	Y	2023-06-09 11:43:37		2023-06-10 00:11:14
3501	USHA979	Ushakumary, Mereena George	H9349946	Active	mereena.ushakumary@pnnl.gov	PNL	\N	N	Y	2022-04-01 08:37:10		2026-01-31 00:11:56.591356
3574	TOPP501	Topping, Maisie E	H7133504	Inactive	maisie.topping@pnnl.gov	PNL	\N	N	N	2023-08-24 14:28:55		2025-05-31 00:11:48.868159
3207	VELI278	Velickovic, Dusan	H9837498	Active	dusan.velickovic@pnnl.gov	PNL		Y	Y	2016-06-10 16:50:31		2017-11-12 00:11:18
3445	VELI973	Velickovic, Marija	H0634030	Active	marija.velickovic@pnnl.gov	PNL		Y	Y	2021-03-12 15:17:13		2021-03-13 00:11:13
2149	D3M043	Verma, Seema	H0383988	Inactive			3M043	N	N	2004-06-03 00:00:00		\N
2161	D3K157	Victry, Kristin D	H0268563	Active	kristin.victry@pnnl.gov	PNL	3K157	Y	Y	2005-05-11 00:00:00		\N
2299	D3X887	Wilkins, Michael J	H2360508	Inactive	Michael.Wilkins@pnnl.gov	PNL	3X887	N	N	2009-05-01 00:00:00		2013-08-21 00:11:11
2083	D3L147	Vilkov, Andrey N	H1205007	Inactive			3L147	N	N	2002-10-14 00:00:00		\N
3309	METOOSON	Vo, Eric A	H4390130	Inactive	eric.vo@pnnl.gov	PNL		N	N	2018-07-19 10:46:03		2019-08-31 00:11:12
2319	D3Y399	Wang, Yuexi	H8886967	Inactive			3Y399	N	N	2009-09-23 00:00:00		2009-09-23 00:00:00
2554	D3H664	Wahl, Karen L	H0017074	Active	karen.wahl@pnnl.gov	PNL	3H664	Y	Y	2015-06-19 17:27:40		2016-05-14 17:23:53
3488	RAMI995	Walker, Jennifer	H6494192	Active	jennifer.walker@pnnl.gov	PNL		Y	Y	2022-01-25 16:03:38		2022-10-19 00:11:13
2025	D3J346	Walker, Kevin G	H0072907	Inactive			3J346	N	N	2002-01-01 00:00:00		\N
2090	D3J566	Weber, Thomas	H0568800	Active	Thomas.Weber@pnnl.gov	PNL	3J566	N	Y	2002-10-16 00:00:00		2025-10-03 00:12:09.186527
2436	WANG017	Wang, Chenchen	H1874017	Inactive	Chenchen.Wang@pnnl.gov	PNL	\N	N	N	2013-01-31 15:39:52		2013-01-31 15:39:52
2142	D3M321	Wang, Haixing H	H7231930	Inactive	haixing.wang@pnl.gov	PNL	3M321	N	N	2004-04-15 00:00:00		\N
2275	D3X493	Wang, Helen	H1363383	Inactive			3X493	N	N	2009-01-01 00:00:00		\N
2549	WANG690	Wang, Heng	H9633864	Inactive	heng.wang@pnnl.gov	PNL		N	N	2015-05-12 15:54:59		2016-05-14 17:23:53
2515	WANG426	Wang, Hui	H0666090	Inactive	hui.wang@pnnl.gov	PNL	\N	N	N	2014-09-05 18:25:51	\N	2017-05-21 00:11:17
2360	WIED688	Wiedner, Susan D	H9620661	Inactive	Susan.Wiedner@pnnl.gov	PNL	3Y688	N	N	2010-08-06 11:03:34		2013-10-01 00:11:10
3496	D3Y420	Wang (Richland), Wei	H5343920	Active	Wei.Wang@pnnl.gov	PNL	3Y420	Y	Y	2022-02-17 13:30:04		2025-01-29 00:12:02.36636
2201	D3M851	Wang, Ting	H2497990	Inactive			3M851	N	N	2006-03-01 00:00:00		\N
3279	WANG349	Wang, Xi	H0140349	Inactive	xi.wang@pnnl.gov	PNL		N	N	2017-12-21 14:10:13		2020-01-03 00:11:12
2373	WANG575	Wang, Lu	H0755010	Inactive			\N	N	N	2010-12-10 14:26:16	\N	2010-12-10 14:26:16
3299	WARD753	Ward, Nicholas D	H1524313	Active	nicholas.ward@pnnl.gov	PNL		Y	Y	2018-06-19 05:43:08		2018-06-20 00:11:11
2120	D3M191	Warner, Cynthia L	H4283866	Active	cynthia.warner@pnnl.gov	PNL	3M191	Y	Y	2003-09-25 00:00:00		\N
3436	WASH418	Washburn, Rick	H5422699	Active	rick.washburn@pnnl.gov	PNL	\N	Y	Y	2021-01-08 05:42:58		2021-01-09 00:11:13
2476	WASH198	Washton, Nancy M	H9555964	Active	Nancy.Washton@pnnl.gov	PNL	\N	Y	Y	2013-10-22 05:43:04		2013-10-23 00:11:11
2452	D3M552	Waters, Katrina M	H3561076	Active	katrina.waters@pnnl.gov	PNL	3M552	Y	Y	2013-06-05 15:01:15		2013-06-05 15:02:04
2394	WESC032	Wescott, Rachael E	H3106591	Inactive			\N	N	N	2011-11-28 13:51:25		2011-11-28 13:51:25
2433	WEBB446	Webb, Ian K	H6232625	Inactive	Ian.Webb@pnnl.gov	PNL		N	N	2013-01-23 14:00:14		2018-07-06 00:11:11
2256	BOBBIEJO	Webb-Robertson, Bobbie-Jo M	H8282056	Active	bobbie-jo.webb-robertson@pnnl.gov	PNL	3L349	Y	Y	2007-10-01 00:00:00		2013-06-07 14:16:32
2240	D3G716	Weitz, Karl K	H0002214	Active	karl.weitz@pnnl.gov	PNL	3G716	Y	Y	2007-02-16 00:00:00	\N	\N
2465	D3H496	Whattam, Kevin M	H0014389	Inactive	whattam@pnnl.gov	PNL	3H496	N	N	2013-06-07 14:44:48		2021-05-19 00:11:13
2167	D3L348	White, Amanda M	H8616901	Active	Amanda.White@pnnl.gov	PNL	3L348	Y	Y	2005-01-01 00:00:00		\N
2095	D3K397	Wiley, Steven	H2208930	Active	Steven.Wiley@pnnl.gov	PNL	3K397	Y	Y	2003-01-01 00:00:00		2025-01-18 00:11:50.45757
2480	WILK011	Wilkins, Christopher S	H8992052	Inactive	christopher.wilkins@pnnl.gov	PNL	\N	N	N	2014-01-22 14:35:28	\N	2017-09-14 00:11:11
3251	WILL968	Williams, Sarai	H7980264	Active	sarah.williams@pnnl.gov	PNL	\N	Y	Y	2017-04-12 16:43:26		2022-11-11 00:11:13
3298	WANG679	Wang, Yang	H0892388	Inactive	yang.wang2018@pnnl.gov	PNL		N	N	2018-06-11 14:52:47		2020-12-12 00:11:13
3174	WHID494	Whidbey, Chris	H5417736	Inactive	christopher.whidbey@pnnl.gov	PNL	\N	N	N	2016-05-06 10:27:35		2018-08-25 00:11:10
3614	WARB426	Warburton, Evan	H8490877	Active	evan.warburton@pnnl.gov	PNL	\N	N	Y	2024-04-24 10:05:11		2025-05-31 00:11:48.868159
2052	D39749	Zangar, Richard C	H0074371	Inactive	Richard.Zangar@pnnl.gov	PNL	39749	N	N	2002-02-01 00:00:00		2016-05-14 17:23:53
2545	WILS630	Wilson, Ryan E	H6074823	Active	ryan.wilson@pnnl.gov	PNL	\N	Y	Y	2015-03-18 10:30:47		2016-05-14 17:23:53
2061	D3K903	Wingerd, Mark A	H3575123	Inactive			3K903	N	N	2002-03-13 00:00:00		\N
3391	WINK808	Winkler, Tanya E	H4103510	Active	tanya.winkler@pnnl.gov	PNL		Y	Y	2020-01-09 10:45:27		2020-01-10 00:11:12
2126	D3M161	Yang, Feng	H2557323	Inactive	feng.yang@pnnl.gov	PNL	3M161	N	N	2003-11-06 00:00:00	\N	2013-10-01 00:11:10
2176	H9312950	Wolfe, Nicole	H9312950	Inactive			\N	N	N	2005-07-01 00:00:00		\N
3627	D3K716	Wolf, Katherine E	H5098728	Active	katherine.wolf@pnnl.gov	PNL	3K716	Y	Y	2024-07-31 14:44:55		2024-08-01 00:11:15
2229	WUSI754	Wu, Si	H0890816	Inactive	Si.Wu@pnnl.gov	PNL	3P754	N	N	2007-03-01 00:00:00	\N	2016-05-14 17:23:53
3626	WOOD347	Wood, Nicholas S	H2164347	Active	nicholas.wood@pnnl.gov	PNL	\N	Y	Y	2024-07-15 15:07:04		2024-07-15 15:07:19
3301	WOOD694	Wood, Nicholas S (old)	H2164347_x	Obsolete	nicholas.wood@pnnl.gov	PNL		N	N	2018-06-19 10:23:28		2024-07-15 00:11:16
3492	D3M240	Woodring, Mitch L	H0948538	Active	mitchell.woodring@pnnl.gov	PNL	3M240	Y	Y	2022-02-10 05:43:03		2025-03-27 00:12:03.135879
3384	WOOJ830	Woo, Jongmin Jacob	H4762847	Inactive	jongmin.woo@pnnl.gov	PNL		N	N	2019-11-13 13:34:40		2021-06-01 00:11:13
3622	WOOL552	Wooldridge, Rowan S	H9724536	Active	rowan.wooldridge@pnnl.gov	PNL	\N	Y	Y	2024-06-17 13:27:39		2024-06-18 00:11:15
2287	D3X516	Wright, Aaron T	H4938028	Inactive	Aaron.Wright@pnnl.gov	PNL	3X516	N	N	2009-02-01 00:00:00		2022-09-16 00:11:12
2538	RWright	Wright, Ryan P	H8512765	Active	Ryan.Wright@pnnl.gov	PNL	3L048	Y	Y	2014-12-15 09:40:24		2016-05-14 17:23:53
3424	WRIG752	Wright, Stephanie A	H6989887	Inactive	swright@pnnl.gov	PNL		N	N	2020-09-17 09:24:21		2023-10-04 00:11:15
2134	D3M332	Wu, Lianming	H6437996	Inactive			3M332	N	N	2004-06-10 00:00:00		\N
2021	D3K641	Wunschel, David S	H0399230	Active	David.Wunschel@pnnl.gov	PNL	3K641	Y	Y	2002-03-11 00:00:00		\N
2065	D3K008	Wunschel, Sharon C	H4489883	Inactive			3K008	N	N	2002-09-01 00:00:00		\N
3213	WUQI320	Wu, Qinghao	H0498624	Inactive	qinghao.wu@pnnl.gov	PNL		N	N	2016-06-27 10:20:11		2019-01-05 00:11:11
3478	WURU978	Wu, Ruonan	H4385580	Active	ruonan.wu@pnnl.gov	PNL		Y	Y	2021-10-11 09:19:33		2025-07-02 00:11:29.997545
2017	H2437513	Xu, Jingdong	H2437513	Inactive	\N	\N	\N	N	N	2002-01-01 00:00:00		\N
3493	XIAN237	Xiang, Piliang	H7217905	Active	piliang.xiang@pnnl.gov	PNL		N	Y	2022-02-10 11:47:01		2025-10-31 00:11:44.524599
2290	D3M011	Xiong, Yijia	H8380907	Inactive	yijia.xiong@pnnl.gov	PNL	3M011	N	N	2009-03-01 00:00:00		2016-05-14 17:23:53
3505	XUZH297	Xu, Zhangyang	H4686297	Active	zhangyang.xu@pnnl.gov	PNL	\N	Y	Y	2022-05-24 11:16:31		2022-05-25 00:11:13
2169	D3M546	Yan, Ping	H2483656	Inactive			3M546	N	N	2005-01-19 00:00:00		\N
2326	D3Y467	Xie, Fang	H6796602	Inactive			3Y467	N	N	2009-10-20 17:37:50	\N	2009-10-20 17:37:50
3216	YILI577	Yi, Lian	H5975238	Inactive	lian.yi@pnnl.gov	PNL		N	N	2016-07-28 15:04:00	Yilian	2018-09-20 00:11:11
2348	D3Y293	Yin, Jian	H2425589	Inactive	Jian.Yin@pnnl.gov	PNL	3Y293	N	N	2010-03-17 14:06:53		2017-05-05 00:11:11
2040	D3K905	Yu, Li-Rong	H7986999	Inactive	\N	\N	3K905	N	N	2001-04-05 00:00:00		\N
2506	D38308	Zachara, John M	H0066671	Inactive	john.zachara@pnnl.gov	PNL	38308	N	N	2014-08-09 05:59:49		2020-01-01 00:11:11
2429	WUCH879	Wu, Chaochao	H6876879	Inactive	Chaochao.Wu@pnnl.gov	PNL	\N	N	N	2013-01-08 10:55:33	Changed from WUCH437 to WUCH879 in June 2015	2016-05-14 17:23:53
2439	XUZH561	Xu, Zhe	H6450878	Inactive	Zhe.Xu@pnnl.gov	PNL	\N	N	N	2013-02-14 13:59:32		2016-08-06 00:11:11
3452	ZEMA927	Zemaitis, Kevin	H6643602	Active	kevin.zemaitis@pnnl.gov	PNL		Y	Y	2021-04-19 13:11:27		2021-04-20 00:11:13
2517	WIND604	Winder, Eric M	H7898633	Inactive	Eric.Winder@pnnl.gov	PNL	\N	N	N	2014-09-14 05:43:25		2019-08-31 00:11:12
3564	YANG900	Yang, Bella	H0871733	Active	isabella.yang@pnnl.gov	PNL	\N	N	Y	2023-06-22 09:10:03		2025-05-01 00:11:41.025483
3453	WINA135	Winans, Natalie	H5955853	Active	natalie.winans@pnnl.gov	PNL		N	Y	2021-05-03 11:26:53		2025-11-25 00:11:56.582182
3502	YOUY793	You, Youngki	H6487545	Active	youngki.you@pnnl.gov	PNL	\N	N	Y	2022-04-01 08:38:18		2026-02-22 00:11:49.157468
2250	D3P524	Zhang, Angela J	H6325682	Inactive			3P524	N	N	2007-06-01 00:00:00		\N
3615	ZENG993	Zeng, Ting	H9994993	Active	ting.zeng@pnnl.gov	PNL	\N	N	Y	2024-04-26 11:02:45		2025-07-12 00:11:40.850254
3317	ZHAN007	Zhang, Pengfei	H5486007	Inactive	pengfei.zhang@pnnl.gov	PNL		N	N	2018-08-23 11:06:16		2018-11-14 00:11:10
3266	ZHAN344	Zhang, Tong	H0443425	Active	tong.zhang@pnnl.gov	PNL	\N	Y	Y	2017-10-10 16:09:13		2022-06-27 00:11:13
2145	D3L308	Zhang, Weiwen	H8070106	Inactive			3L308	N	N	2004-07-01 00:00:00		\N
2712	ZHEN038	Zheng, Xueyun	H4616844	Active	xueyun.zheng@pnnl.gov	PNL		Y	Y	2015-11-24 15:21:48		2019-12-02 00:11:10
2518	ZHAN367	Zhang, Xinyu	H1385945	Inactive	\N	\N	\N	N	N	2014-09-17 15:42:22	\N	2016-05-14 17:23:53
2082	H1179950	Zhang, Rui	H1179950	Inactive			3L314	N	N	2003-01-09 00:00:00		2013-06-07 14:16:32
3525	AMER322	Vandergriend, Alicia	H0903845	Active	alicia.amerson@pnnl.gov	PNL	\N	N	Y	2022-11-02 05:42:58		2025-10-09 00:11:37.934232
2135	D3M272	Zimmer, Jennifer S	H5354907	Inactive			3M272	N	N	2004-02-16 00:00:00		\N
3468	ZIMM824	Zimmerman, Amy E	H8306689	Active	amy.zimmerman@pnnl.gov	PNL		Y	Y	2021-09-01 13:31:51		2023-12-18 00:11:16
2217	D3P704	Zink, Erika M	H1902241	Inactive	erika.zink@pnnl.gov	PNL	3P704	N	N	2006-07-27 00:00:00		2019-01-23 00:11:10
3230	ZUCK016	Zucker, Jeremy D	H0782427	Active	jeremy.zucker@pnnl.gov	PNL	\N	Y	Y	2016-10-06 15:34:26		2016-10-07 00:11:11
3653	D3M752	Golovich, Elizabeth C	H4170407	Active	elizabeth.golovich@pnnl.gov	PNL	3M752	Y	Y	2025-04-14 05:42:54.869681		2025-04-15 00:11:23.818498
3274	WANG328	Wang, Yi-Ting	H7211204	Inactive	yi-ting.wang@pnnl.gov	PNL	\N	N	N	2017-10-31 10:22:36		2023-03-16 00:11:15
2541	FARR225	Farris, Yuliya	H0365225	Inactive	Yuliya.Farris@pnnl.gov	PNL		N	N	2015-01-28 16:29:33		2016-05-14 17:23:53
3280	ZEGE355	Zegeye, Elias	H4240355	Inactive	elias.zegeye@pnnl.gov	PNL		N	N	2018-01-04 11:22:49		2022-06-21 00:11:13
3534	GLUT168	Gluth, Austin	H8192371	Inactive	austin.gluth@wsu.edu	PNL	\N	N	N	2022-12-01 11:43:20		2025-01-02 00:11:33.932713
2026	D35877	Smith, Richard D	H0028375	Inactive	dick.smith@pnnl.gov	PNL	35877	N	N	2002-02-25 00:00:00		2024-02-04 00:11:15
2049	D3K256	Varnum, Susan	H0104370	Inactive	susan.varnum@pnnl.gov	PNL	3K256	N	N	2001-09-06 00:00:00		2025-03-12 00:11:46.9122
2066	D3J685	Jarman, Kristin H	H6347500	Inactive	Kristin.Jarman@pnnl.gov	PNL	3J685	N	N	2002-09-01 00:00:00		2021-11-16 00:11:13
2075	D3K821	Rodland, Karin D	H6966460	Inactive	Karin.Rodland@pnnl.gov	PNL	3K821	N	N	2003-02-11 00:00:00		2023-06-01 00:11:14
2133	D3M196	Sacksteder, Colette A	H2241100	Inactive	colette.sacksteder@pnnl.gov	PNL	3M196	N	N	2004-03-12 00:00:00		2024-10-26 00:11:51.003557
2449	PROS259	Prost, Spencer A	H4202195	Inactive	Spencer.Prost@pnnl.gov	PNL	\N	N	N	2013-06-03 12:51:59		2024-09-07 00:11:58.2079
2464	D3A603	Ozanich, Rich M	H0100056	Inactive	richard.ozanich@pnnl.gov	PNL	3A603	N	N	2013-06-07 14:44:48		2023-10-01 00:11:15
2490	D3K684	Orr, Galya	H6948149	Inactive	Galya.Orr@pnnl.gov	PNL	3K684	N	N	2014-05-06 05:43:22		2023-06-01 00:11:14
2492	D3E782	Hess, Nancy J	H0074391	Inactive	nancy.hess@pnnl.gov	PNL	3E782	N	N	2014-05-31 05:44:03		2022-10-01 00:11:13
2499	D3K305	Dohnalkova, Alice	H8068178	Inactive	Alice.Dohnalkova@pnnl.gov	PNL	3K305	N	N	2014-06-27 05:45:36		2023-08-04 00:11:14
2508	ZHOU351	Zhou, Mowei	H5308633	Inactive	mowei.zhou@pnnl.gov	PNL		N	N	2014-08-15 13:42:28		2023-06-13 00:11:15
2528	JANS146	Jansson, Janet K	H6271535	Inactive	janet.jansson@pnnl.gov	PNL	\N	N	N	2014-11-04 05:43:54		2023-06-01 00:11:14
2542	D3G911	Campbell, Allison A	H0005192	Inactive	allison.campbell@pnnl.gov	PNL	3G911	N	N	2015-01-31 05:45:29		2021-03-13 00:11:13
2711	WOJC044	Wojcik, Roza	H4120307	Inactive	roza.wojcik@pnnl.gov	PNL		N	N	2015-11-24 14:43:47		2023-04-06 00:11:14
2804	STAN070	Stanfill, Bryan A	H6779254	Inactive	bryan.stanfill@pnnl.gov	PNL	\N	N	N	2016-01-07 15:18:18	\N	2019-11-02 00:11:10
2834	JANS178	Jansson, Chris	H1830646	Inactive	georg.jansson@pnnl.gov	PNL	\N	N	N	2016-01-21 13:55:02	\N	2022-01-01 00:11:14
3199	D3M951	Kreuzer, Helen W	H2173850	Inactive	helen.kreuzer@pnnl.gov	PNL	3M951	N	N	2016-05-15 05:44:05		2023-02-11 00:11:14
3201	RRENSLOW	Renslow, Ryan S	H9754953	Inactive	Ryan.Renslow@pnnl.gov	PNL	\N	N	N	2016-05-15 05:44:05		2022-05-27 00:11:13
3211	BROW015	Brown, Joseph M	H3505558	Inactive	joseph.brown@pnnl.gov	PNL	\N	N	N	2016-06-14 14:22:13		2018-11-03 00:11:11
3218	ZHUY570	Zhu, Ying	H0684083	Inactive	ying.zhu@pnnl.gov	PNL		N	N	2016-08-23 10:08:22		2022-10-15 00:11:13
2185	D3P156	Zhang, Qibin	H8658334	Inactive	qibin.zhang@pnnl.gov	PNL	3P156	N	N	2005-10-17 00:00:00		2016-05-14 17:23:53
2252	D3X016	Zhang, Xu	H4239109	Inactive			3X016	N	N	2007-10-24 00:00:00		\N
2186	D3L282	Zhao, Rui	H0925321	Active	Rui.Zhao@pnnl.gov	PNL	3L282	N	Y	2005-10-19 00:00:00		2025-05-01 00:11:41.025483
3215	KOBO523	Kobold, Mark A	H8796804	Inactive	Markus.Kobold@pnnl.gov	PNL	\N	N	N	2016-07-19 12:20:16	\N	2020-06-13 00:11:11
3228	STOD153	Stoddard, Ethan G	H7812474	Inactive	ethan.stoddard@pnnl.gov	PNL	\N	N	N	2016-10-06 13:50:35		2018-09-01 00:11:11
3238	SCHI688	Schimelfenig, Colby E	H4784931	Inactive	colby.schimelfenig@pnnl.gov	PNL	\N	N	N	2016-12-15 13:59:40		2019-03-01 00:11:10
3242	NUNE558	Nunez, Jamie	H9438862	Inactive	jamie.nunez@pnnl.gov	PNL		N	N	2017-02-03 10:18:05	Jamie Dunn	2022-09-17 00:11:13
3247	RAMO756	Ramos-Hunter, Susan J	H2365594	Inactive	susan.ramos-hunter@pnnl.gov	PNL	\N	N	N	2017-03-10 12:27:29		2019-07-06 00:11:10
3248	BRAN716	Brandvold, Kristoffer R	H7462479	Inactive	kristoffer.brandvold@pnnl.gov	PNL	\N	N	N	2017-03-10 12:32:52		2022-07-30 00:11:13
3256	EATO377	Eaton, Arielle M	H7579891	Inactive	arielle.eaton@pnnl.gov	PNL	\N	N	N	2017-06-14 14:33:12		2021-02-09 00:11:13
3262	VOLK088	Volk, Regan F	H0219916	Inactive	regan.volk@pnnl.gov	PNL	\N	N	N	2017-08-03 10:05:39		2019-05-18 00:11:11
3263	NAGY240	Nagy, Gabe	H5384051	Inactive	gavril.nagy@pnnl.gov	PNL		N	N	2017-08-29 15:48:25		2020-06-13 00:11:11
3264	LASK512	Laskin, Julia	H7381512	Inactive	julia.laskin@pnnl.gov	PNL	\N	N	N	2017-09-12 12:08:25		2020-12-24 00:11:13
3267	LIAI339	Li, Ailin	H3368330	Inactive	ailin.li@pnnl.gov	PNL	\N	N	N	2017-10-10 16:09:32		2020-09-20 00:11:11
3270	ZHAO078	Zhao, Qian	H9891850	Inactive	qian.zhao@pnnl.gov	PNL	\N	N	N	2017-10-24 14:51:42		2024-12-21 00:11:20.80125
3273	TSAI327	Tsai, CF	H3124617	Inactive	chia-feng.tsai@pnnl.gov	PNL		N	N	2017-10-31 10:22:21	Chia-Feng Tsai	2023-03-16 00:11:15
3281	CADY159	Cady, Sherry L	H6686481	Inactive	Sherry.Cady@pnnl.gov	PNL	\N	N	N	2018-01-10 05:43:08		2021-01-01 00:11:13
3285	LEEJ792	Lee, Ju Yeon	H0533792	Inactive	juyeon.lee@pnnl.gov	PNL		N	N	2018-02-05 15:46:43		2020-01-01 00:11:11
3289	D3K736	Magnuson, Jon K	H0857265	Inactive	Jon.Magnuson@pnnl.gov	PNL	3K736	N	N	2018-03-23 05:43:07		2023-10-03 00:11:15
3291	MOON622	Moon, Jamie S	H3436267	Inactive	jamie.moon@pnnl.gov	PNL	\N	N	N	2018-04-03 17:23:30		2020-10-03 00:11:11
3292	PETE496	Peterson, Matthew J	H1319149	Inactive	matthew.peterson@pnnl.gov	PNL	\N	N	N	2018-04-16 10:00:21		2019-06-14 00:11:11
3296	WINS350	Tucker, Abigail E	H5775416	Inactive	Abigail.Tucker@pnnl.gov	PNL		N	N	2018-05-23 10:15:59		2021-10-23 00:11:13
3297	COLO636	Colon, Christian	H6219728	Inactive	christian.colon@pnnl.gov	PNL		N	N	2018-06-08 11:35:02		2019-11-28 00:11:11
3303	BRAC832	Bracken, Carter C	H9982532	Inactive	carter.bracken@pnnl.gov	PNL		N	N	2018-06-22 10:28:11		2024-02-10 00:11:15
3308	NOVI385	El Khoury, Irina V	H9951642	Inactive	irina.elKhoury@pnnl.gov	PNL	\N	N	N	2018-07-17 05:43:07		2024-08-03 00:11:15
3310	SCHU684	Martin, Kendall D	H0050098	Inactive	kendall.martin@pnnl.gov	PNL		N	N	2018-07-26 12:58:38	Previously Kendall Schultz	2021-09-04 00:11:13
3311	COLB804	Colby, Sean	H7001914	Inactive	Sean.Colby@pnnl.gov	PNL		N	N	2018-07-26 14:53:38		2025-02-02 00:12:06.622151
3313	STAR042	Starke, Robert F	H7716985	Inactive	robert.starke@pnnl.gov	PNL		N	N	2018-08-02 10:08:16		2018-10-01 00:11:10
3314	COLE140	Cole, Jesse	H3360140	Inactive	Jessica.Cole@pnnl.gov	PNL		N	N	2018-08-16 17:46:44		2019-01-18 00:11:11
3316	VEGH378	Veghte, Daniel P	H4168132	Inactive	daniel.veghte@pnnl.gov	PNL		N	N	2018-08-17 11:09:25		2018-11-17 00:11:12
3318	VILB764	Vilbert, Avery C	H2374004	Inactive	avery.vilbert@pnnl.gov	PNL		N	N	2018-10-02 11:58:25		2020-07-25 00:11:11
3320	DIDO959	DiDonato, Nicole	H4460113	Inactive	Nicole.Didonato@pnnl.gov	PNL		N	N	2018-10-25 19:34:10		2024-03-05 00:11:15
3323	BOIT795	Boiteau, Rene M	H8466795	Inactive	rene.boiteau@pnnl.gov	PNL		N	N	2018-10-29 14:37:00	E-mail originally r.boiteau@pnnl.gov, then username BOIT511 was created in September 2019, then in January 2020 the active username switched back to BOIT795 and e-mail updated to rene.boiteau@pnnl.gov	2023-09-07 00:11:15
3325	OGDE923	Ogden, Aaron J	H4335477	Inactive	aaron.ogden@pnnl.gov	PNL		N	N	2018-11-08 12:45:58		2022-01-02 00:11:14
3328	D3C103	Bolton Jr, Harvey	H0031095	Inactive	harvey.bolton@pnnl.gov	PNL	3C103	N	N	2018-11-21 05:43:06		2020-02-02 00:11:11
3334	LIUW983	Liu, Weijing	H3836158	Inactive	weijing.liu@pnnl.gov	PNL		N	N	2018-12-18 11:43:40		2019-11-03 00:11:12
3337	YEYI917	Ye, Yinyin	H4827727	Inactive	yinyin.ye@pnnl.gov	PNL		N	N	2019-01-18 11:12:11		2021-01-01 00:11:13
3339	DANN850	Danna, Vincent G	H9467051	Inactive	vincent.danna@pnnl.gov	PNL		N	N	2019-02-07 14:19:50		2022-08-30 00:11:13
3341	CONA951	Conant, Christopher R	H4255975	Inactive	christopher.conant@pnnl.gov	PNL		N	N	2019-02-21 14:10:39		2021-10-14 00:11:15
3343	MAYR071	Mayr, Hannah E	H8062502	Inactive	hannah.mayr@pnnl.gov	PNL		N	N	2019-03-11 21:49:39		2020-09-01 00:11:11
3350	WONG564	Wong, Allison R	H2567115	Inactive	allison.wong@pnnl.gov	PNL		N	N	2019-04-15 16:24:26		2020-05-23 00:11:10
3351	LUKO115	Lukowski, Jessica K	H9417492	Inactive	jessica.lukowski@pnnl.gov	PNL		N	N	2019-04-19 15:55:47		2022-03-18 00:11:13
3352	STEI060	Steiger, Andrea K	H4711984	Inactive	andrea.steiger@pnnl.gov	PNL		N	N	2019-04-30 15:18:21		2022-06-25 00:11:13
3353	SENG514	Sengupta, Aditi	H6214469	Inactive	aditi.sengupta@pnnl.gov	PNL		N	N	2019-05-13 12:44:20		2024-10-26 00:11:51.003557
3364	MILL648	Miller, Carson J	H3033185	Inactive	carson.miller@pnnl.gov	PNL		N	N	2019-08-22 10:57:49		2020-09-05 00:11:11
3365	LOMA230	Lomas Jr, Gerard X	H7715286	Inactive	gerard.lomas@pnnl.gov	PNL		N	N	2019-08-23 15:50:11		2022-08-03 00:11:12
3375	GUPT903	Gupta, Khushboo	H3188543	Inactive	khushboo.gupta@pnnl.gov	PNL		N	N	2019-10-14 15:26:57		2021-04-17 00:11:13
3377	BOWM074	Bowman, Maggie	H3600074	Inactive	maggie.bowman@pnnl.gov	PNL		N	N	2019-10-18 14:34:41	Margaret.Bowman@colorado.edu and maggie.bowman6@gmail.com; previously margaret.bowman@pnnl.gov	2023-06-10 00:11:14
3383	TAYL915	Taylor, Mike J	H1499248	Inactive	michael.taylor@pnnl.gov	PNL		N	N	2019-11-13 10:23:54		2022-10-22 00:11:13
3385	YOUN792	Young, Robert P	H2956917	Inactive	robert.young@pnnl.gov	PNL	903792	N	N	2019-12-06 16:25:04		2024-10-26 00:11:51.003557
3387	WANG942	Wang, Juan	H2239548	Inactive	juan.wang@pnnl.gov	PNL	905942	N	N	2019-12-17 16:50:32		2022-04-30 00:11:13
3393	REYE112	Reyes, Brandon C	H5370845	Inactive	brandon.reyes@pnnl.gov	PNL		N	N	2020-01-31 15:18:51	Has remote desktop access to Protoappsold	2020-12-02 00:11:11
3395	GRAH126	Graham, Katherine A	H5314261	Inactive	katherine.graham@pnnl.gov	PNL		N	N	2020-02-10 10:58:13	Katie	2023-07-28 00:11:14
3398	DOLL260	Doll, Charles	H9077111	Inactive	Charles.Doll@pnnl.gov	PNL		N	N	2020-03-16 13:50:32		2025-03-17 00:11:52.521538
3399	WEBB124	Webber, Lucas C	H1365720	Inactive	lucas.webber@pnnl.gov	PNL		N	N	2020-03-16 16:05:09		2022-06-18 00:11:13
3402	GAIT871	Gaither, Kari A	H7670827	Inactive	kari.gaither@pnnl.gov	PNL	3K871	N	N	2020-04-02 10:05:42		2023-02-01 00:11:13
3404	BLUM443	Blumer, Madison R	H3606192	Inactive	madison.blumer@pnnl.gov	PNL		N	N	2020-04-02 13:00:17		2023-08-26 00:11:15
3406	MCGR397	McGrady, Monee Y	H4136060	Inactive	monee.mcgrady@pnnl.gov	PNL		N	N	2020-04-02 13:43:48		2021-02-13 00:11:12
3408	BEND914	Bender, Grant S	H5284649	Inactive	grant.bender@pnnl.gov	PNL		N	N	2020-04-03 13:11:57		2024-01-20 00:11:14
3410	NEST161	Nestor, Michael D	H6194265	Inactive	michael.nestor@pnnl.gov	PNL		N	N	2020-06-01 12:03:19		2022-01-15 00:11:13
3411	GERB256	Gerbasi, Robert V	H4920672	Inactive	robertvince.gerbasi@pnnl.gov	PNL		N	N	2020-06-01 18:03:34	Vince Gerbasi	2023-03-31 00:11:14
3415	DONO019	Donor, Micah T	H3054674	Inactive	micah.donor@pnnl.gov	PNL		N	N	2020-07-02 10:58:59		2022-06-16 00:11:12
3416	WILS480	Wilson, Jesse W	H7163975	Inactive	jesse.wilson@pnnl.gov	PNL		N	N	2020-07-09 12:06:20		2022-06-25 00:11:13
3417	CLAR400	Clark, Sue	H3769400	Inactive	sue.clark@pnnl.gov	PNL	\N	N	N	2020-07-15 05:42:57		2021-06-21 00:11:12
3419	CLIF300	Cliff III, John B	H0293893	Inactive	john.cliff@pnnl.gov	PNL	3M300	N	N	2020-08-10 15:54:50		2023-10-21 00:11:15
3420	TAYL377	Taylor, Zane W	H4609351	Inactive	zane.taylor@pnnl.gov	PNL		N	N	2020-08-10 17:18:35		2022-03-03 00:11:13
3422	KWAN679	Kwantwi-Barima, Pearl	H7168870	Inactive	pearl.kwantwi-barima@pnnl.gov	PNL		N	N	2020-09-11 12:48:00		2024-01-03 00:11:14
3423	LAWV490	Lawver, Albert	H0872259	Inactive	albert.lawver@pnnl.gov	PNL		N	N	2020-09-17 09:21:31		2022-09-24 00:11:13
3426	JYST649	Jystad, Amy M	H8282575	Inactive	amy.jystad@pnnl.gov	PNL		N	N	2020-09-18 11:16:17		2023-07-29 00:11:14
3428	NIXO277	Nixon, Agne	H1036448	Inactive	agne.nixon@pnnl.gov	PNL		N	N	2020-09-25 12:56:11		2022-08-04 00:11:13
3433	HEND004	Powell, Nikki	H4071936	Inactive	Nikki.Powell@pnnl.gov	PNL	\N	N	N	2020-12-05 05:42:58		2023-02-01 00:11:13
3434	LIAO381	Liao, Yen-Chen	H2510347	Inactive	yenchen.liao@pnnl.gov	PNL		N	N	2020-12-08 17:09:46		2024-12-06 00:12:04.703356
3438	MART077	Martin, Evan A	H2762241	Inactive	evan.martin@pnnl.gov	PNL		N	N	2021-01-29 15:18:44		2022-12-24 00:11:12
3444	SMER354	Smercina, Darian N	H2766622	Inactive	darian.smercina@pnnl.gov	PNL		N	N	2021-03-11 09:06:36		2022-12-30 00:11:13
3448	ZAMB441	Zambare, Neerja M	H8242363	Inactive	neerja.zambare@pnnl.gov	PNL	\N	N	N	2021-03-20 05:43:02		2023-02-11 00:11:14
3450	POIR043	Poirier, Brenton C	H6150861	Inactive	brenton.poirier@pnnl.gov	PNL		N	N	2021-04-19 13:08:51		2022-12-02 00:11:13
3451	MCCO081	McCoy, Heather S	H3448714	Inactive	heather.mccoy@pnnl.gov	PNL		N	N	2021-04-19 13:09:33		2023-04-20 00:11:14
3454	GRIG707	Griggs, Lydia H	H2356808	Inactive	lydia.griggs@pnnl.gov	PNL		N	N	2021-05-14 15:00:25		2023-03-09 00:11:15
3459	PING279	Pingili, Rajani	H3208211	Inactive	rajani.pingili@pnnl.gov	PNL		N	N	2021-06-30 16:19:09		2021-09-01 00:11:13
3461	MADD010	Madda, Rashmi	H9959497	Inactive	rashmi.madda@pnnl.gov	PNL		N	N	2021-07-01 08:34:05		2023-01-14 00:11:14
3464	ARNO805	Arnold, Anne M	H3403336	Inactive	anne.arnold@pnnl.gov	PNL		N	N	2021-07-26 17:49:09		2022-05-28 00:11:12
3465	BOBA374	Bobadilla-Regalado, Stephanie	H6750361	Inactive	stephanie.bobadilla-regalado@pnnl.gov	PNL		N	N	2021-08-02 10:53:31		2021-12-27 00:11:13
3469	HUDS575	Hudson, LaRae A	H2824590	Inactive	larae.hudson@pnnl.gov	PNL		N	N	2021-09-01 16:34:44		2022-06-25 00:11:13
3472	CAMP388	Campbell, Tayte P	H2443851	Inactive	tayte.campbell@pnnl.gov	PNL		N	N	2021-09-17 10:13:21		2022-02-01 00:11:13
3473	PARK198	Park, Junho	H8233130	Inactive	junho.park@pnnl.gov	PNL		N	N	2021-09-22 14:49:34		2022-03-31 00:11:13
3474	LERC713	Lercher, Johannes	H7228274	Inactive	Johannes.Lercher@pnnl.gov	PNL	\N	N	N	2021-09-23 05:43:00		2025-01-24 00:11:56.791542
3476	CHAM248	Chamberlain, Jen	H5618348	Inactive	jennifer.chamberlain@pnnl.gov	PNL	3X248	N	N	2021-10-01 05:43:00		2023-10-07 00:11:15
3479	MAST527	Mast, David H	H1564842	Inactive	david.mast@pnnl.gov	PNL		N	N	2021-10-22 14:37:45		2023-12-05 00:11:14
3480	THIB230	Thibert, Stephanie M	H6950436	Inactive	stephanie.thibert@pnnl.gov	PNL		N	N	2021-10-22 16:58:10		2024-02-15 00:11:15
3481	LEON067	Leonard, Bojana	H3374856	Inactive	bojana.leonard@pnnl.gov	PNL		N	N	2021-10-29 08:47:55		2023-09-20 00:11:15
3482	NGUY784	Nguyen, Quynhngoc T	H5357298	Inactive	quynhngoc.nguyen@pnnl.gov	PNL		N	N	2021-11-01 16:09:23		2022-04-13 00:11:13
3484	PINO216	Pino, James C	H5514811	Inactive	james.pino@pnnl.gov	PNL		N	N	2021-12-01 20:35:07		2024-06-17 00:11:15
3489	LEWI878	Lewis, Daniel H	H7723506	Inactive	daniel.h.lewis@pnnl.gov	PNL		N	N	2022-01-25 17:46:34		2024-04-04 00:11:14
3498	ROSE554	Rosenstock, Zoe Carolyn Anne	H3119752	Inactive	zoe.rosenstock@pnnl.gov	PNL	\N	N	N	2022-03-16 13:14:29		2024-08-01 00:11:15
3499	CULV869	Culver, Lane R	H9859712	Inactive	lane.culver@pnnl.gov	PNL	\N	N	N	2022-03-16 13:23:38		2022-08-20 00:11:13
3500	SCHU835	Schutz, Mischelle M	H5184965	Inactive	mischelle.schutz@pnnl.gov	PNL	\N	N	N	2022-04-01 08:36:04		2023-09-15 00:11:14
3504	SUAZ921	Suazo, Kiall Francis G	H6761705	Inactive	kiallfrancis.suazo@pnnl.gov	PNL	\N	N	N	2022-05-23 14:39:09		2023-09-30 00:11:15
3507	ELLI442	Elliott, Emily	H3237785	Inactive	emily.elliott@pnnl.gov	PNL	\N	N	N	2022-06-01 10:46:51		2024-07-12 00:11:15
3510	LEES161	Lee, Sophia	H2165822	Inactive	sophia.lee@pnnl.gov	PNL	\N	N	N	2022-06-30 13:42:07		2022-08-20 00:11:13
3512	SEYM219	Seymour, Robert W	H7835408	Inactive	robert.seymour@pnnl.gov	PNL	\N	N	N	2022-07-12 18:02:23		2024-08-17 00:11:35.445338
3516	CHEN597	Chen, Liang	H7094445	Inactive	liang.chen@pnnl.gov	PNL	\N	N	N	2022-08-26 14:20:40		2025-02-01 00:12:05.510401
3518	STAN534	Stanley, Robert K	H6372121	Inactive	robert.stanley@pnnl.gov	PNL	\N	N	N	2022-08-30 15:11:36		2024-03-16 00:11:15
3533	CAVA830	Cavanagh, Alexis M	H7080831	Inactive	alexis.m.cavanagh@pnnl.gov	PNL	\N	N	N	2022-11-28 09:35:08		2023-07-01 00:11:15
3535	TURE780	Turetcaia, Anna	H8209980	Inactive	anna.turetcaia@pnnl.gov	PNL	\N	N	N	2023-01-03 09:32:24		2024-11-16 00:11:13.754026
3536	PRYM311	Prymolenna, Anastasiya V	H1812326	Inactive	anastasiya.prymolenna@pnnl.gov	PNL	\N	N	N	2023-01-11 10:42:30		2024-06-23 00:11:16
3537	MLOD097	Mlodzik, Michael R	H1395457	Inactive	michael.mlodzik@pnnl.gov	PNL	\N	N	N	2023-01-17 09:41:02		2023-04-29 00:11:15
3545	CHOE644	Choe, Kisurb	H3294417	Inactive	kisurb.choe@pnnl.gov	PNL	\N	N	N	2023-04-05 13:14:45		2024-09-21 00:11:13.350813
3548	SHIC892	Shi, Cheng	H5001050	Inactive	cheng.shi@pnnl.gov	PNL	\N	N	N	2023-04-27 17:42:56		2024-07-03 00:11:14
3556	TAYL745	Taylor, Nathan T	H4375125	Inactive	nathan.taylor@pnnl.gov	PNL	\N	N	N	2023-05-24 11:50:42		2023-07-29 00:11:14
3561	XUSE537	Xu, Sean J	H2348442	Inactive	sean.xu@pnnl.gov	PNL	\N	N	N	2023-06-14 12:25:58		2024-03-16 00:11:15
3562	DOAM899	Do, Amy Q	H8864096	Inactive	amy.do@pnnl.gov	PNL	\N	N	N	2023-06-21 11:53:01		2023-12-02 00:11:14
3565	DELG580	Delgado, Dillman	H7774409	Inactive	dillman.delgadoparedes@pnnl.gov	PNL	\N	N	N	2023-06-28 11:25:53		2025-01-11 00:11:42.892045
3567	NADE287	Nadeau, Kyle D	H4225125	Inactive	kyle.nadeau@pnnl.gov	PNL	\N	N	N	2023-07-05 12:10:39		2024-10-19 00:11:43.299358
3575	DAUE023	Dauenhauer, Bolton	H3477410	Inactive	bolton.dauenhauer@pnnl.gov	PNL	\N	N	N	2023-09-05 08:32:15		2023-12-17 00:11:15
3577	DUCK228	Duckworth, Summer C	H6612457	Inactive	summer.duckworth@pnnl.gov	PNL	\N	N	N	2023-09-06 11:46:05		2024-12-27 00:11:27.201972
3585	AGHA982	Aghawani, Sedra	H6051555	Inactive	sedra.aghawani@pnnl.gov	PNL	\N	N	N	2023-10-12 16:32:06		2025-04-26 00:11:35.787526
3586	VANR270	VanReenen, Phoenix	H6337409	Inactive	phoenix.vanreenen@pnnl.gov	PNL	\N	N	N	2023-10-12 16:32:53		2024-08-10 00:11:15.201807
3589	JOHN002	Johnson, Zachary D	H6684002	Inactive	zachary.d.johnson@pnnl.gov	\N	\N	N	N	2023-11-01 15:30:06		2023-11-02 00:11:15
3590	SCHW939	Schwartz, Sydney	H8142437	Inactive	sydney.schwartz@pnnl.gov	PNL	\N	N	N	2023-11-16 15:03:21		2024-12-01 00:11:59.199256
3606	HERM689	Hermosillo, Dylan G	H7749292	Inactive	dylan.hermosillo@pnnl.gov	PNL	\N	N	N	2024-01-19 11:25:42		2024-04-27 00:11:14
3616	GAND055	Gandhi, Viraj	H2953055	Inactive	viraj.gandhi@pnnl.gov	PNL	\N	N	N	2024-04-30 13:01:32		2024-11-06 00:12:03.040555
2537	NIES456	Nie, Song	H3619293	Inactive	song.nie@pnnl.gov	PNL	\N	N	N	2014-12-14 19:19:00		2016-12-11 00:11:12
2539	FERR126	Ferrieri, Abigail P	H5873861	Inactive	abigail.ferrieri@pnnl.gov	PNL	\N	N	N	2014-12-16 18:31:55		2016-08-02 00:11:10
2544	DENG418	Deng, Liulin	H6690824	Inactive	liulin.deng@pnnl.gov	PNL	\N	N	N	2015-03-02 12:13:24		2017-08-20 00:11:12
2550	HEYM608	Heyman, Heino M	H3512773	Inactive	heino.heyman@pnnl.gov	PNL	\N	N	N	2015-05-21 12:57:26	\N	2018-07-07 00:11:11
2551	CHAN597	Chan, Chi Yuet	H0593463	Inactive	chiyuet.chan@pnnl.gov	PNL	\N	N	N	2015-05-22 10:41:18	Xavia	2016-10-16 00:11:11
2552	LAFR656	LaFrance, Andrew	H1894870	Inactive	\N	\N	\N	N	N	2015-06-01 13:47:01		2016-05-14 17:23:53
2555	MARE957	Marean-Reardon, Carrie L	H3242957	Inactive	carrie.marean-reardon@pnnl.gov	PNL	\N	N	N	2015-06-26 17:45:37	\N	2016-09-23 00:11:10
2557	SONG743	Song, Ehwang	H6143244	Inactive	ehwang.song@pnnl.gov	PNL	\N	N	N	2015-07-14 14:26:46		2017-08-20 00:11:12
2558	ROYC538	Roy Chowdhury, Taniya	H6115743	Inactive	taniya.roychowdhury@pnnl.gov	PNL	\N	N	N	2015-07-29 10:24:30		2017-12-01 00:11:11
2559	BOTT530	Bottos, Eric M	H6977702	Inactive	eric.bottos@pnnl.gov	PNL	\N	N	N	2015-07-29 10:24:47		2017-10-01 00:11:12
2560	LULI319	Lu, Linda	H5450591	Inactive	linda.lu@pnnl.gov	PNL	\N	N	N	2015-08-11 10:03:36		2016-07-30 00:11:10
2562	NGISERN	Isern, Nancy G	H0017803	Inactive	Nancy.Isern@pnnl.gov	PNL	3H709	N	N	2015-08-18 14:18:23		2017-10-14 00:11:11
2586	LIUY701	Liu, Yina	H7172624	Inactive	yina.liu@pnnl.gov	PNL	\N	N	N	2015-09-09 10:19:13		2017-07-23 00:11:17
2610	BELF005	Belford, Nakiya C	H4817449	Inactive	nakiya.belford@pnnl.gov	PNL	\N	N	N	2015-10-05 10:53:39		2016-06-02 00:11:11
2659	ALYN292	Aly, Noor A	H8383419	Inactive	noor.aly@pnnl.gov	PNL	\N	N	N	2015-10-30 15:40:42		2018-06-03 00:11:11
2739	D3K846	Laskin, Alexander	H2529374	Inactive	Alexander.Laskin@pnnl.gov	PNL	3K846	N	N	2015-12-07 10:04:22		2017-08-13 00:11:11
2741	LINP969	Lin, Peng Paul	H9095988	Inactive	peng.lin@pnnl.gov	PNL	\N	N	N	2015-12-07 10:05:57		2017-08-04 00:11:12
2829	MATH075	Mathews, Blake	H0129878	Inactive	charles.mathews@pnnl.gov	PNL	\N	N	N	2016-01-19 10:17:51		2017-11-08 00:11:12
2981	KRIS239	Kristiyanto, Daniel D	H3050467	Inactive	daniel.kristiyanto@pnnl.gov	PNL	\N	N	N	2016-03-14 16:31:03		2016-07-14 00:11:11
2994	D3G276	Butcher, Mark G	H0095725	Inactive	mark.butcher@pnnl.gov	PNL	3G276	N	N	2016-03-17 10:50:13		2018-06-14 00:11:11
3099	HAWK790	Hawkins, Dakota Y	H5524211	Inactive	dakota.hawkins@pnnl.gov	PNL	\N	N	N	2016-04-12 10:10:16		2016-06-24 00:11:11
3202	LIND436	Lindemann, Steve	H7877386	Inactive	Stephen.Lindemann@pnnl.gov	PNL	\N	N	N	2016-05-16 05:44:04		2016-08-13 00:11:11
3203	SIEB277	Sieber, Jennifer M	H7152348	Inactive	jennifer.sieber@pnnl.gov	PNL	\N	N	N	2016-05-24 10:21:35		2016-08-07 00:11:11
3204	CORN264	Cornwell, Kaitlin	H8920606	Inactive	kaitlin.cornwell@pnnl.gov	PNL	\N	N	N	2016-05-24 10:22:36		2016-08-03 00:11:11
3205	SEFA266	Sefas, Justice DR	H0649802	Inactive	justice.sefas@pnnl.gov	PNL	\N	N	N	2016-05-24 10:23:44		2016-12-16 00:11:11
3208	D3Y095	Sandoval, Jeremy A	H0661138	Inactive	Jeremy.Sandoval@pnnl.gov	PNL	3Y095	N	N	2016-06-13 11:10:39		2016-10-03 00:11:11
3209	TUMM596	Tummalacherla, Meghasyam	H9070868	Inactive	meghasyam.tummalacherla@pnnl.gov	PNL	\N	N	N	2016-06-13 12:55:17	\N	2016-08-28 00:11:12
3212	MATT893	Matta, Sonali	H7569036	Inactive	sonali.matta@pnnl.gov	PNL	\N	N	N	2016-06-23 13:20:23		2018-08-04 00:11:11
3222	FLIE972	Flieger, Kellsey L	H3462276	Inactive	kellsey.flieger@pnnl.gov	PNL	\N	N	N	2016-09-13 14:30:16	\N	2017-11-23 00:11:10
3231	LIAN608	Liang, Liyuan	H2066981	Inactive	liyuan.liang@pnnl.gov	PNL	\N	N	N	2016-10-15 05:44:08		2018-03-03 00:11:11
3234	ZBIB769	Zbib, Haz	H8629453	Inactive	hamzeh.zbib@pnnl.gov	PNL	\N	N	N	2016-12-01 14:10:36		2017-03-02 00:11:13
3235	BING955	Bingol, Kerem	H8847942	Inactive	ahmet.bingol@pnnl.gov	PNL	\N	N	N	2016-12-05 14:34:14	\N	2018-05-19 00:11:10
3240	DENN573	Denney, Chelsea C	H2006257	Inactive	chelsea.denney@pnnl.gov	PNL	\N	N	N	2017-01-05 10:14:41	\N	2018-07-27 00:11:11
3246	DUPU957	Dupuis, Kevin T	H1845682	Inactive	kevin.dupuis@pnnl.gov	PNL	\N	N	N	2017-03-07 12:13:39		2017-10-02 00:11:10
3252	AWAN001	Awan, Muaaz Gul	H2767563	Inactive	muaazgul.awan@pnnl.gov	PNL	\N	N	N	2017-05-15 14:58:43		2017-09-02 00:11:11
3254	ZHOU353	Zhou, Yuxuan	H5459872	Inactive	yuxuan.zhou@pnnl.gov	PNL	\N	N	N	2017-05-17 15:01:15		2017-07-25 00:11:11
3260	DELE087	DeLeon, Adrian J	H9831606	Inactive	adrian.deleon@pnnl.gov	PNL	\N	N	N	2017-08-03 10:05:00	\N	2018-07-18 00:11:11
3261	GARC096	Garcia, Karina M	H7323922	Inactive	karina.garcia@pnnl.gov	PNL	\N	N	N	2017-08-03 10:05:20	\N	2017-11-05 00:11:15
3268	XUKE732	Xu, Kerui	H7992275	Inactive	kerui.xu@pnnl.gov	PNL	\N	N	N	2017-10-12 17:57:40		2018-06-08 00:11:11
3278	BERN786	Bernstein, Hans C	H4074334	Inactive	Hans.Bernstein@pnnl.gov	PNL	\N	N	N	2017-12-16 05:43:08		2018-05-02 00:11:11
3282	KUSH494	Kushner, Irena	H9267245	Inactive	irena.kushner@pnnl.gov	PNL	\N	N	N	2018-01-10 16:59:55		2018-06-07 00:11:11
3283	MCQU553	McQuoid, Aaron R	H1721553	Inactive	\N	\N	\N	N	N	2018-01-11 14:57:48		2018-01-12 00:11:12
3331	GORT145	Gorton, Ian	H4674145	Inactive	ian.gorton@pnnl.gov	PNL	3K941	N	N	2018-11-26 18:50:48		2023-06-10 00:11:14
3654	PANA982	Panapitiya, Gihan U	H5165695	Active	gihan.panapitiya@pnnl.gov	PNL	\N	Y	Y	2025-05-16 14:29:04.089614		2025-06-19 00:11:15.773221
3655	MANY710	Many, Gina	H8584824	Active	gina.many@pnnl.gov	PNL	\N	Y	Y	2025-05-21 17:28:05.497772		2025-05-22 00:12:03.236415
3658	VULC453	Vulcan, Alina	H4642453	Active	alina.vulcan@pnnl.gov	PNL	\N	N	Y	2025-05-28 13:42:21.737745		2025-07-26 00:11:55.888507
3656	DENG705	Deng, Grace	H7782478	Active	grace.deng@pnnl.gov	PNL	\N	N	Y	2025-05-28 13:41:29.037937		2025-07-28 00:11:58.217099
3657	LEEJ887	Lee, Joshua	H3194887	Active	joshua.lee@pnnl.gov	PNL	\N	N	Y	2025-05-28 13:41:56.512251		2025-10-09 00:11:37.934232
3659	VINC116	Vincent, Madison	H9420116	Active	madison.vincent@pnnl.gov	PNL	\N	Y	Y	2025-05-28 13:42:47.221582		2026-01-19 00:11:56.584159
\.


--
-- Name: t_users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_users_user_id_seq', 3679, true);


--
-- PostgreSQL database dump complete
--


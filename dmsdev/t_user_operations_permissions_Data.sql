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
-- Data for Name: t_user_operations_permissions; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_user_operations_permissions (user_id, operation_id) FROM stdin;
4	17
6	17
6	35
7	34
8	35
15	18
16	18
17	18
18	16
18	17
18	34
2004	32
2012	32
2046	16
2046	17
2069	32
2085	16
2085	17
2085	35
2086	18
2086	35
2097	16
2097	17
2116	17
2123	32
2126	32
2127	35
2138	17
2138	34
2159	18
2159	19
2159	32
2159	35
2164	25
2166	33
2173	17
2173	34
2185	17
2186	17
2193	32
2193	34
2194	19
2197	16
2197	32
2207	17
2207	34
2211	16
2211	17
2217	16
2217	17
2219	19
2229	17
2229	34
2230	32
2233	25
2235	32
2236	17
2238	17
2239	32
2240	17
2240	34
2253	18
2253	19
2258	25
2260	16
2260	17
2263	25
2264	33
2265	26
2269	26
2270	26
2270	32
2272	17
2277	17
2278	26
2279	32
2280	17
2282	32
2283	32
2286	32
2289	32
2291	25
2293	17
2294	32
2296	16
2297	16
2301	25
2302	17
2303	25
2304	25
2309	16
2311	16
2311	32
2311	35
2316	16
2318	17
2318	32
2318	34
2318	35
2321	26
2323	16
2326	32
2327	25
2328	19
2328	32
2331	17
2331	34
2333	32
2335	32
2339	17
2340	17
2341	35
2342	17
2343	16
2343	17
2343	34
2346	25
2347	25
2348	25
2349	32
2349	33
2350	32
2352	25
2353	25
2358	32
2361	32
2363	32
2367	32
2368	17
2369	32
2370	32
2372	32
2374	25
2375	17
2375	34
2378	32
2385	16
2385	17
2385	32
2385	35
2386	32
2387	32
2390	25
2391	32
2392	25
2393	16
2395	16
2406	32
2409	17
2414	32
2415	16
2415	17
2418	17
2418	35
2419	32
2420	32
2421	17
2421	34
2422	16
2424	35
2425	32
2426	16
2428	32
2434	17
2434	34
2435	17
2435	34
2441	32
2444	25
2446	16
2446	17
2446	34
2452	25
2453	25
2454	25
2455	25
2456	25
2457	25
2459	25
2460	25
2461	25
2462	25
2468	25
2474	25
2476	25
2477	17
2480	33
2483	25
2484	32
2488	16
2490	25
2491	25
2492	25
2493	25
2496	25
2497	25
2498	18
2498	19
2498	33
2499	25
2506	25
2507	32
2508	17
2508	32
2512	25
2515	16
2516	32
2517	25
2518	32
2520	25
2525	25
2528	25
2529	25
2530	32
2532	25
2533	25
2534	32
2538	25
2541	16
2542	25
2543	25
2547	25
2548	25
2550	32
2553	25
2554	25
2561	25
2684	25
2711	32
2712	32
2739	32
2804	25
2829	17
2834	25
2879	16
2994	25
3099	25
3122	25
3199	25
3200	25
3201	25
3202	25
3207	32
3208	25
3209	25
3214	16
3214	17
3214	32
3215	25
3217	17
3218	32
3219	17
3221	18
3221	19
3221	33
3222	16
3223	17
3224	17
3225	16
3231	25
3232	25
3235	25
3237	25
3238	25
3240	16
3241	16
3244	32
3244	35
3246	25
3250	25
3251	16
3251	17
3255	17
3255	32
3255	35
3263	32
3269	16
3275	16
3278	25
3281	25
3284	25
3285	32
3286	25
3287	25
3289	25
3293	32
3294	25
3295	25
3297	25
3301	17
3303	32
3305	25
3306	25
3307	25
3308	25
3309	16
3310	32
3312	25
3314	25
3315	32
3316	32
3318	25
3320	32
3320	35
3323	32
3324	16
3326	32
3328	25
3329	25
3331	25
3334	32
3335	16
3337	32
3338	17
3338	32
3340	25
3342	32
3345	17
3347	17
3347	32
3348	17
3348	35
3351	32
3353	34
3353	36
3354	25
3355	25
3357	16
3360	25
3361	16
3362	25
3363	25
3367	25
3368	25
3371	25
3373	25
3376	25
3379	16
3381	16
3382	25
3383	32
3388	16
3390	25
3391	16
3393	25
3394	25
3398	25
3400	16
3401	25
3414	32
3416	17
3416	32
3417	25
3419	25
3424	16
3425	25
3430	25
3433	25
3435	25
3436	36
3437	25
3442	25
3443	25
3445	17
3445	32
3447	32
3448	25
3449	25
3450	17
3452	17
3452	32
3455	16
3458	32
3466	25
3471	17
3471	32
3472	25
3474	25
3475	25
3476	25
3480	32
3487	34
3487	36
3488	16
3489	25
3492	25
3494	25
3495	25
3496	25
3503	25
3513	25
3514	25
3517	17
3518	17
3520	25
3521	25
3524	25
3525	25
3529	32
3530	17
3530	26
3538	32
3539	25
3540	25
3541	25
3543	16
3545	32
3548	25
3549	25
3551	16
3552	25
3553	25
3557	25
3558	25
3559	25
3560	25
3562	25
3564	25
3567	25
3573	25
3574	16
3579	25
3588	25
3589	25
3605	25
3611	32
\.


--
-- PostgreSQL database dump complete
--

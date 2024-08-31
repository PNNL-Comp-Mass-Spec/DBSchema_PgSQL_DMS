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
-- Data for Name: t_processor_instrument; Type: TABLE DATA; Schema: cap; Owner: d3l243
--

COPY cap.t_processor_instrument (processor_name, instrument_name, enabled, comment) FROM stdin;
Monroe_CTM	12T_FTICR_B	0	Bruker
Monroe_CTM	15T_FTICR	0	Bruker
Monroe_CTM	QExactP02	0	
Proto-2_CTM	IMS02_AgTOF06	0	IMS Instrument
Proto-2_CTM	IMS03_AgQTOF01	0	IMS Instrument
Proto-2_CTM	IMS04_AgTOF05	0	IMS Instrument
Proto-2_CTM	IMS05_AgQTOF04	0	IMS Instrument
Proto-2_CTM	IMS06_AgTOF07	0	IMS Instrument
Proto-2_CTM	IMS07_AgQTOF02	0	IMS Instrument
Proto-2_CTM	IMS_TOF_1	0	IMS Instrument
Proto-4_CTM	9T_FTICR_Imaging	0	Bruker Imaging; old instrument
Proto-7_CTM_2	Maxis_01	0	Maxis
Proto-8_CTM_2	12T_FTICR_B	1	Bruker
Proto-8_CTM_2	15T_FTICR	1	Bruker
Proto-8_CTM_2	15T_FTICR_Imaging	1	Bruker Imaging
\.


--
-- PostgreSQL database dump complete
--


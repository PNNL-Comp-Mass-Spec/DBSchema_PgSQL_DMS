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
-- Data for Name: t_dim_error_solution; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dim_error_solution (error_text, solution) FROM stdin;
A Proposal ID and associated users must be selected	No Proposal ID Provided:\rObtain proposal ID from DMS\rSearch requests for this dataset\rhttp://dms2.pnl.gov/scheduled_run/report
already in database	Dataset with That Name Already in Database:\rCheck to confirm dataset already uploaded\rIf this is a new dataset, change the name to reflect different data\r\rhttp://dms2.pnl.gov/dataset/report
Could not find entry in database for experiment	Experiment Name Not Valid:\rCheck name for errors\rIf the name is correct, enter new experiment name in DMS\rhttp://dms2.pnl.gov/experiment/report
Could not resolve column number to ID	Column number not in DMS:\rCheck the column number\rEnter a new column in DMS\rhttp://dms2.pnl.gov/lc_column/report
Could not resolve EUS usage type	EMSL User Information Not Provided:\r\nFill out Usage Type (e.g. User_Onsite, User_Remote, Cap_Dev, or Maintenance)\r\nIf Usage Type is "User" also provide User Number and Proposal Number\r\n\r\nGet EMSL User information from DMS by looking at a similar request\r\nhttps://dms2.pnl.gov/eus_proposals/report
Could not verify EUS proposal ID	Proposal ID Number Is Not Valid:\rGet correct number from DMS Database\rSearch requests for this dataset\rhttp://dms2.pnl.gov/scheduled_run/report
Dataset name may not contain spaces	Dataset entered contains spaces:\rPlease check dataset name and experiment name for spaces\r
Operator payroll number/HID was blank	Operator Payroll Number Not Provided:\r\rProvide Operator payroll number
Request ID not found	Request Number Not Valid: \r\nCheck request number against DMS request page\r\nhttps://dms2.pnl.gov/scheduled_run/report\r\nIf this is a rerun the request might have already been used, or is waiting to be dispositioned\r\nIf no request is found upload the dataset with a "0" request number and provided appropriate Usage Type, User Number and Proposal
The dataset data is not available for capture	Dataset Not Found in Instrument Transfer Folder:\rPossible causes:\r\r(1) Difference between Xcalibur queue and LCMS queue (i.e. Check the date in dataset name)\r(2) Cart is running and the Mass Spectrometer is not running\r(3) Wrong directory on instrument selected, datasets being saved in another folder\r(4) Name of dataset changed (e.g. bad_ or marg_) before upload
\.


--
-- PostgreSQL database dump complete
--


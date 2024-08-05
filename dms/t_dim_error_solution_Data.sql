--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
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
The dataset data is not available for capture	Dataset not found in instrument transfer folder; possible causes:\r\n\r\n(1) Difference between Xcalibur queue and LCMS queue (i.e. Check the date in dataset name)\r\n(2) Cart is running and the Mass Spectrometer is not running\r\n(3) Wrong directory on instrument selected, datasets being saved in another folder\r\n(4) Name of dataset changed (e.g. bad_ or marg_) before upload
A Proposal ID and associated users must be selected	No proposal ID provided:\r\nObtain proposal ID from DMS\r\nSearch requests for this dataset\r\nhttps://dms2.pnl.gov/scheduled_run/report
already in database	Dataset with that name is already in the database:\r\nCheck to confirm the dataset already uploaded\r\nIf this is a new dataset, change the name to reflect different data\r\nhttps://dms2.pnl.gov/dataset/report
Could not find entry in database for experiment	Experiment name not valid:\r\nCheck name for errors\r\nIf the name is correct, enter new experiment name in DMS\r\nhttps://dms2.pnl.gov/experiment/report
Could not resolve column number to ID	Column name not in DMS:\r\nCheck the column name\r\nEnter a new column in DMS\r\nhttps://dms2.pnl.gov/lc_column/report
Could not resolve EUS usage type	EMSL user information not provided:\r\nFill out Usage Type (e.g. User_Onsite, User_Remote, Cap_Dev, or Maintenance)\r\nIf Usage Type is "User" also provide User Number and Proposal Number\r\n\r\nGet EMSL User information from DMS by looking at a similar request\r\nhttps://dms2.pnl.gov/eus_proposals/report
Could not verify EUS proposal ID	Proposal ID is not valid:\r\nGet correct ID from DMS\r\nSearch requests for this dataset\r\nhttps://dms2.pnl.gov/scheduled_run/report
Dataset name may not contain spaces	Dataset entered contains spaces:\r\nPlease check dataset name and experiment name for spaces
Operator payroll number/HID was blank	Operator payroll number not provided:\r\nProvide Operator payroll number
Request ID not found	Request Number Not Valid: \r\nCheck request number against DMS request page\r\nhttps://dms2.pnl.gov/scheduled_run/report\r\nIf this is a rerun the request might have already been used, or is waiting to be dispositioned\r\nIf no request is found upload the dataset with a "0" request number and provided appropriate Usage Type, User Number and Proposal
\.


--
-- PostgreSQL database dump complete
--


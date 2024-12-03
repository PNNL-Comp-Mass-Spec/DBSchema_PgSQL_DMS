--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
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
-- Data for Name: t_naming_authorities; Type: TABLE DATA; Schema: pc; Owner: d3l243
--

COPY pc.t_naming_authorities (authority_id, name, description, web_address) FROM stdin;
22	BROAD	BROAD Institute	http://www.broadinstitute.org/
13	Contigs	Proteins generated from contiguous genomic sequences	
18	CyanoBase	Genome Database for Cyanobacteria	http://www.kazusa.or.jp/cyano/
9	Ensembl	Joint Project between the EBI and Sanger Centre	http://www.ensembl.org/
10	H-INV	H-Invitational Database	http://www.jbirc.aist.go.jp/hinv/index.jsp
4	IPI	International Protein Index	http://www.ebi.ac.uk/IPI/
17	Interpro	EMBL Interpro Database	http://www.ebi.ac.uk/interpro/
16	JGI	Joint Genomics Institute	http://www.jgi.doe.gov/
21	MScDB	Mass Spectrometry Centric Protein Sequence Database for Proteomics	http://www.wzw.tum.de/proteomics/content/research/software/mscdb/
2	NCBI	National Center for Biotechnology Information	http://www.ncbi.nlm.nih.gov/
6	None	No Naming Authority Specified	\N
15	ORNL	Oak Ridge National Laboratory	http://www.ornl.gov/
7	Other	\N	\N
14	Poxvirus_Bioinf_Res_Center	Poxvirus Bioinformatics Reseach Center	http://www.poxvirus.org/
19	SGD	Saccharomyces Genome Database	http://www.yeastgenome.org/
3	Sanger	Wellcome Trust Sanger Institute	http://www.sanger.ac.uk/
5	Stanford	Stanford Saccharomyces Genome Database	http://www.yeastgenome.org/
12	Stop-To-Stop	Locally generated Stop-to-Stop database	\N
20	TAIR	The Arabidopsis Information Resource	http://www.arabidopsis.org/
1	TIGR	The Institute for Genomic Research	http://www.tigr.org/
8	UniProt	UniProt	http://www.uniprot.org/
\.


--
-- Name: t_naming_authorities_authority_id_seq; Type: SEQUENCE SET; Schema: pc; Owner: d3l243
--

SELECT pg_catalog.setval('pc.t_naming_authorities_authority_id_seq', 22, true);


--
-- PostgreSQL database dump complete
--


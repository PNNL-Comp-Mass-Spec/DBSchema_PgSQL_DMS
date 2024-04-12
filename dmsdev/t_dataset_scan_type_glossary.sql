--
-- Name: t_dataset_scan_type_glossary; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_scan_type_glossary (
    scan_type public.citext NOT NULL,
    sort_key integer DEFAULT 0 NOT NULL,
    comment public.citext DEFAULT ''::public.citext NOT NULL
);


ALTER TABLE public.t_dataset_scan_type_glossary OWNER TO d3l243;

--
-- Name: t_dataset_scan_type_glossary pk_t_dataset_scan_type_glossary; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_scan_type_glossary
    ADD CONSTRAINT pk_t_dataset_scan_type_glossary PRIMARY KEY (scan_type);

--
-- Name: TABLE t_dataset_scan_type_glossary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_scan_type_glossary TO readaccess;
GRANT SELECT ON TABLE public.t_dataset_scan_type_glossary TO writeaccess;


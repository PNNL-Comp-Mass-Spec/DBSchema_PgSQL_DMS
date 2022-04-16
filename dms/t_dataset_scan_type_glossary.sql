--
-- Name: t_dataset_scan_type_glossary; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_scan_type_glossary (
    scan_type public.citext NOT NULL,
    sort_key integer NOT NULL,
    comment public.citext NOT NULL
);


ALTER TABLE public.t_dataset_scan_type_glossary OWNER TO d3l243;

--
-- Name: TABLE t_dataset_scan_type_glossary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_scan_type_glossary TO readaccess;


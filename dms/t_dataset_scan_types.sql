--
-- Name: t_dataset_scan_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_scan_types (
    entry_id integer NOT NULL,
    dataset_id integer NOT NULL,
    scan_type public.citext NOT NULL,
    scan_count integer,
    scan_filter public.citext
);


ALTER TABLE public.t_dataset_scan_types OWNER TO d3l243;

--
-- Name: TABLE t_dataset_scan_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_scan_types TO readaccess;


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
-- Name: t_dataset_scan_types_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_dataset_scan_types ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_dataset_scan_types_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dataset_scan_types pk_t_dataset_scan_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_dataset_scan_types
    ADD CONSTRAINT pk_t_dataset_scan_types PRIMARY KEY (entry_id);

--
-- Name: TABLE t_dataset_scan_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_scan_types TO readaccess;


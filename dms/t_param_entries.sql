--
-- Name: t_param_entries; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_param_entries (
    param_entry_id integer NOT NULL,
    entry_sequence_order integer,
    entry_type public.citext,
    entry_specifier public.citext,
    entry_value public.citext,
    param_file_id integer NOT NULL,
    entered timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_param_entries OWNER TO d3l243;

--
-- Name: t_param_entries_param_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_param_entries ALTER COLUMN param_entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_param_entries_param_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_entries pk_t_param_entries; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_entries
    ADD CONSTRAINT pk_t_param_entries PRIMARY KEY (param_entry_id);

--
-- Name: TABLE t_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_entries TO readaccess;


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
-- Name: TABLE t_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_entries TO readaccess;


--
-- Name: t_acceptable_param_entries; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_acceptable_param_entries (
    entry_id integer NOT NULL,
    parameter_name public.citext NOT NULL,
    description public.citext,
    parameter_category public.citext NOT NULL,
    default_value public.citext,
    display_name public.citext NOT NULL,
    canonical_name public.citext NOT NULL,
    analysis_tool_id integer NOT NULL,
    first_applicable_version public.citext,
    last_applicable_version public.citext,
    param_entry_type_id integer,
    picker_items_list public.citext,
    output_order integer
);


ALTER TABLE public.t_acceptable_param_entries OWNER TO d3l243;

--
-- Name: t_acceptable_param_entries_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_acceptable_param_entries ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_acceptable_param_entries_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_acceptable_param_entries pk_t_acceptable_param_entries; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_acceptable_param_entries
    ADD CONSTRAINT pk_t_acceptable_param_entries PRIMARY KEY (entry_id);

--
-- Name: TABLE t_acceptable_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_acceptable_param_entries TO readaccess;


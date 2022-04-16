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
-- Name: TABLE t_acceptable_param_entries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_acceptable_param_entries TO readaccess;


--
-- Name: t_acceptable_param_entry_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_acceptable_param_entry_types (
    param_entry_type_id integer NOT NULL,
    param_entry_type_name public.citext NOT NULL,
    description public.citext,
    formatting_string public.citext
);


ALTER TABLE public.t_acceptable_param_entry_types OWNER TO d3l243;

--
-- Name: TABLE t_acceptable_param_entry_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_acceptable_param_entry_types TO readaccess;


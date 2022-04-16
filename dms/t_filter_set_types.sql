--
-- Name: t_filter_set_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_types (
    filter_type_id integer NOT NULL,
    filter_type_name public.citext NOT NULL
);


ALTER TABLE public.t_filter_set_types OWNER TO d3l243;

--
-- Name: TABLE t_filter_set_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_types TO readaccess;


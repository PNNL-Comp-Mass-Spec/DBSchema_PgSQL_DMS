--
-- Name: t_filter_sets; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_sets (
    filter_set_id integer NOT NULL,
    filter_type_id integer NOT NULL,
    filter_set_name public.citext NOT NULL,
    filter_set_description public.citext NOT NULL,
    date_created timestamp without time zone NOT NULL,
    date_modified timestamp without time zone NOT NULL
);


ALTER TABLE public.t_filter_sets OWNER TO d3l243;

--
-- Name: TABLE t_filter_sets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_sets TO readaccess;


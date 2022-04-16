--
-- Name: t_secondary_sep_usage; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_secondary_sep_usage (
    separation_type_id integer NOT NULL,
    usage_last12months integer,
    usage_all_years integer,
    most_recent_use timestamp without time zone
);


ALTER TABLE public.t_secondary_sep_usage OWNER TO d3l243;

--
-- Name: TABLE t_secondary_sep_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_secondary_sep_usage TO readaccess;


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
-- Name: t_secondary_sep_usage pk_t_secondary_sep_usage; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep_usage
    ADD CONSTRAINT pk_t_secondary_sep_usage PRIMARY KEY (separation_type_id);

--
-- Name: TABLE t_secondary_sep_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_secondary_sep_usage TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_secondary_sep_usage TO writeaccess;


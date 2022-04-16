--
-- Name: t_filter_set_criteria; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria (
    filter_set_criteria_id integer NOT NULL,
    filter_criteria_group_id integer NOT NULL,
    criterion_id integer NOT NULL,
    criterion_comparison character(2) NOT NULL,
    criterion_value double precision NOT NULL
);


ALTER TABLE public.t_filter_set_criteria OWNER TO d3l243;

--
-- Name: TABLE t_filter_set_criteria; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria TO readaccess;


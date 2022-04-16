--
-- Name: t_filter_set_criteria_names; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria_names (
    criterion_id integer NOT NULL,
    criterion_name public.citext NOT NULL,
    criterion_description public.citext
);


ALTER TABLE public.t_filter_set_criteria_names OWNER TO d3l243;

--
-- Name: TABLE t_filter_set_criteria_names; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria_names TO readaccess;


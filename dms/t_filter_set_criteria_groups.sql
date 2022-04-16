--
-- Name: t_filter_set_criteria_groups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_filter_set_criteria_groups (
    filter_criteria_group_id integer NOT NULL,
    filter_set_id integer NOT NULL
);


ALTER TABLE public.t_filter_set_criteria_groups OWNER TO d3l243;

--
-- Name: TABLE t_filter_set_criteria_groups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_filter_set_criteria_groups TO readaccess;


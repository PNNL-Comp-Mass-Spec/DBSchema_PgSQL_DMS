--
-- Name: t_experiment_group_members; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_group_members (
    group_id integer NOT NULL,
    exp_id integer NOT NULL
);


ALTER TABLE public.t_experiment_group_members OWNER TO d3l243;

--
-- Name: TABLE t_experiment_group_members; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_group_members TO readaccess;


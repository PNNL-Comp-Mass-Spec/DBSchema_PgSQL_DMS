--
-- Name: t_experiment_groups; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_groups (
    group_id integer NOT NULL,
    group_type public.citext NOT NULL,
    created timestamp without time zone NOT NULL,
    description public.citext,
    parent_exp_id integer NOT NULL,
    prep_lc_run_id integer,
    researcher public.citext,
    tab public.citext,
    member_count integer NOT NULL
);


ALTER TABLE public.t_experiment_groups OWNER TO d3l243;

--
-- Name: TABLE t_experiment_groups; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_groups TO readaccess;


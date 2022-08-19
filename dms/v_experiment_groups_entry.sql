--
-- Name: v_experiment_groups_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_groups_entry AS
 SELECT eg.group_id AS id,
    eg.group_type,
    eg.tab,
    eg.description,
    e.experiment AS parent_exp,
    public.get_exp_group_experiment_list(eg.group_id) AS experiment_list,
    eg.researcher
   FROM (public.t_experiment_groups eg
     JOIN public.t_experiments e ON ((eg.parent_exp_id = e.exp_id)));


ALTER TABLE public.v_experiment_groups_entry OWNER TO d3l243;

--
-- Name: TABLE v_experiment_groups_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_groups_entry TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_groups_entry TO writeaccess;


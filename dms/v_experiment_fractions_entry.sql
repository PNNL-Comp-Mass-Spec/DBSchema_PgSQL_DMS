--
-- Name: v_experiment_fractions_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_fractions_entry AS
 SELECT eg.group_id AS id,
    eg.group_type,
    e.experiment AS parent_experiment,
    eg.description,
    eg.created,
    1 AS starting_index,
    1 AS step,
    25 AS total_count
   FROM (public.t_experiment_groups eg
     JOIN public.t_experiments e ON ((eg.parent_exp_id = e.exp_id)));


ALTER TABLE public.v_experiment_fractions_entry OWNER TO d3l243;

--
-- Name: TABLE v_experiment_fractions_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_fractions_entry TO readaccess;


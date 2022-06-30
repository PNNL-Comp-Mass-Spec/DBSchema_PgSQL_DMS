--
-- Name: v_dms_get_experiment_metadata; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_get_experiment_metadata AS
 SELECT e.experiment,
    ai.target,
    ai.category,
    ai.subcategory,
    ai.item,
    ai.value
   FROM (public.t_experiments e
     JOIN public.v_aux_info_value ai ON ((e.exp_id = ai.target_id)))
  WHERE (ai.target OPERATOR(public.=) 'Experiment'::public.citext);


ALTER TABLE cap.v_dms_get_experiment_metadata OWNER TO d3l243;


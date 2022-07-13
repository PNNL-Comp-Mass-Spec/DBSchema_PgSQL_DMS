--
-- Name: v_biomaterial_experiment_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_experiment_tracking AS
 SELECT e.experiment,
    count(t_dataset.dataset_id) AS datasets,
    e.reason,
    e.created,
    b.biomaterial_name AS "#CCName"
   FROM (((public.t_experiment_biomaterial eb
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)))
     JOIN public.t_biomaterial b ON ((eb.biomaterial_id = b.biomaterial_id)))
     LEFT JOIN public.t_dataset ON ((e.exp_id = t_dataset.exp_id)))
  GROUP BY b.biomaterial_name, e.experiment, e.reason, e.created;


ALTER TABLE public.v_biomaterial_experiment_tracking OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_experiment_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_experiment_tracking TO readaccess;


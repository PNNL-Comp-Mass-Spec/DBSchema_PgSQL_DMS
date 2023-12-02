--
-- Name: v_dataset_qc_metric_definitions; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_metric_definitions AS
 SELECT t_dataset_qc_metric_names.metric,
    t_dataset_qc_metric_names.short_description,
    t_dataset_qc_metric_names.source,
    t_dataset_qc_metric_names.category,
    t_dataset_qc_metric_names.metric_group,
    t_dataset_qc_metric_names.metric_value,
    t_dataset_qc_metric_names.units,
    t_dataset_qc_metric_names.optimal,
    t_dataset_qc_metric_names.purpose,
    t_dataset_qc_metric_names.description,
    t_dataset_qc_metric_names.sort_key
   FROM public.t_dataset_qc_metric_names
  WHERE (t_dataset_qc_metric_names.ignored = 0);


ALTER VIEW public.v_dataset_qc_metric_definitions OWNER TO d3l243;

--
-- Name: TABLE v_dataset_qc_metric_definitions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_metric_definitions TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_qc_metric_definitions TO writeaccess;


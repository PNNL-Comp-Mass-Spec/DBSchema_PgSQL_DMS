--
-- Name: v_dataset_nom_stats_definitions; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_nom_stats_definitions AS
 SELECT metric,
    short_description,
    source,
    category,
    metric_value,
    units,
    optimal,
    purpose,
    description,
    sort_key
   FROM public.t_dataset_nom_stat_names
  WHERE (ignored = 0);


ALTER VIEW public.v_dataset_nom_stats_definitions OWNER TO d3l243;

--
-- Name: TABLE v_dataset_nom_stats_definitions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_nom_stats_definitions TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_nom_stats_definitions TO writeaccess;


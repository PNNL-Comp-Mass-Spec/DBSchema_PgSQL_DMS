--
-- Name: v_export_biomaterial_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_export_biomaterial_jobs AS
 SELECT DISTINCT b.biomaterial_name AS biomaterial,
    b.biomaterial_id,
    j.job
   FROM ((((public.t_biomaterial b
     JOIN public.t_experiment_biomaterial eb ON ((b.biomaterial_id = eb.biomaterial_id)))
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)))
     JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)))
     JOIN public.t_analysis_job j ON ((ds.dataset_id = j.dataset_id)));


ALTER VIEW public.v_export_biomaterial_jobs OWNER TO d3l243;

--
-- Name: TABLE v_export_biomaterial_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_export_biomaterial_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_export_biomaterial_jobs TO writeaccess;


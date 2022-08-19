--
-- Name: v_export_biomaterial_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_export_biomaterial_datasets AS
 SELECT DISTINCT b.biomaterial_name AS biomaterial,
    b.biomaterial_id,
    ds.dataset_id
   FROM (((public.t_biomaterial b
     JOIN public.t_experiment_biomaterial eb ON ((b.biomaterial_id = eb.biomaterial_id)))
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)))
     JOIN public.t_dataset ds ON ((e.exp_id = ds.exp_id)));


ALTER TABLE public.v_export_biomaterial_datasets OWNER TO d3l243;

--
-- Name: TABLE v_export_biomaterial_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_export_biomaterial_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_export_biomaterial_datasets TO writeaccess;


--
-- Name: v_export_biomaterial_experiments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_export_biomaterial_experiments AS
 SELECT b.biomaterial_name AS biomaterial,
    e.experiment
   FROM ((public.t_biomaterial b
     JOIN public.t_experiment_biomaterial eb ON ((b.biomaterial_id = eb.biomaterial_id)))
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)));


ALTER TABLE public.v_export_biomaterial_experiments OWNER TO d3l243;

--
-- Name: TABLE v_export_biomaterial_experiments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_export_biomaterial_experiments TO readaccess;
GRANT SELECT ON TABLE public.v_export_biomaterial_experiments TO writeaccess;


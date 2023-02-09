--
-- Name: v_experiment_biomaterial_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_biomaterial_report AS
 SELECT e.experiment,
    e.researcher_username AS researcher,
    org.organism,
    e.comment,
    b.biomaterial_name AS biomaterial
   FROM (((public.t_experiment_biomaterial eb
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_biomaterial b ON ((eb.biomaterial_id = b.biomaterial_id)));


ALTER TABLE public.v_experiment_biomaterial_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_biomaterial_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_biomaterial_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_biomaterial_report TO writeaccess;


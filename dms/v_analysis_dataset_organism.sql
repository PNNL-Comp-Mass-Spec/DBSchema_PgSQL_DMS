--
-- Name: v_analysis_dataset_organism; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_dataset_organism AS
 SELECT ds.dataset,
    org.organism,
    org.organism_db_path AS client_path,
    ''::public.citext AS server_path
   FROM ((public.t_dataset ds
     JOIN public.t_experiments ON ((ds.exp_id = t_experiments.exp_id)))
     JOIN public.t_organisms org ON ((t_experiments.organism_id = org.organism_id)));


ALTER TABLE public.v_analysis_dataset_organism OWNER TO d3l243;

--
-- Name: TABLE v_analysis_dataset_organism; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_dataset_organism TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_dataset_organism TO writeaccess;


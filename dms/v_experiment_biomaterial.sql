--
-- Name: v_experiment_biomaterial; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_biomaterial AS
 SELECT e.experiment,
    b.biomaterial_name
   FROM ((public.t_experiment_biomaterial eb
     JOIN public.t_experiments e ON ((eb.exp_id = e.exp_id)))
     JOIN public.t_biomaterial b ON ((eb.biomaterial_id = b.biomaterial_id)));


ALTER TABLE public.v_experiment_biomaterial OWNER TO d3l243;

--
-- Name: TABLE v_experiment_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_biomaterial TO readaccess;


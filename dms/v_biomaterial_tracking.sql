--
-- Name: v_biomaterial_tracking; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_tracking AS
 SELECT b.biomaterial_name,
    bt.experiment_count AS experiments,
    bt.dataset_count AS datasets,
    bt.job_count AS jobs,
    b.reason,
    b.created
   FROM (public.t_biomaterial_tracking bt
     JOIN public.t_biomaterial b ON ((bt.biomaterial_id = b.biomaterial_id)));


ALTER TABLE public.v_biomaterial_tracking OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_tracking; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_tracking TO readaccess;


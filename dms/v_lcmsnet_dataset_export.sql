--
-- Name: v_lcmsnet_dataset_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lcmsnet_dataset_export AS
 SELECT ds.dataset,
    e.experiment,
    ds.created,
    ds.dataset_id AS id,
    dsn.dataset_state AS state,
    instname.instrument
   FROM (((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
  WHERE (e.experiment OPERATOR(public.<>) 'Tracking'::public.citext);


ALTER TABLE public.v_lcmsnet_dataset_export OWNER TO d3l243;

--
-- Name: TABLE v_lcmsnet_dataset_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lcmsnet_dataset_export TO readaccess;
GRANT SELECT ON TABLE public.v_lcmsnet_dataset_export TO writeaccess;


--
-- Name: v_mage_dataset_factor_summary; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_dataset_factor_summary AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    rr.request_id AS request,
    count(f.factor_id) AS factors
   FROM ((public.t_dataset ds
     JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_factor f ON ((rr.request_id = f.target_id)))
  WHERE (f.type OPERATOR(public.=) 'Run_Request'::public.citext)
  GROUP BY ds.dataset_id, ds.dataset, rr.request_id, rr.request_name;


ALTER VIEW public.v_mage_dataset_factor_summary OWNER TO d3l243;

--
-- Name: TABLE v_mage_dataset_factor_summary; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_dataset_factor_summary TO readaccess;
GRANT SELECT ON TABLE public.v_mage_dataset_factor_summary TO writeaccess;


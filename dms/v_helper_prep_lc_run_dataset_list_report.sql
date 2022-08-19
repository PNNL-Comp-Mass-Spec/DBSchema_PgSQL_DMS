--
-- Name: v_helper_prep_lc_run_dataset_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_prep_lc_run_dataset_list_report AS
 SELECT ds.dataset_id AS id,
    'x'::text AS sel,
    ds.dataset,
    instname.instrument,
    ds.comment
   FROM (public.t_dataset ds
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
  WHERE ((NOT (EXISTS ( SELECT t_prep_lc_run_dataset.dataset_id
           FROM public.t_prep_lc_run_dataset
          WHERE (t_prep_lc_run_dataset.dataset_id = ds.dataset_id)))) AND (ds.dataset_type_id = 31));


ALTER TABLE public.v_helper_prep_lc_run_dataset_list_report OWNER TO d3l243;

--
-- Name: TABLE v_helper_prep_lc_run_dataset_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_prep_lc_run_dataset_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_helper_prep_lc_run_dataset_list_report TO writeaccess;


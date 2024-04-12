--
-- Name: v_batch_tracking_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_batch_tracking_list_report AS
 SELECT rrb.batch_id AS batch,
    rrb.batch AS name,
    rr.state_name AS status,
    rr.request_id AS request,
    ds.dataset_id,
    ds.dataset,
    instname.instrument,
    lc.lc_column,
    ds.acq_time_start AS start,
    rr.block,
    rr.run_order
   FROM (((public.t_lc_column lc
     JOIN public.t_dataset ds ON ((lc.lc_column_id = ds.lc_column_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     RIGHT JOIN (public.t_requested_run_batches rrb
     JOIN public.t_requested_run rr ON ((rrb.batch_id = rr.batch_id))) ON ((ds.dataset_id = rr.dataset_id)));


ALTER VIEW public.v_batch_tracking_list_report OWNER TO d3l243;

--
-- Name: TABLE v_batch_tracking_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_batch_tracking_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_batch_tracking_list_report TO writeaccess;


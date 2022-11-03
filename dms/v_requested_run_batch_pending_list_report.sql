--
-- Name: v_requested_run_batch_pending_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_pending_list_report AS
 SELECT v_requested_run_batch_list_report.id,
    v_requested_run_batch_list_report.name,
    v_requested_run_batch_list_report.requests,
    v_requested_run_batch_list_report.runs,
    v_requested_run_batch_list_report.blocked,
    v_requested_run_batch_list_report.blkmissing,
    v_requested_run_batch_list_report.first_request,
    v_requested_run_batch_list_report.last_request,
    v_requested_run_batch_list_report.req_priority,
    v_requested_run_batch_list_report.instrument,
    v_requested_run_batch_list_report.inst_group,
    v_requested_run_batch_list_report.description,
    v_requested_run_batch_list_report.owner,
    v_requested_run_batch_list_report.created,
    v_requested_run_batch_list_report.days_in_queue,
    v_requested_run_batch_list_report.complete_by,
    v_requested_run_batch_list_report.days_in_prep_queue,
    v_requested_run_batch_list_report.justification_for_high_priority,
    v_requested_run_batch_list_report.comment,
    v_requested_run_batch_list_report.separation_type,
    v_requested_run_batch_list_report.days_in_queue_bin
   FROM public.v_requested_run_batch_list_report
  WHERE (v_requested_run_batch_list_report.requests > 0);


ALTER TABLE public.v_requested_run_batch_pending_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_pending_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_pending_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_pending_list_report TO writeaccess;


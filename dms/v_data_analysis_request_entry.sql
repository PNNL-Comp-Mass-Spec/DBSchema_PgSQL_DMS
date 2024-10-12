--
-- Name: v_data_analysis_request_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_entry AS
 SELECT r.request_id AS id,
    r.request_name,
    r.analysis_type,
    r.requester_username,
    r.description,
    r.analysis_specifications,
    r.comment,
    public.get_data_analysis_request_batch_list(r.request_id) AS batch_ids,
    public.get_data_analysis_request_data_package_list(r.request_id) AS data_package_ids,
    r.exp_group_id,
    r.work_package,
    r.requested_personnel,
    r.assigned_personnel,
    r.priority,
    r.reason_for_high_priority,
    r.estimated_analysis_time_days,
    sn.state_name,
    r.state_comment
   FROM (public.t_data_analysis_request r
     JOIN public.t_data_analysis_request_state_name sn ON ((r.state = sn.state_id)));


ALTER VIEW public.v_data_analysis_request_entry OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_entry TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_entry TO writeaccess;


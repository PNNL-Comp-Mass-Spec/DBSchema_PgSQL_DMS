--
-- Name: v_data_analysis_request_updates_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_updates_list_report AS
 SELECT updates.entered,
    updates.entered_by,
    u.name,
    updates.old_state_id,
    updates.new_state_id,
    oldstate.state_name AS old_state,
    newstate.state_name AS new_state,
    updates.request_id
   FROM (((public.t_data_analysis_request_updates updates
     JOIN public.t_data_analysis_request_state_name oldstate ON ((updates.old_state_id = oldstate.state_id)))
     JOIN public.t_data_analysis_request_state_name newstate ON ((updates.new_state_id = newstate.state_id)))
     LEFT JOIN public.t_users u ON ((updates.entered_by OPERATOR(public.=) u.username)));


ALTER TABLE public.v_data_analysis_request_updates_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_updates_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_updates_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_updates_list_report TO writeaccess;


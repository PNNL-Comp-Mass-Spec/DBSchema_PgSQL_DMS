--
-- Name: v_sample_prep_request_updates_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_updates_list_report AS
 SELECT updates.date_of_change,
    updates.system_account,
    u.name,
    bsn.state_name AS beginning_state,
    esn.state_name AS end_state,
    updates.request_id
   FROM (((public.t_sample_prep_request_updates updates
     JOIN public.t_sample_prep_request_state_name bsn ON ((updates.beginning_state_id = bsn.state_id)))
     JOIN public.t_sample_prep_request_state_name esn ON ((updates.end_state_id = esn.state_id)))
     LEFT JOIN public.t_users u ON ((updates.system_account OPERATOR(public.=) u.username)));


ALTER TABLE public.v_sample_prep_request_updates_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_updates_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_updates_list_report TO readaccess;


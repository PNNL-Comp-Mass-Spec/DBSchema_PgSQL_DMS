--
-- Name: v_analysis_status_monitor; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_status_monitor AS
 SELECT ajp.processor_id AS id,
    ajp.processor_name AS name,
    public.get_aj_processor_analysis_tool_list(ajp.processor_id) AS tools,
    public.get_aj_processor_membership_in_groups_list(ajp.processor_id, 1) AS enabled_groups,
    public.get_aj_processor_membership_in_groups_list(ajp.processor_id, 0) AS disabled_groups,
    mp.status_file_name_path,
    mp.check_box_state,
    mp.use_for_status_check
   FROM (public.t_analysis_job_processors ajp
     JOIN public.t_analysis_status_monitor_params mp ON ((ajp.processor_id = mp.processor_id)));


ALTER TABLE public.v_analysis_status_monitor OWNER TO d3l243;

--
-- Name: TABLE v_analysis_status_monitor; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_status_monitor TO readaccess;


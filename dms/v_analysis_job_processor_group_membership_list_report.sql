--
-- Name: v_analysis_job_processor_group_membership_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_membership_list_report AS
 SELECT ajpgm.processor_id AS id,
    ajp.processor_name AS name,
    ajpgm.membership_enabled,
    ajp.machine,
    ajp.notes,
    ajpgm.group_id AS "#group_id",
    public.get_aj_processor_membership_in_groups_list(ajp.processor_id, 2) AS group_membership
   FROM (public.t_analysis_job_processor_group_membership ajpgm
     JOIN public.t_analysis_job_processors ajp ON ((ajpgm.processor_id = ajp.processor_id)));


ALTER TABLE public.v_analysis_job_processor_group_membership_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_membership_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_membership_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_group_membership_list_report TO writeaccess;


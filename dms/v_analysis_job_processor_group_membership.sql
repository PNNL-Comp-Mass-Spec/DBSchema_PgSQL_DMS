--
-- Name: v_analysis_job_processor_group_membership; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_membership AS
 SELECT ajpgm.group_id,
    ajpg.group_name,
    ajpg.group_description,
    ajpg.group_enabled,
    'Y'::public.citext AS available_for_general_processing,
    ajpgm.processor_id,
    ajp.processor_name,
    ajp.state,
    ajp.machine,
    ajp.notes,
    ajpgm.membership_enabled,
    ajpgm.last_affected
   FROM ((public.t_analysis_job_processor_group_membership ajpgm
     JOIN public.t_analysis_job_processors ajp ON ((ajpgm.processor_id = ajp.processor_id)))
     JOIN public.t_analysis_job_processor_group ajpg ON ((ajpgm.group_id = ajpg.group_id)));


ALTER TABLE public.v_analysis_job_processor_group_membership OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_membership; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_membership TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_group_membership TO writeaccess;


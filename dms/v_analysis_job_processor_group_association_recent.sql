--
-- Name: v_analysis_job_processor_group_association_recent; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_association_recent AS
 SELECT ajpg.group_name,
    ajpga.job,
    js.job_state AS state,
    ds.dataset,
    tool.analysis_tool AS tool,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file
   FROM (public.t_analysis_job_processor_group_membership ajpgm
     RIGHT JOIN (((((public.t_analysis_job_processor_group_associations ajpga
     JOIN public.t_analysis_job j ON ((ajpga.job = j.job)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
     JOIN public.t_analysis_job_processor_group ajpg ON ((ajpga.group_id = ajpg.group_id))) ON (((ajpgm.group_id = ajpg.group_id) AND (ajpgm.membership_enabled OPERATOR(public.=) 'Y'::public.citext))))
  WHERE ((j.job_state_id = ANY (ARRAY[1, 2, 3, 8, 9, 10, 11, 16, 17])) OR (j.finish >= (CURRENT_TIMESTAMP - '5 days'::interval)))
  GROUP BY ajpga.job, js.job_state, ds.dataset, tool.analysis_tool, j.param_file_name, j.settings_file_name, ajpga.group_id, ajpg.group_name;


ALTER TABLE public.v_analysis_job_processor_group_association_recent OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_association_recent; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_association_recent TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_group_association_recent TO writeaccess;


--
-- Name: v_get_pipeline_processors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_processors AS
 SELECT ajp.processor_id AS id,
    ajp.processor_name,
    ajp.state,
    count(COALESCE(pgm.group_id, 0)) AS groups,
    sum(1) AS gp_groups,
    ajp.machine
   FROM ((public.t_analysis_job_processors ajp
     LEFT JOIN public.t_analysis_job_processor_group_membership pgm ON ((ajp.processor_id = pgm.processor_id)))
     JOIN public.t_analysis_job_processor_group pg ON ((pgm.group_id = pg.group_id)))
  WHERE (pgm.membership_enabled = 'Y'::bpchar)
  GROUP BY ajp.processor_name, ajp.state, ajp.processor_id, ajp.machine;


ALTER TABLE public.v_get_pipeline_processors OWNER TO d3l243;

--
-- Name: TABLE v_get_pipeline_processors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_processors TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_processors TO writeaccess;


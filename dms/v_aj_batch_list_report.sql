--
-- Name: v_aj_batch_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_aj_batch_list_report AS
 SELECT t_analysis_job_batches.batch_id AS batch,
    t_analysis_job_batches.batch_description AS description,
    t_analysis_job_batches.batch_created AS created
   FROM public.t_analysis_job_batches;


ALTER TABLE public.v_aj_batch_list_report OWNER TO d3l243;

--
-- Name: TABLE v_aj_batch_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_aj_batch_list_report TO readaccess;

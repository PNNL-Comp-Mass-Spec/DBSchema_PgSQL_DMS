--
-- Name: v_analysis_job_requests_recent; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_requests_recent AS
 SELECT v_analysis_job_request_list_report.request,
    v_analysis_job_request_list_report.name,
    v_analysis_job_request_list_report.state,
    v_analysis_job_request_list_report.requester,
    v_analysis_job_request_list_report.created,
    v_analysis_job_request_list_report.tool,
    v_analysis_job_request_list_report.jobs,
    v_analysis_job_request_list_report.param_file,
    v_analysis_job_request_list_report.settings_file,
    v_analysis_job_request_list_report.organism,
    v_analysis_job_request_list_report.organism_db_file,
    v_analysis_job_request_list_report.protein_collection_list,
    v_analysis_job_request_list_report.protein_options,
    v_analysis_job_request_list_report.datasets,
    v_analysis_job_request_list_report.data_package,
    v_analysis_job_request_list_report.comment
   FROM public.v_analysis_job_request_list_report
  WHERE ((v_analysis_job_request_list_report.state OPERATOR(public.=) 'new'::public.citext) OR (v_analysis_job_request_list_report.created >= (CURRENT_TIMESTAMP - '5 days'::interval)));


ALTER VIEW public.v_analysis_job_requests_recent OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_requests_recent; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_requests_recent TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_requests_recent TO writeaccess;


--
-- Name: v_analysis_job_requests_recent; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_requests_recent AS
 SELECT request,
    name,
    state,
    requester,
    created,
    tool,
    jobs,
    param_file,
    settings_file,
    organism,
    organism_db_file,
    protein_collection_list,
    protein_options,
    datasets,
    data_package,
    comment
   FROM public.v_analysis_job_request_list_report
  WHERE ((state OPERATOR(public.=) 'new'::public.citext) OR (created >= (CURRENT_TIMESTAMP - '5 days'::interval)));


ALTER VIEW public.v_analysis_job_requests_recent OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_requests_recent; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_requests_recent TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_requests_recent TO writeaccess;


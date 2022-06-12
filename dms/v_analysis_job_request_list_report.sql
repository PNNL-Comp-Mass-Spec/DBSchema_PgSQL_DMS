--
-- Name: v_analysis_job_request_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_list_report AS
 SELECT ajr.request_id AS request,
    ajr.request_name AS name,
    ajrs.request_state AS state,
    u.username AS requester,
    ajr.created,
    ajr.analysis_tool AS tool,
    ajr.job_count AS jobs,
    ajr.param_file_name AS param_file,
    ajr.settings_file_name AS settings_file,
    org.organism,
    ajr.organism_db_name AS organism_db_file,
    ajr.protein_collection_list,
    ajr.protein_options_list AS protein_options,
        CASE
            WHEN (COALESCE(ajr.data_package_id, 0) > 0) THEN ''::text
            WHEN (ajr.dataset_min OPERATOR(public.=) ajr.dataset_max) THEN (ajr.dataset_min)::text
            ELSE COALESCE((((ajr.dataset_min)::text || ', '::text) || (ajr.dataset_max)::text), (ajr.dataset_min)::text, (ajr.dataset_max)::text)
        END AS datasets,
    ajr.data_package_id AS data_package,
    ajr.comment
   FROM (((public.t_analysis_job_request ajr
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
     JOIN public.t_analysis_job_request_state ajrs ON ((ajr.request_state_id = ajrs.request_state_id)))
     JOIN public.t_organisms org ON ((ajr.organism_id = org.organism_id)));


ALTER TABLE public.v_analysis_job_request_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_list_report TO readaccess;


--
-- Name: v_analysis_job_request_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_entry AS
 SELECT ajr.request_id,
    ajr.request_name,
    ajr.created,
    ajr.analysis_tool,
    ajr.param_file_name,
    ajr.settings_file_name,
    ajr.organism_db_name,
    org.organism AS organism_name,
        CASE
            WHEN (COALESCE(ajr.data_pkg_id, 0) > 0) THEN ''::text
            ELSE public.get_job_request_dataset_name_list(ajr.request_id)
        END AS datasets,
    ajr.data_pkg_id AS data_package_id,
    ajr.comment,
    ajr.special_processing,
    ars.request_state AS state,
    u.username AS requester,
    ajr.protein_collection_list AS prot_coll_name_list,
    ajr.protein_options_list AS prot_coll_options_list
   FROM (((public.t_analysis_job_request ajr
     JOIN public.t_analysis_job_request_state ars ON ((ajr.request_state_id = ars.request_state_id)))
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
     JOIN public.t_organisms org ON ((ajr.organism_id = org.organism_id)));


ALTER VIEW public.v_analysis_job_request_entry OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_entry TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_request_entry TO writeaccess;


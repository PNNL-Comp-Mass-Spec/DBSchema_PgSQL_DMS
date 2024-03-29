--
-- Name: v_sample_submission_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_submission_detail_report AS
 SELECT ss.submission_id AS id,
    c.campaign,
    u.name_with_username AS received_by,
    ss.description,
    ss.container_list,
    ss.created
   FROM (((public.t_sample_submission ss
     JOIN public.t_campaign c ON ((ss.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((ss.received_by_user_id = u.user_id)))
     LEFT JOIN public.t_prep_file_storage pfs ON ((ss.storage_id = pfs.storage_id)));


ALTER VIEW public.v_sample_submission_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_submission_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_submission_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_submission_detail_report TO writeaccess;


--
-- Name: v_dataset_funding_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_funding_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    instname.instrument,
    exp.experiment,
    ds.acq_time_start AS run_start,
    ds.acq_time_end AS run_finish,
    ds.acq_length_minutes AS acq_length,
    c.campaign,
    dsn.dataset_state AS state,
    ds.created,
    dsrating.dataset_rating AS rating,
    rr.request_id AS request,
    rr.requester_prn AS requester,
    rr.eus_proposal_id AS emsl_proposal,
    rr.work_package,
    spr.work_package AS sample_prep_work_package,
    public.get_proposal_eus_users_list(rr.eus_proposal_id, 'N'::text, 5) AS emsl_users,
    public.get_proposal_eus_users_list(rr.eus_proposal_id, 'I'::text, 20) AS emsl_user_ids,
    dtn.dataset_type,
    ds.operator_prn AS operator,
    ds.scan_count,
    ds.separation_type,
    ds.comment,
        CASE
            WHEN (c.fraction_emsl_funded > (0)::numeric) THEN c.fraction_emsl_funded
            WHEN ((spr.work_package OPERATOR(public.~~) 'K798%'::public.citext) OR (rr.work_package OPERATOR(public.~~) 'K798%'::public.citext)) THEN (1)::numeric
            ELSE (0)::numeric
        END AS fraction_emsl_funded,
    EXTRACT(year FROM (COALESCE(ds.acq_time_start, ds.created) + '92 days'::interval)) AS fy,
    instname.operations_role AS instrument_ops_role,
    instname.instrument_class
   FROM ((public.t_sample_prep_request spr
     RIGHT JOIN ((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments exp ON ((ds.exp_id = exp.exp_id)))
     JOIN public.t_campaign c ON ((exp.campaign_id = c.campaign_id))) ON ((spr.prep_request_id = exp.sample_prep_request_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
  WHERE ((ds.dataset_rating_id > 0) AND (ds.dataset_state_id = 3));


ALTER TABLE public.v_dataset_funding_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_funding_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_funding_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_funding_report TO writeaccess;


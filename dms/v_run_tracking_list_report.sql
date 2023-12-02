--
-- Name: v_run_tracking_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_run_tracking_list_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    ds.acq_time_start AS time_start,
    ds.acq_time_end AS time_end,
    ds.acq_length_minutes AS duration,
    ds.interval_to_next_ds AS "interval",
    t_instrument_name.instrument,
    dsn.dataset_state AS state,
    drn.dataset_rating AS rating,
    ((('C:'::public.citext)::text || (lc.lc_column)::text))::public.citext AS lc_column,
    rr.request_id AS request,
    rr.work_package,
    rr.eus_proposal_id AS eus_proposal,
    eut.eus_usage_type AS eus_usage,
    c.campaign_id,
    c.fraction_emsl_funded,
    c.eus_proposal_list AS campaign_proposals,
    EXTRACT(year FROM ds.acq_time_start) AS year,
    EXTRACT(month FROM ds.acq_time_start) AS month,
    EXTRACT(day FROM ds.acq_time_start) AS day,
        CASE
            WHEN (ds.dataset_type_id = 100) THEN 'Tracking'::public.citext
            ELSE 'Regular'::public.citext
        END AS dataset_type
   FROM ((((((((public.t_dataset ds
     JOIN public.t_instrument_name ON ((ds.instrument_id = t_instrument_name.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)));


ALTER VIEW public.v_run_tracking_list_report OWNER TO d3l243;

--
-- Name: TABLE v_run_tracking_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_run_tracking_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_run_tracking_list_report TO writeaccess;


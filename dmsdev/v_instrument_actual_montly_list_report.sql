--
-- Name: v_instrument_actual_montly_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_actual_montly_list_report AS
 SELECT usageq.year,
    usageq.month,
    COALESCE(usageq.proposal_id, '0'::public.citext) AS proposal_id,
    (COALESCE(
        CASE
            WHEN (char_length((ep.title)::text) > 32) THEN ((("left"((ep.title)::text, 32))::public.citext)::text || ('...'::public.citext)::text)
            ELSE (ep.title)::text
        END, ('-No Proposal-'::public.citext)::text))::public.citext AS title,
    sn.state_name AS status,
    ((((((usageq.ft_actual + usageq.ims_actual) + usageq.orb_actual) + usageq.exa_actual) + usageq.ltq_actual) + usageq.gc_actual) + usageq.qqq_actual) AS total_actual,
    usageq.ft_actual,
    usageq.ims_actual,
    usageq.orb_actual,
    usageq.exa_actual,
    usageq.ltq_actual,
    usageq.gc_actual,
    usageq.qqq_actual,
    usageq.campaigns,
    usageq.campaign_first,
    usageq.campaign_last,
    ((((((usageq.ft_emsl_actual + usageq.ims_emsl_actual) + usageq.orb_emsl_actual) + usageq.exa_emsl_actual) + usageq.ltq_emsl_actual) + usageq.gc_emsl_actual) + usageq.qqq_emsl_actual) AS total_emsl_actual,
    usageq.ft_emsl_actual,
    usageq.ims_emsl_actual,
    usageq.orb_emsl_actual,
    usageq.exa_emsl_actual,
    usageq.ltq_emsl_actual,
    usageq.gc_emsl_actual,
    usageq.qqq_emsl_actual
   FROM ((public.t_eus_proposal_state_name sn
     JOIN public.t_eus_proposals ep ON ((sn.state_id = ep.state_id)))
     RIGHT JOIN ( SELECT EXTRACT(year FROM ds.acq_time_start) AS year,
            EXTRACT(month FROM ds.acq_time_start) AS month,
            rr.eus_proposal_id AS proposal_id,
            count(DISTINCT c.campaign) AS campaigns,
            public.min(c.campaign) AS campaign_first,
            public.max(c.campaign) AS campaign_last,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'FT'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS ft_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'IMS'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS ims_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'ORB'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS orb_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'EXA'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS exa_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'LTQ'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS ltq_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'GC'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS gc_actual,
            round(((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'QQQ'::public.citext) THEN ds.acq_length_minutes
                    ELSE 0
                END))::numeric / 60.0), 1) AS qqq_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'FT'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS ft_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'IMS'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS ims_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'ORB'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS orb_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'EXA'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS exa_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'LTQ'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS ltq_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'GC'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS gc_emsl_actual,
            round((sum(
                CASE
                    WHEN (instgroup.allocation_tag OPERATOR(public.=) 'QQQ'::public.citext) THEN ((ds.acq_length_minutes)::numeric * c.fraction_emsl_funded)
                    ELSE (0)::numeric
                END) / 60.0), 1) AS qqq_emsl_actual
           FROM (((((public.t_dataset ds
             JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
             JOIN public.t_instrument_name instname ON ((instname.instrument_id = ds.instrument_id)))
             JOIN public.t_instrument_group instgroup ON ((instname.instrument_group OPERATOR(public.=) instgroup.instrument_group)))
             JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
             JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
          WHERE ((ds.dataset_rating_id > 1) AND (rr.eus_usage_type_id <> ALL (ARRAY[10, 12, 13])) AND (ds.dataset_state_id = 3) AND (instname.operations_role OPERATOR(public.<>) ALL (ARRAY['Offsite'::public.citext, 'InSilico'::public.citext])))
          GROUP BY (EXTRACT(year FROM ds.acq_time_start)), (EXTRACT(month FROM ds.acq_time_start)), rr.eus_proposal_id) usageq ON ((ep.proposal_id OPERATOR(public.=) usageq.proposal_id)));


ALTER VIEW public.v_instrument_actual_montly_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_actual_montly_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_actual_montly_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_actual_montly_list_report TO writeaccess;


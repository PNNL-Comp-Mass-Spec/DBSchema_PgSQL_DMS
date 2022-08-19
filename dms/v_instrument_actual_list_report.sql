--
-- Name: v_instrument_actual_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_actual_list_report AS
 SELECT usageq.fiscal_year,
    COALESCE(usageq.proposal_id, '0'::public.citext) AS proposal_id,
    COALESCE(
        CASE
            WHEN (char_length((ep.title)::text) > 32) THEN ("left"((ep.title)::text, 32) || '...'::text)
            ELSE (ep.title)::text
        END, '-No Proposal-'::text) AS title,
    sn.state_name AS status,
    usageq.ft_usage,
    usageq.ims_usage,
    usageq.orb_usage,
    usageq.exa_usage,
    usageq.ltq_usage,
    usageq.gc_usage,
    usageq.qqq_usage,
    usageq.ft_alloc,
    usageq.ims_alloc,
    usageq.orb_alloc,
    usageq.exa_alloc,
    usageq.ltq_alloc,
    usageq.gc_alloc,
    usageq.qqq_alloc,
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
     RIGHT JOIN ( SELECT COALESCE(tal.fiscal_year, tac.fy) AS fiscal_year,
            COALESCE(tal.proposal_id, tac.proposal) AS proposal_id,
                CASE
                    WHEN (tal.ft_alloc > (0)::double precision) THEN (round(((((tac.ft_actual)::double precision / tal.ft_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.ft_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS ft_usage,
                CASE
                    WHEN (tal.ims_alloc > (0)::double precision) THEN (round(((((tac.ims_actual)::double precision / tal.ims_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.ims_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS ims_usage,
                CASE
                    WHEN (tal.orb_alloc > (0)::double precision) THEN (round(((((tac.orb_actual)::double precision / tal.orb_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.orb_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS orb_usage,
                CASE
                    WHEN (tal.exa_alloc > (0)::double precision) THEN (round(((((tac.exa_actual)::double precision / tal.exa_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.exa_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS exa_usage,
                CASE
                    WHEN (tal.ltq_alloc > (0)::double precision) THEN (round(((((tac.ltq_actual)::double precision / tal.ltq_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.ltq_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS ltq_usage,
                CASE
                    WHEN (tal.gc_alloc > (0)::double precision) THEN (round(((((tac.gc_actual)::double precision / tal.gc_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.gc_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS gc_usage,
                CASE
                    WHEN (tal.qqq_alloc > (0)::double precision) THEN (round(((((tac.qqq_actual)::double precision / tal.qqq_alloc) * (100)::double precision))::numeric, 1) || '%'::text)
                    ELSE
                    CASE
                        WHEN (tac.qqq_actual > (0)::numeric) THEN 'Non alloc use'::text
                        ELSE ''::text
                    END
                END AS qqq_usage,
            tal.ft_alloc,
            tac.ft_actual,
            tal.ims_alloc,
            tac.ims_actual,
            tal.orb_alloc,
            tac.orb_actual,
            tal.exa_alloc,
            tac.exa_actual,
            tal.ltq_alloc,
            tac.ltq_actual,
            tal.gc_alloc,
            tac.gc_actual,
            tal.qqq_alloc,
            tac.qqq_actual,
            tac.campaigns,
            tac.campaign_first,
            tac.campaign_last,
            tac.ft_emsl_actual,
            tac.ims_emsl_actual,
            tac.orb_emsl_actual,
            tac.exa_emsl_actual,
            tac.ltq_emsl_actual,
            tac.gc_emsl_actual,
            tac.qqq_emsl_actual
           FROM (( SELECT public.get_fy_from_date(ds.acq_time_start) AS fy,
                    rr.eus_proposal_id AS proposal,
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
                  GROUP BY (public.get_fy_from_date(ds.acq_time_start)), rr.eus_proposal_id) tac
             FULL JOIN ( SELECT t_instrument_allocation.fiscal_year,
                    t_instrument_allocation.proposal_id,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'FT'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS ft_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'IMS'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS ims_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'ORB'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS orb_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'EXA'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS exa_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'LTQ'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS ltq_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'GC'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS gc_alloc,
                    sum(
                        CASE
                            WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'QQQ'::public.citext) THEN t_instrument_allocation.allocated_hours
                            ELSE (0)::double precision
                        END) AS qqq_alloc
                   FROM public.t_instrument_allocation
                  GROUP BY t_instrument_allocation.proposal_id, t_instrument_allocation.fiscal_year) tal ON (((tac.proposal OPERATOR(public.=) tal.proposal_id) AND (tac.fy = tal.fiscal_year))))) usageq ON ((ep.proposal_id OPERATOR(public.=) usageq.proposal_id)));


ALTER TABLE public.v_instrument_actual_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_actual_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_actual_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_actual_list_report TO writeaccess;


--
-- Name: v_instrument_allocation_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_allocation_list_report AS
 SELECT sumq.fiscal_year,
    sumq.proposal_id,
        CASE
            WHEN (char_length((ep.title)::text) > 32) THEN (((("left"((ep.title)::text, 32))::public.citext)::text || ('...'::public.citext)::text))::public.citext
            ELSE ep.title
        END AS title,
    sn.state_name AS status,
    generalq.general,
    sumq.ft,
    sumq.ims,
    sumq.orb,
    sumq.exa,
    sumq.ltq,
    sumq.gc,
    sumq.qqq,
    sumq.last_affected AS last_updated,
    sumq.fy_proposal
   FROM (((( SELECT t_instrument_allocation.fiscal_year,
            t_instrument_allocation.proposal_id,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'FT'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS ft,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'IMS'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS ims,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'ORB'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS orb,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'EXA'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS exa,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'LTQ'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS ltq,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'GC'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS gc,
            sum(
                CASE
                    WHEN (t_instrument_allocation.allocation_tag OPERATOR(public.=) 'QQQ'::public.citext) THEN t_instrument_allocation.allocated_hours
                    ELSE (0)::double precision
                END) AS qqq,
            max(t_instrument_allocation.last_affected) AS last_affected,
            t_instrument_allocation.fy_proposal
           FROM public.t_instrument_allocation
          GROUP BY t_instrument_allocation.proposal_id, t_instrument_allocation.fiscal_year, t_instrument_allocation.fy_proposal) sumq
     JOIN public.t_eus_proposals ep ON ((sumq.proposal_id OPERATOR(public.=) ep.proposal_id)))
     JOIN public.t_eus_proposal_state_name sn ON ((sn.state_id = ep.state_id)))
     LEFT JOIN ( SELECT tia.comment AS general,
            tia.fiscal_year,
            tia.proposal_id
           FROM public.t_instrument_allocation tia
          WHERE (tia.allocation_tag OPERATOR(public.=) 'General'::public.citext)) generalq ON (((generalq.fiscal_year = sumq.fiscal_year) AND (generalq.proposal_id OPERATOR(public.=) sumq.proposal_id))));


ALTER VIEW public.v_instrument_allocation_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_allocation_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_allocation_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_allocation_list_report TO writeaccess;


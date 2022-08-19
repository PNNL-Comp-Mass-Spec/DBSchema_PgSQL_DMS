--
-- Name: v_eus_proposals_helper_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposals_helper_list_report AS
 SELECT p.proposal_id,
    p.title,
    COALESCE((rr.request_id)::text, '(none yet)'::text) AS request,
    COALESCE(ds.dataset, '(none yet)'::public.citext) AS dataset,
    p.proposal_type,
        CASE
            WHEN (sn.state_id = 5) THEN sn.state_name
            ELSE
            CASE
                WHEN (p.proposal_end_date < CURRENT_TIMESTAMP) THEN 'Closed'::public.citext
                ELSE sn.state_name
            END
        END AS proposal_state
   FROM (((public.t_eus_proposals p
     JOIN public.t_eus_proposal_state_name sn ON ((p.state_id = sn.state_id)))
     LEFT JOIN public.t_requested_run rr ON ((rr.eus_proposal_id OPERATOR(public.=) p.proposal_id)))
     LEFT JOIN public.t_dataset ds ON ((ds.dataset_id = rr.dataset_id)))
  WHERE (p.state_id = ANY (ARRAY[2, 5]));


ALTER TABLE public.v_eus_proposals_helper_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposals_helper_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposals_helper_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposals_helper_list_report TO writeaccess;


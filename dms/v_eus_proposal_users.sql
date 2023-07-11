--
-- Name: v_eus_proposal_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_proposal_users AS
 SELECT u.person_id AS user_id,
    u.name_fm AS user_name,
    pu.proposal_id AS proposal,
    COALESCE(usageq.prep_requests, (0)::bigint) AS prep_requests,
    pu.last_affected,
    p.proposal_start_date,
    p.proposal_end_date
   FROM (((public.t_eus_proposal_users pu
     JOIN public.t_eus_users u ON ((pu.person_id = u.person_id)))
     JOIN public.t_eus_proposals p ON ((pu.proposal_id OPERATOR(public.=) p.proposal_id)))
     LEFT JOIN ( SELECT t_sample_prep_request.eus_user_id AS person_id,
            count(t_sample_prep_request.prep_request_id) AS prep_requests
           FROM public.t_sample_prep_request
          WHERE (NOT (t_sample_prep_request.eus_user_id IS NULL))
          GROUP BY t_sample_prep_request.eus_user_id) usageq ON ((u.person_id = usageq.person_id)))
  WHERE ((pu.of_dms_interest = 'Y'::bpchar) AND (pu.state_id <> 5));


ALTER TABLE public.v_eus_proposal_users OWNER TO d3l243;

--
-- Name: TABLE v_eus_proposal_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_proposal_users TO readaccess;
GRANT SELECT ON TABLE public.v_eus_proposal_users TO writeaccess;


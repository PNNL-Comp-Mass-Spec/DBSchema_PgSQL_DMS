--
-- Name: v_eus_active_proposal_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_active_proposal_list_report AS
 SELECT p.proposal_id,
    p.title,
    p.proposal_type,
    p.proposal_start_date AS start_date,
    p.proposal_end_date AS end_date,
        CASE
            WHEN (sn.state_id = 5) THEN sn.state_name
            ELSE
            CASE
                WHEN (p.proposal_end_date < CURRENT_TIMESTAMP) THEN 'Closed'::public.citext
                ELSE sn.state_name
            END
        END AS state,
    (public.get_proposal_eus_users_list(p.proposal_id, 'L'::text, 100))::public.citext AS user_last_names
   FROM (public.t_eus_proposals p
     JOIN public.t_eus_proposal_state_name sn ON ((p.state_id = sn.state_id)))
  WHERE (p.state_id = ANY (ARRAY[2, 5]));


ALTER VIEW public.v_eus_active_proposal_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_active_proposal_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_active_proposal_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_active_proposal_list_report TO writeaccess;


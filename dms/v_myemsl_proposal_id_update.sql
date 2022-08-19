--
-- Name: v_myemsl_proposal_id_update; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_myemsl_proposal_id_update AS
 SELECT rr.request_id,
    ds.dataset_id,
    public.get_dataset_myemsl_transaction_ids(ds.dataset_id) AS myemsl_transaction_id_list,
    rr.eus_proposal_id,
    rr.updated
   FROM ((public.t_requested_run rr
     JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)));


ALTER TABLE public.v_myemsl_proposal_id_update OWNER TO d3l243;

--
-- Name: VIEW v_myemsl_proposal_id_update; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_myemsl_proposal_id_update IS 'This view is used by MyEMSL to check for updated EUS Proposal IDs';

--
-- Name: TABLE v_myemsl_proposal_id_update; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_myemsl_proposal_id_update TO readaccess;
GRANT SELECT ON TABLE public.v_myemsl_proposal_id_update TO writeaccess;


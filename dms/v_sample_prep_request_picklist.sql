--
-- Name: v_sample_prep_request_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_picklist AS
 SELECT spr.prep_request_id AS id,
    spr.request_name,
    spr.request_type AS type,
    spr.created,
    spr.priority,
    sn.state_name AS state,
        CASE
            WHEN (char_length((spr.reason)::text) > 42) THEN ("left"((spr.reason)::text, 42))::public.citext
            ELSE spr.reason
        END AS reason,
    spr.number_of_samples AS num_samples,
    spr.prep_method,
    spr.assigned_personnel,
    spr.organism,
    spr.campaign
   FROM (public.t_sample_prep_request spr
     JOIN public.t_sample_prep_request_state_name sn ON ((spr.state_id = sn.state_id)))
  WHERE (spr.state_id > 0)
  GROUP BY spr.prep_request_id, spr.request_name, spr.created, spr.estimated_completion, spr.priority, spr.state_id, sn.state_name, spr.request_type, spr.reason, spr.number_of_samples, spr.estimated_ms_runs, spr.prep_method, spr.requested_personnel, spr.assigned_personnel, spr.requester_username, spr.organism, spr.biohazard_level, spr.campaign;


ALTER TABLE public.v_sample_prep_request_picklist OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_picklist TO writeaccess;


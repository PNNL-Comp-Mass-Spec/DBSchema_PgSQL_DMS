--
-- Name: v_requested_run_eus_users_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_eus_users_export AS
 SELECT rrusers.request_id,
    rrusers.eus_person_id,
    rr.request_name,
    eususers.name_fm AS eus_user_name
   FROM ((public.t_requested_run_eus_users rrusers
     JOIN public.t_requested_run rr ON ((rrusers.request_id = rr.request_id)))
     JOIN public.t_eus_users eususers ON ((rrusers.eus_person_id = eususers.person_id)));


ALTER VIEW public.v_requested_run_eus_users_export OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_eus_users_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_eus_users_export TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_eus_users_export TO writeaccess;


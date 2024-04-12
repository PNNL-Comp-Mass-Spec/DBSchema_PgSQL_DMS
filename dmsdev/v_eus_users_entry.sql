--
-- Name: v_eus_users_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_users_entry AS
 SELECT person_id AS id,
    name_fm AS name,
    hid AS hanford_id,
    site_status_id AS site_status
   FROM public.t_eus_users;


ALTER VIEW public.v_eus_users_entry OWNER TO d3l243;

--
-- Name: TABLE v_eus_users_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_users_entry TO readaccess;
GRANT SELECT ON TABLE public.v_eus_users_entry TO writeaccess;


--
-- Name: v_eus_users_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_users_entry AS
 SELECT t_eus_users.person_id AS id,
    t_eus_users.name_fm AS name,
    t_eus_users.hid AS hanford_id,
    t_eus_users.site_status_id AS site_status
   FROM public.t_eus_users;


ALTER TABLE public.v_eus_users_entry OWNER TO d3l243;

--
-- Name: TABLE v_eus_users_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_users_entry TO readaccess;


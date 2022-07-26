--
-- Name: v_eus_users_id; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_users_id AS
 SELECT u.person_id AS user_id,
    u.name_fm AS user_name,
    u.hid AS hanford_id,
    s.eus_site_status AS site_status,
    u.valid AS valid_eus_id
   FROM (public.t_eus_users u
     JOIN public.t_eus_site_status s ON ((u.site_status_id = s.eus_site_status_id)));


ALTER TABLE public.v_eus_users_id OWNER TO d3l243;

--
-- Name: TABLE v_eus_users_id; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_users_id TO readaccess;


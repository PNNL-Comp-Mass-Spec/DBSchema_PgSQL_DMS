--
-- Name: v_users_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_users_export AS
 SELECT u.user_id AS id,
    u.username,
    u.name,
    u.hid AS hanford_id,
    u.status,
    u.email,
    u.comment,
    u.created AS created_dms,
    u.name_with_username,
    u.active
   FROM public.t_users u;


ALTER TABLE public.v_users_export OWNER TO d3l243;

--
-- Name: TABLE v_users_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_users_export TO readaccess;
GRANT SELECT ON TABLE public.v_users_export TO writeaccess;


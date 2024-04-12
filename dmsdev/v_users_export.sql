--
-- Name: v_users_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_users_export AS
 SELECT user_id AS id,
    username,
    name,
    hid AS hanford_id,
    status,
    email,
    comment,
    created AS created_dms,
    name_with_username,
    active
   FROM public.t_users u;


ALTER VIEW public.v_users_export OWNER TO d3l243;

--
-- Name: TABLE v_users_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_users_export TO readaccess;
GRANT SELECT ON TABLE public.v_users_export TO writeaccess;


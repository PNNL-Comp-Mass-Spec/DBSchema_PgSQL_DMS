--
-- Name: v_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_users AS
 SELECT username,
    name,
    user_id AS id
   FROM public.t_users;


ALTER VIEW public.v_users OWNER TO d3l243;

--
-- Name: TABLE v_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_users TO readaccess;
GRANT SELECT ON TABLE public.v_users TO writeaccess;


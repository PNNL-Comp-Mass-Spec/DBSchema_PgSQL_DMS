--
-- Name: v_active_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_users AS
 SELECT username,
    name,
    (((((name)::text || (' ('::public.citext)::text) || (username)::text) || (')'::public.citext)::text))::public.citext AS name_with_username
   FROM public.t_users
  WHERE (status OPERATOR(public.=) 'Active'::public.citext);


ALTER VIEW public.v_active_users OWNER TO d3l243;

--
-- Name: TABLE v_active_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_users TO readaccess;
GRANT SELECT ON TABLE public.v_active_users TO writeaccess;


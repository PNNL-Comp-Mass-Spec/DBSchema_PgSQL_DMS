--
-- Name: v_users; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_users AS
 SELECT t_users.username,
    t_users.name,
    t_users.user_id AS id
   FROM public.t_users;


ALTER TABLE public.v_users OWNER TO d3l243;

--
-- Name: TABLE v_users; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_users TO readaccess;


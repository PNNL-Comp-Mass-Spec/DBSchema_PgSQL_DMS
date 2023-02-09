--
-- Name: v_experiment_user_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_user_picklist AS
 SELECT DISTINCT u.username,
    u.name
   FROM (public.t_users u
     JOIN public.t_experiments e ON ((e.researcher_username OPERATOR(public.=) u.username)))
  WHERE ((e.created > (CURRENT_TIMESTAMP - '1 year'::interval)) AND (u.status OPERATOR(public.=) 'Active'::public.citext));


ALTER TABLE public.v_experiment_user_picklist OWNER TO d3l243;

--
-- Name: TABLE v_experiment_user_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_user_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_user_picklist TO writeaccess;


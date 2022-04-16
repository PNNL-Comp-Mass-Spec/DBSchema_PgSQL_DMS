--
-- Name: t_eus_proposal_users_state_name; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_eus_proposal_users_state_name (
    eus_user_state_id integer NOT NULL,
    eus_user_state public.citext
);


ALTER TABLE public.t_eus_proposal_users_state_name OWNER TO d3l243;

--
-- Name: TABLE t_eus_proposal_users_state_name; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_eus_proposal_users_state_name TO readaccess;


--
-- Name: t_user_status; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_user_status (
    user_status public.citext NOT NULL,
    status_description public.citext
);


ALTER TABLE public.t_user_status OWNER TO d3l243;

--
-- Name: TABLE t_user_status; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_user_status TO readaccess;


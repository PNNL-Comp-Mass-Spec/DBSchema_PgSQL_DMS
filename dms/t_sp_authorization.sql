--
-- Name: t_sp_authorization; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sp_authorization (
    procedure_name public.citext NOT NULL,
    login_name public.citext NOT NULL,
    host_name public.citext NOT NULL
);


ALTER TABLE public.t_sp_authorization OWNER TO d3l243;

--
-- Name: TABLE t_sp_authorization; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sp_authorization TO readaccess;


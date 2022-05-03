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
-- Name: t_sp_authorization pk_t_sp_authorization; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sp_authorization
    ADD CONSTRAINT pk_t_sp_authorization PRIMARY KEY (procedure_name, login_name, host_name);

--
-- Name: TABLE t_sp_authorization; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sp_authorization TO readaccess;


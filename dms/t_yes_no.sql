--
-- Name: t_yes_no; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_yes_no (
    flag smallint NOT NULL,
    description public.citext NOT NULL
);


ALTER TABLE public.t_yes_no OWNER TO d3l243;

--
-- Name: t_yes_no pk_t_yes_no_flag; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_yes_no
    ADD CONSTRAINT pk_t_yes_no_flag PRIMARY KEY (flag);

--
-- Name: TABLE t_yes_no; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_yes_no TO readaccess;
GRANT SELECT ON TABLE public.t_yes_no TO writeaccess;


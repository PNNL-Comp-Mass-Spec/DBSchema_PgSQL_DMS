--
-- Name: t_data_release_restrictions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_data_release_restrictions (
    release_restriction_id integer NOT NULL,
    release_restriction public.citext NOT NULL
);


ALTER TABLE public.t_data_release_restrictions OWNER TO d3l243;

--
-- Name: t_data_release_restrictions pk_t_data_release_restrictions; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_data_release_restrictions
    ADD CONSTRAINT pk_t_data_release_restrictions PRIMARY KEY (release_restriction_id);

--
-- Name: TABLE t_data_release_restrictions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_data_release_restrictions TO readaccess;


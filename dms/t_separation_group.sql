--
-- Name: t_separation_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_separation_group (
    separation_group public.citext NOT NULL,
    comment public.citext DEFAULT ''::public.citext,
    active smallint DEFAULT 1 NOT NULL,
    sample_prep_visible smallint DEFAULT 1 NOT NULL,
    fraction_count smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.t_separation_group OWNER TO d3l243;

--
-- Name: t_separation_group pk_t_separation_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_separation_group
    ADD CONSTRAINT pk_t_separation_group PRIMARY KEY (separation_group);

ALTER TABLE public.t_separation_group CLUSTER ON pk_t_separation_group;

--
-- Name: TABLE t_separation_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_separation_group TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_separation_group TO writeaccess;


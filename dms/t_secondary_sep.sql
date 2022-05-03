--
-- Name: t_secondary_sep; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_secondary_sep (
    separation_type_id integer NOT NULL,
    separation_type public.citext NOT NULL,
    comment public.citext NOT NULL,
    active smallint NOT NULL,
    separation_group public.citext NOT NULL,
    sample_type_id integer NOT NULL,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_secondary_sep OWNER TO d3l243;

--
-- Name: t_secondary_sep pk_t_secondary_sep; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep
    ADD CONSTRAINT pk_t_secondary_sep PRIMARY KEY (separation_type_id);

--
-- Name: TABLE t_secondary_sep; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_secondary_sep TO readaccess;


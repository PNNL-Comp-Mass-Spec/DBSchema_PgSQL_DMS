--
-- Name: t_secondary_sep_sample_type; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_secondary_sep_sample_type (
    sample_type_id integer NOT NULL,
    name public.citext NOT NULL
);


ALTER TABLE public.t_secondary_sep_sample_type OWNER TO d3l243;

--
-- Name: t_secondary_sep_sample_type pk_t_secondary_sep_sample_type_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_secondary_sep_sample_type
    ADD CONSTRAINT pk_t_secondary_sep_sample_type_id PRIMARY KEY (sample_type_id);

--
-- Name: TABLE t_secondary_sep_sample_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_secondary_sep_sample_type TO readaccess;


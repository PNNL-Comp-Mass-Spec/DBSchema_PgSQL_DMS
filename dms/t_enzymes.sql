--
-- Name: t_enzymes; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_enzymes (
    enzyme_id integer NOT NULL,
    enzyme_name public.citext NOT NULL,
    description public.citext NOT NULL,
    p1 public.citext NOT NULL,
    p1_exception public.citext NOT NULL,
    p2 public.citext NOT NULL,
    p2_exception public.citext NOT NULL,
    cleavage_method public.citext NOT NULL,
    cleavage_offset smallint NOT NULL,
    sequest_enzyme_index integer,
    protein_collection_name public.citext,
    comment public.citext
);


ALTER TABLE public.t_enzymes OWNER TO d3l243;

--
-- Name: t_enzymes_enzyme_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_enzymes ALTER COLUMN enzyme_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_enzymes_enzyme_id_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_enzymes pk_t_enzymes; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_enzymes
    ADD CONSTRAINT pk_t_enzymes PRIMARY KEY (enzyme_id);

--
-- Name: TABLE t_enzymes; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_enzymes TO readaccess;


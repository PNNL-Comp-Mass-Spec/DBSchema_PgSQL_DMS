--
-- Name: t_organism_db_file; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_organism_db_file (
    org_db_file_id integer NOT NULL,
    file_name public.citext NOT NULL,
    organism_id integer NOT NULL,
    description public.citext,
    active smallint NOT NULL,
    num_proteins integer,
    num_residues bigint,
    valid smallint,
    file_size_kb real,
    created timestamp without time zone
);


ALTER TABLE public.t_organism_db_file OWNER TO d3l243;

--
-- Name: t_organism_db_file_org_db_file_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_organism_db_file ALTER COLUMN org_db_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_organism_db_file_org_db_file_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_organism_db_file pk_t_organism_db_file; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organism_db_file
    ADD CONSTRAINT pk_t_organism_db_file PRIMARY KEY (org_db_file_id);

--
-- Name: TABLE t_organism_db_file; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organism_db_file TO readaccess;


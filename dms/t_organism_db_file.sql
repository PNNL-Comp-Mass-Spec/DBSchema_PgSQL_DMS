--
-- Name: t_organism_db_file; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_organism_db_file (
    org_db_file_id integer NOT NULL,
    file_name public.citext NOT NULL,
    organism_id integer NOT NULL,
    description public.citext DEFAULT ''::public.citext,
    active smallint DEFAULT 1 NOT NULL,
    num_proteins integer,
    num_residues bigint,
    valid smallint DEFAULT 1,
    file_size_kb real DEFAULT 0,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: t_organism_db_file ix_t_organism_db_file_unique_file_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organism_db_file
    ADD CONSTRAINT ix_t_organism_db_file_unique_file_name UNIQUE (file_name);

--
-- Name: t_organism_db_file pk_t_organism_db_file; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organism_db_file
    ADD CONSTRAINT pk_t_organism_db_file PRIMARY KEY (org_db_file_id);

--
-- Name: t_organism_db_file fk_t_organism_db_file_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_organism_db_file
    ADD CONSTRAINT fk_t_organism_db_file_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: TABLE t_organism_db_file; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organism_db_file TO readaccess;


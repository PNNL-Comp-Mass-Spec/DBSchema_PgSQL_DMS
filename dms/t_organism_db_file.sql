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
-- Name: TABLE t_organism_db_file; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_organism_db_file TO readaccess;


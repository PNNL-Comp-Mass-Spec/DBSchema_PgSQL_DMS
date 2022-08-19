--
-- Name: t_archived_output_files; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_archived_output_files (
    archived_file_id integer NOT NULL,
    archived_file_type_id integer NOT NULL,
    archived_file_state_id integer NOT NULL,
    archived_file_path public.citext NOT NULL,
    svn_repository_path public.citext,
    svn_revision_number integer,
    authentication_hash public.citext NOT NULL,
    file_size_bytes bigint NOT NULL,
    protein_count integer,
    creation_options public.citext,
    archived_file_creation_date timestamp without time zone NOT NULL,
    file_modification_date timestamp without time zone NOT NULL,
    protein_collection_list public.citext,
    collection_list_hash public.citext,
    collection_list_hex_hash public.citext
);


ALTER TABLE pc.t_archived_output_files OWNER TO d3l243;

--
-- Name: t_archived_output_files_archived_file_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_archived_output_files ALTER COLUMN archived_file_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_archived_output_files_archived_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_archived_output_files pk_t_archived_output_files; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_output_files
    ADD CONSTRAINT pk_t_archived_output_files PRIMARY KEY (archived_file_id);

--
-- Name: t_archived_output_files fk_t_archived_output_files_t_archived_file_states; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_output_files
    ADD CONSTRAINT fk_t_archived_output_files_t_archived_file_states FOREIGN KEY (archived_file_state_id) REFERENCES pc.t_archived_file_states(archived_file_state_id);

--
-- Name: t_archived_output_files fk_t_archived_output_files_t_archived_file_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_archived_output_files
    ADD CONSTRAINT fk_t_archived_output_files_t_archived_file_types FOREIGN KEY (archived_file_type_id) REFERENCES pc.t_archived_file_types(archived_file_type_id);

--
-- Name: TABLE t_archived_output_files; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_archived_output_files TO readaccess;


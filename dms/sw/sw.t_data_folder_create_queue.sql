--
-- Name: t_data_folder_create_queue; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_data_folder_create_queue (
    entry_id integer NOT NULL,
    state integer DEFAULT 1 NOT NULL,
    source_db public.citext,
    source_table public.citext,
    source_id integer,
    source_id_field_name public.citext,
    path_local_root public.citext NOT NULL,
    path_shared_root public.citext NOT NULL,
    path_folder public.citext NOT NULL,
    command public.citext DEFAULT 'add'::public.citext NOT NULL,
    processor public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer
);


ALTER TABLE sw.t_data_folder_create_queue OWNER TO d3l243;

--
-- Name: t_data_folder_create_queue_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_data_folder_create_queue ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_data_folder_create_queue_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_folder_create_queue pk_data_folder_create_queue; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_data_folder_create_queue
    ADD CONSTRAINT pk_data_folder_create_queue PRIMARY KEY (entry_id);

--
-- Name: TABLE t_data_folder_create_queue; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_data_folder_create_queue TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_data_folder_create_queue TO writeaccess;


--
-- Name: t_dataset_archive; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset_archive (
    dataset_id integer NOT NULL,
    archive_state_id integer NOT NULL,
    archive_state_last_affected timestamp without time zone,
    storage_path_id integer NOT NULL,
    archive_date timestamp without time zone,
    last_update timestamp without time zone,
    last_verify timestamp without time zone,
    archive_update_state_id integer,
    archive_update_state_last_affected timestamp without time zone,
    purge_holdoff_date timestamp without time zone,
    archive_processor public.citext,
    update_processor public.citext,
    verification_processor public.citext,
    instrument_data_purged smallint NOT NULL,
    last_successful_archive timestamp without time zone,
    stagemd5_required smallint NOT NULL,
    qc_data_purged smallint NOT NULL,
    purge_policy smallint NOT NULL,
    purge_priority smallint NOT NULL,
    myemsl_state smallint NOT NULL
);


ALTER TABLE public.t_dataset_archive OWNER TO d3l243;

--
-- Name: TABLE t_dataset_archive; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset_archive TO readaccess;


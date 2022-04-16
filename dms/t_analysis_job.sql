--
-- Name: t_analysis_job; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job (
    job integer NOT NULL,
    batch_id integer,
    priority integer NOT NULL,
    created timestamp without time zone NOT NULL,
    start timestamp without time zone,
    finish timestamp without time zone,
    analysis_tool_id integer NOT NULL,
    param_file_name public.citext NOT NULL,
    settings_file_name public.citext,
    organism_db_name public.citext,
    organism_id integer NOT NULL,
    dataset_id integer NOT NULL,
    comment public.citext,
    owner public.citext,
    job_state_id integer NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    assigned_processor_name public.citext,
    results_folder_name public.citext,
    protein_collection_list public.citext,
    protein_options_list public.citext NOT NULL,
    request_id integer NOT NULL,
    extraction_processor public.citext,
    extraction_start timestamp without time zone,
    extraction_finish timestamp without time zone,
    analysis_manager_error smallint NOT NULL,
    data_extraction_error smallint NOT NULL,
    propagation_mode smallint NOT NULL,
    state_name_cached public.citext NOT NULL,
    processing_time_minutes real,
    special_processing public.citext,
    dataset_unreviewed smallint NOT NULL,
    purged smallint NOT NULL,
    myemsl_state smallint NOT NULL,
    analysis_tool_cached public.citext,
    progress real,
    eta_minutes real
);


ALTER TABLE public.t_analysis_job OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job TO readaccess;


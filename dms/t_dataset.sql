--
-- Name: t_dataset; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_dataset (
    dataset_id integer NOT NULL,
    dataset public.citext NOT NULL,
    operator_prn public.citext NOT NULL,
    comment public.citext,
    created timestamp without time zone NOT NULL,
    instrument_id integer,
    lc_column_id integer,
    dataset_type_id integer,
    wellplate public.citext,
    well public.citext,
    separation_type public.citext,
    ds_state_id integer NOT NULL,
    last_affected timestamp without time zone NOT NULL,
    folder_name public.citext,
    storage_path_id integer,
    exp_id integer NOT NULL,
    internal_standard_id integer,
    dataset_rating_id smallint NOT NULL,
    ds_comp_state smallint,
    ds_compress_date timestamp without time zone,
    ds_prep_server_name public.citext NOT NULL,
    acq_time_start timestamp without time zone,
    acq_time_end timestamp without time zone,
    scan_count integer,
    file_size_bytes bigint,
    file_info_last_modified timestamp without time zone,
    interval_to_next_ds integer,
    acq_length_minutes integer GENERATED ALWAYS AS (COALESCE((EXTRACT(epoch FROM (acq_time_end - acq_time_start)) / (60)::numeric), (0)::numeric)) STORED,
    date_sort_key timestamp without time zone NOT NULL,
    decon_tools_job_for_qc integer,
    capture_subfolder public.citext,
    cart_config_id integer
);


ALTER TABLE public.t_dataset OWNER TO d3l243;

--
-- Name: TABLE t_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_dataset TO readaccess;


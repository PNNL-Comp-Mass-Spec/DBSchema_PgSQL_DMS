--
-- Name: v_myemsl_uploads2; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_uploads2 AS
 SELECT mu.entry_id,
    mu.job,
    ds.dataset,
    mu.dataset_id,
    mu.subfolder,
    mu.file_count_new,
    mu.file_count_updated,
    round((((mu.bytes)::numeric / 1024.0) / 1024.0), 3) AS mb,
    round((mu.upload_time_seconds)::numeric, 1) AS upload_time_seconds,
    mu.status_uri_path_id,
    mu.status_num,
    mu.error_code,
    mu.transaction_id,
    (((statusu.uri_path)::text || (mu.status_num)::text) ||
        CASE
            WHEN (statusu.uri_path OPERATOR(public.~~) '%/status/%'::public.citext) THEN '/xml'::text
            ELSE ''::text
        END) AS status_uri,
    mu.verified,
    mu.ingest_steps_completed,
    mu.entered,
    mu.eus_instrument_id,
    mu.eus_proposal_id,
    mu.eus_uploader_id,
    tf.transfer_folder_path,
    dfp.dataset_folder_path
   FROM ((((cap.t_myemsl_uploads mu
     LEFT JOIN cap.t_uri_paths statusu ON ((mu.status_uri_path_id = statusu.uri_path_id)))
     LEFT JOIN public.t_dataset ds ON ((mu.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((mu.dataset_id = dfp.dataset_id)))
     LEFT JOIN ( SELECT ds_1.dataset_id,
            (((transferq.vol_name_client)::text || (transferq.storage_path)::text) || (ds_1.dataset)::text) AS transfer_folder_path
           FROM ((public.t_dataset ds_1
             JOIN public.t_storage_path spath ON ((ds_1.storage_path_id = spath.storage_path_id)))
             JOIN ( SELECT t_storage_path.machine_name,
                    t_storage_path.storage_path,
                    t_storage_path.vol_name_client
                   FROM public.t_storage_path
                  WHERE (t_storage_path.storage_path_function OPERATOR(public.=) 'results_transfer'::public.citext)) transferq ON ((spath.machine_name OPERATOR(public.=) transferq.machine_name)))) tf ON ((mu.dataset_id = tf.dataset_id)));


ALTER TABLE cap.v_myemsl_uploads2 OWNER TO d3l243;


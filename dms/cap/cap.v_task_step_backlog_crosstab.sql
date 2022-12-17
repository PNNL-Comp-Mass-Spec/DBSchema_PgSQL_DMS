--
-- Name: v_task_step_backlog_crosstab; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_backlog_crosstab AS
 SELECT ct.posting_time,
    COALESCE(ct."ArchiveStatusCheck", 0) AS archive_status_check,
    COALESCE(ct."ArchiveUpdate", 0) AS archive_update,
    COALESCE(ct."ArchiveVerify", 0) AS archive_verify,
    COALESCE(ct."DatasetArchive", 0) AS dataset_archive,
    COALESCE(ct."DatasetCapture", 0) AS dataset_capture,
    COALESCE(ct."DatasetInfo", 0) AS dataset_info,
    COALESCE(ct."DatasetIntegrity", 0) AS dataset_integrity,
    COALESCE(ct."DatasetQuality", 0) AS dataset_quality,
    COALESCE(ct."SourceFileRename", 0) AS source_file_rename,
    COALESCE(ct."ImsDeMultiplex", 0) AS ims_demultiplex
   FROM public.crosstab('SELECT date_trunc(''minute'', posting_time) AS posting_time,
           step_tool,
           backlog_count
    FROM cap.v_task_step_backlog_history
    ORDER  BY 1,2'::text, 'SELECT unnest(''{ArchiveStatusCheck, ArchiveUpdate, ArchiveVerify,
                     DatasetArchive, DatasetCapture, DatasetInfo,
                     DatasetIntegrity, DatasetQuality,
                     SourceFileRename, ImsDeMultiplex}''::text[])'::text) ct(posting_time timestamp without time zone, "ArchiveStatusCheck" integer, "ArchiveUpdate" integer, "ArchiveVerify" integer, "DatasetArchive" integer, "DatasetCapture" integer, "DatasetInfo" integer, "DatasetIntegrity" integer, "DatasetQuality" integer, "SourceFileRename" integer, "ImsDeMultiplex" integer);


ALTER TABLE cap.v_task_step_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_task_step_backlog_crosstab; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_step_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE cap.v_task_step_backlog_crosstab TO writeaccess;


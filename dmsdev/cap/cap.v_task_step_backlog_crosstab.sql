--
-- Name: v_task_step_backlog_crosstab; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_backlog_crosstab AS
 SELECT posting_time,
    COALESCE("ArchiveStatusCheck", 0) AS archive_status_check,
    COALESCE("ArchiveUpdate", 0) AS archive_update,
    COALESCE("ArchiveVerify", 0) AS archive_verify,
    COALESCE("DatasetArchive", 0) AS dataset_archive,
    COALESCE("DatasetCapture", 0) AS dataset_capture,
    COALESCE("DatasetInfo", 0) AS dataset_info,
    COALESCE("DatasetIntegrity", 0) AS dataset_integrity,
    COALESCE("DatasetQuality", 0) AS dataset_quality,
    COALESCE("SourceFileRename", 0) AS source_file_rename,
    COALESCE("ImsDeMultiplex", 0) AS ims_demultiplex
   FROM public.crosstab('SELECT date_trunc(''minute'', posting_time) AS posting_time,
           step_tool,
           backlog_count
    FROM cap.v_task_step_backlog_history
    ORDER BY 1,2'::text, 'SELECT unnest(
                  ''{ArchiveStatusCheck, ArchiveUpdate, ArchiveVerify,
                     DatasetArchive, DatasetCapture, DatasetInfo,
                     DatasetIntegrity, DatasetQuality,
                     SourceFileRename, ImsDeMultiplex}''::text[])'::text) ct(posting_time timestamp without time zone, "ArchiveStatusCheck" integer, "ArchiveUpdate" integer, "ArchiveVerify" integer, "DatasetArchive" integer, "DatasetCapture" integer, "DatasetInfo" integer, "DatasetIntegrity" integer, "DatasetQuality" integer, "SourceFileRename" integer, "ImsDeMultiplex" integer);


ALTER VIEW cap.v_task_step_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_task_step_backlog_crosstab; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_task_step_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE cap.v_task_step_backlog_crosstab TO writeaccess;


--
-- Name: v_task_step_backlog_crosstab; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_task_step_backlog_crosstab AS
 SELECT ct.posting_time,
    ct."ArchiveStatusCheck",
    ct."ArchiveUpdate",
    ct."ArchiveVerify",
    ct."DatasetArchive",
    ct."DatasetCapture",
    ct."DatasetInfo",
    ct."DatasetIntegrity",
    ct."DatasetQuality",
    ct."SourceFileRename",
    ct."ImsDeMultiplex"
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


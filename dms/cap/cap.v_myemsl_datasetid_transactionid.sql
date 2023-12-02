--
-- Name: v_myemsl_datasetid_transactionid; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_datasetid_transactionid AS
 SELECT t_myemsl_uploads.dataset_id,
    COALESCE(t_myemsl_uploads.transaction_id, t_myemsl_uploads.status_num) AS transaction_id,
    t_myemsl_uploads.verified,
    t_myemsl_uploads.file_count_new,
    t_myemsl_uploads.file_count_updated
   FROM cap.t_myemsl_uploads
  WHERE ((NOT (t_myemsl_uploads.status_num IS NULL)) OR (NOT (t_myemsl_uploads.transaction_id IS NULL)));


ALTER VIEW cap.v_myemsl_datasetid_transactionid OWNER TO d3l243;

--
-- Name: VIEW v_myemsl_datasetid_transactionid; Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON VIEW cap.v_myemsl_datasetid_transactionid IS 'TransactionID was deprecated 2019-05-21; use StatusNum (aka MyEMSL Upload ID) if transaction_id is null';

--
-- Name: TABLE v_myemsl_datasetid_transactionid; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_myemsl_datasetid_transactionid TO readaccess;
GRANT SELECT ON TABLE cap.v_myemsl_datasetid_transactionid TO writeaccess;


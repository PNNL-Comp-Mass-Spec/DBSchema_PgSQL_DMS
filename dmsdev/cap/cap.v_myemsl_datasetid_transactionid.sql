--
-- Name: v_myemsl_datasetid_transactionid; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_myemsl_datasetid_transactionid AS
 SELECT dataset_id,
    COALESCE(transaction_id, status_num) AS transaction_id,
    verified,
    file_count_new,
    file_count_updated
   FROM cap.t_myemsl_uploads
  WHERE ((NOT (status_num IS NULL)) OR (NOT (transaction_id IS NULL)));


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


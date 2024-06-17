--
-- Name: get_dataset_myemsl_transaction_ids(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_myemsl_transaction_ids(_datasetid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Returns a comma-separated list of the MyEMSL ingest transaction IDs for this dataset ID
**
**  Arguments:
**     _datasetID   Dataset ID
**
**  Auth:   mem
**  Date:   02/28/2018 mem - Initial version
**          06/19/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(Transaction_ID::text, ', ' ORDER BY Transaction_ID)
    INTO _result
    FROM cap.V_MyEMSL_DatasetID_TransactionID
    WHERE Dataset_ID = _datasetID AND
          Verified > 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_dataset_myemsl_transaction_ids(_datasetid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_myemsl_transaction_ids(_datasetid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_myemsl_transaction_ids(_datasetid integer) IS 'GetDatasetMyEMSLTransactionIDs';


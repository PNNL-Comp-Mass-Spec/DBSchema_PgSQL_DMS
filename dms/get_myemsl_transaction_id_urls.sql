--
-- Name: get_myemsl_transaction_id_urls(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_myemsl_transaction_id_urls(_datasetid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a comma-separated list of the URLs used to view files associated with
**      each transaction ID for this dataset ID
**
**  Arguments:
**    _datasetID    Dataset ID
**
**  Auth:   mem
**  Date:   02/28/2018 mem - Initial version
**          06/13/2022 mem - Ported to PostgreSQL
**          12/24/2022 mem - Use ::text
**          05/24/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(format('https://status.my.emsl.pnl.gov/view/%s', transaction_id), ', ' ORDER BY transaction_id)
    INTO _result
    FROM cap.V_MyEMSL_DatasetID_TransactionID
    WHERE Dataset_ID = _datasetID AND
          Verified > 0;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_myemsl_transaction_id_urls(_datasetid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_myemsl_transaction_id_urls(_datasetid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_myemsl_transaction_id_urls(_datasetid integer) IS 'GetMyEMSLTransactionIdURLs';


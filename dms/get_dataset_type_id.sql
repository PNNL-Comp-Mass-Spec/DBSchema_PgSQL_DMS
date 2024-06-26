--
-- Name: get_dataset_type_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_type_id(_datasettype text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get dataset type ID for given for given dataset type name
**
**  Arguments:
**    _datasetType      Dataset type name
**
**  Example usage:
**      SELECT public.get_dataset_type_id('HMS-MSn');
**      SELECT public.get_dataset_type_id('HMS-HCD-HMSn');
**      SELECT public.get_dataset_type_id('IMS-HMS-HMSn');
**
**  Auth:   grk
**  Date:   01/26/2001 grk - Initial version
**          09/02/2010 mem - Expand _datasetType to varchar(50)
**          08/03/2017 mem - Add Set NoCount On
**          10/18/2022 mem - Ported to PostgreSQL
**          09/07/2023 mem - Ignore case when querying t_dataset_type_name
**
*****************************************************/
DECLARE
    _datasetTypeID int;
BEGIN
    SELECT dataset_type_id
    INTO _datasetTypeID
    FROM t_dataset_type_name
    WHERE dataset_type  = _datasetType::citext;

    If FOUND Then
        RETURN _datasetTypeID;
    Else
        RETURN 0;
    End If;

END
$$;


ALTER FUNCTION public.get_dataset_type_id(_datasettype text) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_type_id(_datasettype text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_type_id(_datasettype text) IS 'GetDatasetTypeID';


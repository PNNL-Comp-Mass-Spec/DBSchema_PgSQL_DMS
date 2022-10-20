--
-- Name: get_dataset_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_id(_datasetname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets dataset ID for given dataset name
**
**  Example usage:
**      SELECT get_dataset_id ('Blank_Pos_11Aug22_Fiji_Infusion_r1');
**      SELECT get_dataset_id ('QC_Mam_19_01_R1_08Aug22_Oak_WBEH_22-06-16');
**
**  Auth:   grk
**  Date:   01/26/2001 grk - Initial version
**          08/03/2017 mem - Add Set NoCount On
**          10/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
BEGIN
    SELECT dataset_id
    INTO _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName;

    If FOUND Then
        RETURN _datasetID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_dataset_id(_datasetname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_id(_datasetname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_id(_datasetname text) IS 'GetDatasetID';


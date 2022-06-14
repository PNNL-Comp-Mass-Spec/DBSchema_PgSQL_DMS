--
-- Name: get_dataset_factor_count(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_factor_count(_datasetid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a count of the number of factors defined for this dataset
**
**  Auth:   mem
**  Date:   07/25/2017 mem - Initial version
**          06/13/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result int;
BEGIN

    SELECT Factor_Count
    INTO _result
    FROM V_Factor_Count_By_Dataset
    WHERE Dataset_ID = _datasetID;

    RETURN Coalesce(_result, 0);
END
$$;


ALTER FUNCTION public.get_dataset_factor_count(_datasetid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_factor_count(_datasetid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_factor_count(_datasetid integer) IS 'GetDatasetFactorCount';


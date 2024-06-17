--
-- Name: get_dataset_rating_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_rating_id(_datasetratingname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get dataset rating ID for given dataset rating name
**
**  Arguments:
**     _datasetRatingName     Dataset name
**
**  Example usage:
**      SELECT public.get_dataset_rating_id('Unknown');
**      SELECT public.get_dataset_rating_id('Unreviewed');
**      SELECT public.get_dataset_rating_id('Released');
**
**  Auth:   grk
**  Date:   01/26/2001 grk - Initial version
**          08/03/2017 mem - Add set nocount on
**          10/18/2022 mem - Ported to PostgreSQL
**          01/20/2024 mem - Ignore case when resolving dataset rating name to ID
**
*****************************************************/
DECLARE
    _datasetRatingID int;
BEGIN
    SELECT dataset_rating_id
    INTO _datasetRatingID
    FROM t_dataset_rating_name
    WHERE dataset_rating  = _datasetRatingName::citext;

    If FOUND Then
        RETURN _datasetRatingID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_dataset_rating_id(_datasetratingname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_rating_id(_datasetratingname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_rating_id(_datasetratingname text) IS 'GetDatasetRatingID';


--
-- Name: get_instrument_group_dataset_type_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_group_dataset_type_list(_instrumentgroup text, _delimiter text DEFAULT ', '::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of allowed dataset types for given instrument group
**
**  Arguments:
**    _instrumentGroup  Instrument group name
**    _delimiter        List delimited
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   08/28/2010 grk - Initial version
**          02/04/2021 mem - Add argument _delimiter
**          06/14/2022 mem - Ported to PostgreSQL
**          01/15/2023 mem - Cast _instrumentGroup to citext
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(dataset_type, _delimiter ORDER BY dataset_type)
    INTO _result
    FROM t_instrument_group_allowed_ds_type
    WHERE instrument_group = _instrumentGroup::citext;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_instrument_group_dataset_type_list(_instrumentgroup text, _delimiter text) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_group_dataset_type_list(_instrumentgroup text, _delimiter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_group_dataset_type_list(_instrumentgroup text, _delimiter text) IS 'GetInstrumentGroupDatasetTypeList';


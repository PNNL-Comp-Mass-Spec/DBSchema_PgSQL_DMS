--
-- Name: get_instrument_dataset_type_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_dataset_type_list(_instrumentid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of allowed dataset types for given instrument ID
**
**  Arguments:
**    _instrumentID     Instrument ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   09/17/2009 mem - Initial version (Ticket #748)
**          08/28/2010 mem - Updated to use Get_Instrument_Group_Dataset_Type_List
**          02/04/2021 mem - Provide a delimiter when calling Get_Instrument_Group_Dataset_Type_List
**          06/14/2022 mem - Ported to PostgreSQL
**          04/04/2023 mem - Use char_length() to determine string length
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _list text := '';
    _instrumentGroup text := '';
BEGIN

    -- Lookup the instrument group for this instrument

    SELECT instrument_group
    INTO _instrumentGroup
    FROM t_instrument_name
    WHERE instrument_id = _instrumentID;

    If Trim(Coalesce(_instrumentGroup)) <> '' Then
        _list = public.get_instrument_group_dataset_type_list(_instrumentGroup, ', ');
    End If;

    RETURN _list;
END
$$;


ALTER FUNCTION public.get_instrument_dataset_type_list(_instrumentid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_dataset_type_list(_instrumentid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_dataset_type_list(_instrumentid integer) IS 'GetInstrumentDatasetTypeList';


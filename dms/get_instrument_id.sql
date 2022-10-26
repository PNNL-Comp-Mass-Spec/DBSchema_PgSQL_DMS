--
-- Name: get_instrument_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_instrument_id(_instrumentname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets InstrumentID for given instrument name
**
**  Return values: instrument ID if found, otherwise 0
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _instrumentID int;
BEGIN
    SELECT instrument_id
    INTO _instrumentID
    FROM t_instrument_name
    WHERE instrument = _instrumentName::citext;

    If FOUND Then
        RETURN _instrumentID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_instrument_id(_instrumentname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_instrument_id(_instrumentname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_instrument_id(_instrumentname text) IS 'GetInstrumentID';


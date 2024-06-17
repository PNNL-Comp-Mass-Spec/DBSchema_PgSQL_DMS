--
-- Name: get_well_index(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_well_index(_wellposition text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given a 96 well plate well position (aka well number),
**      return the index position of the well (value between 1 and 96)
**
**      The first row of the plate has wells A1 through A12
**      The last  row of the plate has wells H1 through H12
**
**  Returns:
**      Corresponding well index, or 0 if invalid position
**
**  Arguments:
**    _wellPosition   Well position, e.g. B3 or H04
**
**  Auth:   grk
**  Date:   07/15/2000
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**          09/11/2023 mem - Use schema name with try_cast
**          01/21/2024 mem - Change data type of argument _wellPosition to text
**
*****************************************************/
DECLARE
    _index int;
    _wpRow int;
    _wpRowCharBase int;
    _wpCol int;
    _numCols int;
BEGIN
    _wellPosition := Trim(Coalesce(_wellPosition, ''));

    If char_length(_wellPosition) < 2 Then
        RETURN 0;
    End If;

    _wpRowCharBase := ASCII('A');
    _numCols := 12;

    -- Get row and column for current well
    _wpRow := ASCII(Upper(Substring(_wellPosition, 1, 1))) - _wpRowCharBase;
    _wpCol := public.try_cast(Substring(_wellPosition, 2, 20), -1);

    If _wpRow <= 7 and _wpRow >= 0 and _wpCol <= 12 and _wpCol >= 1 Then
        _index := (_wpRow * _numCols) + _wpCol;
    Else
        _index := 0;
    End If;

    RETURN _index;
END
$$;


ALTER FUNCTION public.get_well_index(_wellposition text) OWNER TO d3l243;

--
-- Name: FUNCTION get_well_index(_wellposition text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_well_index(_wellposition text) IS 'GetWellIndex';


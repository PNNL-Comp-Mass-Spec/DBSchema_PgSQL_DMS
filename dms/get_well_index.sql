--
-- Name: get_well_index(text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_well_index(_wellposition text, _wellcount integer DEFAULT 96) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given a 96 well plate well position (aka well number),
**      return the index position of the well (value between 1 and 96)
**
**      The first row of the plate has wells A01 through A12
**      The last  row of the plate has wells H01 through H12
**
**      For 384 well plates
**      the index position of the well is between 1 and 384
**
**      The first row of the plate has wells A01 through A24
**      The last  row of the plate has wells P01 through P24
**
**  Returns:
**      Corresponding well index, or 0 if invalid position
**
**  Arguments:
**    _wellPosition     Well position, e.g. B3 or H04
**    _wellCount        Number of wells in the plate: 24, 96, or 384
**
**  Auth:   grk
**  Date:   07/15/2000
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**          09/11/2023 mem - Use schema name with try_cast
**          01/21/2024 mem - Change data type of argument _wellPosition to text
**          08/21/2024 mem - Allow _wellNumber to be an integer instead of A1, A2, A3, A04, B06, etc.
**          07/27/2026 mem - Add support for 384 well plates
**
*****************************************************/
DECLARE
    _integerWellNumber int;
    _index int;
    _wpRow int;
    _wpRowCharBase int;
    _wpCol int;
    _numCols int;
BEGIN
    _wellPosition := Trim(Coalesce(_wellPosition, ''));

    _integerWellNumber := public.try_cast(_wellPosition, null::int);

    If Not _integerWellNumber Is Null Then
        -- The well number is an integer
        RETURN _integerWellNumber;
    End If;

    If char_length(_wellPosition) < 2 Then
        RETURN 0;
    End If;

    _wpRowCharBase := ASCII('A');

    If _wellCount = 24 Then
        _numCols := 6;
    ElsIf _wellCount = 384 Then
        _numCols := 24;
    Else
        -- Assume well count is 96
        _numCols := 12;
    End If;

    -- Get row and column for current well
    _wpRow := ASCII(Upper(Substring(_wellPosition, 1, 1))) - _wpRowCharBase;
    _wpCol := public.try_cast(Substring(_wellPosition, 2, 20), -1);

    If _wellCount = 24     And _wpRow >= 0 And _wpRow <= 3  And _wpCol >= 1 And _wpCol <= 6 Then
        _index := (_wpRow * _numCols) + _wpCol;
    ElsIf _wellCount = 96  And _wpRow >= 0 And _wpRow <= 7  And _wpCol >= 1 And _wpCol <= 12 Then
        _index := (_wpRow * _numCols) + _wpCol;
    ElsIf _wellCount = 384 And _wpRow >= 0 And _wpRow <= 15 And _wpCol >= 1 And _wpCol <= 24 Then
        _index := (_wpRow * _numCols) + _wpCol;
    Else
        _index := 0;
    End If;

    RETURN _index;
END
$$;


ALTER FUNCTION public.get_well_index(_wellposition text, _wellcount integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_well_index(_wellposition text, _wellcount integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_well_index(_wellposition text, _wellcount integer) IS 'GetWellIndex';


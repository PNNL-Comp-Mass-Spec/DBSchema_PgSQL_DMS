--
-- Name: get_well_position(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_well_position(_index integer, _wellcount integer DEFAULT 96) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given a 96 well plate well index number (value between 1 and 96),
**      return the well position (aka well number), e.g. B09 or F12
**
**      Also supports 384 well plates and 24 well plates
**
**  Returns:
**      Well position, or empty string if invalid index
**
**  Arguments:
**    _index        One-based well index
**    _wellCount    Number of wells in the plate: 24, 96, or 384
**
**  Auth:   grk
**  Date:   07/15/2000
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**          07/27/2026 mem - Add support for 384 well plates
**
*****************************************************/
DECLARE
    _wpRow int;
    _wpRowCharBase int;
    _numCols int;
    _wpCol int;
    _row text;
    _col text;
BEGIN
    _index := Coalesce(_index, 0);

    If _index < 1 Or _index > _wellCount Then
        RETURN '';
    End If;

    _wpRowCharBase := ASCII('A');

    If _wellCount = 24 Then
        _numCols := 6;

        _wpRow = CASE WHEN _index <= 6 THEN 0
                      WHEN _index <= 12 THEN 1
                      WHEN _index <= 18 THEN 2
                      WHEN _index <= 24 THEN 3
                 END;

    ElsIf _wellCount = 384 Then
        _numCols := 24;

        _wpRow = CASE WHEN _index <= 24 THEN 0
                      wHEN _index <= 48 THEN 1
                      wHEN _index <= 72 THEN 2
                      wHEN _index <= 96 THEN 3
                      wHEN _index <= 120 THEN 4
                      wHEN _index <= 144 THEN 5
                      wHEN _index <= 168 THEN 6
                      wHEN _index <= 192 THEN 7
                      wHEN _index <= 216 THEN 8
                      wHEN _index <= 240 THEN 9
                      wHEN _index <= 264 THEN 10
                      wHEN _index <= 288 THEN 11
                      wHEN _index <= 312 THEN 12
                      wHEN _index <= 336 THEN 13
                      wHEN _index <= 360 THEN 14
                      wHEN _index <= 384 THEN 15
                      ELSE 0
                 END;
    Else
        -- Assume well count is 96
        _numCols := 12;

        _wpRow = CASE WHEN _index <= 12 THEN 0
                      WHEN _index <= 24 THEN 1
                      WHEN _index <= 36 THEN 2
                      WHEN _index <= 48 THEN 3
                      WHEN _index <= 60 THEN 4
                      WHEN _index <= 72 THEN 5
                      WHEN _index <= 84 THEN 6
                      WHEN _index <= 96 THEN 7
                      ELSE 0
                 END;
    End If;

    _wpCol := _index - (_wpRow * _numCols);

    _row := chr(_wpRow + _wpRowCharBase);
    _col := to_char(_wpCol, 'fm00');

    -- Return well position
    RETURN format('%s%s', _row, _col);
END
$$;


ALTER FUNCTION public.get_well_position(_index integer, _wellcount integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_well_position(_index integer, _wellcount integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_well_position(_index integer, _wellcount integer) IS 'GetWellNum';


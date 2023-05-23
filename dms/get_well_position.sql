--
-- Name: get_well_position(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_well_position(_index integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given 96 well plate well index number (value between 1 and 96),
**      return the well position (aka well number), e.g. B09 or F12
**
**  Return values: well position, or empty string if invalid index
**
**  Auth:   grk
**  Date:   07/15/2000
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Use format() for string concatenation
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

    If _index < 1 OR _index > 96 Then
        RETURN '';
    End If;

    _wpRowCharBase := ASCII('A');
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

    _wpCol := _index - (_wpRow * _numCols);

    _row := chr(_wpRow + _wpRowCharBase);
    _col := to_char(_wpCol, 'fm00');

    -- Return well position
    RETURN format('%s%s', _row, _col);
END
$$;


ALTER FUNCTION public.get_well_position(_index integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_well_position(_index integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_well_position(_index integer) IS 'GetWellNum';


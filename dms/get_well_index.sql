--
-- Name: get_well_index(public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_well_index(_wellposition public.citext) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Given 96 well plate well position (aka well number),
**      return the index position of the well (value between 1 and 96)
**
**      The first row of the plate has wells A1 through A12
**      The last  row of the plate has wells H1 through H12
*
**  Return values: corresponding well index, or 0 if invalid position
**
**  Arguments:
**    _wellPosition   Well position, e.g. B3 or H04
**
**  Auth:   grk
**  Date:   07/15/2000
**          06/23/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _index int;
    _wpRow int;
    _wpRowCharBase int;
    _wpCol int;
    _numCols int;
BEGIN
    If char_length(Trim(Coalesce(_wellPosition, ''))) < 2 Then
        Return 0;
    End If;

    _wpRowCharBase := ASCII('A');
    _numCols := 12;

    -- Get row and column for current well
    _wpRow := ASCII(Upper(substring(_wellPosition, 1, 1))) - _wpRowCharBase;
    _wpCol := try_cast(substring(_wellPosition, 2, 20), -1);

    If _wpRow <= 7 and _wpRow >= 0 and _wpCol <= 12 and _wpCol >= 1 Then
        _index := (_wpRow * _numCols) + _wpCol;
    Else
        _index := 0;
    End If;

    Return _index;
END
$$;


ALTER FUNCTION public.get_well_index(_wellposition public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_well_index(_wellposition public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_well_index(_wellposition public.citext) IS 'GetWellIndex';


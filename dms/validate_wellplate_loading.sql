--
-- Name: validate_wellplate_loading(text, text, integer, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_wellplate_loading(INOUT _wellplatename text, INOUT _wellposition text, IN _totalcount integer, INOUT _wellindex integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Checks to see if a given set of consecutive well loadings for a given wellplate are valid
**
**      Only works for a 96 well plate, where
**      the first row of the plate has wells A1 through A12 and
**      the last row  of the plate has wells H1 through H12
**
**  Arguments:
**    _wellplateName    Input/output: wellplate name
**    _wellPosition     Input/output: well position (aka well number), e.g. 'A4' or 'C12'
**    _totalCount       Number of consecutive wells to be filled
**    _wellIndex        Output: index position of _wellPosition; will be a value between 1 and 96
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   07/24/2009
**          07/24/2009 grk - Initial version (http://prismtrac.pnl.gov/trac/ticket/741)
**          11/30/2009 grk - Fixed problem with filling last well causing error message
**          12/01/2009 grk - Modified to skip checking of existing well occupancy if _totalCount = 0
**          05/16/2022 mem - Show example well numbers
**          11/25/2022 mem - Rename parameter to _wellplate
**          12/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _index int;
    _count int;
    _hits int;
    _wellList text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Normalize wellplate values
    ---------------------------------------------------

    _wellplateName := Trim(Coalesce(_wellplateName, ''));
    _wellPosition  := Upper(Trim(Coalesce(_wellPosition, '')));

    -- Normalize values meaning 'empty' to null

    If _wellplateName::citext In ('', 'na') Then
        _wellplateName := null;
    End If;

    If _wellPosition::citext In ('', 'na') Then
        _wellPosition := null;
    End If;

    -- Make sure that wellplate and well values are consistent
    -- with each other

    If (_wellPosition Is Null And Not _wellplateName Is Null) Or (Not _wellPosition Is Null And _wellplateName is null) Then
        _message := 'Wellplate and well must either both be empty or both be set';
        _returnCode := 'U5142';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get wellplate index
    ---------------------------------------------------

    _wellIndex := 0;

    -- Check for overflow

    If Not _wellPosition Is Null Then

        _wellIndex := public.get_well_index(_wellPosition::citext);

        If _wellIndex = 0 Then
            _message := 'Well position is not valid; should be in the format A4 or C12';
            _returnCode := 'U5243';
            RETURN;
        End If;

        -- For a 96 well plate, _wellIndex is between 1 and 96
        -- If _wellIndex is 96 and _totalCount is 1, the sum is 97, which is why the following if statement uses "sum > 97" and not "sum >= 97"

        If _wellIndex + _totalCount > 97 Then
            _message := 'Wellplate capacity would be exceeded (assuming a 96 well plate)';
            _returnCode := 'U5244';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Make sure wells are not in current use
    ---------------------------------------------------

    If _totalCount = 0 Then
        -- Don't bother since we are not adding a new item
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_Wells (
        wellIndex int
    );

    _count := _totalCount;
    _index := _wellIndex;

    WHILE _count > 0
    LOOP
        INSERT INTO Tmp_Wells (wellIndex)
        VALUES (_index);

        _count := _count - 1;
        _index := _index + 1;
    END LOOP;

    _wellList := '';
    _hits := 0;

    SELECT string_agg(well, ', ' ORDER BY well)
    INTO _wellList
    FROM t_experiments
    WHERE wellplate = _wellplateName::citext AND
          public.get_well_index(well) IN (
              SELECT wellIndex
              FROM Tmp_Wells
          );

    If Coalesce(_wellList, '') <> '' Then

        _hits := array_length(string_to_array(_wellList, ','), 1);

        _wellList := Substring(_wellList, 0, 256);

        If _hits = 1 Then
            _message := format('Well %s on wellplate "%s" is currently filled', _wellList, _wellplateName);
        Else
            _message := format('Wells %s on wellplate "%s" are currently filled', _wellList, _wellplateName);
        End If;

        _returnCode := 'U5145';
    End If;

    DROP TABLE Tmp_Wells;
END
$$;


ALTER PROCEDURE public.validate_wellplate_loading(INOUT _wellplatename text, INOUT _wellposition text, IN _totalcount integer, INOUT _wellindex integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_wellplate_loading(INOUT _wellplatename text, INOUT _wellposition text, IN _totalcount integer, INOUT _wellindex integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_wellplate_loading(INOUT _wellplatename text, INOUT _wellposition text, IN _totalcount integer, INOUT _wellindex integer, INOUT _message text, INOUT _returncode text) IS 'ValidateWellplateLoading';


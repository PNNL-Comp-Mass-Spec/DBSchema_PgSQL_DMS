--
CREATE OR REPLACE FUNCTION public.extract_number_from_text
(
    _searchText text,
    _startLoc int
)
RETURNS int
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the text provided to return the next
**      integer value present, starting at _startLoc
**
**  Return values: number found, or 0 if no number found
**
**  Arguments:
**    _searchText   The text to search for a number
**    _startLoc     The position to start searching at
**
**  See also UDF ExtractInteger
**  That UDF does not have a _startLoc parameter, and it returns null if a number is not found
**
**  Auth:   mem
**  Date:   07/31/2007
**          04/26/2016 mem - Check for negative numbers
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _value int;
    _loc int;
    _textLength int;
    _nextChar char;
    _valueText text;
BEGIN
BEGIN
    _value := 0;

    _textLength := char_length(_searchText);

    If Coalesce(_startLoc, 0) > 1 Then
        _searchText := Substring(_searchText, _startLoc, _textLength);
        _textLength := char_length(_searchText);
    End If;

    -- Find the first number in _searchText, starting at _startLoc
    _loc := PatIndex('%[0-9]%', _searchText);

    If _loc > 0 Then
        -- Number found
        -- Step through _searchText to find the contiguous numbers

        _valueText := Substring(_searchText, _loc, 1);

        -- Check for negative numbers
        If _loc > 1 And SubString(_searchText, _loc-1, 1) = '-' Then
            _valueText := '-' || _valueText;
        End If;

        WHILE _loc > 0 And _loc < _textLength
        LOOP
            _nextChar := Substring(_searchText, _loc+1, 1);
            If _nextChar SIMILAR TO '[0-9]' Then
                _valueText := _valueText + _nextChar;
                _loc := _loc + 1;
            Else
                _loc := 0;
            End If;
        END LOOP;

        _value := _valueText::int;
    End If;

    Return _value
END

END
$$;

COMMENT ON FUNCTION public.extract_number_from_text IS 'ExtractNumberFromText';

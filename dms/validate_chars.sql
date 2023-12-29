--
-- Name: validate_chars(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.validate_chars(_string text, _validch text DEFAULT ''::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate that _string only contains characters from valid set
**
**  Return value: The invalid characters, if any are found
**                Uses '[space]' if a space is found and _validCh does not have a space (and is not an empty string)
***
**  Arguments:
**    _string    Text to examine
**    _validCh   If default (empty string), allows letters, numbers, underscore, and dash
**
**  Auth:   grk
**  Date:   04/30/2007 grk - Ticket #450
**          02/13/2008 mem - Updated to check for _string containing a space (Ticket #602)
**          06/24/2022 mem - Ported to PostgreSQL
**          04/27/2023 mem - Use boolean for data type name
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _ch text;
    _position int;
    _stringLength int;
    _badChars text;
    _warnSpace boolean;
BEGIN
    IF Coalesce(_validCh, '') = '' Then
        _validCh := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
    End If;

    _badChars := '';
    _warnSpace := false;
    _position := 1;
    _stringLength := char_length(_string);

    WHILE _position <= _stringLength
    LOOP
        _ch := Substring(_string, _position, 1);

        -- On SQL Server, _ch will have a length of 0 if it is a space
        -- On Postgres, Substring retains spaces

        If Position(_ch In _validCh) = 0 Then
            If _ch = ' ' Then
                _warnSpace := true;
            ElsIf Position(_ch in _badChars) = 0 Then
                _badChars := format('%s%s', _badChars, _ch);
            End If;
        End If;

        _position := _position + 1;
    END LOOP;

    If _warnSpace Then
        _badChars := format('[space]%s', _badChars);
    End If;

    RETURN _badChars;
END
$$;


ALTER FUNCTION public.validate_chars(_string text, _validch text) OWNER TO d3l243;

--
-- Name: FUNCTION validate_chars(_string text, _validch text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.validate_chars(_string text, _validch text) IS 'ValidateChars';


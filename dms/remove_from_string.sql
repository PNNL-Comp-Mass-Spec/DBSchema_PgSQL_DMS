--
-- Name: remove_from_string(text, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.remove_from_string(_text text, _texttoremove text, _caseinsensitivematching boolean DEFAULT true) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes the specified text from the given string, including
**      removing any comma or semicolon delimiter that precedes the text
**
**      If _textToRemove ends in a percent sign (wildcard symbol), this function will also remove text
**      following _textToRemove, continuing to the next delimiter (comma, semicolon, or end of string)
**
**  Return value: Updated text
**
**  Arguments:
**    _text                     Text to search
**    _textToRemove             Text to remove; may optionally end with a percent sign
**    _caseInsensitiveMatching  When true, ignore case; if _textToRemove does not have a percent sign, uses regexp_replace(), meaning _textToRemove cannot have RegEx specific characters
**
**  Auth:   mem
**  Date:   10/25/2016 mem - Initial version
**          08/08/2017 mem - Add support for _textToRemove ending in %
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _iteration int := 0;
    _textToFind text;
    _matchPos int;
    _matchFlag text;
BEGIN
    If Coalesce(_text, '') = '' Then
        RETURN '';
    End If;

    If Coalesce(_textToRemove, '') = '' Then
        RETURN _text;
    End If;

    If Right(_textToRemove, 1) = '%' Then
        _textToRemove = Trim(_textToRemove, '%');

        If _caseInsensitiveMatching Then
            _matchPos := Position(Lower(_textToRemove) In Lower(_text));
            _matchFlag := 'i';
        Else
            _matchPos := Position(_textToRemove In _text);
            _matchFlag := '';
        End If;

        If _matchPos >= 1 Then
            -- Look for the next semicolon after the matching text
            If char_length((regexp_match(_text, _textToRemove || '[^;]*;', _matchFlag))[1]) > 0 Then
                -- Semicolon found
                _text = regexp_replace(_text, _textToRemove || '[^;]*; *', '', _matchFlag);

            ElseIf char_length((regexp_match(_text, _textToRemove || '[^,]*,', _matchFlag))[1]) > 0 Then
                -- Comma found
                _text = regexp_replace(_text, _textToRemove || '[^,]*, *', '', _matchFlag);
            Else
                _text := Left(_text, _matchPos - 1);
            End If;
        End If;

    ElseIf Coalesce(_textToRemove, '') <> '' Then
        WHILE _iteration <= 4
        LOOP
            If _iteration = 0 Then
                _textToFind := format('; %s', _textToRemove);
            End If;

            If _iteration = 1 Then
                _textToFind := format(';%s', _textToRemove);
            End If;

            If _iteration = 2 Then
                _textToFind := format(', %s', _textToRemove);
            End If;

            If _iteration = 3 Then
                _textToFind := format(',%s', _textToRemove);
            End If;

            If _iteration = 4 Then
                _textToFind := _textToRemove;
            End If;

            If _caseInsensitiveMatching Then
                _text := regexp_replace(_text, _textToFind, '', 'i');
            Else
                _text := Replace(_text, _textToFind, '');
            End If;

            _iteration := _iteration + 1;
        END LOOP;
    End If;

    -- Check for leading or trailing whitespace, comma, or semicolon
    _text := Trim(_text);

    _text := Trim(_text, ',');
    _text := Trim(_text, ';');

    RETURN Trim(_text);
END
$$;


ALTER FUNCTION public.remove_from_string(_text text, _texttoremove text, _caseinsensitivematching boolean) OWNER TO d3l243;

--
-- Name: FUNCTION remove_from_string(_text text, _texttoremove text, _caseinsensitivematching boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.remove_from_string(_text text, _texttoremove text, _caseinsensitivematching boolean) IS 'RemoveFromString';


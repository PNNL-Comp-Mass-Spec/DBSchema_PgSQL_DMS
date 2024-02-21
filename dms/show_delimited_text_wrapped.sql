--
-- Name: show_delimited_text_wrapped(text, text, integer, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.show_delimited_text_wrapped(IN _delimitedlist text, IN _delimiter text DEFAULT ','::text, IN _maxlinelength integer DEFAULT 512, IN _indentsize integer DEFAULT 4)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Use RAISE INFO calls to display the contents of _delimitedList, wrapping at the given maximum line length
**
**      If the delimiter is not a space, items will be separated by the delimiter and a space, even if _delimiter does not end in a space
**
**  Arguments:
**    _delimitedList    Text to show
**    _delimiter        Delimiter (comma by default); use ' ' to split on spaces
**    _maxLineLength    Maximum line length, in characters; minimum 20 characters
***   _indentSize       Number of characters to indent each line after the first line
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _currentLine text;
    _currentLineLength int;
    _currentItem text;
    _linesShown int;
BEGIN
    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _delimitedList := Trim(Coalesce(_delimitedList, ''));
    _delimiter     := Coalesce(_delimiter, ',');
    _maxLineLength := Coalesce(_maxLineLength, 512);
    _indentSize    := Coalesce(_indentSize, 4);

    If Trim(_delimiter) = '' Then
        -- Delimiter is one or more spaces
        _delimiter := ' ';
    Else
        -- Trim whitepsace from the delimiter since it is not a space
        _delimiter := Trim(_delimiter);
    End If;

    If _maxLineLength < 20 Then
        _maxLineLength := 20;
    End If;

    If Position(_delimiter In _delimitedList) = 0 Then
        RAISE INFO '%', _delimitedList;
        RETURN;
    End If;

    _currentLine := '';
    _currentLineLength := 0;
    _linesShown := 0;

    FOR _currentItem IN
        SELECT value
        FROM public.parse_delimited_list_ordered(
                    _delimitedlist => _delimitedList,
                    _delimiter     => _delimiter,
                    _maxRows       => 0)
    LOOP
        If _currentLineLength + char_length(_currentItem) > _maxLineLength Then
            RAISE INFO '%', format('%s%s',
                                   CASE WHEN _linesShown > 0 AND _indentSize > 0
                                        THEN Repeat(' ', _indentSize)
                                        ELSE ''
                                   END,
                                   _currentLine);

            _linesShown        := _linesShown + 1;
            _currentLine       := _currentItem;
            _currentLineLength := char_length(_currentItem);

            CONTINUE;
        End If;

        If _currentLineLength = 0 Then
            _currentLine       := _currentItem;
            _currentLineLength := char_length(_currentItem);

            CONTINUE;
        End If;

        If _delimiter = ' ' Then
            _currentLine       := format('%s %s', _currentLine, _currentItem);
            _currentLineLength := _currentLineLength + char_length(_currentItem) + 1;
        Else
            _currentLine       := format('%s%s %s', _currentLine, _delimiter, _currentItem);
            _currentLineLength := _currentLineLength + char_length(_currentItem) + 2;
        End If;
    END LOOP;

    If _currentLineLength > 0 Then
        RAISE INFO '%', format('%s%s',
                               CASE WHEN _linesShown > 0 AND _indentSize > 0
                                    THEN Repeat(' ', _indentSize)
                                    ELSE ''
                               END,
                               _currentLine);
    End If;
END
$$;


ALTER PROCEDURE public.show_delimited_text_wrapped(IN _delimitedlist text, IN _delimiter text, IN _maxlinelength integer, IN _indentsize integer) OWNER TO d3l243;


--
-- Name: append_to_text(text, text, boolean, text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.append_to_text(_basetext text, _addnltext text, _addduplicatetext boolean DEFAULT false, _delimiter text DEFAULT '; '::text, _maxlength integer DEFAULT 1024) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Appends a new string to an existing string, using the specified delimiter
**
**  Arguments:
**    _baseText          Text to append to (can be an empty string)
**    _addnlText         Additional text to add
**    _addDuplicateText  When false, prevent duplicate text from being added
**    _delimiter         Delimiter (semicolon by default)
**    _maxLength         Maximum length of the returned text
**
**  Auth:   mem
**  Date:   05/12/2010 mem - Initial version
**          06/12/2018 mem - Add parameter _maxLength
**          02/10/2020 mem - Ported to PostgreSQL
**          08/20/2022 mem - Do not append the delimiter if already present at the end of the base text
**          05/22/2023 mem - Use format() for string concatenation
**          06/16/2023 mem - Change _addDuplicateText to a boolean
**                         - Ignore _maxlength if _addnlText is an empty string
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _charLoc int;
    _updatedText text;
BEGIN

    If Trim(COALESCE(_baseText, '')) = '' THEN
        _updatedText = '';
    Else
        _updatedText = _baseText;
    End If;

    If Trim(COALESCE(_addnlText, '')) = '' THEN
        RETURN _updatedText;
    End If;

    _charLoc := Position(Lower(_addnlText) In Lower(_updatedText));

    If _charLoc = 0 Or _addDuplicateText Then
        If _updatedText = '' Then
            _updatedText := _addnlText;
        Else
            If char_length(Trim(_delimiter)) > 0 And RTrim(_updatedText) Like '%' || RTrim(_delimiter) Then
                -- The text already ends with the delimiter, though we may need to add a space
                If _delimiter Like '% ' And Not _updatedText Like '% ' Then
                    _updatedText := format('%s ', _updatedText);
                End If;
            Else
                _updatedText := format('%s%s', _updatedText, _delimiter);
            End If;

            _updatedText := format('%s%s', _updatedText, _addnlText);
        End If;
    End If;

    If Coalesce(_maxLength, 0) > 0 And char_length(_updatedText) > _maxLength THEN
        _updatedText := Substring(_updatedText, 1, _maxLength);
    End IF;

    RETURN _updatedText;
END
$$;


ALTER FUNCTION public.append_to_text(_basetext text, _addnltext text, _addduplicatetext boolean, _delimiter text, _maxlength integer) OWNER TO d3l243;

--
-- Name: FUNCTION append_to_text(_basetext text, _addnltext text, _addduplicatetext boolean, _delimiter text, _maxlength integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.append_to_text(_basetext text, _addnltext text, _addduplicatetext boolean, _delimiter text, _maxlength integer) IS 'AppendToText';


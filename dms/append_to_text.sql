--
-- Name: udf_append_to_text(text, text, integer, text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.udf_append_to_text(_basetext text, _addnltext text, _addduplicatetext integer DEFAULT 0, _delimiter text DEFAULT '; '::text, _maxlength integer DEFAULT 1024) RETURNS text
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
**    _addDuplicateText  When 0, prevent duplicate text from being added
**    _delimiter         Delimiter (semicolon by default)
**    _maxLength         Maximum length of the returned text
**
**  Auth:   mem
**  Date:   05/12/2010 mem - Initial version
**          06/12/2018 mem - Add parameter _maxLength
**          02/10/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _charLoc int;
    _updatedText text;
BEGIN

    If COALESCE(_baseText, '') = '' OR _baseText IS NULL THEN
        _updatedText = '';
    Else
        _updatedText = _baseText;
    End If;

    If COALESCE(_addnlText, '') <> '' THEN
        _charLoc := position(_addnlText in _updatedText);

        If _charLoc = 0 Or _addDuplicateText > 0 Then
            If _updatedText = '' Then
                _updatedText := _addnlText;
            Else
                _updatedText := _updatedText || _delimiter || _addnlText;
            End If;
        End If;

    End If;

    If _maxLength > 0 AND char_length(_updatedText) > _maxLength THEN
        _updatedText := Substring(_updatedText, 1, _maxLength);
    End IF;

    RETURN _updatedText;
END
$$;


ALTER FUNCTION public.udf_append_to_text(_basetext text, _addnltext text, _addduplicatetext integer, _delimiter text, _maxlength integer) OWNER TO d3l243;


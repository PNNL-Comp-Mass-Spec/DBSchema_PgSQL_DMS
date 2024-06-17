--
-- Name: remove_capture_errors_from_string(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.remove_capture_errors_from_string(_comment text) RETURNS public.citext
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Removes common dataset capture error messages
**
**  Arguments:
**    _comment   Dataset comment
**
**  Returns:
**      Updated comment
**
**  Auth:   mem
**  Date:   08/08/2017 mem - Initial version
**          08/16/2017 mem - Add "Error running OpenChrom"
**          11/22/2017 mem - Add "Authentication failure: The user name or password is incorrect."
**          06/23/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          01/21/2024 mem - Change data type of argument _comment to text
**
*****************************************************/
DECLARE
    _updatedComment citext;
    _commentsToRemove citext[];
    _textToFind citext;
BEGIN
    _updatedComment := Coalesce(_comment, '');

    _commentsToRemove :=
        ARRAY[
            'Dataset not ready: Exception validating constant file size',
            'Dataset not ready: Exception validating constant folder size',
            'Dataset not ready: Folder size changed',
            'Dataset not ready: File size changed',
            'Dataset name matched multiple files; must be a .uimf file, .d folder, or folder with a single .uimf file',
            'Error running OpenChrom',
            'Authentication failure: The user name or password is incorrect.'
             ];

    FOREACH _textToFind IN ARRAY _commentsToRemove
    LOOP
        _updatedComment := remove_from_string(_updatedComment, _textToFind, _caseInsensitiveMatching => true);
    END LOOP;

    RETURN _updatedComment;
END
$$;


ALTER FUNCTION public.remove_capture_errors_from_string(_comment text) OWNER TO d3l243;

--
-- Name: FUNCTION remove_capture_errors_from_string(_comment text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.remove_capture_errors_from_string(_comment text) IS 'RemoveCaptureErrorsFromString';


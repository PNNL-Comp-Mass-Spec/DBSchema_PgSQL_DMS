--
-- Name: handle_dataset_capture_validation_failure_update_dataset_tables(text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.handle_dataset_capture_validation_failure_update_dataset_tables(IN _datasetnameorid text, IN _comment text DEFAULT 'Bad .raw file'::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This procedure can be used with datasets that are successfully captured but fail the dataset integrity check
**      (.Raw file too small, expected files missing, etc).
**
**      The procedure sets the dataset state to 4 (Inactive), changes the rating to -1 = No Data (Blank/bad),
**      and makes sure a dataset archive entry exists
**
**  Arguments:
**    _datasetNameOrID  Dataset name or dataset ID
**    _comment          Text to append to the comment; if a space, period, semicolon, comma, exclamation mark or caret, will not change the dataset comment
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   04/28/2011 mem - Initial version
**          10/29/2014 mem - Now allowing _comment to contain a single punctuation mark, which means the comment should not be updated
**          11/25/2014 mem - Now using public.append_to_text() to avoid appending duplicate text
**          02/27/2015 mem - Add space after semicolon when calling Append_To_Text
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          05/22/2017 mem - Change _comment to '' if 'Bad .raw file' yet the dataset comment contains 'Cannot convert .D to .UIMF'
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/17/2023 mem - Ported to PostgreSQL, renaming from handle_dataset_capture_validation_failure to handle_dataset_capture_validation_failure_update_dataset_tables
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _datasetID int;
    _datasetName text;
    _existingComment citext;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetName := '';
    _datasetID := 0;
    _existingComment := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _datasetNameOrID := Trim(Coalesce(_datasetNameOrID, ''));
    _comment         := Trim(Coalesce(_comment, ''));

    -- Treat the following characters as meaning "do not update the comment"
    If _comment In (' ', '.', ';', ',', '!', '^') Then
        _comment := '';
    ElsIf _comment = '' Then
        _comment := 'Bad dataset';
    End If;

    RAISE INFO '';

    _datasetID := Coalesce(public.try_cast(_datasetNameOrID, null::int), 0);

    If _datasetID > 0 Then
        -----------------------------------------
        -- Lookup the Dataset Name
        -----------------------------------------

        SELECT dataset, comment
        INTO _datasetName, _existingComment
        FROM t_dataset
        WHERE dataset_id = _datasetID;

        If Not FOUND Then
            _message := format('Dataset ID not found in t_dataset: %s', _datasetNameOrID);
            _returnCode := 'U5201';
            RAISE WARNING '%', _message;
            RETURN;
        End If;

    Else
        -----------------------------------------
        -- Lookup the dataset ID
        -----------------------------------------

        _datasetName := _datasetNameOrID;

        SELECT dataset_id, comment
        INTO _datasetID, _existingComment
        FROM t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Dataset not found in t_dataset: %s', _datasetName);
            _returnCode := 'U5202';
            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    If _comment::citext = 'Bad .raw file' And _existingComment ILike '%Cannot convert .D to .UIMF%' Then
        _comment := '';
    End If;

    If _infoOnly Then
        RAISE INFO 'Mark dataset ID % as bad: % (%)',
                        _datasetID,
                        CASE WHEN _comment = ''
                             THEN 'leave the comment unchanged'
                             ELSE _comment
                        END,
                    _datasetName;
        RETURN;
    End If;

    UPDATE t_dataset
    SET comment = public.append_to_text(comment, _comment),
        dataset_state_id = 4,
        dataset_rating_id = -1
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Unable to update dataset in t_dataset: %s', _datasetName);
        _returnCode := 'U5203';
        RAISE INFO '%', _message;
    Else
        If Not Exists (SELECT dataset_id FROM t_dataset_archive WHERE dataset_id = _datasetID) Then
            -- Add the dataset to t_dataset_archive
            CALL public.add_archive_dataset (
                            _datasetID,
                            _message     => _message,       -- Output
                            _returnCode  => _returnCode);   -- Output
        End If;

        _message := format('Marked dataset as bad in t_dataset: %s', _datasetName);
        RAISE INFO '%', _message;

    End If;

END
$$;


ALTER PROCEDURE public.handle_dataset_capture_validation_failure_update_dataset_tables(IN _datasetnameorid text, IN _comment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE handle_dataset_capture_validation_failure_update_dataset_tables(IN _datasetnameorid text, IN _comment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.handle_dataset_capture_validation_failure_update_dataset_tables(IN _datasetnameorid text, IN _comment text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'HandleDatasetCaptureValidationFailure';


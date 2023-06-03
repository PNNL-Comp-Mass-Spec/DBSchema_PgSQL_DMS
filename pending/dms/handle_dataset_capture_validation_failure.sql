--
CREATE OR REPLACE PROCEDURE public.handle_dataset_capture_validation_failure
(
    _datasetNameOrID text,
    _comment text = 'Bad .raw file',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      This procedure can be used with datasets that
**      are successfully captured but fail the dataset integrity check
**      (.Raw file too small, expected files missing, etc).
**
**      The procedure marks the dataset state as Inactive,
**      changes the rating to -1 = No Data (Blank/bad),
**      and makes sure a dataset archive entry exists
**
**  Arguments:
**    _comment   If space, period, semicolon, comma, exclamation mark or caret, will not change the dataset comment
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _datasetName text;
    _existingComment text;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetName := '';
    _datasetID := 0;
    _existingComment := '';

    ----------------------------------------
    -- Validate the inputs
    ----------------------------------------

    _datasetNameOrID := Coalesce(_datasetNameOrID, '');
    _comment := Coalesce(_comment, '');

    If _comment = '' Then
        _comment := 'Bad dataset';
    End If;

    -- Treat the following characters as meaning "do not update the comment"
    If _comment in (' ', '.', ';', ',', '!', '^') Then
        _comment := '';
    End If;

    _datasetID := Coalesce(public.try_cast(_datasetNameOrID, null::int), 0);

    If _datasetID > 0 Then
        ----------------------------------------
        -- Lookup the Dataset Name
        ----------------------------------------

        _datasetID := _datasetNameOrID::int;

        SELECT dataset,
               comment
        INTO _datasetName, _existingComment
        FROM t_dataset
        WHERE dataset_id = _datasetID;

        If _datasetName = '' Then
            _message := format('Dataset ID not found: %s', _datasetNameOrID);
            _returnCode := 'U5201';
            RAISE WARNING '%', _message;
            RETURN;
        End If;

    Else
        ----------------------------------------
        -- Lookup the dataset ID
        ----------------------------------------

        _datasetName := _datasetNameOrID;

        SELECT dataset_id,
               comment
        INTO _datasetID, _existingComment
        FROM t_dataset
        WHERE (dataset = _datasetName)

        If _datasetName = '' Then
            _message := format('Dataset not found: %s', _datasetName);
            _returnCode := 'U5202';
            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    If _comment = 'Bad .raw file' AND _existingComment LIKE '%Cannot convert .D to .UIMF%' Then
        _comment := '';
    End If;

    If _infoOnly Then
        RAISE INFO 'Mark dataset ID % as bad: % (%)', _datasetID, _comment, _datasetName;
        EXIT;
    End If;

    UPDATE t_dataset
    SET comment = public.append_to_text(comment, _comment, 0, '; ', 512),
        dataset_state_id = 4,
        dataset_rating_id = -1
    WHERE dataset_id = _datasetID

    If Not FOUND Then
        _message := format('Unable to update dataset in t_dataset: %s', _datasetName);
        _returnCode := 'U5203';
        RAISE INFO '%', _message;
    Else
        -- Also update t_dataset_archive
        CALL add_archive_dataset _datasetID

        _message := format('Marked dataset as bad: %s', _datasetName);
        RAISE INFO '%', _message;

    End If;

END
$$;

COMMENT ON PROCEDURE public.handle_dataset_capture_validation_failure IS 'HandleDatasetCaptureValidationFailure';

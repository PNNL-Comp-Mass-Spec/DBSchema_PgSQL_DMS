--
CREATE OR REPLACE PROCEDURE public.set_capture_task_complete
(
    _datasetName text,
    _completionCode int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _failureMessage text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets state of dataset record given by _datasetName
**      according to given completion code and
**      adjusts related database entries accordingly.
**
**  Arguments:
**    _completionCode   0=success, 1=failed, 2=not ready, 100=success (capture broker), 101=Duplicate dataset files (capture broker)
**
**  Auth:   grk
**  Date:   11/04/2002 grk - Initial release
**          08/06/2003 grk - Added handling for 'Not Ready' state
**          11/13/2003 dac - Changed FTICR instrument class to Finnigan_FTICR following instrument class renaming
**          06/21/2005 grk - Added handling 'requires_preparation'
**          09/25/2007 grk - Return result from DoDatasetCompletionActions (http://prismtrac.pnl.gov/trac/ticket/537)
**          10/09/2007 grk - Limit number of retries (ticket 537)
**          12/16/2007 grk - Add completion code '100' for use by capture broker
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          04/04/2012 mem - Added parameter _failureMessage
**          08/19/2015 mem - If _completionCode is 0, now looking for and removing messages of the form "Error while copying \\15TFTICR64\data\"
**          12/16/2017 mem - If _completionCode is 0, now calling CleanupDatasetComments to remove error messages in the comment field
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          06/13/2018 mem - Add support for _completionCode 101
**          08/08/2018 mem - Add _completionState 14 (Duplicate Dataset Files)
**
*****************************************************/
DECLARE
    _maxRetries int;
    _datasetID int;
    _datasetState int;
    _completionState int;
    _result int;
    _instrumentClass text;
    _doPrep int;
    _comment text;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _failureMessage := Coalesce(_failureMessage, '');

    _maxRetries := 20;

    ---------------------------------------------------
    -- Resolve dataset into instrument class
    ---------------------------------------------------
    --
    SELECT t_dataset.dataset_id,
           t_instrument_name.instrument_class,
           t_instrument_class.requires_preparation,
           t_dataset.comment
    INTO _datasetID, _instrumentClass, _doPrep, _comment
    FROM t_dataset
         INNER JOIN t_instrument_name
           ON t_dataset.instrument_id = t_instrument_name.instrument_id
         INNER JOIN t_instrument_class
           ON t_instrument_name.instrument_class = t_instrument_class.instrument_class
    WHERE dataset = _datasetName;

    ---------------------------------------------------
    -- Define _completionState based on _completionCode
    ---------------------------------------------------

    If _completionCode = 0 Then
        If _doPrep > 0 Then
            _completionState := 6; -- received
        Else
            _completionState := 3; -- normal completion;
        End If;
    ElsIf _completionCode = 1
        _completionState := 5; -- capture failed
    ElsIf _completionCode = 2
        _completionState := 9; -- dataset not ready
    ElsIf _completionCode = 100
        _completionState := 3; -- normal completion
    ElsIf _completionCode = 101
        _completionState := 14; -- Duplicate Dataset Files
    End If;

    ---------------------------------------------------
    -- Limit number of retries
    ---------------------------------------------------

    If _completionState = 9 Then
        SELECT COUNT(*)
        INTO _result
        FROM t_event_log
        WHERE target_type = 4 AND
              target_state = 1 AND
              (prev_target_state = 2 OR
               prev_target_state = 5) AND
              target_id = _datasetID

        If _result > _maxRetries Then
            _completionState := 5; -- capture failed
            _message := format('Number of capture retries exceeded limit of %s for dataset "%s"', _maxRetries, _datasetName);

            CALL post_log_entry ('Error', _message, 'Set_Capture_Task_Complete');

            _message := '';
        End If;
    End If;

    ---------------------------------------------------
    -- Perform the actions necessary when dataset is complete
    ---------------------------------------------------
    --
    CALL do_dataset_completion_actions (
            _datasetName,
            _completionState,
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    ---------------------------------------------------
    -- Update the comment as needed
    ---------------------------------------------------

    _comment := Coalesce(_comment, '');

    If _completionState = 3 Then
        -- Dataset successfully captured
        -- Remove error messages of the form Error while copying \\15TFTICR64\data\ ...

        CALL cleanup_dataset_comments (_datasetID, _infoOnly => false);

    End If;

    If _completionState = 5 And _failureMessage <> '' Then
        -- Add _failureMessage to the dataset comment (If not yet present)
        _comment := public.append_to_text(_comment, _failureMessage, 0, '; ', 512);

        UPDATE t_dataset
        SET comment = _comment
        WHERE dataset_id = _datasetID;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('Set_Capture_Task_Complete', _usageMessage);

    If _message <> '' Then
        RAISE WARNING '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.set_capture_task_complete IS 'SetCaptureTaskComplete';

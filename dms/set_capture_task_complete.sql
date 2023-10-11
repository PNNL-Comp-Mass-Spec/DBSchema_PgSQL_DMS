--
-- Name: set_capture_task_complete(text, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_capture_task_complete(IN _datasetname text, IN _completioncode integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _failuremessage text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determines new dataset state based on completion code,
**      then calls do_dataset_completion_actions, plus also
**      cleanup_dataset_comments if the new state is 3
**
**  Arguments:
**    _datasetName      Dataset name
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
**          12/16/2017 mem - If _completionCode is 0, now calling Cleanup_Dataset_Comments to remove error messages in the comment field
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          06/13/2018 mem - Add support for _completionCode 101
**          08/08/2018 mem - Add _completionState 14 (Duplicate Dataset Files)
**          06/16/2023 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(event_id) instead of COUNT(*)
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
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

    _failureMessage := Trim(Coalesce(_failureMessage, ''));

    _maxRetries := 20;

    ---------------------------------------------------
    -- Resolve dataset into instrument class
    ---------------------------------------------------

    SELECT DS.dataset_id,
           InstName.instrument_class,
           InstClass.requires_preparation,
           DS.comment
    INTO _datasetID, _instrumentClass, _doPrep, _comment
    FROM t_dataset DS
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_instrument_class InstClass
           ON InstName.instrument_class = InstClass.instrument_class
    WHERE DS.Dataset = _datasetName::citext;

    If Not FOUND Then
        _message := format('Dataset %s not found in t_dataset', Coalesce(_datasetName, '??'));
        _returnCode := 'U5220';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Define _completionState based on _completionCode
    ---------------------------------------------------

    If _completionCode = 0 Then
        If _doPrep > 0 Then
            _completionState := 6;  -- Received
        Else
            _completionState := 3;  -- Normal completion;
        End If;
    ElsIf _completionCode = 1 Then
        _completionState := 5;      -- Capture failed
    ElsIf _completionCode = 2 Then
        _completionState := 9;      -- Dataset not ready
    ElsIf _completionCode = 100 Then
        _completionState := 3;      -- Normal completion
    ElsIf _completionCode = 101 Then
        _completionState := 14;     -- Duplicate Dataset Files
    Else
        _message := format('Unrecognized completion code: %s', _completionCode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Limit number of retries
    ---------------------------------------------------

    If _completionState = 9 Then
        SELECT COUNT(event_id)
        INTO _result
        FROM t_event_log
        WHERE target_type = 4 AND
              target_state = 1 AND
              (prev_target_state = 2 OR
               prev_target_state = 5) AND
              target_id = _datasetID;

        If _result > _maxRetries Then
            _completionState := 5;  -- Capture failed
            _message := format('Number of capture retries exceeded limit of %s for dataset "%s"', _maxRetries, _datasetName);

            CALL post_log_entry ('Error', _message, 'Set_Capture_Task_Complete');

            _message := '';
        End If;
    End If;

    ---------------------------------------------------
    -- Perform the actions necessary when dataset is complete
    ---------------------------------------------------

    CALL public.do_dataset_completion_actions (
                    _datasetName,
                    _completionState,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    ---------------------------------------------------
    -- Update the comment as needed
    ---------------------------------------------------

    _comment := Trim(Coalesce(_comment, ''));

    If _completionState = 3 Then
        -- Dataset successfully captured
        -- Remove error messages of the form Error while copying \\15TFTICR64\data\ ...

        CALL public.cleanup_dataset_comments (
                        _datasetID::text,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode,     -- Output
                        _infoOnly   => false);

    End If;

    If _completionState = 5 And _failureMessage <> '' Then
        -- Add _failureMessage to the dataset comment (If not yet present)
        _comment := public.append_to_text(_comment, _failureMessage);

        UPDATE t_dataset
        SET comment = _comment
        WHERE dataset_id = _datasetID;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Dataset: %s', _datasetName);
    CALL post_usage_log_entry ('set_capture_task_complete', _usageMessage);

    If _message <> '' Then
        RAISE WARNING '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.set_capture_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text, IN _failuremessage text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_capture_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text, IN _failuremessage text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.set_capture_task_complete(IN _datasetname text, IN _completioncode integer, INOUT _message text, INOUT _returncode text, IN _failuremessage text) IS 'SetCaptureTaskComplete';


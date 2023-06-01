--
CREATE OR REPLACE PROCEDURE public.do_dataset_completion_actions
(
    _datasetName text,
    _completionState int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '';
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
**    _completionState   3 (complete), 5 (capture failed), 6 (received), 8 (prep. failed), 9 (not ready), 14 (Duplicate Dataset Files)
**
**  Auth:   grk
**  Date:   11/04/2002
**          08/06/2003 grk - Added handling for 'Not Ready' state
**          07/01/2005 grk - Changed to use 'schedule_predefined_analysis_jobs'
**          11/18/2010 mem - Now checking dataset rating and not calling schedule_predefined_analysis_jobs if the rating is -10 (unreviewed)
**                         - Removed CD burn schedule code
**          02/09/2011 mem - Added back calling schedule_predefined_analysis_jobs regardless of dataset rating
**                         - Required since predefines with Trigger_Before_Disposition should create jobs even if a dataset is unreviewed
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/08/2018 mem - Add state 14 (Duplicate dataset files)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _datasetID int;
    _datasetState int;
    _datasetRating int;
    _result int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Resolve dataset into ID and state
    ---------------------------------------------------
    --
    SELECT dataset_id,
           dataset_state_id,
           dataset_rating_id
    INTO _datasetID, _datasetState, _datasetRating
    FROM t_dataset
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _message := format('Could not get dataset ID for dataset %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that datset is in correct state
    ---------------------------------------------------
    --
    If Not _completionState in (3, 5, 6, 8, 9, 14) Then
        _message := format('Completion state argument incorrect for %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Not _datasetState in (2, 7) Then
        _message := format('Dataset in incorrect state: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 2 and not _completionState in (3, 5, 6, 9, 14) Then
        _message := format('Transition 1 not allowed: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 7 and not _completionState in (3, 6, 8) Then
        _message := format('Transition 2 not allowed: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update state of dataset
    ---------------------------------------------------
    --
    UPDATE t_dataset
    SET dataset_state_id = _completionState,
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _returnCode := 'U5252';
        _message := format('Update was unsuccessful for dataset %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Skip further changes if completion was anything
    -- other than normal completion
    ---------------------------------------------------

    If _completionState <> 3 Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create a new dataset archive task
    -- However, if 'ArchiveDisabled" has a value of 1 in T_Misc_Options, the archive task will not be created
    ---------------------------------------------------
    --
    CALL Add_Archive_Dataset (_datasetID, _returnCode => _returnCode);

    If _returnCode <> '' Then
        ROLLBACK;

        _message := format('Update was unsuccessful for archive table %s', _datasetName);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    COMMIT;

    ---------------------------------------------------
    -- Schedule default analyses for this dataset
    -- Call schedule_predefined_analysis_jobs even if the rating is -10 = Unreviewed
    ---------------------------------------------------
    --
    CALL schedule_predefined_analysis_jobs (_datasetName, _returnCode => _returnCode);

    If _message <> '' Then
        RAISE WARNING '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.do_dataset_completion_actions IS 'DoDatasetCompletionActions';

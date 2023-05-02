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
**          08/06/2003 grk - added handling for 'Not Ready' state
**          07/01/2005 grk - changed to use 'schedule_predefined_analysis_jobs'
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
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _datasetID int;
    _datasetState int;
    _datasetRating int;
    _compressonState int;
    _compressionDate timestamp;
    _transName text;
    _result int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

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
        _message := 'Could not get dataset ID for dataset ' || _datasetName;
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that datset is in correct state
    ---------------------------------------------------
    --
    If Not _completionState in (3, 5, 6, 8, 9, 14) Then
        _message := 'Completion state argument incorrect for ' || _datasetName;
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Not _datasetState in (2, 7) Then
        _message := 'Dataset in incorrect state: ' || _datasetName;
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 2 and not _completionState in (3, 5, 6, 9, 14) Then
        _message := 'Transition 1 not allowed: ' || _datasetName;
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 7 and not _completionState in (3, 6, 8) Then
        _message := 'Transition 2 not allowed: ' || _datasetName;
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Set up proper compression state
    -- Note: as of February 2010, datasets no longer go through 'prep'
    -- Thus, _compressonState and _compressionDate will be null
    ---------------------------------------------------
    --
    --
    -- If dataset is in preparation,
    -- compression fields must be marked with values
    -- appropriate to success or failure
    --
    If _datasetState = 7  -- dataset is in preparation Then
        If _completionState = 8 -- preparation failed Then
                _compressonState := null;
                _compressionDate := null;
        Else                    -- preparation succeeded
                _compressonState := 1;
                _compressionDate := CURRENT_TIMESTAMP;
        End If;
    End If;

    --
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    _transName := 'SetCaptureComplete';
    begin transaction _transName

    ---------------------------------------------------
    -- Update state of dataset
    ---------------------------------------------------
    --
    UPDATE t_dataset
    SET dtaset_state_id = _completionState,
        -- Remove or update since skipped column: DS_Comp_State = _compressonState,
        -- Remove or update since skipped column: DS_Compress_Date = _compressionDate
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _returnCode := 'U5252';
        _message := 'Update was unsuccessful for dataset ' || _datasetName;
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
    Call AddArchiveDataset (_datasetID, _returnCode => _returnCode);

    If _returnCode <> '' Then
        ROLLBACK;

        _message := 'Update was unsuccessful for archive table ' || _datasetName;
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    commit transaction _transName

    ---------------------------------------------------
    -- Schedule default analyses for this dataset
    -- Call schedule_predefined_analysis_jobs even if the rating is -10 = Unreviewed
    ---------------------------------------------------
    --
    Call schedule_predefined_analysis_jobs (_datasetName, _returnCode => _returnCode);

    If _message <> '' Then
        RAISE WARNING '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.do_dataset_completion_actions IS 'DoDatasetCompletionActions';

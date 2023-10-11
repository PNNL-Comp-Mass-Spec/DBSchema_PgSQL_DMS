--
-- Name: do_dataset_completion_actions(text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_dataset_completion_actions(IN _datasetname text, IN _completionstate integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates dataset state based on the value of _completionState,
**      provided the current dataset state is 2 (Capture In Progress)
**
**      If the new state is 3 (complete), calls add_archive_dataset and schedule_predefined_analysis_jobs
**
**  Arguments:
**    _completionState   3 (complete), 5 (capture failed), 6 (received), 8 (prep. failed), 9 (not ready), 14 (Duplicate Dataset Files)
**
**  Auth:   grk
**  Date:   11/04/2002
**          08/06/2003 grk - Added handling for 'Not Ready' state
**          07/01/2005 grk - Changed to use procedure Schedule_Predefined_Analysis_Jobs
**          11/18/2010 mem - Now checking dataset rating and not calling Schedule_Predefined_Analysis_Jobs if the rating is -10 (unreviewed)
**                         - Removed CD burn schedule code
**          02/09/2011 mem - Added back calling Schedule_Predefined_Analysis_Jobs regardless of dataset rating
**                         - Required since predefines with Trigger_Before_Disposition should create jobs even if a dataset is unreviewed
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/08/2018 mem - Add state 14 (Duplicate dataset files)
**          06/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
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

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    _datasetName := Trim(Coalesce(_datasetName, ''));
    _completionState := Coalesce(_completionState, 0);

    SELECT dataset_id,
           dataset_state_id,
           dataset_rating_id
    INTO _datasetID, _datasetState, _datasetRating
    FROM t_dataset
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _message := format('Dataset not found in t_dataset: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify that the dataset is in correct state
    ---------------------------------------------------

    If Not _completionState In (3, 5, 6, 8, 9, 14) Then
        _message := format('Completion state argument incorrect for %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    -- Require that the current dataset state is 2 (Capture In Progress) or 7 (Prep. In Progress), though state 7 is obsolete
    If Not _datasetState In (2, 7) Then
        _message := format('Dataset in incorrect state (%s but expecting 2 or 7): %s', _datasetState, _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 2 And Not _completionState In (3, 5, 6, 9, 14) Then
        _message := format('State update not allowed since dataset state is 2 but completion state is not 3, 5, 6, 9, or 14: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _datasetState = 7 And Not _completionState In (3, 6, 8) Then
        _message := format('State update not allowed since dataset state is 7 but completion state is not 3, 6, or 8: %s', _datasetName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update state of dataset
    ---------------------------------------------------

    UPDATE t_dataset
    SET dataset_state_id = _completionState
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- Skip further changes if completion was anything
    -- other than normal completion
    ---------------------------------------------------

    If _completionState <> 3 Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create a new dataset archive task
    -- However, if 'ArchiveDisabled' has a value of 1 in t_misc_options, the archive task will not be created
    ---------------------------------------------------

    CALL public.add_archive_dataset (
                    _datasetID,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        ROLLBACK;

        _message := format('Return code %s reported by add_archive_dataset for dataset %s', _returnCode, _datasetName);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Schedule default analyses for this dataset
    -- Call Schedule_Predefined_Analysis_Jobs even if the rating is -10 = Unreviewed
    ---------------------------------------------------

    CALL public.schedule_predefined_analysis_jobs (
                    _datasetName,
                    _excludeDatasetsNotReleased => true,
                    _preventDuplicateJobs       => true,
                    _message                    => _message,        -- Output
                    _returnCode                 => _returnCode);    -- Output

    If _message <> '' Then
        RAISE WARNING '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.do_dataset_completion_actions(IN _datasetname text, IN _completionstate integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_dataset_completion_actions(IN _datasetname text, IN _completionstate integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_dataset_completion_actions(IN _datasetname text, IN _completionstate integer, INOUT _message text, INOUT _returncode text) IS 'DoDatasetCompletionActions';


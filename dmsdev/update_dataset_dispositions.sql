--
-- Name: update_dataset_dispositions(text, text, text, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_dispositions(IN _datasetidlist text, IN _rating text DEFAULT ''::text, IN _comment text DEFAULT ''::text, IN _recyclerequest text DEFAULT ''::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update datasets in list according to disposition parameters
**
**  Arguments:
**    _datasetIDList    Comma-separated list of dataset IDs
**    _rating           New dataset rating, e.g. 'Released' or 'No Interest'
**    _comment          Text to append to the dataset comment
**    _recycleRequest   If 'yes', call unconsume_scheduled_run() to recycle the request
**    _mode             Mode: if 'update', update t_dataset and possibly call unconsume_scheduled_run() and schedule_predefined_analysis_jobs()
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**    _showDebug        When true, show debug messages
**
**  Auth:   grk
**  Date:   04/25/2007 grk - Initial version
**          06/26/2007 grk - Fix problem with multiple datasets (Ticket #495)
**          08/22/2007 mem - Disallow setting datasets to rating 5 (Released) when their state is 5 (Capture Failed); Ticket #524
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          08/15/2008 mem - Added call to alter_event_log_entry_user to handle dataset rating entries (event log target type 8)
**          08/19/2010 grk - Use try-catch for error handling
**          11/18/2010 mem - Updated logic for calling schedule_predefined_analysis_jobs to include dataset state 4 (Inactive)
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/13/2011 mem - Now passing _callingUser to Unconsume_scheduled_run
**          02/20/2013 mem - Expanded _message to varchar(1024)
**          02/21/2013 mem - More informative error messages
**          05/08/2013 mem - No longer passing _wellplateName and _wellNumber to Unconsume_scheduled_run
**          03/30/2015 mem - Tweak warning message grammar
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/23/2021 mem - Use a semicolon when appending to an existing dataset comment
**          02/29/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _list text;
    _datasetCount int := 0;
    _ratingID int;
    _datasetInfo record;
    _usageMessage text;
    _targetType int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetIDList  := Trim(Coalesce(_datasetIDList, ''));
        _rating         := Trim(Coalesce(_rating, ''));
        _comment        := Trim(Coalesce(_comment, ''));
        _recycleRequest := Trim(Lower(Coalesce(_recycleRequest, '')));
        _mode           := Trim(Lower(Coalesce(_mode, '')));
        _showDebug      := Coalesce(_showDebug, false);

        If _datasetIDList = '' Then
            RAISE EXCEPTION 'Dataset list is empty';
        End If;

        ---------------------------------------------------
        -- Resolve rating name
        ---------------------------------------------------

        SELECT dataset_rating_id
        INTO _ratingID
        FROM t_dataset_rating_name
        WHERE dataset_rating = _rating::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid dataset rating: %', _rating;
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold list of datasets
        ---------------------------------------------------

         CREATE TEMP TABLE Tmp_DatasetInfo (
            DatasetID int,
            DatasetName text NULL,
            RatingID int NULL,
            StateID int NULL,
            Comment text NULL
        );

        ---------------------------------------------------
        -- Populate table from dataset list
        ---------------------------------------------------

        INSERT INTO Tmp_DatasetInfo (DatasetID)
        SELECT Value
        FROM public.parse_delimited_integer_list(_datasetIDList);

        ---------------------------------------------------
        -- Verify that all datasets exist
        ---------------------------------------------------

        SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID)
        INTO _list
        FROM Tmp_DatasetInfo
        WHERE NOT DatasetID IN (SELECT dataset_id FROM t_dataset);

        If _list <> '' Then
            If Position(',' In _list) > 0 Then
                _message := format('The following datasets do not exist: "%s"', _list);
            Else
                _message := format('Dataset "%s" does not exist', _list);
            End If;

            _returnCode := 'U5201';

            DROP TABLE Tmp_DatasetInfo;
            RETURN;
        End If;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetInfo;

        _message := format('Number of affected datasets: %s', _datasetCount);

        ---------------------------------------------------
        -- Get information for datasets in list
        ---------------------------------------------------

        UPDATE Tmp_DatasetInfo
        SET RatingID    = DS.dataset_rating_id,
            DatasetName = DS.dataset,
            StateID     = DS.dataset_state_id,
            Comment     = DS.Comment
        FROM t_dataset DS
        WHERE Tmp_DatasetInfo.DatasetID = DS.Dataset_ID;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Update datasets from temporary table
    ---------------------------------------------------

    If _mode = 'update' Then

        FOR _datasetInfo IN
            SELECT D.DatasetID,
                   D.DatasetName,
                   D.RatingID,
                   D.StateID,
                   D.Comment,
                   DSN.dataset_state AS DatasetStateName
            FROM Tmp_DatasetInfo AS D
                 INNER JOIN t_dataset_state_name DSN
                   ON D.StateID = DSN.dataset_state_id
            ORDER BY D.DatasetID
        LOOP

            BEGIN
                If _datasetInfo.StateID = 5 Then
                    -- Do not allow update to rating of 2 or higher when the dataset state ID is 5 (Capture Failed)
                    If _ratingID >= 2 Then
                        RAISE EXCEPTION 'Cannot set dataset rating to % for dataset "%" since its state is %', _rating, _datasetInfo.DatasetName, _datasetInfo.DatasetStateName;
                    End If;
                End If;
            EXCEPTION
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS
                        _sqlState         = returned_sqlstate,
                        _exceptionMessage = message_text,
                        _exceptionDetail  = pg_exception_detail,
                        _exceptionContext = pg_exception_context;

                _message := local_error_handler (
                                _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                                _callingProcLocation => '', _logError => true);

                If Coalesce(_returnCode, '') = '' Then
                    _returnCode := _sqlState;
                End If;

                -- Break out of the for loop
                EXIT;
            END;

            If Trim(_datasetInfo.Comment) <> '' And _comment <> '' Then
                -- Append the new comment only if it is not already present
                If Position(_comment In _datasetInfo.Comment) = 0 Then
                    _datasetInfo.Comment := format('%s; %s', _datasetInfo.Comment, _comment);
                End If;

            ElsIf _comment <> '' Then
                _datasetInfo.Comment := _comment;
            End If;

            If _showDebug Then
                RAISE INFO '';
                RAISE INFO 'Update dataset ID % to have rating % and comment "%"', _datasetInfo.DatasetID, _ratingID, _datasetInfo.Comment;
            End If;

            UPDATE t_dataset
            SET comment = _datasetInfo.Comment,
                dataset_rating_id = _ratingID
            WHERE dataset_id = _datasetInfo.DatasetID;

            -----------------------------------------------
            -- Recycle request?
            -----------------------------------------------

            If _recycleRequest = 'yes' Then
                BEGIN
                    If _showDebug Then
                        RAISE INFO '';
                        RAISE INFO 'Call unconsume_scheduled_run() for dataset %', _datasetInfo.DatasetName;
                        RAISE INFO '';
                    End If;

                    CALL public.unconsume_scheduled_run (
                            _datasetName   => _datasetInfo.DatasetName,
                            _retainHistory => true,
                            _message       => _message,         -- Output
                            _returnCode    => _returnCode,      -- Output
                            _callingUser   => _callingUser,
                            _showDebug     => _showDebug);

                    If _returnCode <> '' Then
                        RAISE EXCEPTION '%', _message;
                    ElsIf _message <> '' Then
                        RAISE INFO '%', _message;
                    End If;

                    _message := '';
                EXCEPTION
                    WHEN OTHERS THEN
                        GET STACKED DIAGNOSTICS
                            _sqlState         = returned_sqlstate,
                            _exceptionMessage = message_text,
                            _exceptionDetail  = pg_exception_detail,
                            _exceptionContext = pg_exception_context;

                    _message := local_error_handler (
                                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                                    _callingProcLocation => '', _logError => true);

                    If Coalesce(_returnCode, '') = '' Then
                        _returnCode := _sqlState;
                    End If;

                    -- Break out of the for loop
                    EXIT;
                END;
            End If;

            -----------------------------------------------
            -- Evaluate predefined analyses
            -----------------------------------------------

            If _datasetInfo.RatingID = -10 And _ratingID = 5 And _datasetInfo.StateID In (3, 4) Then
                -- Rating changed from unreviewed to released, so dataset capture is complete
                -- Schedule default analysis jobs for this dataset

                If _showDebug Then
                    RAISE INFO '';
                    RAISE INFO 'Call schedule_predefined_analysis_jobs() for dataset %', _datasetInfo.DatasetName;
                End If;

                CALL public.schedule_predefined_analysis_jobs (
                                _datasetName                => _datasetInfo.DatasetName,
                                _callingUser                => _callingUser,
                                _analysisToolNameFilter     => '',
                                _excludeDatasetsNotReleased => true,
                                _preventDuplicateJobs       => true,
                                _infoOnly                   => false,
                                _message                    => _message,
                                _returnCode                 => _returnCode);

                If _returnCode <> '' Then
                    ROLLBACK;

                    DROP TABLE Tmp_DatasetInfo;
                    RETURN;
                ElsIf _message <> '' Then
                    RAISE INFO '';
                    RAISE INFO '%', _message;
                End If;

            End If;

            BEGIN
                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If Trim(Coalesce(_callingUser, '')) <> '' Then
                    _targetType := 8;
                    CALL public.alter_event_log_entry_user ('public', _targetType, _datasetInfo.DatasetID, _ratingID, _callingUser, _message => _alterEnteredByMessage);
                End If;
            EXCEPTION
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS
                        _sqlState         = returned_sqlstate,
                        _exceptionMessage = message_text,
                        _exceptionDetail  = pg_exception_detail,
                        _exceptionContext = pg_exception_context;

                _message := local_error_handler (
                                _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                                _callingProcLocation => '', _logError => true);

                If Coalesce(_returnCode, '') = '' Then
                    _returnCode := _sqlState;
                End If;

                -- Break out of the for loop
                EXIT;
            END;

        END LOOP;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets'));
    CALL post_usage_log_entry ('update_dataset_dispositions', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
END
$$;


ALTER PROCEDURE public.update_dataset_dispositions(IN _datasetidlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_dispositions(IN _datasetidlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_dispositions(IN _datasetidlist text, IN _rating text, IN _comment text, IN _recyclerequest text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) IS 'UpdateDatasetDispositions';


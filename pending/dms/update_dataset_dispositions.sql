
CREATE OR REPLACE PROCEDURE public.update_dataset_dispositions
(
    _datasetIDList text,
    _rating text = '',
    _comment text = '',
    _recycleRequest text = '',
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates datasets in list according to disposition parameters
**
**  Arguments:
**    _datasetIDList    Comma-separated list of dataset IDs
**    _rating           New dataset rating
**    _comment          Text to append to the dataset comment
**    _recycleRequest   If 'yes', call unconsume_scheduled_run()
**    _mode             Mode: if 'update', update t_dataset and possibly call unconsume_scheduled_run and schedule_predefined_analysis_jobs
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   04/25/2007
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
**          12/15/2023 mem - Ported to PostgreSQL
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If _datasetIDList = '' Then
            RAISE EXCEPTION 'Dataset list is empty';
        End If;

        _recycleRequest := Trim(Lower(Coalesce(_recycleRequest, '')));
        _mode           := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Resolve rating name
        ---------------------------------------------------

        SELECT dataset_rating_id
        INTO _ratingID
        FROM  t_dataset_rating_name
        WHERE (dataset_rating = _rating)

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid rating: %', _rating;
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
        WHERE NOT DatasetID IN (SELECT dataset_id FROM t_dataset)

        If _list <> '' Then
            If Position(',' In _list) = 0 Then
                _message := format('Dataset "%s" was not found in the database', _list);
            Else
                _message := format('The following datasets were not in the database: "%s"', _list);
            End If;

            _returnCode := 'U5201';

            DROP TABLE Tmp_DatasetInfo;
            RETURN;
        End If;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetInfo;

        _message := format('Number of affected datasets: %s', _datasetCount)

        ---------------------------------------------------
        -- Get information for datasets in list
        ---------------------------------------------------

        UPDATE M
        SET M.RatingID = T.dataset_rating_id,
            M.DatasetName = T.dataset,
            M.StateID = dataset_state_id,
            M.Comment = Comment
        FROM Tmp_DatasetInfo M
             INNER JOIN t_dataset T
               ON T.dataset_id = M.DatasetID;

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
            SELECT
                D.DatasetID,
                D.DatasetName,
                D.RatingID,
                D.StateID,
                D.Comment,
                DSN.dataset_state AS DatasetStateName
            FROM Tmp_DatasetInfo AS D INNER JOIN
                 t_dataset_state_name DSN ON DS.StateID = DSN.dataset_state_id
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

            If _datasetInfo.Comment <> '' And _comment <> '' Then
                -- Append the new comment only if it is not already present
                If Position(_comment In _datasetInfo.Comment) = 0 Then
                    _datasetInfo.Comment := format('%s; %s', _datasetInfo.Comment, _comment);
                End If;

            ElsIf _datasetInfo.Comment = '' And _comment <> '' Then
                _datasetInfo.Comment := _comment;

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
                    CALL public.unconsume_scheduled_run (
                            _datasetInfo.DatasetName,
                            _retainHistory => true,
                            _message => _message,           -- Output
                            _returnCode => _returnCode,     -- Output
                            _callingUser => _callingUser);

                    If _returnCode <> '' Then
                        RAISE EXCEPTION '%', _message;
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
            --
            -- If rating changes from unreviewed to released and dataset capture is complete
            --
            If _datasetInfo.RatingID = -10 And _ratingID = 5 And _datasetInfo.StateID In (3, 4) Then
                -- schedule default analyses for this dataset
                --
                CALL public.schedule_predefined_analysis_jobs (_datasetInfo.DatasetName, _callingUser, _returnCode => _returnCode);

                If _returnCode <> '' Then
                    ROLLBACK;

                    DROP TABLE Tmp_DatasetInfo;
                    RETURN;
                End If;

            End If;

            BEGIN
                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If char_length(_callingUser) > 0 Then
                    CALL public.alter_event_log_entry_user ('public', 8, _datasetInfo.DatasetID, _ratingID, _callingUser, _message => _alterEnteredByMessage);
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

    End If; -- update mode

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets');
    CALL post_usage_log_entry ('update_dataset_dispositions', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
END
$$;

COMMENT ON PROCEDURE public.update_dataset_dispositions IS 'UpdateDatasetDispositions';

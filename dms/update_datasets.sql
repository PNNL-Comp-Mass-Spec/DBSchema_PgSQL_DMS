--
-- Name: update_datasets(text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_datasets(IN _datasetlist text, IN _state text DEFAULT ''::text, IN _rating text DEFAULT ''::text, IN _comment text DEFAULT ''::text, IN _findtext text DEFAULT ''::text, IN _replacetext text DEFAULT ''::text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update dataset state, rating, or comment for the specified list of datasets
**
**  Arguments:
**    _datasetList      Comma-separated list of dataset names
**    _state            New dataset state name; use '' or '[no change]' to leave unchanged
**    _rating           New dataset rating;     use '' or '[no change]' to leave unchanged
**    _comment          New dataset comment;    use '' or '[no change]' to leave unchanged
**    _findText         Text to find when finding/replacing text in dataset comments;     use '' or '[no change]' to leave unchanged
**    _replaceText      Replacement text when finding/replacing text in dataset comments; use '' or '[no change]' to leave unchanged
**    _mode             Mode: 'update' or 'preview'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   jds
**  Date:   09/21/2006
**          03/28/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user_multi_id (Ticket #644)
**          08/19/2010 grk - Use try-catch for error handling
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          03/30/2015 mem - Tweak warning message grammar
**          10/07/2015 mem - Added _mode 'preview'
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/01/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          06/27/2025 mem - Use new parameter name when calling schedule_predefined_analysis_jobs
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _list text;
    _datasetStateUpdated boolean;
    _datasetRatingUpdated boolean;
    _datasetCount int := 0;
    _stateID int;
    _ratingID int;
    _currentDataset text;
    _usageMessage text;
    _targetType int;
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _logErrors boolean := false;
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
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetList := Trim(Coalesce(_datasetList, ''));
        _state       := Trim(Coalesce(_state, ''));
        _rating      := Trim(Coalesce(_rating, ''));
        _comment     := Trim(Coalesce(_comment, ''));
        _findText    := Trim(Coalesce(_findText, ''));
        _replaceText := Trim(Coalesce(_replaceText, ''));

        _mode        := Trim(Lower(Coalesce(_mode, '')));

        If _state::citext In ('', '[no change]') Then
            _state := '[no change]';
        End If;

        If _rating::citext In ('', '[no change]') Then
            _rating := '[no change]';
        End If;

        If _comment::citext In ('', '[no change]') Then
            _comment := '[no change]';
        End If;

        If _findText::citext In ('', '[no change]') Then
            _findText := '[no change]';
        End If;

        If _replaceText::citext In ('', '[no change]') Then
            _replaceText := '[no change]';
        End If;

        ---------------------------------------------------
        -- Validate the dataset list and find/replace text
        ---------------------------------------------------

        If _datasetList = '' Then
            _msg := 'Dataset list is empty';
            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        If (_findText = '[no change]' And _replaceText <> '[no change]') Or (_findText <> '[no change]' And _replaceText = '[no change]') Then
            _msg := 'The Find In Comment and Replace In Comment values must either both be defined or both be blank';
            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Create temporary tables to hold the list of datasets
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name citext NOT NULL
        );

        CREATE TEMP TABLE Tmp_DatasetSchedulePredefine (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Dataset_Name text NOT NULL
        );

        ---------------------------------------------------
        -- Populate table from dataset list
        ---------------------------------------------------

        INSERT INTO Tmp_DatasetInfo (Dataset_Name)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_datasetList);

        ---------------------------------------------------
        -- Verify that all datasets exist
        ---------------------------------------------------

        SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
        INTO _list
        FROM Tmp_DatasetInfo
        WHERE NOT Dataset_Name IN (SELECT dataset FROM t_dataset);

        If Coalesce(_list, '') <> '' Then
            If Position(',' In _list) > 0 Then
                _msg := format('The following datasets do not exist: "%s"', _list);
            Else
                _msg := format('Dataset "%s" does not exist', _list);
            End If;

            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetInfo;

        If Not _mode In ('preview', 'update') Then
            _message := format('Invalid mode: %s', _mode);
            RAISE WARNING '%', _message;
        Else
            _message := format('Number of affected datasets: %s', _datasetCount);
        End If;

        ---------------------------------------------------
        -- Resolve state name
        ---------------------------------------------------

        If _state <> '[no change]' Then
            SELECT Dataset_state_ID
            INTO _stateID
            FROM t_dataset_state_name
            WHERE dataset_state = _state;

            If Not FOUND Then
                _msg := format('Invalid dataset state name: %s', _state);
                RAISE INFO '%', _msg;
                RAISE EXCEPTION '%', _msg;
            End If;
        Else
            _stateID := 0;
        End If;

        ---------------------------------------------------
        -- Resolve rating name
        ---------------------------------------------------

        If _rating <> '[no change]' Then
            SELECT dataset_rating_id
            INTO _ratingID
            FROM t_dataset_rating_name
            WHERE dataset_rating = _rating::citext;

            If Not FOUND Then
                _msg := format('Invalid dataset rating name: %s', _rating);
                RAISE INFO '%', _msg;
                RAISE EXCEPTION '%', _msg;
            End If;
        Else
            _ratingID := 0;
        End If;

        If _mode = 'preview' Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-80s %-8s %-12s %-9s %-13s %-60s %-60s %-60s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Dataset_Name',
                                'State_ID',
                                'State_ID_New',
                                'Rating_ID',
                                'Rating_ID_New',
                                'Comment',
                                'Comment_via_Append',
                                'Comment_via_Replace'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------------------------------------------------------------------',
                                         '--------',
                                         '------------',
                                         '---------',
                                         '-------------',
                                         '------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DS.Dataset_ID,
                       DS.Dataset,
                       DS.dataset_state_id AS State_ID,
                       CASE
                           WHEN _state <> '[no change]' THEN _stateID
                           ELSE DS.dataset_state_id
                       END AS State_ID_New,
                       DS.dataset_rating_id AS Rating_ID,
                       CASE
                           WHEN _rating <> '[no change]' THEN _ratingID
                           ELSE DS.dataset_rating_id
                       END AS Rating_ID_New,
                       DS.Comment,
                       CASE
                           WHEN _comment <> '[no change]' THEN public.append_to_text(Comment, _comment)
                           ELSE 'n/a'
                       END AS Comment_via_Append,
                       CASE
                           WHEN _findText <> '[no change]' AND
                                _replaceText <> '[no change]' THEN Replace(Comment, _findText, _replaceText)
                           ELSE 'n/a'
                       END AS Comment_via_Replace
                FROM t_dataset DS
                     INNER JOIN Tmp_DatasetInfo DI
                       ON DS.dataset = DI.Dataset_Name
                ORDER BY DS.dataset
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Dataset,
                                    _previewData.State_ID,
                                    _previewData.State_ID_New,
                                    _previewData.Rating_ID,
                                    _previewData.Rating_ID_New,
                                    _previewData.Comment,
                                    _previewData.Comment_via_Append,
                                    _previewData.Comment_via_Replace
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        _datasetStateUpdated  := false;
        _datasetRatingUpdated := false;
        _logErrors := true;

        If _mode = 'update' Then
            ---------------------------------------------------
            -- Update datasets
            ---------------------------------------------------

            If _state <> '[no change]' Then
                UPDATE t_dataset
                SET dataset_state_id = _stateID
                FROM Tmp_DatasetInfo DI
                WHERE dataset = DI.Dataset_Name;

                _datasetStateUpdated := true;
            End If;

            If _rating <> '[no change]' Then

                -- Find the datasets that have an existing rating of -5, -6, or -7
                INSERT INTO Tmp_DatasetSchedulePredefine (Dataset_Name)
                SELECT DS.dataset
                FROM t_dataset DS
                     INNER JOIN Tmp_DatasetInfo DI
                       ON DS.dataset = DI.Dataset_Name
                     LEFT OUTER JOIN t_analysis_job AJ
                       ON DS.dataset_id = AJ.dataset_id AND
                          AJ.dataset_unreviewed = 0
                WHERE DS.dataset_rating_id IN (-5, -6, -7) AND
                      AJ.job IS NULL;

                UPDATE t_dataset
                SET dataset_rating_id = _ratingID
                FROM Tmp_DatasetInfo DI
                WHERE dataset = DI.dataset_name;

                _datasetRatingUpdated := true;

                If Exists (SELECT * FROM Tmp_DatasetSchedulePredefine) And _ratingID >= 2 Then

                    -- Schedule Predefines

                    FOR _currentDataset IN
                        SELECT Dataset_Name
                        FROM Tmp_DatasetSchedulePredefine
                        ORDER BY Entry_ID
                    LOOP

                        CALL public.schedule_predefined_analysis_jobs (
                                        _datasetNamesOrIDs          => _currentDataset,
                                        _callingUser                => _callingUser,
                                        _analysisToolNameFilter     => '',
                                        _excludeDatasetsNotReleased => true,
                                        _preventDuplicateJobs       => true,
                                        _infoOnly                   => false,
                                        _message                    => _message,
                                        _returnCode                 => _returnCode);

                    END LOOP;

                End If;

            End If;

            If _comment <> '[no change]' Then
                UPDATE t_dataset
                SET comment = CASE WHEN comment IS NULL THEN _comment
                                   ELSE public.append_to_text(comment, _comment)
                              END
                FROM Tmp_DatasetInfo DI
                WHERE dataset = DI.dataset_name;
            End If;

            If _findText <> '[no change]' And _replaceText <> '[no change]' Then
                UPDATE t_dataset
                SET comment = Replace(comment, _findText, _replaceText)
                FROM Tmp_DatasetInfo DI
                WHERE dataset = DI.dataset_name;
            End If;

            If Trim(Coalesce(_callingUser, '')) <> '' And (_datasetStateUpdated Or _datasetRatingUpdated) Then
                -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id
                -- to alter the entered_by field in t_event_log

                -- Populate a temporary table with the list of Dataset IDs just updated
                CREATE TEMP TABLE Tmp_ID_Update_List (
                    TargetID int NOT NULL
                );

                CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

                INSERT INTO Tmp_ID_Update_List (TargetID)
                SELECT DISTINCT DS.dataset_id
                FROM t_dataset DS
                     INNER JOIN Tmp_DatasetInfo DI
                       ON DS.dataset = DI.Dataset_Name;

                If _datasetStateUpdated Then
                    _targetType := 4;
                    CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _stateID, _callingUser, _message => _alterEnteredByMessage);
                End If;

                If _datasetRatingUpdated Then
                    _targetType := 8;
                    CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _ratingID, _callingUser, _message => _alterEnteredByMessage);
                End If;

                DROP TABLE Tmp_ID_Update_List;
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
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_ID_Update_List;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets'));
    CALL post_usage_log_entry ('update_datasets', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
    DROP TABLE IF EXISTS Tmp_DatasetSchedulePredefine;
END
$$;


ALTER PROCEDURE public.update_datasets(IN _datasetlist text, IN _state text, IN _rating text, IN _comment text, IN _findtext text, IN _replacetext text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_datasets(IN _datasetlist text, IN _state text, IN _rating text, IN _comment text, IN _findtext text, IN _replacetext text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_datasets(IN _datasetlist text, IN _state text, IN _rating text, IN _comment text, IN _findtext text, IN _replacetext text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateDatasets';


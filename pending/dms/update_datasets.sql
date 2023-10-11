--
CREATE OR REPLACE PROCEDURE public.update_datasets
(
    _datasetList text,
    _state text = '',
    _rating text = '',
    _comment text = '',
    _findText text = '',
    _replaceText text = '',
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
**      Updates parameters to new values for datasets in list
**
**  Arguments:
**    _mode   Can be update or preview
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
**          12/15/2023 mem - Ported to PostgreSQL
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
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _datasetStateUpdated := false;
    _datasetRatingUpdated := false;

    _state       := Trim(Coalesce(_state, ''));
    _rating      := Trim(Coalesce(_rating, ''));
    _comment     := Trim(Coalesce(_comment, ''));
    _findText    := Trim(Coalesce(_findText, ''));
    _replaceText := Trim(Coalesce(_replaceText, ''));

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

        If _datasetList = '' Then
            _msg := 'Dataset list is empty';
            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        If (_findText = '[no change]' And _replaceText <> '[no change]') Or (_findText <> '[no change]' And _replaceText = '[no change]') Then
            _msg := 'The Find In Comment and Replace In Comment enabled flags must both be enabled or disabled';
            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Create temporary tables to hold the list of datasets
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetInfo (
            Dataset_Name text NOT NULL
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
        WHERE NOT Dataset_Name IN ( SELECT dataset FROM t_dataset );

        If Coalesce(_list, '') <> '' Then
            _msg := format('The following datasets were not in the database: "%s"', _list);
            RAISE INFO '%', _msg;
            RAISE EXCEPTION '%', _msg;
        End If;

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DatasetInfo;

        _message := format('Number of affected datasets: %s', _datasetCount);

        ---------------------------------------------------
        -- Resolve state name
        ---------------------------------------------------

        _stateID := 0;

        If _state <> '[no change]' Then
            SELECT Dataset_state_ID
            INTO _stateID
            FROM  t_dataset_rating_name
            WHERE dataset_rating = _state;

            If Not FOUND Then
                _msg := format('Could not find state %s in t_dataset_rating_name', _state);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve rating name
        ---------------------------------------------------

        _ratingID := 0;

        If _rating <> '[no change]' Then
            SELECT dataset_rating_id
            INTO _ratingID
            FROM  t_dataset_rating_name
            WHERE dataset_rating = _rating::citext;

            If Not FOUND Then
                _msg := format('Could not find rating %s in t_dataset_rating_name', _rating);
                RAISE EXCEPTION '%', _msg;
            End If;
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
                SELECT Dataset_ID,
                       Dataset,
                       dataset_state_id AS State_ID,
                       CASE
                           WHEN _state <> '[no change]' THEN _stateID
                           ELSE dataset_state_id
                       END AS State_ID_New,
                       dataset_rating_id AS Rating_ID,
                       CASE
                           WHEN _rating <> '[no change]' THEN _ratingID
                           ELSE dataset_rating_id
                       END AS Rating_ID_New,
                       Comment,
                       CASE
                           WHEN _comment <> '[no change]' THEN format('%s %s', Comment, _comment)
                           ELSE Comment
                       END AS Comment_via_Append,
                       CASE
                           WHEN _findText <> '[no change]' AND
                                _replaceText <> '[no change]' THEN Replace(Comment, _findText, _replaceText)
                           ELSE Comment
                       END AS Comment_via_Replace
                FROM t_dataset
                WHERE dataset IN ( SELECT Dataset_Name FROM Tmp_DatasetInfo)
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Dataset_Name,
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

        ---------------------------------------------------
        -- Update datasets from temporary table
        -- in cases where parameter has changed
        ---------------------------------------------------

        If _mode = 'update' Then

            If _state <> '[no change]' Then
                UPDATE t_dataset
                SET dataset_state_id = _stateID
                WHERE dataset IN (SELECT Dataset_Name FROM Tmp_DatasetInfo);

                _datasetStateUpdated := true;
            End If;

            -----------------------------------------------
            If _rating <> '[no change]' Then

                -- Find the datasets that have an existing rating of -5, -6, or -7
                INSERT INTO Tmp_DatasetSchedulePredefine (Dataset_Name)
                SELECT DS.dataset
                FROM t_dataset DS
                     LEFT OUTER JOIN t_analysis_job J
                       ON DS.dataset_id = J.dataset_id AND
                          J.dataset_unreviewed = 0
                WHERE DS.dataset IN ( SELECT Dataset_Name FROM Tmp_DatasetInfo ) AND
                      DS.dataset_rating_id IN (-5, -6, -7) AND
                      J.job IS NULL;

                UPDATE t_dataset
                SET dataset_rating_id = _ratingID
                WHERE dataset IN (SELECT Dataset_Name FROM Tmp_DatasetInfo);

                _datasetRatingUpdated := true;

                If Exists (SELECT * FROM Tmp_DatasetSchedulePredefine) And _ratingID >= 2 Then

                    -- Schedule Predefines
                    --
                    FOR _currentDataset IN
                        SELECT Dataset_Name
                        FROM Tmp_DatasetSchedulePredefine
                        ORDER BY Entry_ID
                    LOOP

                        CALL public.schedule_predefined_analysis_jobs (
                                        _datasetName =>_currentDataset,
                                        _message     => _message
                                        _returnCode  => _returnCode);

                    END LOOP;

                End If;

            End If;

            -----------------------------------------------
            If _comment <> '[no change]' Then
                UPDATE t_dataset
                SET comment = CASE WHEN comment Is Null THEN _comment
                                   ELSE format('%s; %s', comment, _comment)
                              END
                WHERE dataset IN (SELECT Dataset_Name FROM Tmp_DatasetInfo);
            End If;

            -----------------------------------------------
            If _findText <> '[no change]' and _replaceText <> '[no change]' Then
                UPDATE t_dataset
                SET comment = Replace(comment, _findText, _replaceText)
                WHERE dataset IN (SELECT Dataset_Name FROM Tmp_DatasetInfo);
            End If;

            If char_length(_callingUser) > 0 And (_datasetStateUpdated Or _datasetRatingUpdated) Then
                -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id
                -- to alter the entered_by field in t_event_log
                --

                -- Populate a temporary table with the list of Dataset IDs just updated
                CREATE TEMP TABLE Tmp_ID_Update_List (
                    TargetID int NOT NULL
                );

                CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

                INSERT INTO Tmp_ID_Update_List (TargetID)
                SELECT DISTINCT dataset_id
                FROM t_dataset
                WHERE dataset IN (SELECT Dataset_Name FROM Tmp_DatasetInfo);

                If _datasetStateUpdated Then
                    CALL public.alter_event_log_entry_user_multi_id ('public', 4, _stateID, _callingUser, _message => _alterEnteredByMessage);
                End If;

                If _datasetRatingUpdated Then
                    CALL public.alter_event_log_entry_user_multi_id ('public', 8, _ratingID, _callingUser, _message => _alterEnteredByMessage);
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
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_ID_Update_List;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets');
    CALL post_usage_log_entry ('update_datasets', _usageMessage);

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
    DROP TABLE IF EXISTS Tmp_DatasetSchedulePredefine;
END
$$;

COMMENT ON PROCEDURE public.update_datasets IS 'UpdateDatasets';

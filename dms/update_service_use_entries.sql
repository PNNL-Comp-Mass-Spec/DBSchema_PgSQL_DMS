--
-- Name: update_service_use_entries(text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_service_use_entries(IN _mode text, IN _newvalue text, IN _entryidlist text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the dataset rating of the datasets associated with the specified service use entries
**      Service use entries must be associated with an active service use report
**
**      This procedure is called via a POST to service_use/operation/ , originating from https://dms2.pnl.gov/service_use_admin/report
**         - See file service_use_admin_cmds.php at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/app/Views/cmd/service_use_admin_cmds.php
**           and file lcmd.js at https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/89871a5bbbde297a5878194787c418e7a42cd9ad/public/javascript/lcmd.js#L226
**
**  Arguments:
**    _mode             Mode: 'datasetRating'
**    _newValue         When mode is 'datasetRating', this is the dataset rating name
**    _entryIdList      Comma-separated list of service use entry IDs
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   mem
**  Date:   08/18/2025 mem - Initial version
**          08/20/2025 mem - Reference schema svc instead of cc
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;

    _lockedServiceUseEntries int;
    _updateCount int;
    _entryCount int := 0;
    _valueList text;
    _msg text;

    _newDatasetRating citext := '';
    _newDatasetRatingID int := 0;
    _datasetID int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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
        -- Uncomment to log the values of the procedure arguments in T_Log_Entries
        --
        -- _msg := format('Procedure called with _mode=%s, _newValue=%s, _entryIdList=%s',
        --                 Coalesce(_mode, '??'), Coalesce(_newValue, '??'), Coalesce(_entryIdList, '??'));
        -- CALL post_log_entry ('Debug', _msg, 'update_service_use_entries');

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode         := Trim(Lower(Coalesce(_mode, '')));
        _newValue     := Trim(Coalesce(_newValue, ''));
        _entryIdList  := Trim(Coalesce(_entryIdList, ''));
        _infoOnly     := Coalesce(_infoOnly, false);

        If Not _mode::citext IN ('datasetRating') Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Unsupported mode: %', _mode;
        End If;

        ---------------------------------------------------
        -- Populate a temporary table with the values in _entryIdList
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_ServiceUseIDs (
            Entry_ID int
        );

        INSERT INTO Tmp_ServiceUseIDs (Entry_ID)
        SELECT DISTINCT value
        FROM public.parse_delimited_integer_list(_entryIdList);
        --
        GET DIAGNOSTICS _entryCount = ROW_COUNT;

        If _entryCount = 0 Then
            _returnCode := 'U5202';
            _message := 'Service use ID list is empty or does not have integers; nothing to do';
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Look for service use entries associated with service use reports that are not New or Active
        ---------------------------------------------------

        SELECT COUNT(U.entry_id)
        INTO _lockedServiceUseEntries
        FROM Tmp_ServiceUseIDs src
             INNER JOIN svc.t_service_use U
               ON U.entry_id = src.entry_id
             INNER JOIN svc.t_service_use_report R
               ON R.report_id = U.report_id
        WHERE Not R.report_state_id IN (1, 2);

        If _lockedServiceUseEntries > 0 Then
            _returnCode := 'U5203';
            _message := format('%s service use %s associated with a service use report that is not in state New or Active; aborting the update',
                               _lockedServiceUseEntries, public.check_plural(_lockedServiceUseEntries, 'entry is', 'entries are'));
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        -- Initial validation checks are complete; now enable _logErrors
        _logErrors := true;

        If _mode::citext = 'datasetRating' Then
            ---------------------------------------------------
            -- Validate the dataset rating
            -- Mode 'datasetRating' is used by http://dms2.pnl.gov/service_use_admin/report
            ---------------------------------------------------

            -- Set the dataset type to _newValue for now
            _newDatasetRating := _newValue;

            ---------------------------------------------------
            -- Make sure a valid dataset rating was chosen
            ---------------------------------------------------

            SELECT dataset_rating,
                   dataset_rating_id
            INTO _newDatasetRating, _newDatasetRatingId
            FROM t_dataset_rating_name
            WHERE dataset_rating = _newDatasetRating;

            If Not FOUND Then
                _logErrors := false;
                _returnCode := 'U5203';
                RAISE EXCEPTION 'Invalid dataset rating: "%" does not exist', _newValue;
            End If;
        End If;

        ----------------------------------------------------------
        -- Generate a log message that describes the service use entries that will be updated
        ----------------------------------------------------------

        -- Create and populate the temp table used by procedure condense_integer_list_to_ranges

        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        );

        INSERT INTO Tmp_ValuesByCategory (Category, Value)
        SELECT 'SvcUseEntry', Entry_ID
        FROM Tmp_ServiceUseIDs
        ORDER BY Entry_ID;

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false)
        LIMIT 1;

        ---------------------------------------------------
        -- Perform the updates (preview the updates if _infoOnly is true)
        ---------------------------------------------------

        If _mode::citext = 'datasetRating' Then

            If _infoOnly Then
                _logMessage := 'Will change';
            Else
                _logMessage := 'Changed';
            End If;

            _logMessage := format('%s the dataset rating to "%s" for %s service use %s; user %s; IDs %s',
                                  _logMessage,
                                  _newDatasetRating,
                                  _entryCount,
                                  public.check_plural(_entryCount, 'entry', 'entries'),
                                  _callingUser,
                                  Coalesce(_valueList, '??'));

            If _infoOnly Then
                ----------------------------------------------------------
                -- Preview what would be updated
                ----------------------------------------------------------

                RAISE INFO '';
                RAISE INFO '%', _logMessage;
                RAISE INFO '';

                _formatSpecifier := '%-10s %-10s %-30s %-30s %-21s %-21s';

                _infoHead := format(_formatSpecifier,
                                    'Entry_ID',
                                    'Dataset_ID',
                                    'Old_Dataset_Rating',
                                    'New_Dataset_Rating',
                                    'Old_Dataset_Rating_ID',
                                    'New_Dataset_Rating_ID'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------',
                                             '----------',
                                             '------------------------------',
                                             '------------------------------',
                                             '---------------------',
                                             '---------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT U.Entry_ID,
                           U.Dataset_ID,
                           DSRating.dataset_rating AS Old_Dataset_Rating,
                           _newDatasetRating       AS New_Dataset_Rating,
                           DS.dataset_rating_id    AS Old_Dataset_Rating_ID,
                           _newDatasetRatingID     AS New_Dataset_Rating_ID
                    FROM Tmp_ServiceUseIDs src
                         INNER JOIN svc.t_service_use U
                           ON U.entry_id = src.entry_id
                         INNER JOIN svc.t_service_use_report R
                           ON R.report_id = U.report_id
                         INNER JOIN t_dataset DS
                           ON DS.dataset_id = U.dataset_id
                         INNER JOIN t_dataset_rating_name DSRating
                           ON DSRating.dataset_rating_id = DS.dataset_rating_id
                    WHERE R.report_state_id IN (1, 2)
                    ORDER BY Entry_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Entry_ID,
                                        _previewData.Dataset_ID,
                                        _previewData.Old_Dataset_Rating,
                                        _previewData.New_Dataset_Rating,
                                        _previewData.Old_Dataset_Rating_ID,
                                        _previewData.New_Dataset_Rating_ID
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

                _message := _logMessage;
            Else
                UPDATE t_dataset DS
                SET dataset_rating_id = _newDatasetRatingID
                FROM Tmp_ServiceUseIDs src
                     INNER JOIN svc.t_service_use U
                       ON U.entry_id = src.entry_id
                     INNER JOIN svc.t_service_use_report R
                       ON R.report_id = U.report_id
                WHERE R.report_state_id IN (1, 2) AND
                      DS.dataset_id = U.dataset_id;
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                _message := format('Changed the dataset rating to "%s" for %s service use %s',
                                   _newDatasetRating, _updateCount, public.check_plural(_updateCount, 'entry', 'entries'));
            End If;

            ---------------------------------------------------
            -- Update the the service_type_id in t_dataset in case the new dataset rating results in a change to the service type ID logic
            -- (preview if _infoOnly is true)
            ---------------------------------------------------

            FOR _datasetID IN
                SELECT ds.dataset_ID
                FROM Tmp_ServiceUseIDs src
                     INNER JOIN svc.t_service_use U
                       ON U.entry_id = src.entry_id
                     INNER JOIN svc.t_service_use_report R
                       ON R.report_id = U.report_id
                     INNER JOIN t_dataset DS
                       ON DS.dataset_id = U.dataset_id
                WHERE R.report_state_id IN (1, 2)
            LOOP
                CALL update_dataset_service_type_if_required (_datasetID, _infoOnly => _infoOnly);
            END LOOP;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If char_length(_entryIdList) < 128 Then
                _logMessage := format('%s; Requests %s', _exceptionMessage, _entryIdList);
            Else
                _logMessage := format('%s; Requests %s ...', _exceptionMessage, Substring(_entryIdList, 1, 128));
            End If;

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _logMessage := format('Updated %s service use %s',
                          _entryCount, public.check_plural(_entryCount, 'entry', 'entries'));

    CALL post_usage_log_entry ('update_service_use_entries', _logMessage);

    DROP TABLE IF EXISTS Tmp_ServiceUseIDs;
    DROP TABLE IF EXISTS Tmp_ValuesByCategory;

    If _returnCode <> '' Then
        -- Raise an exception so that the web page will show the error message
        RAISE EXCEPTION '%', _message;
    End If;
END
$$;


ALTER PROCEDURE public.update_service_use_entries(IN _mode text, IN _newvalue text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_service_use_entries(IN _mode text, IN _newvalue text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_service_use_entries(IN _mode text, IN _newvalue text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateServiceUseEntries';


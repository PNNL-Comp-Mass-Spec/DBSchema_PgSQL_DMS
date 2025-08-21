--
-- Name: update_service_use_comment(text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_service_use_comment(IN _texttofind text, IN _replacementtext text, IN _entryidlist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the comment for the specified service use entries, searching for _textToFind and replacing with _replacementText
**      If _textToFind is an empty string, append _replacementText to the end of the existing comment
**
**  Arguments:
**    _textTofind       Text to find; if an empty string, will append _replacementText to existing comments
**    _replacementText  Replacement text
**    _entryIdList      Service use entry IDs (must be associated with an active service use report)
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**
**  Auth:   mem
**  Date:   08/17/2025 mem - Initial version
**          08/20/2025 mem - Reference schema svc instead of cc
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _dropTempTables boolean := false;
    _logErrors boolean := false;

    _entryCountToUpdate int;
    _entryCount int;
    _lockedServiceUseEntries int;
    _logMessage text;
    _valueList text;

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
        ----------------------------------------------------------
        -- Validate the inputs
        ----------------------------------------------------------

        _textToFind      := Coalesce(_textToFind, '');
        _replacementText := Coalesce(_replacementText, '');
        _infoOnly        := Coalesce(_infoOnly, false);
        _entryIdList     := Trim(Coalesce(_entryIdList, ''));
        _callingUser     := Trim(Coalesce(_callingUser, ''));

        If _callingUser = '' Then
            _callingUser := SESSION_USER;
        End If;

        If Trim(_textToFind) = '' Then
            _textToFind = '';
        End If;

        If _entryIdList = '' Then
            _message := format('Cannot update, one or more service use entry IDs must be provided');
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        -- Uncomment to debug
        /*
        If _textToFind = '' Then
            _logMessage := 'Updating service use comments, appending "' || _replacementText || '" to the existing comment for entries: ' || _entryIdList;
        Else
            _logMessage := 'Updating service use comments, replacing "' || _textToFind || '" with "' || _replacementText || ' for entries: ' || _entryIdList;
        End If;

        CALL post_log_entry ('Debug', _logMessage, 'update_service_use_comment');
        */

        _dropTempTables := true;
        _logErrors := true;

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ServiceUseEntriesToUpdate (
            Entry_ID int NOT NULL,
            Dataset_ID text NOT NULL,
            Comment text NOT NULL,
            New_Comment text NOT NULL
        );

        CREATE INDEX IX_Tmp_ServiceUseEntriesToUpdate ON Tmp_ServiceUseEntriesToUpdate (Entry_ID);

        CREATE TEMP TABLE Tmp_ServiceUseEntries (
            Entry_ID int NOT NULL
        );

        CREATE INDEX IX_Tmp_ServiceUseEntries ON Tmp_ServiceUseEntries (Entry_ID);

        ----------------------------------------------------------
        -- Find the service use entries to update
        ----------------------------------------------------------

        INSERT INTO Tmp_ServiceUseEntries (Entry_ID)
        SELECT Value
        FROM public.parse_delimited_integer_list(_entryIdList);
        --
        GET DIAGNOSTICS _entryCount = ROW_COUNT;

        If _entryCount = 0 Then
            _logErrors := false;
            _message := 'Service use ID list is empty or does not have integers; nothing to do';
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        INSERT INTO Tmp_ServiceUseEntriesToUpdate (
            Entry_ID,
            Dataset_ID,
            Comment,
            New_Comment
        )
        SELECT U.entry_id,
               U.dataset_id,
               U.comment,
               U.comment
        FROM svc.t_service_use U
             INNER JOIN Tmp_ServiceUseEntries src
               ON U.Entry_ID = src.Entry_ID;
        --
        GET DIAGNOSTICS _entryCount = ROW_COUNT;

        If _entryCountToUpdate = 0 Then
            If _entryCount = 1 Then
                _message := format('Service use entry not found in the service use table');
            Else
                _message := format('None of the %s specified service use entries exist in the service use table', _entryCount);
            End If;

            RAISE INFO '%', _message;

            DROP TABLE Tmp_ServiceUseEntriesToUpdate;
            DROP TABLE Tmp_ServiceUseEntries;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Look for service use entries associated with service use reports that are not New or Active
        ---------------------------------------------------

        SELECT COUNT(U.entry_id)
        INTO _lockedServiceUseEntries
        FROM Tmp_ServiceUseEntriesToUpdate src
             INNER JOIN svc.t_service_use U
               ON U.entry_id = src.entry_id
             INNER JOIN svc.t_service_use_report R
               ON R.report_id = U.report_id
        WHERE Not R.report_state_id IN (1, 2);

        If _lockedServiceUseEntries > 0 Then
            _logErrors := false;
            _returnCode := 'U5201';
            _message := format('%s service use %s associated with a service use report that is not in state New or Active; aborting the update',
                               _lockedServiceUseEntries, public.check_plural(_updateCount, 'entry is', 'entries are'));
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        ----------------------------------------------------------
        -- Update the comments in the temporary table
        ----------------------------------------------------------

        If _textToFind = '' Then
            UPDATE Tmp_ServiceUseEntriesToUpdate
            SET New_Comment = Trim(Coalesce(public.append_to_text(Comment, _replacementText), ''));
        Else
            UPDATE Tmp_ServiceUseEntriesToUpdate
            SET New_Comment = Trim(Coalesce(Replace(Comment::citext, _textToFind, _replacementText), ''));
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
        FROM Tmp_ServiceUseEntriesToUpdate
        ORDER BY Entry_ID;

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false)
        LIMIT 1;

        If _infoOnly Then
            _logMessage := 'Will update';
        Else
            _logMessage := 'Updated';
        End If;

        If _textToFind = '' Then
            _logMessage := format('%s comments for %s service use %s, appending "%s"; user %s; IDs %s',
                                  _logMessage,
                                  _entryCountToUpdate,
                                  public.check_plural(_entryCountToUpdate, 'entry', 'entries'),
                                  _replacementText,
                                  _callingUser,
                                  Coalesce(_valueList, '??'));
        Else
            _logMessage := format('%s comments for %s service use %s, replacing "%s" with "%s"; user %s; IDs %s',
                                  _logMessage,
                                  _entryCountToUpdate,
                                  public.check_plural(_entryCountToUpdate, 'entry', 'entries'),
                                  _textToFind,
                                  _replacementText,
                                  _callingUser,
                                  Coalesce(_valueList, '??'));
        End If;

        If _infoOnly Then
            ----------------------------------------------------------
            -- Preview what would be updated
            ----------------------------------------------------------

            RAISE INFO '';
            RAISE INFO '%', _logMessage;
            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-16s %-16s';

            _infoHead := format(_formatSpecifier,
                                'Entry_ID',
                                'Dataset_ID',
                                'Old_Comment',
                                'New_Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '----------',
                                         '----------------',
                                         '----------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Entry_ID,
                       Dataset_ID,
                       Comment,
                       New_Comment
                FROM Tmp_ServiceUseEntriesToUpdate
                ORDER BY Entry_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.Dataset_ID,
                                    _previewData.Comment,
                                    _previewData.New_Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            _message := _logMessage;
        Else
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------

            UPDATE svc.t_service_use target
            SET comment = src.New_Comment
            FROM Tmp_ServiceUseEntriesToUpdate src
            WHERE target.Entry_ID = src.Entry_ID AND
                  target.comment IS DISTINCT FROM src.New_Comment;
        End If;

        DROP TABLE Tmp_ServiceUseEntriesToUpdate;
        DROP TABLE Tmp_ServiceUseEntries;
        DROP TABLE Tmp_ValuesByCategory;

        RETURN;

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
    END;

    If _dropTempTables Then
        DROP TABLE IF EXISTS Tmp_ServiceUseEntriesToUpdate;
        DROP TABLE IF EXISTS Tmp_ServiceUseEntries;
        DROP TABLE IF EXISTS Tmp_ValuesByCategory;
    End If;
END
$$;


ALTER PROCEDURE public.update_service_use_comment(IN _texttofind text, IN _replacementtext text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_service_use_comment(IN _texttofind text, IN _replacementtext text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_service_use_comment(IN _texttofind text, IN _replacementtext text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateServiceUseComment';


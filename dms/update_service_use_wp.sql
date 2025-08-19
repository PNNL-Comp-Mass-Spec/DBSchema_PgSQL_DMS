--
-- Name: update_service_use_wp(text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_service_use_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _entryidlist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Change the work package for the datasets associated with the service use entries, switching from an old value to a new value
**      Service use entries must be associated with an active service use report
**
**      If _entryIdList is empty, finds service use entries that use _oldWorkPackage and are associated with an active service use report
**      If _entryIdList is defined, finds all service use entries in the list use _oldWorkPackage and are associated with an active service use report
**
**  Arguments:
**    _oldWorkPackage   Old work package
**    _newWorkPackage   New work package
**    _entryIdList      Optional: if blank, finds active service use entries that use _oldWorkPackage; if defined, updates all of the specified service use entries if they use _oldWorkPackage (and are associated with an active service use report)
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**
**  Auth:   mem
**  Date:   08/17/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _dropTempTables boolean := false;
    _logErrors boolean := false;

    _validatedWP text;
    _entryCountToUpdate int;
    _entryCount int;
    _lockedServiceUseEntries int;
    _logMessage text;
    _valueList text;
    _updateCount int;

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

        _oldWorkPackage := public.trim_whitespace(_oldWorkPackage);
        _newWorkPackage := public.trim_whitespace(_newWorkPackage);
        _infoOnly       := Coalesce(_infoOnly, false);
        _entryIdList    := Trim(Coalesce(_entryIdList, ''));
        _callingUser    := Trim(Coalesce(_callingUser, ''));

        If _callingUser = '' Then
            _callingUser := SESSION_USER;
        End If;

        If _oldWorkPackage = '' Then
            _message := 'Old work package must be specified';
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        If _newWorkPackage = '' Then
            _message := 'New work package must be specified';
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        -- Uncomment to debug
        -- _logMessage := 'Updating work package from ' || _oldWorkPackage || ' to ' || _newWorkPackage || ' for requests: ' || _entryIdList;
        -- CALL post_log_entry ('Debug', _logMessage, 'update_service_use_wp');

        SELECT charge_code
        INTO _validatedWP
        FROM t_charge_code
        WHERE charge_code = _newWorkPackage::citext;

        If Not FOUND Then
            _message := format('Cannot update, unrecognized work package: %s', _newWorkPackage);
            RAISE WARNING '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        _newWorkPackage := _validatedWP;

        _dropTempTables := true;
        _logErrors := true;

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ServiceUseEntriesToUpdate (
            Entry_ID int NOT NULL,
            Dataset_ID text NOT NULL,
            Work_Package text NOT NULL
        );

        CREATE INDEX IX_Tmp_ServiceUseEntriesToUpdate ON Tmp_ServiceUseEntriesToUpdate (Entry_ID);

        CREATE TEMP TABLE Tmp_ServiceUseEntries (
            Entry_ID int NOT NULL
        );

        CREATE INDEX IX_Tmp_ServiceUseEntries ON Tmp_ServiceUseEntries (Entry_ID);

        ----------------------------------------------------------
        -- Find the service use entries to update
        ----------------------------------------------------------

        If _entryIdList <> '' Then
            ----------------------------------------------------------
            -- Find entries using _entryIdList
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
                Work_Package
            )
            SELECT U.entry_id,
                   U.dataset_id,
                   U.charge_code
            FROM cc.t_service_use U
                 INNER JOIN Tmp_ServiceUseEntries src
                   ON src.Entry_ID = U.Entry_ID
            WHERE U.charge_code = _oldWorkPackage;
            --
            GET DIAGNOSTICS _entryCountToUpdate = ROW_COUNT;

            If _entryCountToUpdate = 0 Then
                If _entryCount = 1 Then
                    _message := format('Service use entry %s does not have work package %s; leaving WP unchanged', _entryIdList, _oldWorkPackage);
                Else
                    _message := format('None of the %s specified service use entries have work package %s; leaving WP unchanged', _entryCount, _oldWorkPackage);
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
                 INNER JOIN cc.t_service_use U
                   ON U.entry_id = src.entry_id
                 INNER JOIN cc.t_service_use_report R
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
        Else
            ----------------------------------------------------------
            -- Find service use entries that use _oldWorkPackage and are associated with an active service use report
            ----------------------------------------------------------

            INSERT INTO Tmp_ServiceUseEntriesToUpdate (
                Entry_ID,
                Dataset_ID,
                Work_Package
            )
            SELECT U.entry_id,
                   U.dataset_id,
                   U.charge_code
            FROM cc.t_service_use U
                 INNER JOIN cc.t_service_use_report R
                   ON R.report_id = U.report_id
            WHERE R.report_state_id IN (1, 2) AND
                  U.charge_code = _oldWorkPackage;
            --
            GET DIAGNOSTICS _entryCountToUpdate = ROW_COUNT;

            If _entryCountToUpdate = 0 Then
                _message := format('Did not find any active service use entries with work package %s', _oldWorkPackage);
                RAISE INFO '%', _message;

                DROP TABLE Tmp_ServiceUseEntriesToUpdate;
                DROP TABLE Tmp_ServiceUseEntries;

                RETURN;
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
        FROM Tmp_ServiceUseEntriesToUpdate
        ORDER BY Entry_ID;

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false)
        LIMIT 1;

        If _infoOnly Then
            _logMessage := 'Will change';
        Else
            _logMessage := 'Changed';
        End If;

        _logMessage := format('%s work package for %s service use %s from %s to %s; user %s; IDs %s',
                              _logMessage,
                              _entryCountToUpdate,
                              public.check_plural(_entryCountToUpdate, 'entry', 'entries'),
                              _oldWorkPackage,
                              _newWorkPackage,
                              _callingUser,
                              Coalesce(_valueList, '??'));

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
                                'Old_Work_Package',
                                'New_Work_Package'
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
                       Work_Package AS Old_Work_Package,
                       _newWorkPackage AS New_Work_Package
                FROM Tmp_ServiceUseEntriesToUpdate
                ORDER BY Entry_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.Dataset_ID,
                                    _previewData.Old_Work_Package,
                                    _previewData.New_Work_Package
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            _message := format('Will change work package for %s service use %s from %s to %s',
                               _entryCountToUpdate,
                               public.check_plural(_entryCountToUpdate, 'entry', 'entries'),
                               _oldWorkPackage,
                               _newWorkPackage);
        Else
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------

            UPDATE cc.t_service_use target
            SET charge_code = _newWorkPackage
            FROM Tmp_ServiceUseEntriesToUpdate src
            WHERE Target.Entry_ID = Src.Entry_ID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Changed work package for %s service use %s from %s to %s',
                               _updateCount, public.check_plural(_updateCount, 'entry', 'entries'), _oldWorkPackage, _newWorkPackage);

            -- Uncomment to debug (_logMessage was defined above)
            -- CALL post_log_entry ('Debug', _logMessage, 'update_service_use_wp');
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


ALTER PROCEDURE public.update_service_use_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_service_use_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_service_use_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _entryidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateServiceUseWP';


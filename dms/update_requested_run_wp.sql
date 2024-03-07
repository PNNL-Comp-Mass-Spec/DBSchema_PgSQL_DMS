--
-- Name: update_requested_run_wp(text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _requestidlist text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Change the work package for requested runs from an old value to a new value
**
**      If _requestIdList is empty, finds active requested runs that use _oldWorkPackage
**      If _requestIdList is defined, finds all requested runs in the list that use _oldWorkPackage, regardless of the state
**
**      Changes will be logged to t_log_entries
**
**  Arguments:
**    _oldWorkPackage   Old work package
**    _newWorkPackage   New work package
**    _requestIdList    Optional: if blank, finds active requested runs that use _oldWorkPackage; if defined, updates all of the specified requested run IDs if they use _oldWorkPackage (and are active)
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/17/2020 mem - Fix typo in error message
**          07/19/2023 mem - Rename request ID list parameter
**          03/06/2024 mem - Ported to PostgreSQL
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
    _requestCountToUpdate int;
    _rrCount int;
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

        ----------------------------------------------------------
        -- Validate the inputs
        ----------------------------------------------------------

        _oldWorkPackage := public.trim_whitespace(_oldWorkPackage);
        _newWorkPackage := public.trim_whitespace(_newWorkPackage);
        _infoOnly       := Coalesce(_infoOnly, false);
        _requestIdList  := Trim(Coalesce(_requestIdList, ''));
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
        -- _logMessage := 'Updating work package from ' || _oldWorkPackage || ' to ' || _newWorkPackage || ' for requests: ' || _requestIdList;
        -- CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_WP');

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

        CREATE TEMP TABLE Tmp_ReqRunsToUpdate (
            Request_ID int NOT NULL,
            Request_Name text NOT NULL,
            Work_Package text NOT NULL
        );

        CREATE INDEX IX_Tmp_ReqRunsToUpdate ON Tmp_ReqRunsToUpdate (Request_ID);

        CREATE TEMP TABLE Tmp_RequestedRunList (
            Request_ID int NOT NULL
        );

        CREATE INDEX IX_Tmp_RequestedRunList ON Tmp_RequestedRunList (Request_ID);

        ----------------------------------------------------------
        -- Find the Requested Runs to update
        ----------------------------------------------------------

        If _requestIdList <> '' Then
            -- Find requested runs using _requestIdList
            INSERT INTO Tmp_RequestedRunList (Request_ID)
            SELECT Value
            FROM public.parse_delimited_integer_list(_requestIdList);

            SELECT COUNT(Request_ID)
            INTO _rrCount
            FROM Tmp_RequestedRunList;

            If _rrCount = 0 Then
                _logErrors := false;
                _message := 'The specified Requested Run ID list is empty or does not have integers';
                RAISE WARNING '%', _message;
                RAISE EXCEPTION '%', _message;
            End If;

            INSERT INTO Tmp_ReqRunsToUpdate (Request_ID,
                                             Request_Name,
                                             Work_Package)
            SELECT RR.request_id,
                   RR.request_name,
                   RR.work_package
            FROM t_requested_run RR
                 INNER JOIN Tmp_RequestedRunList Filter
                   ON RR.request_id = Filter.Request_ID
            WHERE RR.work_package = _oldWorkPackage;
            --
            GET DIAGNOSTICS _requestCountToUpdate = ROW_COUNT;

            If _requestCountToUpdate = 0 Then
                If _rrCount = 1 Then
                    _message := format('Requested run ID %s does not have work package %s; leaving WP unchanged', _requestIdList, _oldWorkPackage);
                Else
                    _message := format('None of the %s specified requested run IDs have work package %s; leaving WP unchanged', _rrCount, _oldWorkPackage);
                End If;

                RAISE INFO '%', _message;

                DROP TABLE Tmp_ReqRunsToUpdate;
                DROP TABLE Tmp_RequestedRunList;

                RETURN;
            End If;
        Else
            -- Find active requested runs that use _oldWorkPackage
            INSERT INTO Tmp_ReqRunsToUpdate (Request_ID,
                                             Request_Name,
                                             Work_Package)
            SELECT request_id,
                   request_name,
                   work_package
            FROM t_requested_run
            WHERE state_name = 'Active' AND
                  work_package = _oldWorkPackage;
            --
            GET DIAGNOSTICS _requestCountToUpdate = ROW_COUNT;

            If _requestCountToUpdate = 0 Then
                _message := format('Did not find any active requested runs with work package %s', _oldWorkPackage);
                RAISE INFO '%', _message;

                DROP TABLE Tmp_ReqRunsToUpdate;
                DROP TABLE Tmp_RequestedRunList;

                RETURN;
            End If;
        End If;

        ----------------------------------------------------------
        -- Generate a log message that describes the requested runs that will be updated
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        );

        INSERT INTO Tmp_ValuesByCategory (Category, Value)
        SELECT 'RR', Request_ID
        FROM Tmp_ReqRunsToUpdate
        ORDER BY Request_ID;

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false)
        LIMIT 1;

        If _infoOnly Then
            _logMessage := 'Will change';
        Else
            _logMessage := 'Changed';
        End If;

        _logMessage := format('%s work package for %s requested %s from %s to %s; user %s; IDs %s',
                              _logMessage,
                              _requestCountToUpdate,
                              public.check_plural(_requestCountToUpdate, 'run', 'runs'),
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

            _formatSpecifier := '%-10s %-80s %-16s %-16s';

            _infoHead := format(_formatSpecifier,
                                'Request_ID',
                                'Request_Name',
                                'Old_Work_Package',
                                'New_Work_Package'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------------------------------------------------------------------',
                                         '----------------',
                                         '----------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Request_ID,
                       Request_Name,
                       Work_Package AS Old_Work_Package,
                       _newWorkPackage AS New_Work_Package
                FROM Tmp_ReqRunsToUpdate
                ORDER BY Request_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Request_ID,
                                    _previewData.Request_Name,
                                    _previewData.Old_Work_Package,
                                    _previewData.New_Work_Package
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            _message := format('Will change work package for %s requested %s from %s to %s',
                               _requestCountToUpdate,
                               public.check_plural(_requestCountToUpdate, 'run', 'runs'),
                               _oldWorkPackage,
                               _newWorkPackage);
        Else
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------

            UPDATE t_requested_run target
            SET work_package = _newWorkPackage
            FROM Tmp_ReqRunsToUpdate src
            WHERE Target.request_id = Src.Request_ID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Changed work package for %s requested %s from %s to %s',
                               _updateCount, public.check_plural(_updateCount, 'run', 'runs'), _oldWorkPackage, _newWorkPackage);

            CALL post_log_entry ('Normal', _logMessage, 'Update_Requested_Run_WP');
        End If;

        DROP TABLE Tmp_ReqRunsToUpdate;
        DROP TABLE Tmp_RequestedRunList;
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
        DROP TABLE IF EXISTS Tmp_ReqRunsToUpdate;
        DROP TABLE IF EXISTS Tmp_RequestedRunList;
        DROP TABLE IF EXISTS Tmp_ValuesByCategory;
    End If;
END
$$;


ALTER PROCEDURE public.update_requested_run_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _requestidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _requestidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_wp(IN _oldworkpackage text, IN _newworkpackage text, IN _requestidlist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunWP';


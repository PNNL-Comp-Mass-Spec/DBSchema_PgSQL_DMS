--
CREATE OR REPLACE PROCEDURE public.update_requested_run_wp
(
    _oldWorkPackage text,
    _newWorkPackage text,
    _requestIdList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Changes the work package for requested runs from an old value to a new value
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
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user
**    _infoOnly         When true, preview updates
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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
        _requestIdList  := Trim(Coalesce(_requestIdList, ''));
        _callingUser    := Trim(Coalesce(_callingUser, ''));
        _infoOnly       := Coalesce(_infoOnly, false);

        If _callingUser = '' Then
            _callingUser := session_user;
        End If;

        If _oldWorkPackage = '' Then
            RAISE EXCEPTION 'Old work package must be specified';
        End If;

        If _newWorkPackage = '' Then
            RAISE EXCEPTION 'New work package must be specified';
        End If;

        -- Uncomment to debug
        -- _logMessage := 'Updating work package from ' || _OldWorkPackage || ' to ' || _NewWorkPackage || ' for requests: ' || _requestIdList;
        -- CALL post_log_entry ('Debug', _logMessage, 'update_requested_run_wp');

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ReqRunsToUpdate (
            request_id int not null,
            Request_Name text not null,
            work_package text not null
        )

        CREATE INDEX IX_Tmp_ReqRunsToUpdate ON Tmp_ReqRunsToUpdate (request_id);

        CREATE TEMP TABLE Tmp_RequestedRunList (
            request_id int not null
        )

        CREATE INDEX IX_Tmp_RequestedRunList ON Tmp_RequestedRunList (request_id);

        ----------------------------------------------------------
        -- Find the Requested Runs to update
        ----------------------------------------------------------

        If _requestIdList <> '' Then

            -- Find requested runs using _requestIdList
            --
            INSERT INTO Tmp_RequestedRunList( request_id )
            SELECT Value
            FROM public.parse_delimited_list(_requestIdList);

            SELECT COUNT(request_id)
            INTO _rrCount
            FROM Tmp_RequestedRunList;

            If _rrCount = 0 Then
                RAISE EXCEPTION 'User supplied Requested Run IDs was empty or did not contain integers';
            End If;

            INSERT INTO Tmp_ReqRunsToUpdate( request_id,
                                             request_name,
                                             work_package )
            SELECT RR.request_id,
                   RR.request_name,
                   RR.work_package
            FROM t_requested_run RR
                 INNER JOIN Tmp_RequestedRunList Filter
                   ON RR.request_id = Filter.request_id
            WHERE RR.work_package = _oldWorkPackage;
            --
            GET DIAGNOSTICS _requestCountToUpdate = ROW_COUNT;

            If _requestCountToUpdate = 0 Then
                _message := format('None of the %s specified requested run IDs uses work package %s', _rrCount, _oldWorkPackage);

                If _infoOnly Then
                    RAISE INFO '%', _message;
                End If;

                DROP TABLE Tmp_ReqRunsToUpdate;
                DROP TABLE Tmp_RequestedRunList;

                RETURN;
            End If;
        Else
            -- Find active requested runs that use _oldWorkPackage
            --

            INSERT INTO Tmp_ReqRunsToUpdate( request_id,
                                             request_name,
                                             work_package )
            SELECT request_id,
                   request_name,
                   work_package
            FROM t_requested_run
            WHERE state_name = 'active' AND
                  work_package = _oldWorkPackage;
            --
            GET DIAGNOSTICS _requestCountToUpdate = ROW_COUNT;

            If _requestCountToUpdate = 0 Then
                _message := format('Did not find any active requested runs with work package %s', _oldWorkPackage);

                If _infoOnly Then
                    RAISE INFO '%', _message;
                End If;

                DROP TABLE Tmp_ReqRunsToUpdate;
                DROP TABLE Tmp_RequestedRunList;

                RETURN;
            End If;

        End If;

        ----------------------------------------------------------
        -- Generate log message that describes the requested runs that will be updated
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        );

        INSERT INTO Tmp_ValuesByCategory (Category, Value)
        SELECT 'RR', request_id
        FROM Tmp_ReqRunsToUpdate
        ORDER BY ID;

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false);
        LIMIT 1;

        If Not _infoOnly Then
            _logMessage := 'Updated';
        Else
            _logMessage := 'Will update';
        End If;

        _logMessage := format('%s work package for %s requested %s from %s to %s; user %; IDs %',
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
                ORDER BY ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Request_ID,
                                    _previewData.Request_Name,
                                    _previewData.Old_Work_Package,
                                    _previewData.New_Work_Package
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            _message := format('Will update work package for %s requested %s from %s to %s',
                                _previewCount, public.check_plural(_requestCountToUpdate, 'run', 'runs'), _oldWorkPackage, _newWorkPackage);

        Else
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------

            UPDATE t_requested_run target
            Set work_package = _newWorkPackage
            FROM Tmp_ReqRunsToUpdate src
            WHERE Target.request_id = Src.request_id;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Updated work package for %s requested %s from %s to %s',
                                _updateCount, public.check_plural(_updateCount, 'run', 'runs'), _oldWorkPackage, _newWorkPackage);

            CALL post_log_entry ('Normal', _logMessage, 'Update_Requested_Run_WP');

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
    END;

    DROP TABLE IF EXISTS Tmp_ReqRunsToUpdate;
    DROP TABLE IF EXISTS Tmp_RequestedRunList;
    DROP TABLE IF EXISTS Tmp_ValuesByCategory;
END
$$;

COMMENT ON PROCEDURE public.update_requested_run_wp IS 'UpdateRequestedRunWP';

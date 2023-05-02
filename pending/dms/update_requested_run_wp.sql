--
CREATE OR REPLACE PROCEDURE public.update_requested_run_wp
(
    _oldWorkPackage text,
    _newWorkPackage text,
    _requestedIdList text = '',
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
**      Updates the work package for requested runs
**      from an old value to a new value
**
**      If _requestedIdList is empty, finds active requested runs that use _oldWorkPackage
**
**      If _requestedIdList is defined, finds all requested runs in the list that use _oldWorkPackage
**      regardless of the state
**
**      Changes will be logged to T_Log_Entries
**
**  Arguments:
**    _requestedIdList   Optional: if blank, finds active requested runs; if defined, updates all of the specified request IDs if they use _oldWorkPackage
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/17/2020 mem - Fix typo in error message
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _requestCountToUpdate int := 0;
    _rrCount int;
    _logMessage text;
    _valueList text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

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

        _oldWorkPackage := public.scrub_whitespace(_oldWorkPackage);
        _newWorkPackage := public.scrub_whitespace(_newWorkPackage);
        _requestedIdList := Coalesce(_requestedIdList, '');
        _message := '';
        _callingUser := Coalesce(_callingUser, '');
        _infoOnly := Coalesce(_infoOnly, false);

        If _callingUser = '' Then
            _callingUser := session_user;
        End If;

        If _oldWorkPackage = '' Then
            RAISE EXCEPTION 'Old work package cannot be blank';
        End If;

        If _newWorkPackage = '' Then
            RAISE EXCEPTION 'New work package cannot be blank';
        End If;

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------
        --
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
        --
        If _requestedIdList <> '' Then

            -- Find requested runs using _requestedIdList
            --
            INSERT INTO Tmp_RequestedRunList( request_id )
            SELECT Value
            FROM public.parse_delimited_list (_requestedIdList, ',')

            SELECT COUNT(*)
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
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _requestCountToUpdate := _myRowcount;

            If _requestCountToUpdate = 0 Then
                _message := 'None of the ' || _rRCount::text || ' specified requested run IDs uses work package ' || _oldWorkPackage;

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
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _requestCountToUpdate := _myRowcount;

            If _requestCountToUpdate = 0 Then
                _message := 'Did not find any active requested runs with work package ' || _oldWorkPackage;

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
        --
        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        )

        INSERT INTO Tmp_ValuesByCategory (Category, Value)
        SELECT 'RR', request_id
        FROM Tmp_ReqRunsToUpdate
        ORDER BY ID

        SELECT ValueList
        INTO _valueList
        FROM condense_integer_list_to_ranges (_debugMode => false);
        LIMIT 1;

        If Not _infoOnly Then
            _logMessage := 'Updated';
        Else
            _logMessage := 'Will update';
        End If;

        _logMessage := format('%s work package for %s requested %s', _logMessage, _myRowCount, public.check_plural(_myRowCount, 'run', 'runs'));
        _logMessage := _logMessage || ' from ' || _oldWorkPackage || ' to ' || _newWorkPackage;

        _logMessage := _logMessage || '; user ' || _callingUser || '; IDs ' || Coalesce(_valueList, '??');

        If _infoOnly Then
            ----------------------------------------------------------
            -- Preview what would be updated
            ----------------------------------------------------------
            --
            RAISE INFO '%', _logMessage;

            -- ToDo: Show this data using RAISE INFO

            SELECT request_id,
                   Request_Name,
                   work_package AS Old_Work_Package,
                   _newWorkPackage AS New_Work_Package
            FROM Tmp_ReqRunsToUpdate
            ORDER BY ID;

            _message := format('Will update work package for %s requested %s from %s to %s',
                                _myRowCount, public.check_plural(_myRowCount, 'run', 'runs'), _oldWorkPackage, _newWorkPackage);

        Else
            ----------------------------------------------------------
            -- Perform the update
            ----------------------------------------------------------
            --

            UPDATE t_requested_run target
            Set work_package = _newWorkPackage
            FROM Tmp_ReqRunsToUpdate src
            WHERE Target.request_id = Src.request_id;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _message := format('Updated work package for %s requested %s from %s to %s',
                                _myRowCount, public.check_plural(_myRowCount, 'run', 'runs'), _oldWorkPackage, _newWorkPackage);

            Call post_log_entry ('Normal', _logMessage, 'UpdateRequestedRunWP');

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

--
-- Name: set_spectral_library_create_task_complete(integer, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_spectral_library_create_task_complete(IN _libraryid integer, IN _completioncode integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Set a spectral library's state to 3 (complete) or 4 (failed), depending on _completionCode
**
**  Arguments:
**    _libraryId        Spectral library ID
**    _completionCode   Completion code:  0 means success; non-zero means failure
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   04/03/2023 mem - Initial Release
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/07/2023 mem - Align assignment statements
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _libraryName text;
    _libraryStateId int := 0;
    _newLibraryState int;
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

        _libraryId      := Coalesce(_libraryId, 0);
        _completionCode := Coalesce(_completionCode, 0);

         ---------------------------------------------------
        -- Lookup the current state of the library
        ---------------------------------------------------

        SELECT Library_Name,
               Library_State_ID
        INTO _libraryName, _libraryStateId
        FROM T_Spectral_Library
        WHERE Library_ID = _libraryId;

        If Not FOUND Then
            _message := format('Spectral library ID %s not found in T_Spectral_Library', _libraryId);
            CALL post_log_entry ('Error', _message, 'Set_Spectral_Library_Create_Task_Complete');

            _returnCode := 'U5201';
            RETURN;
        End If;

        If _libraryStateId <> 2 Then
            _message := format('Spectral library ID %s has state %s in T_Spectral_Library instead of state 2 (In Progress); leaving the state unchanged',
                                _libraryId, _libraryStateId);
            CALL post_log_entry ('Error', _message, 'Set_Spectral_Library_Create_Task_Complete');

            _returnCode := 'U5202';
            RETURN;
        End If;

        If _completionCode = 0 Then
            _newLibraryState := 3;     -- Complete
        Else
            _newLibraryState := 4;     -- Failed
        End If;

        UPDATE T_Spectral_Library
        SET Library_State_ID = _newLibraryState,
            Completion_Code = _completionCode
        WHERE Library_ID = _libraryId AND
              Library_State_ID = 2;

        If Not FOUND Then
            _message := format('Error setting the state for Spectral library ID %s to %s; no rows were updated',
                                _libraryId, _newLibraryState);
            CALL post_log_entry ('Error', _message, 'Set_Spectral_Library_Create_Task_Complete');

            _returnCode := 'U5203';
            RETURN;
        End If;

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
                            'Updating spectral library state',
                            _logError => true, _displayError => true);

        _returnCode := 'U5205';
        RETURN;
    END;
END
$$;


ALTER PROCEDURE public.set_spectral_library_create_task_complete(IN _libraryid integer, IN _completioncode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


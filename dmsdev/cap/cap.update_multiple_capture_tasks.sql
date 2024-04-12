--
-- Name: update_multiple_capture_tasks(text, text, text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_multiple_capture_tasks(IN _joblist text, IN _action text DEFAULT 'Retry'::text, IN _mode text DEFAULT 'Update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update capture task jobs in list
**
**  Arguments:
**    _jobList      Comma-separated list of capture task jobs to update
**    _action       Action to perform: 'Hold', 'Ignore', 'Release', 'Retry', 'UpdateParameters'
**    _mode         Mode: 'Update' or 'Preview'
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   01/04/2010 grk - Initial release
**          01/14/2010 grk - Enabled all modes
**          01/28/2010 grk - Added UpdateParameters action
**          10/25/2010 mem - Now raising an error if _mode is empty or invalid
**          04/28/2011 mem - Set defaults for _action and _mode
**          03/24/2016 mem - Switch to using Parse_Delimited_Integer_List to parse the list of capture task jobs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          06/22/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;
    _countValid int;
    _countInvalid int;
    _invalidJobList text;

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
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _jobList := Trim(Coalesce(_jobList, ''));

        If _jobList = '' Then
            _message := 'Job list is empty';
            _returnCode := 'U5201';
            _logErrors := false;

            RAISE EXCEPTION '%', _message;
        End If;

        _action := Trim(Coalesce(_action, ''));
        _mode   := Trim(Coalesce(_mode, ''));

        If Not _mode::citext In ('Update', 'Preview') Then
            If _action::citext In ('Hold', 'Ignore', 'Release', 'Retry') Then
                _message := format('Mode should be Update when Action is %s', _action);
            Else
                _message := 'Mode should be Update or Preview';
            End If;

            _returnCode := 'U5202';
            _logErrors := false;

            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Update parameters for capture task jobs
        ---------------------------------------------------

        If _action::citext = 'UpdateParameters' And _mode::citext = 'Update' Then
            CALL cap.update_parameters_for_task (
                        _jobList,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output
        RETURN;
        End If;

        If _action::citext = 'UpdateParameters' And _mode::citext = 'Preview' Then
            CALL cap.update_parameters_for_task (
                        _jobList,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode,     -- Output
                        _infoOnly   => true);
            RETURN;
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold list of capture task jobs
        ---------------------------------------------------

         CREATE TEMP TABLE Tmp_Selected_Jobs (
            Job int,
            State int,
            Valid boolean
        );

        ---------------------------------------------------
        -- Populate table from capture task job list
        ---------------------------------------------------

        INSERT INTO Tmp_Selected_Jobs (Job, Valid)
        SELECT DISTINCT Value, false
        FROM public.parse_delimited_integer_list(_jobList)
        ORDER BY Value;

        ---------------------------------------------------
        -- Look for invalid capture task jobs
        ---------------------------------------------------

        UPDATE Tmp_Selected_Jobs Target
        SET Valid = true,
            State = Src.state
        FROM cap.t_tasks Src
        WHERE Target.Job = Src.job;
        --
        GET DIAGNOSTICS _countValid = ROW_COUNT;

        SELECT COUNT(*)
        INTO _countInvalid
        FROM Tmp_Selected_Jobs
        WHERE NOT Valid;

        If _countInvalid > 0 Then
            SELECT string_agg(Job::text, ', ' ORDER BY Job)
            INTO _invalidJobList
            FROM Tmp_Selected_Jobs
            WHERE NOT Valid;

            If _countValid = 0 Then
                If _countInvalid = 1 Then
                    _message := format('Invalid capture task job: %s not found in cap.t_tasks', _jobList);
                Else
                    _message := format('Capture task jobs not found in cap.t_tasks: %s', _invalidJobList);
                End If;
            Else
                _message := format('%s of %s capture task jobs not found in cap.t_tasks: %s',
                                   _countInvalid,
                                   _countInvalid + _countValid,
                                   _invalidJobList);
            End If;

            RAISE WARNING '%', _message;
        End If;

        ---------------------------------------------------
        -- Retry capture task jobs
        ---------------------------------------------------

        If _action::citext = 'Retry' And _mode::citext = 'Update' Then

            -- Procedure retry_selected_tasks performs the following actions
            --   1) Set any failed or holding capture task job steps to waiting and reset retry count from step tools table
            --   2) Reset the entries in cap.t_task_step_dependencies for any steps with state 1
            --   3) Set capture task job state to 1 (New)

            CALL cap.retry_selected_tasks (
                        _message => _message,           -- Output
                        _returncode => _returncode);    -- Output

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Hold
        ---------------------------------------------------

        If _action::citext = 'Hold' And _mode::citext = 'Update' Then

            UPDATE cap.t_tasks
            SET state = 100
            WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Ignore
        ---------------------------------------------------

        If _action::citext = 'Ignore' And _mode::citext = 'Update' Then

            UPDATE cap.t_tasks
            SET state = 101
            WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Release
        ---------------------------------------------------

        If _action::citext = 'Release' And _mode::citext = 'Update' Then

            UPDATE cap.t_tasks
            SET state = 1
            WHERE job IN (SELECT job FROM Tmp_Selected_Jobs);

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete?
        ---------------------------------------------------

        -- CALL cap.remove_selected_tasks (_infoOnly => false, _logDeletions => false, _message => _message, _returnCode => _returnCode);


        ---------------------------------------------------
        -- If we reach this point, action was not implemented
        ---------------------------------------------------

        If _action::citext In ('Hold', 'Ignore', 'Release', 'Retry', 'UpdateParameters') Then
            _message := format('Action "%s" does not support mode "%s"', _action, _mode);
            _returnCode := 'U5203';
        Else
            _message := format('Action "%s" is not implemented', _action);
            _returnCode := 'U5204';
        End If;

        RAISE WARNING '%', _message;

        DROP TABLE Tmp_Selected_Jobs;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_Selected_Jobs;
    END;
END
$$;


ALTER PROCEDURE cap.update_multiple_capture_tasks(IN _joblist text, IN _action text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_multiple_capture_tasks(IN _joblist text, IN _action text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_multiple_capture_tasks(IN _joblist text, IN _action text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateMultipleCaptureTasks or UpdateMultipleCaptureJobs';


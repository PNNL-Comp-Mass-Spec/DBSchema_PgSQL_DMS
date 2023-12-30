--
-- Name: delete_multiple_tasks(text, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.delete_multiple_tasks(IN _joblist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete entries from appropriate tables for all capture task jobs in given list
**
**  Arguments:
**    _jobList      Comma-separated list of capture task job numbers
**    _message      Status message
**    _returnCode   Return code
**    _callingUser  Username of the calling user
**
**  Auth:   grk
**  Date:   06/03/2010 grk - Initial release
**          09/11/2012 mem - Renamed from DeleteMultipleJobs to DeleteMultipleTasks
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/24/2016 mem - Switch to using Parse_Delimited_Integer_List to parse the list of jobs
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/11/2022 mem - Ported to PostgreSQL
**          04/27/2023 mem - Use boolean for data type name
**          05/22/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          12/08/2023 mem - Select a single column when using If Not Exists()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobCount int;
    _jobCountDeleted int;

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

        ---------------------------------------------------
        -- Create and populate a temporary table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Job_List (
            Job int
        );

        INSERT INTO Tmp_Job_List (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobList)
        ORDER BY Value;
        --
        GET DIAGNOSTICS _jobCount = ROW_COUNT;

        If _jobCount = 0 Then
            _message := format('Job number(s) not found in _jobList: %s', _jobList);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_Job_List;
            RETURN;
        End If;

        If Not Exists (SELECT JT.job  FROM cap.t_tasks JT INNER JOIN Tmp_Job_List L ON JT.job = L.Job) THEN
            _message := format('Capture task %s not found in cap.t_tasks: %s',
                                public.check_plural(_jobCount, 'job', 'jobs'),
                                _jobList);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_Job_List;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete capture task job dependencies
        ---------------------------------------------------

        DELETE FROM cap.t_task_step_dependencies
        WHERE Job IN (SELECT Job FROM Tmp_Job_List);

        ---------------------------------------------------
        -- Delete capture task job parameters
        ---------------------------------------------------

        DELETE FROM cap.t_task_parameters
        WHERE Job IN (SELECT Job FROM Tmp_Job_List);

        ---------------------------------------------------
        -- Delete capture task job steps
        ---------------------------------------------------

        DELETE FROM cap.t_task_steps
        WHERE Job IN (SELECT Job FROM Tmp_Job_List);

        ---------------------------------------------------
        -- Delete capture task jobs
        ---------------------------------------------------

        DELETE FROM cap.t_tasks
        WHERE Job IN (SELECT Job FROM Tmp_Job_List);
        --
        GET DIAGNOSTICS _jobCountDeleted = ROW_COUNT;

        DROP TABLE Tmp_Job_List;

        _message := format('Deleted %s capture task %s', _jobCountDeleted, public.check_plural(_jobCountDeleted, 'job', 'jobs'));
        RAISE INFO '%', _message;

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

        DROP TABLE IF EXISTS Tmp_Job_List;
    END;
END
$$;


ALTER PROCEDURE cap.delete_multiple_tasks(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_multiple_tasks(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.delete_multiple_tasks(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteMultipleTasks';


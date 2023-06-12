--
CREATE OR REPLACE PROCEDURE cap.update_multiple_capture_tasks
(
    _jobList text,
    _action text default 'Retry',
    _mode text default 'Update',
    INOUT _message text DEFAULT '',
    INOUT _returnCode text DEFAULT '',
    _callingUser text DEFAULT ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates capture task jobs in list
**
**  Arguments:
**    _action   Hold, Ignore, Release, Retry, UpdateParameters
**    _mode     Update or Preview
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := true;

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
        -- Validate the inputs
        ---------------------------------------------------

        If Coalesce(_jobList, '') = '' Then
            _message := 'Job list is empty';
            _returnCode := 'U5201';
            _logErrors := false;

            RAISE EXCEPTION '%', _message;
        End If;

        _action := Trim(Lower(Coalesce(_action, '')));
        _mode := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode::citext IN ('Update', 'Preview') Then
            If _action::citext = 'Retry' Then
                _message := 'Mode should be Update when Action is Retry';
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

        If _action::citext = 'UpdateParameters' AND _mode = 'update' Then

            CALL cap.update_parameters_for_task (_jobList, _message => _message, _returnCode => _returnCode);

            RETURN;
        End If;

        If _action::citext = 'UpdateParameters' AND _mode = 'preview' Then
            RETURN;
        End If;

        ---------------------------------------------------
        -- Create temporary table to hold list of capture task jobs
        ---------------------------------------------------

         CREATE TEMP TABLE Tmp_Selected_Jobs (
            Job int,
            Dataset text NULL
        )

        ---------------------------------------------------
        -- Populate table from capture task job list
        ---------------------------------------------------

        INSERT INTO Tmp_Selected_Jobs (Job)
        SELECT Distinct Value
        FROM public.parse_delimited_integer_list(_jobList, ',')
        ORDER BY Value

        ---------------------------------------------------
        -- future: verify that capture task jobs exist?
        ---------------------------------------------------
        --

        ---------------------------------------------------
        -- Retry capture task jobs
        ---------------------------------------------------

        If _action::citext = 'Retry' AND _mode = 'update' Then

            CALL cap.retry_selected_tasks (_message => _message);

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Hold
        ---------------------------------------------------
        If _action::citext = 'Hold' AND _mode = 'update' Then

            UPDATE cap.t_tasks
            SET State = 100
            WHERE Job IN ( SELECT Job FROM Tmp_Selected_Jobs );

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Ignore
        ---------------------------------------------------
        If _action::citext = 'Ignore' AND _mode = 'update' Then

            UPDATE cap.t_tasks
            SET State = 101
            WHERE Job IN ( SELECT Job FROM Tmp_Selected_Jobs );

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Release
        ---------------------------------------------------
        If _action::citext = 'Release' AND _mode = 'update' Then

            UPDATE cap.t_tasks
            SET State = 1
            WHERE Job IN ( SELECT Job FROM Tmp_Selected_Jobs );

            DROP TABLE Tmp_Selected_Jobs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Delete?
        ---------------------------------------------------

        -- CALL Remove_Selected_Jobs 0, _message => _message, 0

        ---------------------------------------------------
        -- If we reach this point, action was not implemented
        ---------------------------------------------------

        _message := format('The ACTION "%s" is not implemented.', _action);
        _returnCode := 'U5201;'

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

COMMENT ON PROCEDURE cap.update_multiple_capture_tasks IS 'UpdateMultipleCaptureJobs';

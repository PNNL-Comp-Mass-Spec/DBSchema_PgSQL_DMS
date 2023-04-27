--
CREATE OR REPLACE PROCEDURE cap.set_ctm_step_task_tool_version
(
    _job int,
    _step int,
    _toolVersionInfo text,
    INOUT _returnCode text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Record the tool version for the given capture task job step
**      Looks up existing entry in T_Step_Tool_Versions; adds new entry if not defined
**
**  Auth:   mem
**  Date:   03/12/2012 mem - Initial version (ported from DMS_Pipeline DB)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _toolVersionID int := 0;

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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------
        --
        _job := Coalesce(_job, 0);
        _step := Coalesce(_step, 0);
        _toolVersionInfo := Coalesce(_toolVersionInfo, '');

        If _toolVersionInfo = '' Then
            _toolVersionInfo := 'Unknown';
        End If;

        ---------------------------------------------------
        -- Look for _toolVersionInfo in cap.t_step_tool_versions
        ---------------------------------------------------
        --
        SELECT tool_version_id
        INTO _toolVersionID
        FROM cap.t_step_tool_versions
        WHERE tool_version = _toolVersionInfo;

        If Not FOUND Then
            ---------------------------------------------------
            -- Add a new entry to cap.t_step_tool_versions
            ---------------------------------------------------

            INSERT INTO cap.t_step_tool_versions (tool_version, entered)
            VALUES (_toolVersionInfo, CURRENT_TIMESTAMP);
            RETURNING tool_version_id
            INTO _toolVersionID;

        End If;

        If _toolVersionID = 0 Then
            ---------------------------------------------------
            -- Something went wrong; _toolVersionInfo wasn't found in cap.t_step_tool_versions
            -- and we were unable to add it
            ---------------------------------------------------

            UPDATE cap.t_task_steps
            SET Tool_Version_ID = 1
            WHERE Job = _job AND
                  Step = _step AND
                  Tool_Version_ID IS NULL;
        Else

            If _job > 0 Then
                UPDATE cap.t_task_steps
                SET Tool_Version_ID = _toolVersionID
                WHERE Job = _job AND
                      Step = _step;

                UPDATE cap.t_step_tool_versions
                SET most_recent_job = _job,
                    last_used = CURRENT_TIMESTAMP
                WHERE tool_version_id = _toolVersionID;
            End If;

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
END
$$;

COMMENT ON PROCEDURE cap.set_ctm_step_task_tool_version IS 'SetStepTaskToolVersion';

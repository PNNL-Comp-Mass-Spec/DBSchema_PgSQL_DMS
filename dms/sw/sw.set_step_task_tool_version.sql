--
-- Name: set_step_task_tool_version(integer, integer, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.set_step_task_tool_version(IN _job integer, IN _step integer, IN _toolversioninfo text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds/updates tool version info in tables sw.t_step_tool_versions and sw.t_job_steps
**
**  Arguments:
**    _job                  Analysis job number
**    _step                 Step number
**    _toolVersionInfo      Tool version info
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   07/05/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          08/12/2023 mem - Ported to PostgreSQL
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

    _toolVersionID int := 0;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job             := Coalesce(_job, 0);
    _step            := Coalesce(_step, 0);
    _toolVersionInfo := Trim(Coalesce(_toolVersionInfo, ''));

    If _toolVersionInfo = '' Then
        _toolVersionInfo := 'Unknown';
        RAISE WARNING '_toolVersionInfo is null or an empty string; using "Unknown" for the version';
    End If;

    ---------------------------------------------------
    -- Look for _toolVersionInfo in sw.t_step_tool_versions
    ---------------------------------------------------

    SELECT tool_version_id
    INTO _toolVersionID
    FROM sw.t_step_tool_versions
    WHERE tool_version = _toolVersionInfo;

    If Not FOUND Then
        ---------------------------------------------------
        -- Add a new entry to sw.t_step_tool_versions
        --
        -- Use an upsert query in case simultaneous calls to this procedure (from separate analysis managers)
        -- results in two threads simultaneously trying to insert a row with the new tool version
        ---------------------------------------------------

        INSERT INTO sw.t_step_tool_versions (tool_version, entered)
        VALUES (_toolVersionInfo, CURRENT_TIMESTAMP)
        ON CONFLICT (tool_version)
        DO UPDATE SET
            entered = CASE WHEN sw.t_step_tool_versions.entered < EXCLUDED.entered
                           THEN sw.t_step_tool_versions.entered
                           ELSE EXCLUDED.entered
                      END;

        SELECT tool_version_id
        INTO _toolVersionID
        FROM sw.t_step_tool_versions
        WHERE tool_version = _toolVersionInfo;

    End If;

    If _job <= 0 Then
        _message := format('Job is 0 (or negative); nothing to do');
        RETURN;
    End If;

    If Coalesce(_toolVersionID, 0) = 0 Then
        ---------------------------------------------------
        -- Something went wrong; _toolVersionInfo wasn't found in sw.t_step_tool_versions
        -- and we were unable to add it with the upsert query
        ---------------------------------------------------

        UPDATE sw.t_job_steps
        SET tool_version_id = 1
        WHERE job = _job AND
              step = _step AND
              tool_version_id IS NULL;

        _message := format('Unable to add the tool version info to sw.t_job_steps; used 1 for the tool version in sw.t_job_steps for job %s, step %s',
                           _job, _step);

        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
        RETURN;
    End If;

    UPDATE sw.t_job_steps
    SET tool_version_id = _toolVersionID
    WHERE job = _job AND
          step = _step;

    If Not FOUND Then
        _message := format('Job %s, step %s not found in sw.t_job_steps', _job, _step);
        RAISE WARNING '%', _message;
    End If;

    UPDATE sw.t_step_tool_versions
    SET most_recent_job = _job,
        last_used = CURRENT_TIMESTAMP
    WHERE tool_version_id = _toolVersionID;

END
$$;


ALTER PROCEDURE sw.set_step_task_tool_version(IN _job integer, IN _step integer, IN _toolversioninfo text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_step_task_tool_version(IN _job integer, IN _step integer, IN _toolversioninfo text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.set_step_task_tool_version(IN _job integer, IN _step integer, IN _toolversioninfo text, INOUT _message text, INOUT _returncode text) IS 'SetStepTaskToolVersion';


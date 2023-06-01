--
CREATE OR REPLACE PROCEDURE sw.set_step_task_tool_version
(
    _job int,
    _step int,
    _toolVersionInfo text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Record the tool version for the given job step
**      Looks up existing entry in T_Step_Tool_Versions; adds new entry if not defined
**
**  Auth:   mem
**  Date:   07/05/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _toolVersionID int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _job := Coalesce(_job, 0);
    _step := Coalesce(_step, 0);
    _toolVersionInfo := Coalesce(_toolVersionInfo, '');

    RAISE INFO '%', _toolVersionInfo;

    If _toolVersionInfo = '' Then
        _toolVersionInfo := 'Unknown';
    End If;

    ---------------------------------------------------
    -- Look for _toolVersionInfo in sw.t_step_tool_versions
    ---------------------------------------------------
    --
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
        --
        INSERT INTO sw.t_step_tool_versions (tool_version, entered)
        VALUES (source.tool_version, CURRENT_TIMESTAMP)
        ON CONFLICT (tool_version)
        DO UPDATE SET
            entered = CASE WHEN sw.t_step_tool_versions.entered < EXCLUDED.entered
                           THEN sw.t_step_tool_versions.entered
                           ELSE EXCLUDED.entered
                       END;

        SELECT tool_version_id
        INTO _toolVersionID
        FROM sw.t_step_tool_versions
        WHERE tool_version = _toolVersionInfo

    End If;

    If _toolVersionID = 0 Then
        ---------------------------------------------------
        -- Something went wrong; _toolVersionInfo wasn't found in sw.t_step_tool_versions
        -- and we were unable to add it with the Merge statement
        ---------------------------------------------------

        UPDATE sw.t_job_steps
        SET tool_version_id = 1
        WHERE job = _job AND
              step = _step AND
              tool_version_id IS NULL
    Else

        If _job > 0 Then
            UPDATE sw.t_job_steps
            SET tool_version_id = _toolVersionID
            WHERE job = _job AND
                  step = _step

            UPDATE sw.t_step_tool_versions
            SET most_recent_job = _job,
                last_used = CURRENT_TIMESTAMP
            WHERE tool_version_id = _toolVersionID
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.set_step_task_tool_version IS 'SetStepTaskToolVersion';

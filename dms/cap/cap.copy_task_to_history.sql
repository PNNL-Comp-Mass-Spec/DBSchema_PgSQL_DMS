--
-- Name: copy_task_to_history(integer, integer, text, boolean, timestamp without time zone); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.copy_task_to_history(IN _job integer, IN _jobstate integer, INOUT _message text DEFAULT ''::text, IN _overridesavetime boolean DEFAULT false, IN _savetimeoverride timestamp without time zone DEFAULT NULL::timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    For a given capture task job, copies the job details, steps,
**    and parameters to the history tables
**
**  Arguments:
**    _job                  Capture task job number
**    _jobState             Current job state
**    _overrideSaveTime     Set to true to use _saveTimeOverride for the SaveTime instead of CURRENT_TIMESTAMP
**    _saveTimeOverride     Timestamp to use when _overrideSaveTime is true
**
**  Auth:   grk
**  Date:   09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/25/2011 mem - Removed priority column from t_task_steps
**          03/12/2012 mem - Now copying column Tool_Version_ID
**          03/10/2015 mem - Added t_task_step_dependencies_history
**          03/22/2016 mem - Update _message when cannot copy a capture task job
**          11/04/2016 mem - Return a more detailed error message in _message
**          10/10/2022 mem - Ported to PostgreSQL
**          03/07/2023 mem - Use new column name
**
*****************************************************/
DECLARE
    _saveTime timestamp;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Bail if no candidates found
    ---------------------------------------------------
    --
     If Coalesce(_job, 0) = 0 Then
        _message := 'Capture task job cannot be 0';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Bail if not a state we save for
    ---------------------------------------------------
    --
    If Not _jobState In (3, 5) Then
        _message := 'Capture task job state must be 3 or 5 to be copied to t_tasks_history (this is not an error)';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Define a common timestamp for all history entries
    ---------------------------------------------------
    --

    If Coalesce(_overrideSaveTime, false) Then
        _saveTime := Coalesce(_saveTimeOverride, CURRENT_TIMESTAMP);
    Else
        _saveTime := CURRENT_TIMESTAMP;
    End If;

    ---------------------------------------------------
    -- Copy capture task job
    ---------------------------------------------------
    --
    INSERT INTO cap.t_tasks_history (
        Job,
        Priority,
        Script,
        State,
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        Imported,
        Start,
        Finish,
        Saved
    )
    SELECT
        Job,
        Priority,
        Script,
        State,
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        Imported,
        Start,
        Finish,
        _saveTime
    FROM cap.t_tasks
    WHERE Job = _job;

    ---------------------------------------------------
    -- Copy steps
    ---------------------------------------------------
    --
    INSERT INTO cap.t_task_steps_history (
        Job,
        Step,
        Tool,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor,
        Start,
        Finish,
        Completion_Code,
        Completion_Message,
        Evaluation_Code,
        Evaluation_Message,
        Saved,
        Tool_Version_ID
    )
    SELECT
        Job,
        Step,
        Tool,
        State,
        Input_Folder_Name,
        Output_Folder_Name,
        Processor,
        Start,
        Finish,
        Completion_Code,
        Completion_Message,
        Evaluation_Code,
        Evaluation_Message,
        _saveTime,
        Tool_Version_ID
    FROM cap.t_task_steps
    WHERE Job = _job;

    ---------------------------------------------------
    -- Copy parameters
    ---------------------------------------------------
    --
    INSERT INTO cap.t_task_parameters_history (
        Job,
        Parameters,
        Saved
    )
    SELECT
        Job,
        Parameters,
        _saveTime
    FROM cap.t_task_parameters
    WHERE Job = _job;

    ---------------------------------------------------
    -- Copy capture task job step dependencies
    ---------------------------------------------------
    --
    -- First delete any extra steps for this capture task job that are in t_task_step_dependencies_history
    --
    DELETE FROM cap.t_task_step_dependencies_history target
    WHERE EXISTS
        (  SELECT 1
           FROM cap.t_task_step_dependencies_history TSDH
                INNER JOIN ( SELECT H.Job,
                                    H.Step
                             FROM cap.t_task_step_dependencies_history H
                                  LEFT OUTER JOIN cap.t_task_step_dependencies D
                                    ON H.Job = D.Job AND
                                       H.Step = D.Step AND
                                       H.Target_Step = D.Target_Step
                             WHERE H.Job = _job AND
                                   D.Job IS NULL
                            ) DeleteQ
                  ON TSDH.Job = DeleteQ.Job AND
                     TSDH.Step = DeleteQ.Step
            WHERE target.job = TSDH.job AND
                  target.step = TSDH.step
        );

    -- Now add/update the capture task job step dependencies
    --
    INSERT INTO cap.t_task_step_dependencies_history (Job, Step, Target_Step, Condition_Test, Test_Value, Evaluated, Triggered, Enable_Only, Saved)
    SELECT Job,
           Step,
           Target_Step,
           Condition_Test,
           Test_Value,
           Evaluated,
           Triggered,
           Enable_Only,
           _saveTime
    FROM cap.t_task_step_dependencies
    WHERE Job = _job
    ON CONFLICT (Job, Step, Target_Step)
    DO UPDATE SET
        Condition_Test = EXCLUDED.Condition_Test,
        Test_Value = EXCLUDED.Test_Value,
        Evaluated = EXCLUDED.Evaluated,
        Triggered = EXCLUDED.Triggered,
        Enable_Only = EXCLUDED.Enable_Only,
        Saved = _saveTime;

    _message := format('Copied capture task job %s to the history tables', _job);
END
$$;


ALTER PROCEDURE cap.copy_task_to_history(IN _job integer, IN _jobstate integer, INOUT _message text, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_task_to_history(IN _job integer, IN _jobstate integer, INOUT _message text, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.copy_task_to_history(IN _job integer, IN _jobstate integer, INOUT _message text, IN _overridesavetime boolean, IN _savetimeoverride timestamp without time zone) IS 'CopyJobToHistory';


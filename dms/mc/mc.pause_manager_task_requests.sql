--
-- Name: pause_manager_task_requests(text, integer, text, text); Type: PROCEDURE; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE mc.pause_manager_task_requests(IN _managername text, IN _holdoffintervalminutes integer DEFAULT 60, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates parameter TaskRequestEnableTime for the given manager
**
**      This will stop the analysis manager from requesting new analysis jobs for the length of time specified by _holdoffIntervalMinutes
**
**  Arguments:
**    _managerName              Manager name
**    _holdoffIntervalMinutes   Holdoff interval, in minutes
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   09/21/2021 mem - Initial version
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          11/20/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _mgrID int;
    _paramTypeID int;
    _newTime text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _managerName            := Trim(Coalesce(_managerName, ''));
    _holdoffIntervalMinutes := Coalesce(_holdoffIntervalMinutes, 60);

    If _holdoffIntervalMinutes < 1 Then
        _holdoffIntervalMinutes := 1;
    End If;

    RAISE INFO '';

    ------------------------------------------------
    -- Confirm that the manager name is valid
    ------------------------------------------------

    SELECT mgr_id
    INTO _mgrID
    FROM mc.t_mgrs
    WHERE mgr_name = _managerName::citext;

    If Not FOUND Then
        _returnCode := 52002;
        _message    := format('Could not find entry for manager: %s', _managername);

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ------------------------------------------------
    -- Determine the parameter type ID
    ------------------------------------------------

    SELECT param_type_id
    INTO _paramTypeID
    FROM mc.t_param_type
    WHERE param_name = 'TaskRequestEnableTime';

    If Not FOUND Then
        _returnCode := 52003;
        _message    := 'Parameter "TaskRequestEnableTime" not found in table mc.t_param_type';
        CALL post_log_entry ('Error', _message, 'Pause_Manager_Task_Requests');

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the 'TaskRequestEnableTime' entry for this manager
    ---------------------------------------------------

    _newTime := date_trunc('second', CURRENT_TIMESTAMP + make_interval(mins => _holdoffIntervalMinutes))::timestamp::text;

    UPDATE mc.t_param_value
    SET value = _newTime
    WHERE mgr_id = _mgrID AND
          param_type_id = _paramTypeID;

    If FOUND Then
        _message := format('Updated TaskRequestEnableTime to %s for manager %s', _newTime, _managerName);

        RAISE INFO '%', _message;
        RETURN;
    End If;

    -- No rows were updated; may need to make a new entry for 'TaskRequestEnableTime' in the t_param_value table
    If Exists (SELECT entry_id FROM mc.t_param_value WHERE mgr_id = _mgrID AND param_type_id = _paramTypeID) Then
        _returnCode := 52004;
        _message := Format('TaskRequestEnableTime is already defined in t_param_value for manager %s; this code should not have been reached', _managerName);
        CALL post_log_entry ('Error', _message, 'Pause_Manager_Task_Requests');

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    INSERT INTO t_param_value (mgr_id, param_type_id, value)
    VALUES (_mgrID, _paramTypeID, _newTime);

    _message := format('Defined TaskRequestEnableTime as %s for manager %s (added new entry to mc.t_param_value)', _newTime, _managerName);
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE mc.pause_manager_task_requests(IN _managername text, IN _holdoffintervalminutes integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE pause_manager_task_requests(IN _managername text, IN _holdoffintervalminutes integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON PROCEDURE mc.pause_manager_task_requests(IN _managername text, IN _holdoffintervalminutes integer, INOUT _message text, INOUT _returncode text) IS 'PauseManagerTaskRequests';


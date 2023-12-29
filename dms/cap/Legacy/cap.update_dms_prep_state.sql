--
-- Name: update_dms_prep_state(integer, text, integer, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_dms_prep_state(IN _job integer, IN _script text, IN _newjobstateinbroker integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update prep LC state in public.set_prep_lc_task_complete
**
**  Arguments:
**    _job                  Capture task job number
**    _script               Script name; must be 'HPLCSequenceCapture'
**    _newJobStateInBroker  New state for the given job; if 3 or 5, call public.set_prep_lc_task_complete()
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   05/08/2010 grk - Initial Veresion
**          06/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _prepLCID int;
    _storagePathID int;
BEGIN
    _message := '';
    _returnCode := '';

    If _script = 'HPLCSequenceCapture' Then
        SELECT public.try_cast(value, null::int)
        INTO _prepLCID
        FROM cap.get_task_param_table_local(_job)
        WHERE name = 'ID';

        SELECT public.try_cast(value, null::int)
        INTO _storagePathID
        FROM cap.get_task_param_table_local(_job)
        WHERE name = 'Storage_Path_ID';

        -- Call set_prep_lc_task_complete (aka SetPrepLCTaskComplete) if _newJobStateInBroker is 3 or 5

        If _newJobStateInBroker = 3 Then
            CALL public.set_prep_lc_task_complete (_prepLCID, _storagePathID, 0, _message => _message);
        End If;

        If _newJobStateInBroker = 5 Then
            CALL public.set_prep_lc_task_complete (_prepLCID, 0, 1, _message => _message);
        End If;

    End If;

END
$$;


ALTER PROCEDURE cap.update_dms_prep_state(IN _job integer, IN _script text, IN _newjobstateinbroker integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dms_prep_state(IN _job integer, IN _script text, IN _newjobstateinbroker integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_dms_prep_state(IN _job integer, IN _script text, IN _newjobstateinbroker integer, INOUT _message text, INOUT _returncode text) IS 'UpdateDMSPrepState';


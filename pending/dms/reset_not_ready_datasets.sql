--
CREATE OR REPLACE PROCEDURE public.reset_not_ready_datasets
(
    _interval int = 10
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Checks all datasets that are in 'Not Ready' state
**      and resets them to 'New'
**
**  Arguments:
**    _interval   Minutes between retries
**
**  Auth:   grk
**  Date:   08/06/2003
**          05/16/2007 mem - Updated to use DS_Last_Affected (Ticket:478)
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
    _stateNotReady int;
    _stateNew int;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Reset all datasets that are in 'Not Ready' state
    ---------------------------------------------------

    -- Update to 'new' state all datasets that are in the target state
    -- and have been in that state at least for the required interval
    --
    _stateNotReady := 9    -- 'not ready' state;

    _stateNew := 1        -- 'new' state;

    UPDATE t_dataset
    SET    dataset_state_id = _stateNew
    WHERE dataset_state_id = _stateNotReady AND
          last_affected < CURRENT_TIMESTAMP - make_interval(mins => _interval);

END
$$;

COMMENT ON PROCEDURE public.reset_not_ready_datasets IS 'ResetNotReadyDatasets';

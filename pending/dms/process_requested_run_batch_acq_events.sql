--
CREATE OR REPLACE PROCEDURE public.process_requested_run_batch_acq_events
(
    _interval int = 24
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Process 'Requested Run Batch Acq Time Ready' events
**
**  Arguments:
**    _interval   Hours since last run
**
**  Auth:   grk
**  Dte:    03/29/2010 grk - Initial release
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingUser text;
    _threshold timestamp;
    _batchID int;
BEGIN
    _message := '';
    _returnCode:= '';

    _callingUser := get_user_login_without_domain();

    ---------------------------------------------------
    -- Last time we did this
    ---------------------------------------------------

    _threshold := CURRENT_TIMESTAMP - make_interval(hours => _interval);

    ---------------------------------------------------
    -- Temporary list of batches to calculate
    -- automatic factors for
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_BatchIDs (
        BatchID int
    );

    ---------------------------------------------------
    -- Event 'Requested Run Batch Acq Time Ready'
    -- since last time we did this
    ---------------------------------------------------
    --
    INSERT INTO Tmp_BatchIDs ( BatchID )
    SELECT target_id
    FROM t_notification_event
    WHERE ( event_type_id = 3 ) AND entered > _threshold;

    ---------------------------------------------------
    -- Loop through list and make factors
    ---------------------------------------------------

    FOR _batchID IN
        SELECT BatchID
        FROM Tmp_BatchIDs
        ORDER BY BatchID
    LOOP
        CALL make_automatic_requested_run_factors (
                _batchID,
                'actual_run_order',
                _message => _message,
                _returnCode => _returnCode,
                _callingUser);

        If _returnCode <> '' Then
            -- Break out of the For loop
            EXIT;
        End If;
    END LOOP;

    DROP TABLE Tmp_BatchIDs;
END
$$;

COMMENT ON PROCEDURE public.process_requested_run_batch_acq_events IS 'ProcessRequestedRunBatchAcqEvents';

--
-- Name: process_requested_run_batch_acq_events(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.process_requested_run_batch_acq_events(IN _interval integer DEFAULT 24, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Process 'Requested Run Batch Acq Time Ready' events
**
**      Calls make_automatic_requested_run_factors() for events in t_notification_event with event_type_id = 3 and created within the last _interval hours
**
**  Arguments:
**    _interval     Hours since last run; threshold for finding events in t_notification_event to process
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Dte:    03/29/2010 grk - Initial version
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          02/16/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _callingUser text;
    _threshold timestamp;
    _matchCount int;
    _batchID int;
BEGIN
    _message := '';
    _returnCode := '';

    _callingUser := public.get_user_login_without_domain();

    ---------------------------------------------------
    -- Last time we did this
    ---------------------------------------------------

    _interval := Coalesce(_interval, 24);

    If _interval < 1 Then
        _interval := 1;
    End If;

    _threshold := CURRENT_TIMESTAMP - make_interval(hours => _interval);

    ---------------------------------------------------
    -- Temporary list of batches to calculate
    -- automatic factors for
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_BatchIDs (
        BatchID int
    );

    ---------------------------------------------------
    -- Process new 'Requested Run Batch Acq Time Ready' events
    -- since last time we did this
    ---------------------------------------------------

    INSERT INTO Tmp_BatchIDs ( BatchID )
    SELECT target_id
    FROM t_notification_event
    WHERE event_type_id = 3 AND entered > _threshold;

    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount = 0 Then
        RAISE INFO 'No events entered after % were found in t_notification_event',
                    public.timestamp_text(_threshold);
        DROP TABLE Tmp_BatchIDs;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Loop through list and make factors
    ---------------------------------------------------

    RAISE INFO 'Calling make_automatic_requested_run_factors for % notification % entered after %',
               _matchCount,
               public.check_plural(_matchCount, 'event', 'events'),
               public.timestamp_text(_threshold);

    FOR _batchID IN
        SELECT BatchID
        FROM Tmp_BatchIDs
        ORDER BY BatchID
    LOOP
        CALL public.make_automatic_requested_run_factors (
                        _batchID     => _batchID,
                        _mode        => 'actual_run_order',
                        _message     => _message,           -- Output
                        _returnCode  => _returnCode,        -- Output
                        _callingUser => _callingUser);

        If _returnCode <> '' Then

            If Coalesce(_message, '') = '' Then
                RAISE WARNING 'Procedure make_automatic_requested_run_factors reported return code %; aborting processing',
                              _returnCode;
            Else
                RAISE WARNING 'Procedure make_automatic_requested_run_factors: % (return code %); aborting processing',
                              _message,
                              _returnCode;
            End If;

            -- Break out of the for loop
            EXIT;
        End If;
    END LOOP;

    DROP TABLE Tmp_BatchIDs;
END
$$;


ALTER PROCEDURE public.process_requested_run_batch_acq_events(IN _interval integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE process_requested_run_batch_acq_events(IN _interval integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.process_requested_run_batch_acq_events(IN _interval integer, INOUT _message text, INOUT _returncode text) IS 'ProcessRequestedRunBatchAcqEvents';


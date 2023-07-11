--
-- Name: move_capture_entries_to_history(integer, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.move_capture_entries_to_history(IN _intervaldays integer DEFAULT 240, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move entries from log tables into historic log tables
**      In addition, purges old data in cap.t_task_parameters_history
**
**  Arguments:
**    _intervalDays     Move entries older than this number of days before the current date
**    _infoOnly         When true, show the number of entries in each table that would be archived
**
**  Auth:   mem
**  Date:   07/12/2011 mem - Initial version
**          10/04/2011 mem - Removed _dBName parameter
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          10/07/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**          02/15/2023 mem - Add commit statements
**          04/02/2023 mem - Rename procedure and functions
**          04/12/2023 mem - Use new table names
**          05/13/2023 mem - Rename variables
**          07/11/2023 mem - Use COUNT(job) and COUNT(entry_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _dateThreshold text;
    _matchCount int;
    _deleteCount int;
BEGIN

    ----------------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------------

    If Coalesce(_intervalDays, 0) < 32 Then
        _intervalDays := 32;
    End If;

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(days => _intervalDays);

    _dateThreshold = public.timestamp_text(_cutoffDateTime);

    ----------------------------------------------------------
    -- Copy Job_Events entries into historic log tables
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            RAISE INFO '';

            SELECT COUNT(job)
            INTO _matchCount
            FROM cap.t_task_events
            WHERE entered < _cutoffDateTime;

            If _matchCount > 0 Then
                RAISE INFO 'Would move % rows from cap.t_task_events to logcap.t_task_events since entered before %', _matchCount, _dateThreshold;
            Else
                RAISE INFO 'All entries in cap.% are newer than %', RPAD('t_task_events', 26, ' '), _dateThreshold;
            End If;

        Else

            INSERT INTO logcap.t_task_events( event_id,
                                              job,
                                              target_state,
                                              prev_target_state,
                                              entered,
                                              entered_by )
            SELECT event_id,
                   job,
                   target_state,
                   prev_target_state,
                   entered,
                   entered_by
            FROM cap.t_task_events
            WHERE entered < _cutoffDateTime
            ORDER BY event_id
            ON CONFLICT (event_id)
            DO UPDATE SET
              job = EXCLUDED.job,
              target_state = EXCLUDED.target_state,
              prev_target_state = EXCLUDED.prev_target_state,
              entered = EXCLUDED.entered,
              entered_by = EXCLUDED.entered_by;

            -- Remove the old entries
            --
            DELETE FROM cap.t_task_events
            WHERE entered < _cutoffDateTime;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                RAISE INFO 'Deleted % rows from cap.t_task_parameters_history since saved before %', _deleteCount, _dateThreshold;
            End If;
        End If;

        COMMIT;
    END;

    ----------------------------------------------------------
    -- Copy Job_Step_Events entries into historic log tables
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(job)
            INTO _matchCount
            FROM cap.t_task_step_events
            WHERE entered < _cutoffDateTime;

            If _matchCount > 0 Then
                RAISE INFO 'Would move % rows from cap.t_task_step_events to logcap.t_task_step_events since entered before %', _matchCount, _dateThreshold;
            Else
                RAISE INFO 'All entries in cap.% are newer than %', RPAD('t_task_step_events', 26, ' '), _dateThreshold;
            End If;

        Else

            INSERT INTO logcap.t_task_step_events( event_id,
                                                   job,
                                                   step,
                                                   target_state,
                                                   prev_target_state,
                                                   entered,
                                                   entered_by )
            SELECT event_id,
                   job,
                   step,
                   target_state,
                   prev_target_state,
                   entered,
                   entered_by
            FROM cap.t_task_step_events
            WHERE entered < _cutoffDateTime
            ORDER BY event_id
            ON CONFLICT (event_id)
            DO UPDATE SET
              job = EXCLUDED.job,
              step = EXCLUDED.step,
              target_state = EXCLUDED.target_state,
              prev_target_state = EXCLUDED.prev_target_state,
              entered = EXCLUDED.entered,
              entered_by = EXCLUDED.entered_by;

            -- Remove the old entries
            --
            DELETE FROM cap.t_task_step_events
            WHERE entered < _cutoffDateTime;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                RAISE INFO 'Deleted % rows from cap.t_task_step_events since saved before %', _deleteCount, _dateThreshold;
            End If;
        End If;

        COMMIT;
    END;

    ----------------------------------------------------------
    -- Copy Job_Step_Processing_Log entries into historic log tables
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(job)
            INTO _matchCount
            FROM cap.t_task_step_processing_log
            WHERE entered < _cutoffDateTime;

            If _matchCount > 0 Then
                RAISE INFO 'Would move % rows from cap.t_task_step_processing_log to logcap.t_task_step_processing_log since entered before %', _matchCount, _dateThreshold;
            Else
                RAISE INFO 'All entries in cap.% are newer than %', RPAD('t_task_step_processing_log', 26, ' '), _dateThreshold;
            End If;

        Else

            INSERT INTO logcap.t_task_step_processing_log( event_id,
                                                           job,
                                                           step,
                                                           processor,
                                                           entered,
                                                           entered_by )
            SELECT event_id,
                   job,
                   step,
                   processor,
                   entered,
                   entered_by
            FROM cap.t_task_step_processing_log
            WHERE entered < _cutoffDateTime
            ORDER BY event_id
            ON CONFLICT (event_id)
            DO UPDATE SET
              job = EXCLUDED.job,
              step = EXCLUDED.step,
              processor = EXCLUDED.processor,
              entered = EXCLUDED.entered,
              entered_by = EXCLUDED.entered_by;

            -- Remove the old entries
            --
            DELETE FROM cap.t_task_step_processing_log
            WHERE entered < _cutoffDateTime;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                RAISE INFO 'Deleted % rows from cap.t_task_step_processing_log since saved before %', _deleteCount, _dateThreshold;
            End If;
        End If;

        COMMIT;
    END;

    ----------------------------------------------------------
    -- Copy Log entries into historic log tables
    -- Skip entries of type 'Info'
    ----------------------------------------------------------

    BEGIN
        If _infoOnly Then
            SELECT COUNT(entry_id)
            INTO _matchCount
            FROM cap.t_log_entries
            WHERE entered < _cutoffDateTime;

            If _matchCount > 0 Then
                RAISE INFO 'Would move % rows from cap.t_log_entries to logcap.t_log_entries since entered before %', _matchCount, _dateThreshold;
            Else
                RAISE INFO 'All entries in cap.% are newer than %', RPAD('t_log_entries', 26, ' '), _dateThreshold;
            End If;

        Else

            INSERT INTO logcap.t_log_entries( entry_id,
                                              posted_by,
                                              entered,
                                              type,
                                              message,
                                              entered_by )
            SELECT entry_id,
                   posted_by,
                   entered,
                   type,
                   message,
                   entered_by
            FROM cap.t_log_entries
            WHERE entered < _cutoffDateTime AND type <> 'Info'
            ORDER BY entry_id
            ON CONFLICT (entry_id)
            DO UPDATE SET
              posted_by = EXCLUDED.posted_by,
              entered = EXCLUDED.entered,
              type = EXCLUDED.type,
              message = EXCLUDED.message,
              entered_by = EXCLUDED.entered_by;

            -- Remove the old entries
            --
            DELETE FROM cap.t_log_entries
            WHERE entered < _cutoffDateTime;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                RAISE INFO 'Deleted % rows from cap.t_log_entries since saved before %', _deleteCount, _dateThreshold;
            End If;
        End If;

        COMMIT;
    END;

    ----------------------------------------------------------
    -- Delete old entries in T_task_Parameters_History
    --
    -- Note that this data is intentionally not copied to the historic log tables
    -- because it is very easy to re-generate (use update_parameters_for_task)
    ----------------------------------------------------------

    If _infoOnly Then
        SELECT COUNT(job)
        INTO _matchCount
        FROM cap.t_task_parameters_history
        WHERE Saved < _cutoffDateTime;

        If _matchCount > 0 Then
            RAISE INFO 'Would delete % rows from cap.t_task_parameters_history since saved before %', _matchCount, _dateThreshold;
        Else
            RAISE INFO 'All entries in cap.% are newer than %', RPAD('t_task_parameters_history', 26, ' '), _dateThreshold;
        End If;

    Else
        DELETE FROM cap.t_task_parameters_history
        WHERE Saved < _cutoffDateTime;
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _deleteCount > 0 Then
            RAISE INFO 'Deleted % rows from cap.t_task_parameters_history since saved before %', _deleteCount, _dateThreshold;
        End If;
    End If;

END
$$;


ALTER PROCEDURE cap.move_capture_entries_to_history(IN _intervaldays integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE move_capture_entries_to_history(IN _intervaldays integer, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.move_capture_entries_to_history(IN _intervaldays integer, IN _infoonly boolean) IS 'MoveEntriesToHistory';


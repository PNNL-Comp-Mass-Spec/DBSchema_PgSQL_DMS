--
-- Name: move_historic_log_entries(integer, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.move_historic_log_entries(IN _infoholdoffweeks integer DEFAULT 2, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Move log entries from dpkg.t_log_entries into into the historic log table (logdms.t_log_entries_data_package)
**
**  Auth:   mem
**  Date:   03/07/2018 mem - Initial version
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          08/15/2023 mem - Update the where clause filter for finding unimporant log entries
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _rowCount int;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    -- Require that _infoHoldoffWeeks be at least 1
    If Coalesce(_infoHoldoffWeeks, 0) < 1 Then
        _infoHoldoffWeeks := 1;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _cutoffDateTime := CURRENT_TIMESTAMP + make_interval(weeks => -(_infoHoldoffWeeks));

    If _infoOnly Then
        RAISE INFO '';

        SELECT COUNT(entry_id)
        INTO _rowCount
        FROM dpkg.t_log_entries
        WHERE Entered < _cutoffDateTime AND
              type = 'Normal' AND
              message LIKE 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for % data package%';

        If _rowCount > 0 Then
            RAISE INFO 'Would delete % unimportant % from dpkg.t_log_entries (using threshold %)',
                        _rowCount,
                        public.check_plural(_rowCount, 'entry', 'entries'),
                        public.timestamp_text(_cutoffDateTime);
        Else
            RAISE INFO 'No unimportant log entries were found in dpkg.t_log_entries (using threshold %)',
                        public.timestamp_text(_cutoffDateTime);
        End If;

        SELECT COUNT(entry_id)
        INTO _rowCount
        FROM dpkg.t_log_entries
        WHERE Entered < _cutoffDateTime;

        If _rowCount > 0 Then
            RAISE INFO 'Would move % old % from dpkg.t_log_entries to logdms.t_log_entries_data_package (using threshold %)',
                        _rowCount,
                        public.check_plural(_rowCount, 'entry', 'entries'),
                        public.timestamp_text(_cutoffDateTime);
        Else
            RAISE INFO 'No log entries older than % were found in dpkg.t_log_entries',
                        public.timestamp_text(_cutoffDateTime);
        End If;

        RETURN;
    End If;

    -- Delete log entries that we do not want to move to t_log_entries_data_package
    DELETE FROM dpkg.t_log_entries
    WHERE Entered < _cutoffDateTime AND
          type = 'Normal' AND
          message LIKE 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for % data package%';

    -- Copy entries into the historic log table
    INSERT INTO logdms.t_log_entries_data_package (entry_id, posted_by, Entered, type, message)
    SELECT entry_id, posted_by, Entered, type, message
    FROM dpkg.t_log_entries
    WHERE Entered < _cutoffDateTime;

    -- Remove the old entries from dpkg.t_log_entries
    DELETE FROM dpkg.t_log_entries
    WHERE Entered < _cutoffDateTime;

END
$$;


ALTER PROCEDURE dpkg.move_historic_log_entries(IN _infoholdoffweeks integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE move_historic_log_entries(IN _infoholdoffweeks integer, IN _infoonly boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.move_historic_log_entries(IN _infoholdoffweeks integer, IN _infoonly boolean) IS 'MoveHistoricLogEntries';


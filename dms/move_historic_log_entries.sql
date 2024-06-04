--
-- Name: move_historic_log_entries(integer, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.move_historic_log_entries(IN _intervalhrs integer DEFAULT 336, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Move log entries from public.t_log_entries into the historic log table (logdms.t_log_entries)
**
**  Arguments:
**    _intervalHrs      Threshold, in hours, to use when moving move entries from t_log_entries; required to be at least 120
**    _infoOnly         When true, show the number of log entries that would be removed or moved
**
**  Auth:   grk
**  Date:   06/14/2001
**          03/10/2009 mem - Now removing non-noteworthy entries from T_Log_Entries before moving old entries to DMSHistoricLog1
**          10/04/2011 mem - Removed _dBName parameter
**          07/31/2012 mem - Renamed Historic Log DB from DMSHistoricLog1 to DMSHistoricLog
**          10/15/2012 mem - Now excluding routine messages from BackupDMSDBs and RebuildFragmentedIndices
**          10/29/2015 mem - Increase default value from 5 days to 14 days (336 hours)
**          06/09/2022 mem - Rename target table from T_Historic_Log_Entries to T_Log_Entries
**                         - No longer store the database name in the target table
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/01/2023 mem - Ported to PostgreSQL
**          05/26/2024 mem - Use ON CONFLICT () to handle primary key conflicts
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _rowCount int;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    -- Require that _intervalHrs be at least 120
    If Coalesce(_intervalHrs, 0) < 120 Then
        _intervalHrs := 120;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(hours => _intervalHrs);

    If _infoOnly Then
        RAISE INFO '';

        SELECT COUNT(entry_id)
        INTO _rowCount
        FROM public.t_log_entries
        WHERE entered < _cutoffDateTime AND
             (message IN ('Archive or update complete for all available tasks',
                          'Verfication complete for all available tasks',
                          'Capture complete for all available tasks') OR
              message LIKE '%: No Data Files to import.' OR
              message LIKE '%: Completed task'           OR
              posted_by = 'backup_dms_dbs'             AND type = 'Normal' AND message LIKE 'DB Backup Complete (LogBU%' OR
              posted_by = 'rebuild_fragmented_indices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
             );

        If _rowCount > 0 Then
            RAISE INFO 'Would delete % unimportant % from public.t_log_entries (using threshold %)',
                        _rowCount,
                        public.check_plural(_rowCount, 'entry', 'entries'),
                        public.timestamp_text(_cutoffDateTime);
        Else
            RAISE INFO 'No unimportant log entries were found in public.t_log_entries (using threshold %)',
                        public.timestamp_text(_cutoffDateTime);
        End If;

        SELECT COUNT(entry_id)
        INTO _rowCount
        FROM public.t_log_entries
        WHERE entered < _cutoffDateTime;

        If _rowCount > 0 Then
            RAISE INFO 'Would move % old % from public.t_log_entries to logdms.t_log_entries (using threshold %)',
                        _rowCount,
                        public.check_plural(_rowCount, 'entry', 'entries'),
                        public.timestamp_text(_cutoffDateTime);
        Else
            RAISE INFO 'No log entries older than % were found in public.t_log_entries',
                        public.timestamp_text(_cutoffDateTime);
        End If;

        RETURN;
    End If;

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM public.t_log_entries
    WHERE entered < _cutoffDateTime AND
         (message IN ('Archive or update complete for all available tasks',
                      'Verfication complete for all available tasks',
                      'Capture complete for all available tasks') OR
          message LIKE '%: No Data Files to import.' OR
          message LIKE '%: Completed task'           OR
          posted_by = 'backup_dms_dbs'             AND type = 'Normal' AND message LIKE 'DB Backup Complete (LogBU%' OR
          posted_by = 'rebuild_fragmented_indices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
         );

    -- Copy entries into the historic log tables
    INSERT INTO logdms.t_log_entries (entry_id, posted_by, entered, type, message)
    SELECT entry_id,
           posted_by,
           entered,
           type,
           message
    FROM public.t_log_entries
    WHERE entered < _cutoffDateTime
    ORDER BY entry_id
    ON CONFLICT (entry_id)
    DO UPDATE SET
      posted_by  = EXCLUDED.posted_by,
      entered    = EXCLUDED.entered,
      type       = EXCLUDED.type,
      message    = EXCLUDED.message;

    -- Remove the old entries from t_log_entries
    DELETE FROM public.t_log_entries
    WHERE entered < _cutoffDateTime;

END
$$;


ALTER PROCEDURE public.move_historic_log_entries(IN _intervalhrs integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE move_historic_log_entries(IN _intervalhrs integer, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.move_historic_log_entries(IN _intervalhrs integer, IN _infoonly boolean) IS 'MoveHistoricLogEntries';


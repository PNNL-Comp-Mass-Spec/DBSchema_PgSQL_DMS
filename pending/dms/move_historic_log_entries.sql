--
CREATE OR REPLACE PROCEDURE public.move_historic_log_entries
(
    _intervalHrs int = 336
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Move log entries from the main log table into the historic log table (logdms.t_log_entries )
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
BEGIN
    -- Require that _intervalHrs be at least 120
    If Coalesce(_intervalHrs, 0) < 120 Then
        _intervalHrs := 120;
    End If;

    _cutoffDateTime := CURRENT_TIMESTAMP - make_interval(hours => _intervalHrs);

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM public.t_log_entries
    WHERE Entered < _cutoffDateTime AND
         ( message IN ('Archive or update complete for all available tasks',
                       'Verfication complete for all available tasks',
                       'Capture complete for all available tasks') OR
           message LIKE '%: No Data Files to import.' OR
           message LIKE '%: Completed task'           OR
           posted_by = 'BackupDMSDBs'             AND type = 'Normal' AND message LIKE 'DB Backup Complete (LogBU%' OR
           posted_by = 'RebuildFragmentedIndices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
           );

    -- Copy entries into the historic log tables
    --
    INSERT INTO logdms.t_log_entries (entry_id, posted_by, Entered, type, message)
    SELECT entry_id,
           posted_by,
           Entered,
           type,
           message
    FROM public.t_log_entries
    WHERE Entered < _cutoffDateTime;

    -- Remove the old entries from t_log_entries
    --
    DELETE FROM public.t_log_entries
    WHERE Entered < _cutoffDateTime;

END
$$;

COMMENT ON PROCEDURE public.move_historic_log_entries IS 'MoveHistoricLogEntries';

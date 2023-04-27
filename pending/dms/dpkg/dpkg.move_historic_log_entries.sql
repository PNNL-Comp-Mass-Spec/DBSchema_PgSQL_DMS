--
CREATE OR REPLACE PROCEDURE dpkg.move_historic_log_entries
(
    _infoHoldoffWeeks int = 2
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Move log entries from main log into the
**          historic log (insert and then delete)
**          that are older than given by _intervalHrs
**
**  Auth:   mem
**  Date:   03/07/2018 mem - Initial version
**          08/26/2022 mem - Use new column name in T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _cutoffDateTime timestamp;
    _transName text := 'TRAN_MoveHistoricLogEntries';
BEGIN
    -- Require that _infoHoldoffWeeks be at least 1
    If Coalesce(_infoHoldoffWeeks, 0) < 1 Then
        _infoHoldoffWeeks := 1;
    End If;

    _cutoffDateTime := DateAdd(week, -1 * _infoHoldoffWeeks, CURRENT_TIMESTAMP);

    -- Start transaction
    --
    begin transaction _transName

    -- Delete log entries that we do not want to move to the DMS Historic Log DB
    DELETE FROM dbo.t_log_entries
    WHERE Entered < _cutoffDateTime AND
         ( type = 'Normal' AND message Like 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for % data packages%' OR
           posted_by = 'RebuildFragmentedIndices' AND type = 'Normal' AND message LIKE 'Reindexed % due to Fragmentation%'
           )
    --
    if @@error <> 0 Then
        rollback transaction _transName
        RAISERROR ('Error removing unwanted log entries from dpkg.t_log_entries', 10, 1)
        return 51179
    End If;

    -- Copy entries into the historic log database
    --
    INSERT INTO logdms.T_Log_Entries_Data_Package (entry_id, posted_by, Entered, type, message)
    SELECT entry_id, posted_by, Entered, type, message
    FROM dpkg.t_log_entries
    WHERE Entered < _cutoffDateTime;

    --
    if @@error <> 0 Then
        rollback transaction _transName
        RAISERROR ('Insert was unsuccessful for historic log entry table from dpkg.t_log_entries',
            10, 1)
        return 51180
    End If;

    -- Remove the old entries from dpkg.t_log_entries
    --
    DELETE FROM dpkg.t_log_entries
    WHERE Entered < _cutoffDateTime
    --
    if @@error <> 0 Then
        rollback transaction _transName
        RAISERROR ('Delete was unsuccessful for dpkg.t_log_entries',
            10, 1)
        return 51181
    End If;

    commit transaction _transName

    return 0
END
$$;

COMMENT ON PROCEDURE dpkg.move_historic_log_entries IS 'MoveHistoricLogEntries';

--
CREATE OR REPLACE PROCEDURE pc.reindex_database
(
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Reindexes the key tables in the database
**      Once complete, updates ReindexDatabaseNow to 0 in T_Process_Step_Control
**
**  Return values: 0:  success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/11/2007
**          10/30/2007 mem - Now calling VerifyUpdateEnabled
**          10/09/2008 mem - Added T_Score_Inspect
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _tableCount int;
    _updateEnabled int;
BEGIN
    _tableCount := 0;

    _message := '';

    -----------------------------------------------------------
    -- Reindex the data tables
    -----------------------------------------------------------
    DBCC DBREINDEX (pc.t_archived_output_files, '', 90)
    _tableCount := _tableCount + 1;

    -- Validate that updating is enabled, abort if not enabled
    Call _callingFunctionDescription => 'reindex_database', _allowPausing => 1, _updateEnabled => _updateEnabled output, _message => _message output
    If _updateEnabled = 0 Then
        Goto Done;
    End If;

    DBCC DBREINDEX (pc.t_protein_names, '', 90)
    _tableCount := _tableCount + 1;

    -- Validate that updating is enabled, abort if not enabled
    Call _callingFunctionDescription => 'reindex_database', _allowPausing => 1, _updateEnabled => _updateEnabled output, _message => _message output
    If _updateEnabled = 0 Then
        Goto Done;
    End If;

    DBCC DBREINDEX (pc.t_proteins, '', 90)
    _tableCount := _tableCount + 1;

    -- Validate that updating is enabled, abort if not enabled
    Call _callingFunctionDescription => 'reindex_database', _allowPausing => 1, _updateEnabled => _updateEnabled output, _message => _message output
    If _updateEnabled = 0 Then
        Goto Done;
    End If;

    DBCC DBREINDEX (pc.t_protein_headers, '', 90)
    _tableCount := _tableCount + 1;

    -- Validate that updating is enabled, abort if not enabled
    Call _callingFunctionDescription => 'reindex_database', _allowPausing => 1, _updateEnabled => _updateEnabled output, _message => _message output
    If _updateEnabled = 0 Then
        Goto Done;
    End If;

    DBCC DBREINDEX (pc.t_protein_collection_members, '', 90)
    _tableCount := _tableCount + 1;

    -----------------------------------------------------------
    -- Log the reindex
    -----------------------------------------------------------

    _message := 'Reindexed ' || _tableCount::text || ' tables';
    Call post_log_entry 'Normal', _message, 'ReindexDatabase'

    -----------------------------------------------------------
    -- Update pc.t_process_step_control
    -----------------------------------------------------------

    -- Set 'ReindexDatabaseNow' to 0
    --
    UPDATE pc.t_process_step_control
    SET enabled = 0
    WHERE (processing_step_name = 'ReindexDatabaseNow')
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _message := 'Entry "ReindexDatabaseNow" not found in pc.t_process_step_control; adding it';
        Call post_log_entry 'Error', _message, 'ReindexDatabase'

        INSERT INTO pc.t_process_step_control (processing_step_name, enabled)
        VALUES ('ReindexDatabaseNow', 0)
    End If;

    -- Set 'InitialDBReindexComplete' to 1
    --
    UPDATE pc.t_process_step_control
    SET enabled = 1
    WHERE (processing_step_name = 'InitialDBReindexComplete')
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _message := 'Entry "InitialDBReindexComplete" not found in pc.t_process_step_control; adding it';
        Call post_log_entry 'Error', _message, 'ReindexDatabase'

        INSERT INTO pc.t_process_step_control (processing_step_name, enabled)
        VALUES ('InitialDBReindexComplete', 1)
    End If;

Done:
    Return _myError

END
$$;

COMMENT ON PROCEDURE pc.reindex_database IS 'ReindexDatabase';

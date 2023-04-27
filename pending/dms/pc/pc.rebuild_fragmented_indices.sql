--
CREATE OR REPLACE PROCEDURE pc.rebuild_fragmented_indices
(
    _maxFragmentation int = 15,
    _trivialPageCount int = 12,
    _verifyUpdateEnabled int = 1,
    _infoOnly int = 1,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Reindexes fragmented indices in the database
**
**  Return values: 0:  success, otherwise, error code
**
**  Arguments:
**    _verifyUpdateEnabled   When non-zero, then calls VerifyUpdateEnabled to assure that database updating is enabled
**
**  Auth:   mem
**  Date:   11/12/2007
**          10/15/2012 mem - Added spaces prior to printing debug messages
**          10/18/2012 mem - Added parameter _verifyUpdateEnabled
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _objectid int;
    _indexid int;
    _partitioncount bigint;
    _schemaname text;
    _objectname text;
    _indexname text;
    _partitionnum bigint;
    _partitions bigint;
    _frag float;
    _command text;
    _hasBlobColumn int;
    _startTime timestamp;
    _continue int;
    _uniqueID int;
    _indexCountProcessed int;
    _updateEnabled int;
BEGIN
    _indexCountProcessed := 0;

    ---------------------------------------
    -- Validate the inputs
    ---------------------------------------
    --
    _maxFragmentation := Coalesce(_maxFragmentation, 15);
    _trivialPageCount := Coalesce(_trivialPageCount, 12);
    _verifyUpdateEnabled := Coalesce(_verifyUpdateEnabled, 1);
    _infoOnly := Coalesce(_infoOnly, 1);
    _message := '';

    ---------------------------------------
    -- Create a table to track the indices to process
    ---------------------------------------
    --
    CREATE TABLE dbo.TmpIndicesToProcess(
        [UniqueID] int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        [objectid] [int] NULL,
        [indexid] [int] NULL,
        [partitionnum] [int] NULL,
        [frag] [float] NULL
    ) ON [PRIMARY]

    ---------------------------------------
    -- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function
    -- and convert object and index IDs to names.
    ---------------------------------------
    --
    INSERT INTO TmpIndicesToProcess (objectid, indexid, partitionnum, frag)
    SELECT object_id,
           index_id,
           partition_number,
           avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats ( DB_ID(), NULL, NULL, NULL, 'LIMITED' )
    WHERE avg_fragmentation_in_percent > _maxFragmentation
      AND index_id > 0 -- cannot defrag a heap
      AND page_count > _trivialPageCount -- ignore trivial sized indexes
     ORDER BY avg_fragmentation_in_percent Desc
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _message := 'All database indices have fragmentation levels below ' || _maxFragmentation::text || '%';
        If _infoOnly <> 0 Then
            RAISE INFO '%', '  ' || _message;
        End If;
        Return;
    End If;

    ---------------------------------------
    -- Loop through TmpIndicesToProcess and process the indices
    ---------------------------------------
    --
    _startTime := CURRENT_TIMESTAMP;
    _continue := 1;
    _uniqueID := -1;

    While _continue = 1 Loop
        -- This While loop can probably be converted to a For loop; for example:
        --    For _itemName In
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    Loop
        --        ...
        --    End Loop

        -- Moved to bottom of query: TOP 1
        SELECT UniqueiD, INTO _uniqueID
                     _objectid = objectid,
                     _indexid = indexid,
                     _partitionnum = partitionnum,
                     _frag = frag
        FROM TmpIndicesToProcess
        WHERE UniqueID > _uniqueID
        ORDER BY UniqueID
        LIMIT 1;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _continue := 0;
        Else
        -- <b>

            _hasBlobColumn := 0; -- reinitialize
            SELECT QUOTENAME(o.name), INTO _objectname
                   _schemaname = QUOTENAME(s.name)
            FROM sys.objects AS o
                 JOIN sys.schemas AS s
                   ON s.schema_id = o.schema_id
            WHERE o.object_id = _objectid

            SELECT QUOTENAME(name) INTO _indexname
            FROM sys.indexes
            WHERE object_id = _objectid AND
                  index_id = _indexid

            SELECT count(*) INTO _partitioncount
            FROM sys.partitions
            WHERE object_id = _objectid AND
                  index_id = _indexid

            -- Check for BLOB columns
            If _indexid = 1 -- only check here for clustered indexes ANY blob column on the table counts  Then
                SELECT CASE INTO _hasBlobColumn
                                            WHEN max(so.object_ID) IS NULL THEN 0
                                            ELSE 1
                                        End If;
                FROM sys.objects SO
                     INNER JOIN sys.columns SC
                       ON SO.Object_id = SC.object_id
                     INNER JOIN sys.types ST
                       ON SC.system_type_id = ST.system_type_id
                   AND
                ST.name IN ('text', 'ntext', 'image', 'text', 'text', 'varbinary(max)', 'xml')
                WHERE SO.Object_ID = _objectID
            Else -- nonclustered. Only need to check if indexed column is a BLOB
                SELECT CASE INTO _hasBlobColumn
                                            WHEN max(so.object_ID) IS NULL THEN 0
                                            ELSE 1
                                        End If;
                FROM sys.objects SO
                     INNER JOIN sys.index_columns SIC
                       ON SO.Object_ID = SIC.object_id
                     INNER JOIN sys.Indexes SI
                       ON SO.Object_ID = SI.Object_ID AND
                          SIC.index_id = SI.index_id
                     INNER JOIN sys.columns SC
                       ON SO.Object_id = SC.object_id AND
                          SIC.Column_id = SC.column_id
                     INNER JOIN sys.types ST
                       ON SC.system_type_id = ST.system_type_id
                          AND ST.name IN ('text', 'ntext', 'image', 'text', 'text', 'varbinary(max)', 'xml')
                WHERE SO.Object_ID = _objectID
            End Loop;

            _command := N'ALTER INDEX ' || _indexname + N' ON ' || _schemaname + N'.' || _objectname + N' REBUILD';

            if _hasBlobColumn = 1  Then
                _command := _command + N' WITH( SORT_IN_TEMPDB = ON) ' ;
            Else
                _command := _command + N' WITH( ONLINE = OFF, SORT_IN_TEMPDB = ON) ' ;
            End If;

            IF _partitioncount > 1  Then
                _command := _command + N' PARTITION=' || CAST(_partitionnum AS text) ;
            End If;

            _message := 'Fragmentation = ' || Convert(text, convert(decimal(9,1), _frag)) || '%; ';
            _message := _message || 'Executing: ' || _command || ' Has Blob = ' || _hasBlobColumn::nvarchar(2) ;

            if _infoOnly <> 0 Then
                RAISE INFO '%', '  ' || _message;
            Else
                Call (_command)

                _message := 'Reindexed ' || _indexname || ' due to Fragmentation = ' || Convert(text, Convert(decimal(9,1), _frag)) || '%; ';
                Call post_log_entry 'Normal', _message, 'RebuildFragmentedIndices'

                _indexCountProcessed := _indexCountProcessed + 1;

                If _verifyUpdateEnabled <> 0 Then
                    -- Validate that updating is enabled, abort if not enabled
                    If Exists (select * from sys.objects where name = 'VerifyUpdateEnabled') Then
                        Call _callingFunctionDescription => 'rebuild_fragmented_indices', _allowPausing => 1, _updateEnabled => _updateEnabled output, _message => _message output
                        If _updateEnabled = 0 Then
                            Goto Done;
                        End If;
                    End If;
                End If;
            End If;

        End -- </b>
    End -- </a>

    If _indexCountProcessed > 0 Then
        ---------------------------------------
        -- Log the reindex
        ---------------------------------------

        _message := 'Reindexed ' || _indexCountProcessed::text || ' indices in ' || convert(text, Convert(decimal(9,1), DateDiff(second, _startTime, CURRENT_TIMESTAMP) / 60.0)) || ' minutes';
        Call post_log_entry 'Normal', _message, 'RebuildFragmentedIndices'
    End If;

Done:

    -- Drop the temporary table.
    DROP TABLE TmpIndicesToProcess

    Return _myError

END
$$;

COMMENT ON PROCEDURE pc.rebuild_fragmented_indices IS 'RebuildFragmentedIndices';

--
-- Name: store_dataset_file_info(text, boolean, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_dataset_file_info(IN _datasetfileinfo text, IN _infoonly boolean DEFAULT false, IN _updateexisting text DEFAULT ''::text, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store SHA-1 hash info or file size info for dataset files
**
**      By default, only adds new data to t_dataset_files; will not replace existing values
**      Set _updateExisting to 'Force' to forcibly replace existing hash values or change existing file sizes
**
**      Filenames cannot contain spaces
**
**      Assumes data is formatted as a SHA-1 hash (40 characters) followed by the relative file path, with one file per line
**      Alternatively, can have file size followed by relative file path
**
**      Hash values (or file sizes) and file paths can be space or tab-separated
**      Determines dataset name by removing the extension from the filename (e.g. .raw)
**
**      Alternatively, the input can be three columns, formatted as SHA-1 hash (or file size), relative path, and dataset name or dataset ID
**
**  Support file info formats:
**      Two-column format:
**        b1edc1310d7989f2107d7d2be903ae756698608d *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**        9f1576f73c290ffa763cf45ffa497af370036719 *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**        3101f1e3b2c548ba6b881739a3682f4971d1ea8a *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**      Two-column column format with file size and relative file path (which is simply the filename if the file is in the dataset directory):
**        1,729,715,419 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**        1,679,089,387 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**        1,708,057,145 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**      Three-column column format, using dataset names:
**        2c6f81f3b421ac9780bc3dc61133e13c9add9097    DATA.MS    Bet_Se_Pel_M
**        f3bba221c7d794826eadda5d8bd8ebffd1c7fe15    DATA.MS    Bet_Se_CoC_Med_M
**        2ce8bafc5506c76ef99343e882f1ed3e55e528f4    DATA.MS    Bet_Rg_Pel_M
**
**      Three-column column format, using dataset IDs:
**        800076cfee2f23efa076394676db9a46c317ed0a    ser    739716
**        6f4959e18d1ddc0ed0a11fc1ba7028a369ba4c25    ser    739715
**        16ba36087f53684be77e3512ea131331044dda63    ser    739714
**
**      Three-column column format with file size, file name, and dataset name:
**        4609024    DATA.MS    Bet_Rg_Pel_M
**        2072576    DATA.MS    Bet_Se_CoC_Med_M
**        4979200    DATA.MS    Bet_Se_Pel_M
**
**  Arguments:
**    _datasetFileInfo      Hash codes and file names, formatted using one of the supported formats shown above
**    _updateExisting       If this is 'Force', updating existing dataset file info
**    _showDebug            When true, show debug messages
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   04/02/2019 mem - Initial version
**          02/23/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _rowCount int;
    _existingInfoSkips int;
    _datasetName text;
    _datasetID int;
    _delimiter text;
    _entryID int;
    _charIndex int;
    _colCount int;
    _lastPeriodLoc int;
    _row text;
    _fileHashOrSize text;
    _datasetNameOrId text;
    _fileHash text;
    _fileSizeText text;
    _fileSizeBytes bigint;
    _filePath text;
    _existingSize bigint;
    _existingHash text;
    _itemsToUpdate int;
    _updateCount int;

    _warning text;
    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Create a temporary table to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_FileData (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Value text NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_FileData_EntryID ON Tmp_FileData (EntryID);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly       := Coalesce(_infoOnly, false);
    _updateExisting := Lower(Trim(Coalesce(_updateExisting, '')));
    _showDebug      := Coalesce(_showDebug, false);

    -----------------------------------------
    -- Split _datasetFileInfo on carriage returns
    -- Store the data in Tmp_FileData
    -----------------------------------------

    If Position(chr(10) In _datasetFileInfo) > 0 Then
        _delimiter := chr(10);
    Else
        _delimiter := chr(13);
    End If;

    INSERT INTO Tmp_FileData (Value)
    SELECT Value
    FROM public.parse_delimited_list(_datasetFileInfo, _delimiter);
    --
    GET DIAGNOSTICS _rowCount = ROW_COUNT;

    If Not Exists (SELECT EntryID FROM Tmp_FileData) Then
        _message := 'Nothing returned when splitting the dataset file list on CR or LF';
        _returnCode := 'U5201';

        DROP TABLE Tmp_FileData;
        RETURN;
    End If;

    If _showDebug Then
        RAISE INFO '';
        RAISE INFO 'Parsing % % in _datasetFileInfo', _rowCount, public.check_plural(_rowCount, 'row', 'rows');
    End If;

    -----------------------------------------
    -- Create more temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_DataColumns (
        EntryID int NOT NULL,
        Value text NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_DataColumns_EntryID ON Tmp_DataColumns (EntryID);

    CREATE TEMP TABLE Tmp_HashUpdates (
        Dataset_ID int NOT NULL,
        InstFilePath text NOT NULL,     -- Relative file path of the instrument file
        InstFileHash text NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_HashUpdates ON Tmp_HashUpdates (Dataset_ID, InstFilePath);

    CREATE TEMP TABLE Tmp_SizeUpdates (
        Dataset_ID int NOT NULL,
        InstFilePath text NOT NULL,     -- Relative file path of the instrument file
        InstFileSize bigint NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_SizeUpdates ON Tmp_SizeUpdates (Dataset_ID, InstFilePath);

    CREATE TEMP TABLE Tmp_Warnings (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Warning text NULL,
        RowText text NULL
    );

    CREATE TEMP TABLE Tmp_UpdatedDatasets (
        Dataset_ID int NOT NULL
    );

    -----------------------------------------
    -- Parse the file list
    -----------------------------------------

    _existingInfoSkips := 0;

    FOR _entryID, _row IN
        SELECT EntryID, Value
        FROM Tmp_FileData
        ORDER BY EntryID
    LOOP
        -- _row should now be empty, or contain something like the following:

        -- Hash and Filename
        -- b1edc1310d7989f2107d7d2be903ae756698608d *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw

        -- FileSize and Filename
        -- 1,729,715,419 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw

        -- Hash, Filename, DatasetName
        -- 2c6f81f3b421ac9780bc3dc61133e13c9add9097    DATA.MS    Bet_Se_Pel_M

        -- Hash, Filename, DatasetId
        -- 800076cfee2f23efa076394676db9a46c317ed0a    ser    739716

        -- FileSize, Filename, DatasetName
        -- 4609024    DATA.MS    Bet_Rg_Pel_M

        _row := Replace (_row, chr(10), '');
        _row := Replace (_row, chr(13), '');
        _row := Trim(Coalesce(_row, ''));

        -- Replace tabs with spaces
        _row := Replace (_row, chr(9), ' ');

        If Trim(Coalesce(_row, '')) = '' Then
            CONTINUE;
        End If;

        If _showDebug Then
            RAISE INFO '';
            RAISE INFO 'Split row on spaces: %', _row;
        End If;

        -- Split the row on spaces
        TRUNCATE TABLE Tmp_DataColumns;

        _delimiter := ' ';

        INSERT INTO Tmp_DataColumns (EntryID, Value)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_row, _delimiter);
        --
        GET DIAGNOSTICS _colCount = ROW_COUNT;

        If _colCount < 2 Then
            _warning := 'Skipped row since less than 2 columns';

            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES (_warning, _row);

            If _showDebug Then
                RAISE INFO '%: %', _warning, _row;
            End If;

            CONTINUE;
        End If;

        If _showDebug Then
            RAISE INFO '  Column count: %', _colCount;
        End If;

        _fileHash      := '';
        _fileSizeText  := '';
        _fileSizeBytes := 0;

        -- This should have the relative file path (simply filename if the file is in the dataset directory)
        _filePath := '';

        _datasetNameOrID := '';
        _datasetName     := format('EntryID_%s', _entryID);
        _datasetID       := 0;
        _fileHashOrSize  := '';

        SELECT Trim(Coalesce(Value, ''))
        INTO _fileHashOrSize
        FROM Tmp_DataColumns
        WHERE EntryID = 1;

        SELECT Trim(Coalesce(Value, ''))
        INTO _filePath
        FROM Tmp_DataColumns
        WHERE EntryID = 2;

        -- SHA1Sum prepends filenames with *; remove the * if present
        _filePath := Replace(_filePath, '*', '');

        If _colCount = 2 Then
            -- Determine the dataset name from the file name
            If _filePath Like '%.%' Then
                _lastPeriodLoc := char_length(_filePath) - Position('.' In Reverse(_filePath));
                _datasetName   := Substring(_filePath, 1, _lastPeriodLoc);
            Else
                _warning := format('Skipped row since filename "%s" does not contain a period', _filePath);

                INSERT INTO Tmp_Warnings (Warning, RowText)
                VALUES (_warning, _row);

                If _showDebug Then
                    RAISE INFO '%', _warning;
                End If;

                CONTINUE;
            End If;
        Else
            SELECT Trim(Coalesce(Value, ''))
            INTO _datasetNameOrId
            FROM Tmp_DataColumns
            WHERE EntryID = 3;

            _datasetId := public.try_cast(_datasetNameOrID, null::int);

            If Not _datasetId Is Null Then
                -- Lookup the dataset name
                SELECT dataset
                INTO _datasetName
                FROM t_dataset
                WHERE dataset_id = _datasetId;

                If Not FOUND Then
                    _warning := format('Skipped row since dataset ID not found in t_dataset: %s', _datasetId);

                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES (_warning, _row);

                    If _showDebug Then
                        RAISE INFO '%; %', _warning, _row;
                    End If;

                    CONTINUE;
                End If;
            Else
                _datasetName := _datasetNameOrId;
            End If;
        End If;

        -- Validate the dataset name
        SELECT dataset_id
        INTO _datasetId
        FROM t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            _warning := format('Skipped row since dataset name not found in t_dataset: %s', _datasetName);

            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES (_warning, _row);

            If _showDebug Then
                RAISE INFO '%; %', _warning, _row;
            End If;

            CONTINUE;
        End If;

        If _showDebug Then
            RAISE INFO '  Parsing file info for Dataset ID % (%)', _datasetId, _datasetName;
        End If;

        If _fileHashOrSize = '' Then
            _warning := 'Skipped row since file hash or size is blank';

            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES (_warning, _row);

            If _showDebug Then
                RAISE INFO '%: %', _warning, _row;
            End If;

            CONTINUE;
        End If;

        If _filePath = '' Then
            _warning := 'Skipped row since file path (typically filename) is blank';

            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES (_warning, _row);

            If _showDebug Then
                RAISE INFO '%: %', _warning, _row;
            End If;

            CONTINUE;
        End If;

        -- Determine whether we're entering hash values or file sizes

        If char_length(_fileHashOrSize) < 40 Then
            _fileSizeBytes := public.try_cast(Replace(_fileHashOrSize, ',', ''), null::bigint);

            If _fileSizeBytes Is Null Then
                _warning := format('Skipped row since file size is not a number (and is less than 40 characters, so is not a hash): %s', _fileHashOrSize);

                INSERT INTO Tmp_Warnings (Warning, RowText)
                VALUES (_warning, _row);

                If _showDebug Then
                    RAISE INFO '%; %', _warning, _row;
                End If;

                CONTINUE;
            End If;
        Else
            If char_length(_fileHashOrSize) > 40 Then
                _warning := format('Skipped row since file hash is not 40 characters long: %s', _fileHashOrSize);

                INSERT INTO Tmp_Warnings (Warning, RowText)
                VALUES (_warning, _row);

                If _showDebug Then
                    RAISE INFO '%; %', _warning, _row;
                End If;

                CONTINUE;
            Else
                _fileHash := _fileHashOrSize;
            End If;
        End If;

        -- Validate that the update is allowed, then cache it

        If _fileHash = '' And _fileSizeBytes > 0 Then

            -- Updating file size

            If _updateExisting <> 'force' Then
                -- Assure that we're not updating an existing file size

                SELECT file_size_bytes
                INTO _existingSize
                FROM t_dataset_files
                WHERE dataset_id = _datasetID AND
                      file_path = _filePath;

                If FOUND And Coalesce(_existingSize, 0) > 0 Then
                    _warning := format('Skipped row since file size is already defined for %s, dataset ID %s', _filePath, _datasetId);

                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES (_warning, _row);

                    If _showDebug Then
                        RAISE INFO '%', _warning;
                    End If;

                    _existingInfoSkips := _existingInfoSkips + 1
                    CONTINUE;
                End If;
            End If;

            INSERT INTO Tmp_SizeUpdates (Dataset_ID, InstFilePath, InstFileSize)
            VALUES (_datasetID, _filePath, _fileSizeBytes);

        End If;

        If _fileHash <> '' Then

            If _updateExisting <> 'force' Then
                -- Assure that we're not updating an existing file size

                SELECT file_hash
                INTO _existingHash
                FROM t_dataset_files
                WHERE dataset_id = _datasetID AND
                      file_path = _filePath;

                If FOUND And char_length(Coalesce(_existingHash, '')) > 0 Then
                    _warning := format('Skipped row since file hash is already defined for %s, dataset ID %s', _filePath, _datasetId);

                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES (_warning, _row);

                    If _showDebug Then
                        RAISE INFO '%', _warning;
                    End If;

                    _existingInfoSkips := _existingInfoSkips + 1
                    CONTINUE;
                End If;
            End If;

            INSERT INTO Tmp_HashUpdates (Dataset_ID, InstFilePath, InstFileHash)
            VALUES (_datasetID, _filePath, _fileHash);
        End If;

    END LOOP;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data (but do not exit, since there might be warning messages to show)
        -----------------------------------------------

        _formatSpecifier := '%-12s %-10s %-80s %-40s';

        _infoHead := format(_formatSpecifier,
                            'Update_Type',
                            'Dataset_ID',
                            'Instrument_File_Path',
                            'Instrument_File_Hash'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '----------------------------------------'
                                    );

        _itemsToUpdate := 0;

        If Exists (SELECT Dataset_ID FROM Tmp_HashUpdates) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            _updateCount := 0;

            FOR _previewData IN
                SELECT 'Update hash' AS Update_Type,
                       Dataset_ID,
                       InstFilePath,
                       InstFileHash
                FROM Tmp_HashUpdates
                ORDER BY Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Update_Type,
                                    _previewData.Dataset_ID,
                                    _previewData.InstFilePath,
                                    _previewData.InstFileHash
                                   );

                RAISE INFO '%', _infoData;

                _updateCount := _updateCount + 1;
            END LOOP;

            _itemsToUpdate := _itemsToUpdate + _updateCount;
        End If;

        If Exists (SELECT Dataset_ID FROM Tmp_SizeUpdates) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            _updateCount := 0;

            FOR _previewData IN
                SELECT 'Update size' AS Update_Type,
                       Dataset_ID,
                       InstFilePath,
                       InstFileSize
                FROM Tmp_SizeUpdates
                ORDER BY Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Update_Type,
                                    _previewData.Dataset_ID,
                                    _previewData.InstFilePath,
                                    _previewData.InstFileSize
                                   );

                RAISE INFO '%', _infoData;

                _updateCount := _updateCount + 1;
            END LOOP;

            _itemsToUpdate := _itemsToUpdate + _updateCount;
        End If;

        If _existingInfoSkips > 0 Then

            RAISE INFO '';
            RAISE INFO 'Skipped % % existing info; to force an update, use "_updateExisting => true"',
                       _existingInfoSkips,
                       public.check_plural(_existingInfoSkips, 'file since it has', 'files since they have');

        ElsIf _itemsToUpdate = 0 Then
            RAISE WARNING 'No valid data was found in _datasetFileInfo';
        End If;

    Else
        -----------------------------------------------
        -- Add/update hash info in t_dataset_files using a merge statement
        -----------------------------------------------

        MERGE INTO t_dataset_files AS Target
        USING (SELECT dataset_id, InstFilePath, InstFileHash
               FROM Tmp_HashUpdates
              ) AS Source
        ON (Target.dataset_id = Source.dataset_id AND Target.file_path = Source.InstFilePath)
        WHEN MATCHED THEN
            UPDATE SET
                file_hash = Source.InstFileHash,
                deleted = false
        WHEN NOT MATCHED THEN
            INSERT (dataset_id, file_path, file_hash)
            VALUES (Source.dataset_id, Source.InstFilePath, Source.InstFileHash);

        -----------------------------------------------
        -- Add/update file size info in t_dataset_files using a merge statement
        -----------------------------------------------

        MERGE INTO t_dataset_files AS Target
        USING (SELECT dataset_id, InstFilePath, InstFileSize
               FROM Tmp_SizeUpdates
              ) AS Source
        ON (Target.dataset_id = Source.dataset_id AND Target.file_path = Source.InstFilePath)
        WHEN MATCHED THEN
            UPDATE SET
                file_size_bytes = Source.InstFileSize,
                deleted = false
        WHEN NOT MATCHED THEN
            INSERT (dataset_id, file_path, file_size_bytes)
            VALUES (Source.dataset_id, Source.InstFilePath, Source.InstFileSize);

        INSERT INTO Tmp_UpdatedDatasets (Dataset_ID)
        SELECT Dataset_ID FROM Tmp_HashUpdates
        UNION
        SELECT Dataset_ID FROM Tmp_SizeUpdates;

        -----------------------------------------------
        -- Update the file_size_rank column for the datasets
        -----------------------------------------------

        UPDATE t_dataset_files Target
        SET file_size_rank = SrcQ.Size_Rank
        FROM (SELECT dataset_id,
                     file_path,
                     file_size_bytes,
                     file_hash,
                     dataset_file_id,
                     Row_Number() OVER (
                        PARTITION BY dataset_id
                        ORDER BY deleted ASC, file_size_bytes DESC
                        ) AS Size_Rank
              FROM t_dataset_files
              WHERE Dataset_ID IN (SELECT Dataset_ID FROM Tmp_UpdatedDatasets)
             ) SrcQ
        WHERE Target.Dataset_File_ID = SrcQ.Dataset_File_ID;

        _message := 'Dataset info update successful';

        -----------------------------------------------
        -- Show the updated files
        -----------------------------------------------

        If Exists (SELECT Dataset_ID FROM Tmp_UpdatedDatasets) Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-80s %-15s %-14s %-41s %-80s %-25s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Dataset',
                                'File_Size_Bytes',
                                'File_Size_Rank',
                                'File_Hash',
                                'File_Path',
                                'Instrument'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------------------------------------------------------------------',
                                         '---------------',
                                         '--------------',
                                         '-----------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '-------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Dataset_ID,
                       Dataset,
                       File_Size_Bytes,
                       File_Size_Rank,
                       File_Hash,
                       File_Path,
                       Instrument
                FROM V_Dataset_Files_List_Report
                WHERE Dataset_ID IN (SELECT Dataset_ID FROM Tmp_UpdatedDatasets)
                ORDER BY Dataset, File_Size_Rank
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Dataset,
                                    _previewData.File_Size_Bytes,
                                    _previewData.File_Size_Rank,
                                    _previewData.File_Hash,
                                    _previewData.File_Path,
                                    _previewData.Instrument
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;
    End If;

    If Exists (SELECT EntryID FROM Tmp_Warnings) Then

        RAISE INFO '';

        _formatSpecifier := '%-160s %-150s';

        _infoHead := format(_formatSpecifier,
                            'Warning',
                            'Row_Text'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------------------------------------------------------------------------------------------------------------------------------------------------',
                                     '----------------------------------------------------------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Warning,
                   RowText
            FROM Tmp_Warnings
            ORDER BY EntryID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Warning,
                                _previewData.RowText
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetId);
    Else
        _usageMessage := format('Dataset: %s', _datasetName);
    End If;

    If Not _infoOnly Then
        CALL post_usage_log_entry ('store_dataset_file_info', _usageMessage);
    End If;

    If Coalesce(_message, '') <> '' Then
        RAISE INFO '';
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_FileData;
    DROP TABLE Tmp_DataColumns;
    DROP TABLE Tmp_HashUpdates;
    DROP TABLE Tmp_SizeUpdates;
    DROP TABLE Tmp_Warnings;
    DROP TABLE Tmp_UpdatedDatasets;
END
$$;


ALTER PROCEDURE public.store_dataset_file_info(IN _datasetfileinfo text, IN _infoonly boolean, IN _updateexisting text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_dataset_file_info(IN _datasetfileinfo text, IN _infoonly boolean, IN _updateexisting text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_dataset_file_info(IN _datasetfileinfo text, IN _infoonly boolean, IN _updateexisting text, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) IS 'StoreDatasetFileInfo';


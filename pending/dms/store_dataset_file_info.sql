--
CREATE OR REPLACE PROCEDURE public.store_dataset_file_info
(
    _datasetFileInfo text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _updateExisting text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Stores SHA-1 hash info or file size info for dataset files
**
**      By default, only adds new data to T_Dataset_Files; will not replace existing values.
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
**  Example 2 column input (will auto replace ' *' with ' '):
**
**    b1edc1310d7989f2107d7d2be903ae756698608d *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**    9f1576f73c290ffa763cf45ffa497af370036719 *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**    3101f1e3b2c548ba6b881739a3682f4971d1ea8a *01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**  Example 2 column input with file size and relative file path (which is simply the filename if the file is in the dataset directory)
**
**    1,729,715,419 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f01_19Mar17_Bane_Rep-16-12-04.raw
**    1,679,089,387 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f02_19Mar17_Bane_Rep-16-12-04.raw
**    1,708,057,145 01CPTAC_CompRefCO_W_PNNL_20170123_B1S5_f03_20Mar17_Bane_Rep-16-12-04.raw
**
**  Example 3 column input (Dataset Name):
**
**    2c6f81f3b421ac9780bc3dc61133e13c9add9097    DATA.MS    Bet_Se_Pel_M
**    f3bba221c7d794826eadda5d8bd8ebffd1c7fe15    DATA.MS    Bet_Se_CoC_Med_M
**    2ce8bafc5506c76ef99343e882f1ed3e55e528f4    DATA.MS    Bet_Rg_Pel_M
**
**  Example 3 column input (Dataset ID):
**
**    800076cfee2f23efa076394676db9a46c317ed0a    ser    739716
**    6f4959e18d1ddc0ed0a11fc1ba7028a369ba4c25    ser    739715
**    16ba36087f53684be77e3512ea131331044dda63    ser    739714
**
**  Example 3 column input with file size, file name, and Dataset Name
**    4609024    DATA.MS    Bet_Rg_Pel_M
**    2072576    DATA.MS    Bet_Se_CoC_Med_M
**    4979200    DATA.MS    Bet_Se_Pel_M
**
**  Arguments:
**    _datasetFileInfo   hash codes and file names
**
**  Auth:   mem
**  Date:   04/02/2019 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _updateCount int;
    _datasetName text := '';
    _datasetID int := 0;
    _delimiter text;
    _entryID int;
    _entryIDEnd int := 0;
    _charIndex int;
    _colCount Int;
    _lastPeriodLoc int;
    _row text;
    _fileHashOrSize text;
    _datasetNameOrId text;
    _fileHash text;
    _fileSizeText text;
    _fileSizeBytes Bigint;
    _filePath text;
    _existingSize Bigint;
    _existingHash text;
    _itemsToUpdate int := 0;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Create temporary tables to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_FileData (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Value text Null
    );

    CREATE UNIQUE INDEX IX_Tmp_FileData_EntryID ON Tmp_FileData (EntryID);

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
        Warning text Null,
        RowText text Null
    );

    CREATE TEMP TABLE Tmp_UpdatedDatasets (
        Dataset_ID Int Not Null
    );

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _updateExisting := Coalesce(_updateExisting, '');

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
    FROM public.parse_delimited_list(_datasetFileInfo, _delimiter)

    If Not Exists (SELECT * FROM Tmp_FileData) Then
        _message := 'Nothing returned when splitting the Dataset File List on CR or LF';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -- Relative file path (simply filename if the file is in the dataset directory)

    SELECT MAX(EntryID)
    INTO _entryIDEnd
    FROM Tmp_FileData;

    -----------------------------------------
    -- Parse the host list
    -----------------------------------------
    --
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

        -- Split the row on spaces
        TRUNCATE TABLE Tmp_DataColumns;

        _delimiter := ' ';

        INSERT INTO Tmp_DataColumns (EntryID, Value)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_row, _delimiter, 0)
        --
        GET DIAGNOSTICS _colCount = ROW_COUNT;

        If _colCount < 2 Then
            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES ('Skipping row since less than 2 columns', _row);

            CONTINUE;
        End If;

        _fileHash := '';
        _fileSizeText := '';
        _fileSizeBytes := 0;
        _filePath := '';

        _datasetNameOrID := '';
        _datasetName := format('EntryID_%s', _entryID);
        _datasetID := 0;

        SELECT Value
        INTO _fileHashOrSize
        FROM Tmp_DataColumns
        WHERE EntryID = 1;

        SELECT Value
        INTO _filePath
        FROM Tmp_DataColumns
        WHERE EntryID = 2;

        -- SHA1Sum prepends filenames with *; remove the * if present
        _filePath := Replace (_filePath, '*', '');

        If _colCount = 2 Then
        -- <d1>
            -- Determine the dataset name from the file name
            If _filePath Like '%.%' Then
                _lastPeriodLoc := char_length(_filePath) - Position('.' In Reverse(_filePath));
                _datasetName := Substring(_filePath, 1, _lastPeriodLoc);
            Else
                INSERT INTO Tmp_Warnings (Warning, RowText)
                VALUES (format('Skipping row since Filename "%s" does not contain a period', _filePath), _row);

                CONTINUE;
            End If;
        Else
        -- <d2>
            SELECT Value
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
                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES ('Skipping row since dataset ID not found in t_dataset: ' || _datasetId), _row);

                    CONTINUE;
                End If;
            Else
                _datasetName := _datasetNameOrId;
            End If;

        End If; -- </d2>

        -- Validate the dataset name
        SELECT dataset_id
        INTO _datasetId
        FROM t_dataset
        WHERE dataset = _datasetName;

        If Not FOUND Then
            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES ('Skipping row since dataset Name not found in t_dataset: ' || _datasetName, _row);

            CONTINUE;
        End If;

        If Not _skipRow And (_fileHashOrSize = '') Then
            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES ('Skipping row since file hash or size is blank', _row);

            CONTINUE;
        End If;

        If Not _skipRow And (_filePath = '') Then
            INSERT INTO Tmp_Warnings (Warning, RowText)
            VALUES ('Skipping row since file path (typically filename) is blank', _row);

            CONTINUE;
        End If;

        If Not _skipRow Then
            -- Determine whether we're entering hash values or file sizes

            If char_length(_fileHashOrSize) < 40 Then
                _fileSizeBytes := public.try_cast(Replace(_fileHashOrSize, ',', ''), null::bigint);

                If _fileSizeBytes Is Null Then
                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES ('Skipping row since file size is not a number (and is less than 40 characters, so is not a hash): ' || _fileHashOrSize, _row);

                    CONTINUE;
                End If;
            Else
                If char_length(_fileHashOrSize) > 40 Then
                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES ('Skipping row since file hash is not 40 characters long: ' || _fileHashOrSize, _row);

                    CONTINUE;
                Else
                    _fileHash := _fileHashOrSize;
                End If;
            End If;
        End If;

        -- Validate that the update is allowed, then cache it

        If _fileHash = '' And _fileSizeBytes > 0 Then
        -- <f>
            -- Updating file size
            If _updateExisting <> 'Force' Then
                -- Assure that we're not updating an existing file size
                _existingSize := 0;

                SELECT file_size_bytes
                INTO _existingSize
                FROM t_dataset_files
                WHERE dataset_id = _datasetID AND
                      file_path = _filePath;

                If FOUND And Coalesce(_existingSize, 0) > 0 Then
                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES (format('Skipping row since file size is already defined for %s, Dataset ID %s', _filePath, _datasetId),
                            _row);

                    CONTINUE;
                End If;
            End If;

            INSERT INTO Tmp_SizeUpdates (Dataset_ID, InstFilePath, InstFileSize)
            VALUES (_datasetID, _filePath, _fileSizeBytes);

        End If; -- </f>

        If _fileHash <> '' Then
        -- <g>
            If _updateExisting <> 'Force' Then
                -- Assure that we're not updating an existing file size
                _existingHash := '';

                SELECT file_hash
                INTO _existingHash
                FROM t_dataset_files
                WHERE dataset_id = _datasetID AND
                      file_path = _filePath;

                If FOUND And char_length(Coalesce(_existingHash, '')) > 0 Then
                    INSERT INTO Tmp_Warnings (Warning, RowText)
                    VALUES (format('Skipping row since file hash is already defined for %s, Dataset ID %s', _filePath, _datasetId),
                            _row);

                    CONTINUE;
                End If;
            End If;

            INSERT INTO Tmp_HashUpdates (Dataset_ID, InstFilePath, InstFileHash)
            VALUES (_datasetID, _filePath, _fileHash);
        End If; -- </g>

    END LOOP;

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        If Exists (Select * From Tmp_HashUpdates) Then

            -- ToDo: Update this to use RAISE INFO

            SELECT *
            FROM Tmp_HashUpdates;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _itemsToUpdate := _itemsToUpdate + _updateCount;
        End If;

        If Exists (Select * From Tmp_SizeUpdates) Then

            -- ToDo: Update this to use RAISE INFO

            SELECT *
            FROM Tmp_SizeUpdates;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _itemsToUpdate := _itemsToUpdate + _updateCount;
        End If;

        If _itemsToUpdate = 0 Then
            RAISE WARNING 'No valid data was found in _datasetFileInfo';
        End If;


        DROP TABLE Tmp_FileData;
        DROP TABLE Tmp_DataColumns;
        DROP TABLE Tmp_HashUpdates;
        DROP TABLE Tmp_SizeUpdates;
        DROP TABLE Tmp_Warnings;
        DROP TABLE Tmp_UpdatedDatasets;
        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update hash info in t_dataset_files using a Merge statement
    -----------------------------------------------
    --
    MERGE INTO t_dataset_files AS target
    USING ( SELECT dataset_id, InstFilePath, InstFileHash
            FROM Tmp_HashUpdates
          ) AS Source
    ON (target.dataset_id = Source.dataset_id And Target.file_path = Source.InstFilePath)
    WHEN MATCHED THEN
        UPDATE SET
            file_hash = Source.InstFileHash,
            deleted = 0
    WHEN NOT MATCHED THEN
        INSERT (dataset_id, file_path, file_hash)
        VALUES (Source.dataset_id, Source.InstFilePath, Source.InstFileHash);

    -----------------------------------------------
    -- Add/Update file size info in t_dataset_files using a Merge statement
    -----------------------------------------------
    --
    MERGE INTO t_dataset_files As target
    USING ( SELECT dataset_id, InstFilePath, InstFileSize
            FROM Tmp_SizeUpdates
          ) AS Source
    ON (target.dataset_id = Source.dataset_id And Target.file_path = Source.InstFilePath)
    WHEN MATCHED THEN
        UPDATE SET
            file_size_bytes = Source.InstFileSize,
            deleted = 0
    WHEN NOT MATCHED THEN
        INSERT (dataset_id, file_path, file_size_bytes)
        VALUES (Source.dataset_id, Source.InstFilePath, Source.InstFileSize);

    INSERT INTO Tmp_UpdatedDatasets (Dataset_ID)
    SELECT Dataset_ID FROM Tmp_HashUpdates
    UNION
    SELECT Dataset_ID FROM Tmp_SizeUpdates;

    -----------------------------------------------
    -- Update the File_Size_Rank column for the datasets
    -----------------------------------------------
    --
    UPDATE t_dataset_files Target
    SET file_size_rank = SrcQ.Size_Rank
    FROM ( SELECT dataset_id,
                  file_path,
                  file_size_bytes,
                  file_hash,
                  dataset_file_id,
                  Row_Number() OVER (
                     PARTITION BY dataset_id
                     ORDER BY deleted ASC, file_size_bytes DESC
                     ) AS Size_Rank
           FROM t_dataset_files
           WHERE Dataset_ID In (SELECT Dataset_ID FROM Tmp_UpdatedDatasets)
         ) SrcQ
    WHERE Target.Dataset_File_ID = SrcQ.Dataset_File_ID;

    _message := 'Dataset info update successful';

    -----------------------------------------------
    -- Show the updated files
    -----------------------------------------------
    If Exists (SELECT Dataset_ID FROM Tmp_UpdatedDatasets) Then

        -- ToDo: Show this using RAISE INFO

        SELECT *
        FROM V_Dataset_Files_List_Report
        WHERE Dataset_ID In (SELECT Dataset_ID FROM Tmp_UpdatedDatasets)
        Order By Dataset
    End If;

    If Exists (Select * From Tmp_Warnings) Then

        -- ToDo: Show this using RAISE INFO
        Select Warning, RowText
        From Tmp_Warnings
        Order By EntryID
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetId);
    Else
        _usageMessage := 'Dataset: ' || _datasetName;
    End If;

    If Not _infoOnly Then
        CALL post_usage_log_entry ('Store_Dataset_File_Info', _usageMessage;);
    End If;

    If char_length(_message) > 0 Then
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

COMMENT ON PROCEDURE public.store_dataset_file_info IS 'StoreDatasetFileInfo';

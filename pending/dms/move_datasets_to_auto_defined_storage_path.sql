--
CREATE OR REPLACE PROCEDURE public.move_datasets_to_auto_defined_storage_path
(
    _datasetIDList text,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the storage and archive locations for one or more datasets to use the
**      auto-defined storage and archive paths instead of the current storage path
**
**      Only valid for Instruments that have Auto_Define_Storage_Path enabled in T_Instrument_Name
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/12/2011 mem - Initial version
**          05/14/2011 mem - Updated the content of MoveCmd
**          06/18/2014 mem - Now passing default to Parse_Delimited_Integer_List
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/19/2016 mem - Call Update_Cached_Dataset_Folder_Paths
**          09/02/2016 mem - Replace archive\dmsarch with simply dmsarch due to switch from \\aurora.emsl.pnl.gov\archive\dmsarch\ to \\adms.emsl.pnl.gov\dmsarch\
**          05/28/2023 mem - Remove unnecessary call to Replace()
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidDatasetIDs text;
    _instrument text;
    _datasetInfo record;
    _storagePathIDNew int;
    _archivePathID int;
    _archivePathIDNew int;
    _oldAndNewPaths text;
    _callingProcName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        -----------------------------------------
        -- Validate the inputs
        -----------------------------------------

        _datasetIDList := Trim(Coalesce(_datasetIDList, ''));
        _infoOnly      := Coalesce(_infoOnly, true);

        -----------------------------------------
        -- Parse the values in _datasetIDList
        -----------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
            DatasetID int not null,
            InstrumentID int null
        );

        CREATE INDEX IX_Tmp_Datasets ON Tmp_Datasets (DatasetID);

        INSERT INTO Tmp_Datasets (DatasetID)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_datasetIDList)

        If Not FOUND Then
            _message := 'No values found in _datasetIDList; unable to continue';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        SELECT string_agg(DatasetID, ', ' ORDER BY DatasetID)
        INTO _invalidDatasetIDs
        FROM Tmp_Datasets
        WHERE NOT EXISTS (SELECT DS.dataset_id FROM t_dataset DS WHERE Tmp_Datasets.DatasetID = DS.dataset_id);

        If _invalidDatasetIDs <> ''
            _message := format('Invalid dataset ID(s); aborting: %s', _invalidDatasetIDs);

            RAISE WARNING '%', _message;

            _returnCode := 'U5202';

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        -----------------------------------------
        -- Determine the instrument IDs
        -----------------------------------------

        UPDATE Tmp_Datasets
        SET InstrumentID = t_dataset.instrument_id
        FROM t_dataset
        WHERE Tmp_Datasets.DatasetID = t_dataset.dataset_id;

        If Not FOUND Then
            _message := 'No rows in Tmp_Datasets matched t_dataset; unable to continue';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        -----------------------------------------
        -- Remove any instruments that don't have Auto_Define_Storage_Path defined
        -----------------------------------------

        If Exists (SELECT *
                   FROM Tmp_Datasets DS INNER JOIN t_instrument_name Inst ON Inst.instrument_id = DS.InstrumentID
                   WHERE Inst.Auto_Define_Storage_Path = 0) Then

            FOR _instrument IN
                SELECT DISTINCT Inst.instrument
                FROM Tmp_Datasets DS
                     INNER JOIN t_instrument_name Inst
                       ON Inst.instrument_id = DS.InstrumentID
                WHERE Inst.auto_define_storage_path = 0
            LOOP
                RAISE WARNING 'Skipping % since it has auto_define_storage_path = 0 in t_instrument_name', _instrument;
            END LOOP;

            DELETE FROM Tmp_Datasets
            WHERE DS.InstrumentID IN (SELECT Inst.instrument_id FROM t_instrument_name Inst WHERE Inst.auto_define_storage_path = 0);

        End If;

        -----------------------------------------
        -- Parse each dataset in _datasetIDList
        -----------------------------------------

        FOR _datasetInfo IN
            SELECT Tmp_Datasets.DatasetID As DatasetID
                   Tmp_Datasets.InstrumentID As InstrumentID,
                   DS.dataset As Dataset,
                   DS.created As RefDate,
                   DS.storage_path_ID As StoragePathID
            FROM Tmp_Datasets
                 INNER JOIN t_dataset DS
                   ON Tmp_Datasets.DatasetID = DS.dataset_id
            ORDER BY Tmp_Datasets.DatasetID
        LOOP

            RAISE INFO 'Processing %', _datasetInfo.Dataset;

            -----------------------------------------
            -- Lookup the auto-defined storage path
            -----------------------------------------

            _storagePathIDNew := get_instrument_storage_path_for_new_datasets (
                                    _datasetInfo.InstrumentID,
                                    _datasetInfo.RefDate,
                                    _autoSwitchActiveStorage => false,
                                    _infoOnly => false);

            If _storagePathIDNew <> 0 And _datasetInfo.StoragePathID <> _storagePathIDNew Then

                SELECT format('%s %s', OldStorage.Path, NewStorage.Path)
                INTO _oldAndNewPaths
                FROM ( SELECT format('\\%s\%s$\%s%s', machine_name, SUBSTRING(vol_name_server, 1, 1), storage_path, _datasetInfo.Dataset) AS Path
                       FROM t_storage_path
                       WHERE storage_path_id = _datasetInfo.StoragePathID
                     ) OldStorage
                     CROSS JOIN
                     ( SELECT format('\\%s\%s$\%s%s', machine_name, SUBSTRING(vol_name_server, 1, 1), storage_path, _datasetInfo.Dataset) AS Path
                       FROM t_storage_path
                       WHERE storage_path_id = _storagePathIDNew
                     ) NewStorage;

                If Not _infoOnly Then

                    UPDATE t_dataset
                    SET storage_path_ID = _storagePathIDNew
                    WHERE dataset_id = _datasetInfo.DatasetID;

                    INSERT INTO t_dataset_storage_move_log (dataset_id, storage_path_old, storage_path_new, MoveCmd)
                    VALUES (_datasetInfo.DatasetID, _datasetInfo.StoragePathID, _storagePathIDNew, _oldAndNewPaths);

                Else
                    RAISE INFO '%', _oldAndNewPaths;
                End If;

            End If;

            -----------------------------------------
            -- Look for this dataset in t_dataset_archive
            -----------------------------------------

            SELECT storage_path_id
            INTO _archivePathID
            FROM t_dataset_archive
            WHERE dataset_id = _datasetInfo.DatasetID;

            If Not FOUND Then
                CONTINUE;
            End If;

            -----------------------------------------
            -- Lookup the auto-defined archive path
            -----------------------------------------

            _archivePathIDNew := public.get_instrument_archive_path_for_new_datasets (
                                            _datasetInfo.InstrumentID,
                                            _datasetInfo.DatasetID,
                                            _autoSwitchActiveArchive => false,
                                            _infoOnly => false);

            If _archivePathIDNew = 0 Or _archivePathID = _archivePathIDNew Then
                CONTINUE;
            End If;

            SELECT format('%s %s', OldArchive.Path, NewArchive.Path)
            INTO _oldAndNewPaths
            FROM ( SELECT format('%s\%s', network_share_path, _datasetInfo.Dataset) AS Path
                   FROM t_archive_path
                   WHERE archive_path_id = _archivePathID
                 ) OldArchive
                 CROSS JOIN
                 ( SELECT format('%s\%s', network_share_path, _datasetInfo.Dataset) AS Path
                   FROM t_archive_path
                   WHERE archive_path_id = _archivePathIDNew
                 ) NewArchive;

            If Not _infoOnly Then

                UPDATE t_dataset_archive
                SET storage_path_id = _archivePathIDNew
                WHERE dataset_id = _datasetInfo.DatasetID

                INSERT INTO t_dataset_storage_move_log (dataset_id, archive_path_old, archive_path_new, MoveCmd)
                VALUES (_datasetInfo.DatasetID, _archivePathID, _archivePathIDNew, _oldAndNewPaths);

            Else
                RAISE INFO '%', _oldAndNewPaths;
            End If;

        END LOOP;

        If Not _infoOnly Then
            UPDATE t_cached_dataset_folder_paths Target
            SET update_required = 1
            FROM Tmp_Datasets Src
            WHERE Target.Dataset_ID = Src.DatasetID;

            CALL public.update_cached_dataset_folder_paths (
                            _processingMode => 0,
                            _showdebug      => false,
                            _message        => _message,       -- Output
                            _returnCode     => _returnCode);   -- Output

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RAISE WARNING '%', _message;
    END;

    -----------------------------------------
    -- Exit
    -----------------------------------------

    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;

COMMENT ON PROCEDURE public.move_datasets_to_auto_defined_storage_path IS 'MoveDatasetsToAutoDefinedStoragePath';

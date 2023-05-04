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
**      Only valid for Instruments that have Auto_Define_Storage_Path
**      enabled in T_Instrument_Name
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/12/2011 mem - Initial version
**          05/14/2011 mem - Updated the content of MoveCmd
**          06/18/2014 mem - Now passing default to udfParseDelimitedIntegerList
**          02/23/2016 mem - Add set XACT_ABORT on
**          08/19/2016 mem - Call UpdateCachedDatasetFolderPaths
**          09/02/2016 mem - Replace archive\dmsarch with simply dmsarch due to switch from \\aurora.emsl.pnl.gov\archive\dmsarch\ to \\adms.emsl.pnl.gov\dmsarch\
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _instrument text;
    _datasetInfo record;
    _storagePathIDNew int;
    _archivePathID int;
    _archivePathIDNew int;
    _moveCmd text;
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
        --
        _datasetIDList := Coalesce(_datasetIDList, '');
        _infoOnly := Coalesce(_infoOnly, true);

        -----------------------------------------
        -- Parse the values in _datasetIDList
        -----------------------------------------
        --

        CREATE TEMP TABLE Tmp_Datasets (
            DatasetID int not null,
            InstrumentID int null
        );

        CREATE INDEX IX_Tmp_Datasets ON Tmp_Datasets (DatasetID);

        INSERT INTO Tmp_Datasets (DatasetID)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_datasetIDList, default)

        If Not FOUND Then
            _message := 'No values found in _datasetIDList; unable to continue';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        DELETE FROM Tmp_Datasets
        WHERE NOT EXISTS (SELECT DS.dataset_id FROM t_dataset DS WHERE Tmp_Datasets.DatasetID = DS.dataset_id);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _message := 'Removed ' || _myRowCount::text || ' entries from _datasetIDList since not present in t_dataset';
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
            _message := 'Tmp_Datasets is now empty; unable to continue';
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
                WHERE Inst.auto_define_storage_path = 0;
            LOOP
                RAISE WARNING 'Skipping % since it has auto_define_storage_path = 0 in t_instrument_name', _instrument;
            END LOOP;

            DELETE FROM Tmp_Datasets
            WHERE DS.InstrumentID IN (SELECT Inst.instrument_id FROM t_instrument_name Inst WHERE Inst.auto_define_storage_path = 0);

        End If;

        -----------------------------------------
        -- Parse each dataset in _datasetIDList
        -----------------------------------------
        --

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

            RAISE INFO '%', 'Processing ' || _datasetInfo.Dataset;

            -----------------------------------------
            -- Lookup the auto-defined storage path
            -----------------------------------------
            --
            _storagePathIDNew := get_instrument_storage_path_for_new_datasets (
                                    _datasetInfo.InstrumentID,
                                    _datasetInfo.RefDate,
                                    _autoSwitchActiveStorage => false,
                                    _infoOnly => false);

            If _storagePathIDNew <> 0 And _datasetInfo.StoragePathID <> _storagePathIDNew Then
            -- <c1>

                SELECT OldStorage.Path || ' ' || NewStorage.Path
                INTO _moveCmd
                FROM ( SELECT '\\' || machine_name || '\' || SUBSTRING(vol_name_server, 1, 1) || '$\' || storage_path || _datasetInfo.Dataset AS Path
                       FROM t_storage_path
                       WHERE (storage_path_id = _datasetInfo.StoragePathID)
                     ) OldStorage
                     CROSS JOIN
                     ( SELECT '\\' || machine_name || '\' || SUBSTRING(vol_name_server, 1, 1) || '$\' || storage_path || _datasetInfo.Dataset AS Path
                       FROM t_storage_path
                       WHERE (storage_path_id = _storagePathIDNew)
                     ) NewStorage
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If Not _infoOnly Then
                -- <d1>

                    UPDATE t_dataset
                    SET storage_path_ID = _storagePathIDNew
                    WHERE dataset_id = _datasetInfo.DatasetID;

                    INSERT INTO t_dataset_storage_move_log (dataset_id, storage_path_old, storage_path_new, MoveCmd)
                    VALUES (_datasetInfo.DatasetID, _datasetInfo.StoragePathID, _storagePathIDNew, _moveCmd);

                Else
                    RAISE INFO '%', _moveCmd;
                End If;

            End If; -- </c1>

            -----------------------------------------
            -- Look for this dataset in t_dataset_archive
            -----------------------------------------
            _archivePathID := -1;

            SELECT storage_path_id
            INTO _archivePathID
            FROM t_dataset_archive
            WHERE (dataset_id = _datasetInfo.DatasetID)

            If _archivePathID >= 0 Then
            -- <c2>
                -----------------------------------------
                -- Lookup the auto-defined archive path
                -----------------------------------------
                --

                _archivePathIDNew := get_instrument_archive_path_for_new_datasets (
                                            _datasetInfo.InstrumentID, _datasetInfo.DatasetID, _autoSwitchActiveArchive => false, _infoOnly => false);

                If _archivePathIDNew <> 0 And _archivePathID <> _archivePathIDNew Then
                -- <d2>

                    SELECT OldArchive.Path || ' ' || NewArchive.Path
                    INTO _moveCmd
                    FROM ( SELECT REPLACE(network_share_path || '\' || _datasetInfo.Dataset, '\dmsarch\', '\dmsarch\') AS Path
                           FROM t_archive_path
                           WHERE (archive_path_id = _archivePathID)
                         ) OldArchive
                         CROSS JOIN
                         ( SELECT REPLACE(network_share_path || '\' || _datasetInfo.Dataset, '\dmsarch\', '\dmsarch\') AS Path
                           FROM t_archive_path
                           WHERE (archive_path_id = _archivePathIDNew)
                         ) NewArchive;

                    If Not _infoOnly Then

                        UPDATE t_dataset_archive
                        SET storage_path_id = _archivePathIDNew
                        WHERE dataset_id = _datasetInfo.DatasetID

                        INSERT INTO t_dataset_storage_move_log (dataset_id, archive_path_old, archive_path_new, MoveCmd)
                        VALUES (_datasetInfo.DatasetID, _archivePathID, _archivePathIDNew, _moveCmd);

                    Else
                        RAISE INFO '%', _moveCmd;
                    End If;

                End If; -- </d2>

            End If; -- </c2>

        END LOOP; -- </a>

        If Not _infoOnly Then
            Update t_cached_dataset_folder_paths
            Set update_required = 1
            FROM t_cached_dataset_folder_paths Target Inner Join Tmp_Datasets Src

            /********************************************************************************
            ** This Update query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE t_cached_dataset_folder_paths
            **   SET ...
            **   FROM source
            **   WHERE source.id = t_cached_dataset_folder_paths.id;
            ********************************************************************************/

                                   ToDo: Fix this query

            On Target.Dataset_ID = Src.DatasetID

            Call update_cached_dataset_folder_paths _processingMode => 0

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
    --

    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;

COMMENT ON PROCEDURE public.move_datasets_to_auto_defined_storage_path IS 'MoveDatasetsToAutoDefinedStoragePath';
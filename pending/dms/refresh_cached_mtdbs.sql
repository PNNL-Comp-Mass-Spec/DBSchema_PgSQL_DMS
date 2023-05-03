--
CREATE OR REPLACE PROCEDURE public.refresh_cached_mtdbs
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_MTS_MT_DBs_Cached using MTS
**
**  Auth:   mem
**  Date:   02/05/2010 mem - Initial Version
**          10/15/2012 mem - Now updating Peptide_DB and Peptide_DB_Count
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _mergeDeleteCount int;
    _fullRefreshPerformed boolean;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    _mergeInsertCount := 0;
    _mergeUpdateCount := 0;
    _mergeDeleteCount := 0;

    Begin
        -- Validate the inputs
        _fullRefreshPerformed := true;

        _currentLocation := 'Update t_mts_cached_data_status';
        --
        Call update_mts_cached_data_status (
                    't_mts_mt_dbs_cached',
                    _incrementRefreshCount => false,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => 0);

        _currentLocation := 'Update t_mts_mt_dbs_cached by merging data from S_MTS_MT_DB';

        SELECT COUNT(*)
        INTO _countBeforeMerge
        FROM t_mts_mt_dbs_cached;

        MERGE INTO t_mts_mt_dbs_cached AS target
        USING ( SELECT server_name, mt_db_id, mt_db_name,
                       state_id, state, description,
                       organism, campaign,
                       peptide_db, peptide_db_count,
                       last_affected
                FROM S_MTS_MT_DBs AS MTSDBInfo
              ) AS Source
        ON (target.mt_db_id = source.mt_db_id)
        WHEN MATCHED AND
             (target.server_name <> source.server_name OR
              target.mt_db_name <> source.mt_db_name OR
              target.state_id <> source.state_id OR
              target.state <> source.state OR
              Coalesce(target.description,'') <> Coalesce(source.description,'') OR
              Coalesce(target.organism,'') <> Coalesce(source.organism,'') OR
              Coalesce(target.campaign,'') <> Coalesce(source.campaign,'') OR
              Coalesce(target.peptide_db,'') <> Coalesce(source.peptide_db,'') OR
              Coalesce(target.peptide_db_count, 0) <> Coalesce(source.peptide_db_count, 0) OR
              Coalesce(target.last_affected ,'')<> Coalesce(source.last_affected,'')) THEN
            UPDATE SET
                server_name = source.server_name,
                mt_db_name = source.mt_db_name,
                state_id = source.state_id,
                state = source.state,
                description = source.description,
                organism = source.organism,
                campaign = source.campaign,
                peptide_db = source.peptide_db,
                peptide_db_count = source.peptide_db_count,
                last_affected = source.last_affected
        WHEN NOT MATCHED THEN
            INSERT (server_name, mt_db_id, mt_db_name,
                    state_id, state, description,
                    organism, campaign,
                    peptide_db, peptide_db_count,
                    last_affected)
            VALUES (source.server_name, source.mt_db_id, source.mt_db_name,
                    source.state_id, source.state, source.description,
                    source.organism, source.campaign,
                    source.peptide_db, source.peptide_db_count,
                    source.last_affected);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(*)
        INTO _countAfterMerge
        FROM t_mts_mt_dbs_cached;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- Delete rows in t_mts_mt_dbs_cached that are not in S_MTS_MT_DBs
        --
        DELETE FROM t_mts_mt_dbs_cached target
        WHERE NOT EXISTS (SELECT source.mt_db_id
                          FROM S_MTS_MT_DBs AS source
                          WHERE target.mt_db_id = source.mt_db_id );

        GET DIAGNOSTICS _mergeDeleteCount = ROW_COUNT;

        _currentLocation := 'Update stats in t_mts_cached_data_status';

        Call update_mts_cached_data_status (
                    't_mts_mt_dbs_cached',
                    _incrementRefreshCount => true,
                    _insertCountNew => _mergeInsertCount,
                    _updateCountNew => _mergeUpdateCount,
                    _deleteCountNew => _mergeDeleteCount,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => 0);

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.refresh_cached_mtdbs IS 'RefreshCachedMTDBs';

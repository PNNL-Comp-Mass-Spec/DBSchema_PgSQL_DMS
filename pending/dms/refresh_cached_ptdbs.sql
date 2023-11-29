--
CREATE OR REPLACE PROCEDURE public.refresh_cached_ptdbs
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the data in t_mts_pt_dbs_cached using MTS
**
**  Arguments:
**    _message      Output message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   02/05/2010 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
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
    _returnCode := '';

    _mergeInsertCount := 0;
    _mergeUpdateCount := 0;
    _mergeDeleteCount := 0;

    BEGIN
        _currentLocation := 'Validate the inputs';

        -- Validate the inputs
        _fullRefreshPerformed := true;

        _currentLocation := 'Update t_mts_cached_data_status';

        CALL public.update_mts_cached_data_status (
                        _cachedDataTableName   => 't_mts_pt_dbs_cached',
                        _incrementRefreshCount => false,
                        _fullRefreshPerformed  => _fullRefreshPerformed,
                        _lastRefreshMinimumID  => 0,
                        _message               => _message,
                        _returnCode            => _returnCode);

        -- Use a MERGE Statement to synchronize t_mts_pt_dbs_cached with S_MTS_PT_DBs

        SELECT COUNT(peptide_db_id)
        INTO _countBeforeMerge
        FROM t_mts_pt_dbs_cached;

        MERGE INTO t_mts_pt_dbs_cached AS target
        USING ( SELECT server_name, peptide_db_id, peptide_db_name,
                       state_id, state, description,
                       organism,
                       last_affected
                FROM S_MTS_PT_DBs AS MTSDBInfo
              ) AS Source
        ON (target.peptide_db_id = source.peptide_db_id)
        WHEN MATCHED AND
             (target.server_name <> source.server_name OR
              target.peptide_db_name <> source.peptide_db_name OR
              target.state_id <> source.state_id OR
              target.state <> source.state OR
              Coalesce(target.description, '') <> Coalesce(source.description, '') OR
              Coalesce(target.organism, '') <> Coalesce(source.organism, '') OR
              Coalesce(target.last_affected, '')<> Coalesce(source.last_affected, '')) THEN
            UPDATE SET
                server_name = source.server_name,
                peptide_db_name = source.peptide_db_name,
                state_id = source.state_id,
                state = source.state,
                description = source.description,
                organism = source.organism,
                last_affected = source.last_affected
        WHEN NOT MATCHED THEN
            INSERT (server_name, peptide_db_id, peptide_db_name,
                    state_id, state, description,
                    organism,
                    last_affected)
            VALUES (source.server_name, source.peptide_db_id, source.peptide_db_name,
                    source.state_id, source.state, source.description,
                    source.organism,
                    source.last_affected);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(peptide_db_id)
        INTO _countAfterMerge
        FROM t_mts_pt_dbs_cached;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- Delete rows in t_mts_pt_dbs_cached that are not in S_MTS_PT_DBs

        DELETE FROM t_mts_pt_dbs_cached target
        WHERE NOT EXISTS (SELECT source.peptide_db_id
                          FROM S_MTS_PT_DBs AS source
                          WHERE target.peptide_db_id = source.peptide_db_id );

        GET DIAGNOSTICS _mergeDeleteCount = ROW_COUNT;

        _currentLocation := 'Update stats in t_mts_cached_data_status';


        CALL public.update_mts_cached_data_status (
                        _cachedDataTableName   => 't_mts_pt_dbs_cached',
                        _incrementRefreshCount => true,
                        _insertCountNew        => _mergeInsertCount,
                        _updateCountNew        => _mergeUpdateCount,
                        _deleteCountNew        => _mergeDeleteCount,
                        _fullRefreshPerformed  => _fullRefreshPerformed,
                        _lastRefreshMinimumID  => 0,
                        _message               => _message,
                        _returnCode            => _returnCode);

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

COMMENT ON PROCEDURE public.refresh_cached_ptdbs IS 'RefreshCachedPTDBs';

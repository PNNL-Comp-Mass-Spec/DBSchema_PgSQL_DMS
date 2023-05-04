--
CREATE OR REPLACE PROCEDURE public.refresh_cached_mts_job_mapping_peptide_dbs
(
    _jobMinimum int = 0,
    _jobMaximum int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_MTS_PT_DB_Jobs_Cached using MTS
**
**  Arguments:
**    _jobMinimum   Set to a positive value to limit the jobs examined; when non-zero, jobs outside the range _jobMinimum to _jobMaximum are ignored
**
**  Auth:   mem
**  Date:   04/21/2010 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _maxInt int;
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

    _maxint := 2147483647;

    _mergeInsertCount := 0;
    _mergeUpdateCount := 0;
    _mergeDeleteCount := 0;

    Begin
        _currentLocation := 'Validate the inputs';

        -- Validate the inputs
        _jobMinimum := Coalesce(_jobMinimum, 0);
        _jobMaximum := Coalesce(_jobMaximum, 0);

        If _jobMinimum <= 0 AND _jobMaximum <= 0 Then
            _fullRefreshPerformed := true;
            _jobMinimum := -_maxInt;
            _jobMaximum := _maxInt;
        Else
            _fullRefreshPerformed := false;
            If _jobMinimum > _jobMaximum Then
                _jobMaximum := _maxInt;
            End If;
        End If;

        _currentLocation := 'Update t_mts_cached_data_status';
        --
        Call update_mts_cached_data_status (
                    't_mts_pt_db_jobs_cached',
                    _incrementRefreshCount => false,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => _jobMinimum);

        -- Use a MERGE Statement to synchronize t_mts_pt_db_jobs_cached with S_MTS_Analysis_Job_to_Peptide_DB_Map

        SELECT COUNT(*)
        INTO _countBeforeMerge
        FROM t_mts_pt_db_jobs_cached;

        MERGE INTO t_mts_pt_db_jobs_cached AS target
        USING ( SELECT server_name, DB_Name AS Peptide_DB_Name, Job,
                       Coalesce(result_type, '') AS result_type, last_affected, process_state
                FROM  S_MTS_Analysis_Job_to_Peptide_DB_Map AS MTSJobInfo
                WHERE job >= _jobMinimum AND
                      job <= _jobMaximum
              ) AS Source
        ON (target.server_name = source.server_name AND
            target.peptide_db_name = source.peptide_db_name AND
            target.job = source.job AND
            target.result_type = source.result_type)
        WHEN MATCHED AND
             (Coalesce(target.last_affected ,'') <> Coalesce(source.last_affected,'') OR
              Coalesce(target.process_state ,'') <> Coalesce(source.process_state,'')) THEN
            UPDATE SET
                last_affected = source.last_affected,
                process_state = source.process_state
        WHEN NOT MATCHED THEN
            INSERT (server_name, peptide_db_name, job,
                    result_type, last_affected, process_state)
            VALUES (source.server_name, source.peptide_db_name, source.job,
                    source.result_type, source.last_affected, source.process_state);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(*)
        INTO _countAfterMerge
        FROM t_mts_pt_db_jobs_cached;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- If _fullRefreshPerformed is true, delete rows in t_mts_pt_db_jobs_cached that are not in S_MTS_Analysis_Job_to_MT_DB_Map

        If _fullRefreshPerformed THEN

            DELETE FROM t_mts_pt_db_jobs_cached target
            WHERE NOT EXISTS (SELECT source.job
                              FROM (SELECT MTSJobInfo.server_name, MTSJobInfo.db_name AS Peptide_DB_Name, MTSJobInfo.Job,
                                           Coalesce(MTSJobInfo.result_type, '') AS result_type
                                    FROM S_MTS_Analysis_Job_to_Peptide_DB_Map AS MTSJobInfo
                                   ) AS Source
                              WHERE target.server_name = source.server_name AND
                                    target.peptide_db_name = source.peptide_db_name AND
                                    target.job = source.job AND
                                    target.result_type = source.result_type);

            GET DIAGNOSTICS _mergeDeleteCount = ROW_COUNT;

        End If;

        _currentLocation := 'Update stats in t_mts_cached_data_status';

        Call update_mts_cached_data_status (
                    't_mts_pt_db_jobs_cached',
                    _incrementRefreshCount => true,
                    _insertCountNew => _mergeInsertCount,
                    _updateCountNew => _mergeUpdateCount,
                    _deleteCountNew => _mergeDeleteCount,
                    _fullRefreshPerformed => _fullRefreshPerformed,
                    _lastRefreshMinimumID => _jobMinimum);
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

COMMENT ON PROCEDURE public.refresh_cached_mts_job_mapping_peptide_dbs IS 'RefreshCachedMTSJobMappingPeptideDBs';
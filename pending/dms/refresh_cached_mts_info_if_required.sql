--
CREATE OR REPLACE PROCEDURE public.refresh_cached_mts_info_if_required
(
    _updateInterval real = 1,
    _dynamicMinimumCountThreshold int = 5000,
    _updateIntervalAllItems real = 24,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Calls the various refresh_cached_mts procedures if the last_refreshed date
**      in t_mts_cached_data_status is over _updateInterval hours before the present
**
**  Arguments:
**    _updateInterval                   Minimum interval in hours to limit update frequency; set to 0 to force an update now
**    _dynamicMinimumCountThreshold     When updating every _updateInterval hours, uses the maximum cached ID value in the given t_mts_%_cached table to determine the minimum ID number to update; for example, for t_mts_analysis_job_info_cached, MinimumJob = MaxJobInTable - _dynamicMinimumCountThreshold; set to 0 to update all items, regardless of ID
**    _updateIntervalAllItems           Interval (in hours) to update all items, regardless of ID
**    _infoOnly                         When true, preview updates
**    _message                          Output message
**    _returnCode                       Return code
**
**  Auth:   mem
**  Date:   02/02/2010 mem - Initial Version
**          04/21/2010 mem - Now calling Refresh_Cached_MTS_Job_Mapping_Peptide_DBs and Refresh_Cached_MTS_Job_Mapping_MTDBs
**          11/21/2012 mem - Now updating job stats in T_MTS_PT_DBs_Cached and T_MTS_MT_DBs_Cached
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentTime timestamp;
    _lastRefreshed timestamp;
    _lastFullRefresh timestamp;
    _cacheTable text;
    _idColumnName text;
    _procedure text;
    _sql text;
    _idMinimum int;
    _maxID int;
    _hoursSinceLastRefresh numeric(9,3);
    _hoursSinceLastFullRefresh numeric(9,3);
    _iteration int;
    _limitToMaxKnownDMSJobs boolean;
    _maxKnownDMSJob int;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _currentTime := CURRENT_TIMESTAMP;

    Begin
        _currentLocation := 'Validate the inputs';
        --
        _updateInterval := Coalesce(_updateInterval, 1);
        _dynamicMinimumCountThreshold := Coalesce(_dynamicMinimumCountThreshold, 10000);
        _updateIntervalAllItems := Coalesce(_updateIntervalAllItems, 24);
        _infoOnly := Coalesce(_infoOnly, false);

        _message := '';

        -- Lookup the largest DMS Job ID (used to filter out bogus job numbers in MTS when performing a partial refresh
        _maxKnownDMSJob := 0;

        SELECT MAX(job)
        INTO _maxKnownDMSJob
        FROM t_analysis_job_id;

        _iteration := 1;
        WHILE _iteration <= 5
        LOOP
            _cacheTable := '';
            _limitToMaxKnownDMSJobs := false;
            _procedure := '';

            If _iteration = 1 Then
                _cacheTable := 't_mts_peak_matching_tasks_cached';
                _idColumnName := 'mts_job_id';
                _procedure := 'Refresh_Cached_MTS_Peak_Matching_Tasks';
            End If;

            If _iteration = 2 Then
                _cacheTable := 't_mts_mt_dbs_cached';
                _idColumnName := '';
                _procedure := 'Refresh_Cached_MTDBs';
            End If;

            If _iteration = 3 Then
                _cacheTable := 't_mts_pt_dbs_cached';
                _idColumnName := '';
                _procedure := 'Refresh_Cached_PTDBs';
            End If;

            If _iteration = 4 Then
                _cacheTable := 't_mts_pt_db_jobs_cached';
                _idColumnName := 'job';
                _procedure := 'Refresh_Cached_MTS_Job_Mapping_Peptide_DBs';
                _limitToMaxKnownDMSJobs := true;
            End If;

            If _iteration = 5 Then
                _cacheTable := 't_mts_mt_db_jobs_cached';
                _idColumnName := 'job';
                _procedure := 'Refresh_Cached_MTS_Job_Mapping_MTDBs';
                _limitToMaxKnownDMSJobs := true;
            End If;

            If char_length(_cacheTable) > 0 Then

                _currentLocation := format('Check refresh time for %s', _cacheTable);

                _lastRefreshed := make_date(2000, 1, 1);
                _lastFullRefresh := make_date(2000, 1, 1);

                SELECT last_refreshed,
                       last_full_refresh
                INTO _lastRefreshed, _lastFullRefresh
                FROM t_mts_cached_data_status
                WHERE table_name = _cacheTable;

                If _infoOnly Then
                    RAISE INFO 'Processing %', _cacheTable;
                End If;

                _hoursSinceLastRefresh := extract(epoch FROM _currentTime - Coalesce(_lastRefreshed, make_date(2000, 1, 1)) / 3600.0;

                If _infoOnly Then
                    RAISE INFO 'Hours since last refresh: % %', _hoursSinceLastRefresh, Case When _hoursSinceLastRefresh >= _updateInterval Then '-> Partial refresh required' Else '' End;
                End If;

                _hoursSinceLastFullRefresh := extract(epoch FROM _currentTime - Coalesce(_lastFullRefresh, make_date(2000, 1, 1)) / 3600.0

                If _infoOnly Then
                    RAISE INFO 'Hours since last full refresh: % %', _hoursSinceLastFullRefresh, Case When _hoursSinceLastFullRefresh >= _updateIntervalAllItems Then '-> Full refresh required' Else '' End;
                End If;

                If _hoursSinceLastRefresh >= _updateInterval Or _hoursSinceLastFullRefresh >= _updateIntervalAllItems Then

                    _idMinimum := 0;

                    If _idColumnName <> '' And _hoursSinceLastFullRefresh < _updateIntervalAllItems Then
                        -- Less than _updateIntervalAllItems hours has elapsed since the last full update
                        -- Bump up _idMinimum to _dynamicMinimumCountThreshold less than the max ID in the target table

                        _sql := format('SELECT MAX(%I) FROM %I', _idColumnName _cacheTable);

                        If _limitToMaxKnownDMSJobs Then
                             _sql := format('%s WHERE %I <= $1', _sql, _idColumnName);
                        End If;

                        EXECUTE _sql
                        INTO _maxID
                        USING _maxKnownDMSJob;

                        If Coalesce(_maxID, 0) > 0 Then
                            _idMinimum := _maxID - _dynamicMinimumCountThreshold;
                            If _idMinimum < 0 Then
                                _idMinimum := 0;
                            End If;

                            If _infoOnly Then
                                RAISE INFO 'Max % in % is %; will set minimum to %', _idColumnName, _cacheTable, _maxID, _idMinimum;
                            End If;
                        End If;
                    End If;

                        _sql := format('CALL %s (%s)',
                                        _procedure,
                                        CASE WHEN _idMinimum > 0 THEN _idMinimum::text ELSE '' END);

                    If _infoOnly Then
                        RAISE INFO 'Need to call % since last refreshed %; %', _procedure, _lastRefreshed, _sql;
                    Else
                        EXECUTE _sql;
                    End If;

                End If;
            End If;

            If _infoOnly Then
                RAISE INFO '';
            End If;

            _iteration := _iteration + 1;
        END LOOP;

        If Not _infoOnly Then
            -- Update the Job stats in t_mts_pt_dbs_cached

            UPDATE t_mts_pt_dbs_cached
            SET msms_jobs = StatsQ.msms_jobs,
                sic_jobs = StatsQ.sic_jobs
            FROM  ( SELECT PTDBs.Peptide_DB_Name,
                                     PTDBs.Server_Name,
                                     SUM(CASE WHEN Coalesce(DBJobs.ResultType, '') LIKE '%Peptide_Hit' THEN 1
                                              ELSE 0
                                         End If;) AS MSMS_Jobs,
                                     SUM(CASE
                                             WHEN Coalesce(DBJobs.ResultType, '') = 'SIC' THEN 1
                                             ELSE 0
                                         END) AS SIC_Jobs
                              FROM t_mts_pt_dbs_cached PTDBs
                                   LEFT OUTER JOIN t_mts_pt_db_jobs_cached DBJobs
                                     ON PTDBs.peptide_db_name = DBJobs.peptide_db_name AND
                                        PTDBs.server_name = DBJobs.server_name
                              GROUP BY PTDBs.peptide_db_name, PTDBs.server_name
                            ) StatsQ
            WHERE t_mts_pt_dbs_cached.peptide_db_name = StatsQ.peptide_db_name AND
                  t_mts_pt_dbs_cached.server_name = StatsQ.server_name AND
                  (Coalesce(Target.MSMS_Jobs, -1) <> StatsQ.MSMS_Jobs OR
                   Coalesce(Target.SIC_Jobs, -1)  <> StatsQ.SIC_Jobs);

            -- Update the Job stats in t_mts_mt_dbs_cached

            UPDATE t_mts_mt_dbs_cached
            SET msms_jobs = StatsQ.msms_jobs,
                ms_jobs = StatsQ.ms_jobs
            FROM ( SELECT MTDBs.MT_DB_Name,
                          MTDBs.Server_Name,
                          SUM(CASE
                                  WHEN Coalesce(DBJobs.ResultType, '') LIKE '%Peptide_Hit' THEN 1
                                  ELSE 0
                              END) AS MSMS_Jobs,
                          SUM(CASE
                                  WHEN Coalesce(DBJobs.ResultType, '') = 'HMMA_Peak' THEN 1
                                  ELSE 0
                              END) AS MS_Jobs
                   FROM t_mts_mt_dbs_cached MTDBs
                        LEFT OUTER JOIN t_mts_mt_db_jobs_cached DBJobs
                          ON MTDBs.mt_db_name = DBJobs.mt_db_name
                             AND
                             MTDBs.server_name = DBJobs.server_name
                   GROUP BY MTDBs.mt_db_name, MTDBs.server_name
                 ) StatsQ
            WHERE Target.mt_db_name = StatsQ.mt_db_name AND
                  Target.server_name = StatsQ.server_name AND
                  (Coalesce(Target.MSMS_Jobs, -1) <> StatsQ.MSMS_Jobs OR
                   Coalesce(Target.MS_Jobs, -1)   <> StatsQ.MS_Jobs);

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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.refresh_cached_mts_info_if_required IS 'RefreshCachedMTSInfoIfRequired';

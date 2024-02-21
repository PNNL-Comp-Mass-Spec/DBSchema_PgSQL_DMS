--
-- Name: update_cached_requested_run_batch_stats(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_requested_run_batch_stats(IN _batchid integer DEFAULT 0, IN _fullrefresh boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update data in t_cached_requested_run_batch_stats
**
**      This table is used by view v_requested_run_batch_list_report
**      to display information about the requested runs and datasets associated with a requested run batch
**
**  Arguments:
**    _batchID      Specific requested run batch to update, or 0 to update all active requested run batches
**    _fullRefresh  When false, only update batches where T_Requested_Run.Updated is later than T_Cached_Requested_Run_Batch_Stats.last_affected; when true, update all
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   02/10/2023 mem - Initial Version
**          02/24/2023 mem - Add argument _fullRefresh
**                         - When _fullRefresh is 0, use "last updated" times to limit the batch IDs to update
**                         - Fix long-running merge queries by using temp tables to store stats
**                         - Post a log entry if the runtime exceeds 30 seconds
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          07/11/2023 mem - Use COUNT(RR.request_id) and COUNT(RR.dataset_id) instead of COUNT(*)
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          01/02/2024 mem - Fix column name bug when joining v_requested_run_queue_times to t_requested_run
**          01/19/2024 mem - Fix bug that failed to populate column separation_group_last when adding a new batch to t_cached_requested_run_batch_stats
**                           Populate columns instrument_group_first and instrument_group_last
**
*****************************************************/
DECLARE
    _callingProcName text;

    -- These runtimes are in milliseconds
    _runtimeStep1 int;
    _runtimeStep2 int;
    _runtimeStep3 int;

    -- Overall runtime, in seconds
    _runtimeSeconds numeric;
    _runtimeMessage text;

    _startTime timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _batchID := Coalesce(_batchID, 0);
    _fullRefresh := Coalesce(_fullRefresh, false);

    BEGIN
        _startTime := clock_timestamp();

        If _batchID = 0 Then
            -- Updating all requested run batches

            -- Delete rows in T_Cached_Requested_Run_Batch_Stats that are not in T_Requested_Run_Batches
            DELETE FROM t_cached_requested_run_batch_stats target
            WHERE NOT EXISTS (SELECT RRB.batch_id FROM T_Requested_Run_Batches RRB WHERE target.batch_id = RRB.batch_id);

            -- Add new batches to T_Cached_Requested_Run_Batch_Stats
            INSERT INTO t_cached_requested_run_batch_stats (batch_id, last_affected)
            SELECT RRB.batch_id, make_date(1970, 1, 1)
            FROM t_requested_run_batches RRB
                 LEFT OUTER JOIN t_cached_requested_run_batch_stats RBS
                   ON RBS.batch_id = RRB.batch_id
            WHERE RRB.batch_id > 0 AND
                  RBS.batch_id IS NULL;
        Else
            -- Assure that the batch exists in the cache table
            INSERT INTO t_cached_requested_run_batch_stats (batch_id, last_affected)
            SELECT RRB.batch_id, make_date(1970, 1, 1)
            FROM t_requested_run_batches RRB
                 LEFT OUTER JOIN t_cached_requested_run_batch_stats RBS
                   ON RBS.batch_id = RRB.batch_id
            WHERE RRB.batch_id = _batchID AND RBS.batch_id IS NULL;
        End If;

        ------------------------------------------------
        -- Find batch IDs to update
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_BatchIDs (
            batch_id int not Null
        );

        CREATE UNIQUE INDEX IX_Tmp_BatchIDs On Tmp_BatchIDs (batch_id);

        If _batchID > 0 Then
            INSERT INTO Tmp_BatchIDs (batch_id)
            SELECT batch_id
            FROM T_Cached_Requested_Run_Batch_Stats
            WHERE batch_id = _batchID;
        Else
            If _fullRefresh Then
                INSERT INTO Tmp_BatchIDs (batch_id)
                SELECT batch_id
                FROM T_Cached_Requested_Run_Batch_Stats
                WHERE batch_id > 0;
            Else
                INSERT INTO Tmp_BatchIDs (batch_id)
                SELECT DISTINCT RBS.batch_id
                FROM T_Cached_Requested_Run_Batch_Stats RBS
                     INNER JOIN T_Requested_Run RR
                       ON RBS.batch_id = RR.batch_id
                WHERE RBS.batch_id > 0 AND RR.Updated > RBS.Last_Affected;
            End If;
        End If;

        ------------------------------------------------
        -- Step 1: Update cached active requested run stats
        ------------------------------------------------

        BEGIN

            MERGE INTO t_cached_requested_run_batch_stats AS t
            USING (
                    SELECT BatchQ.batch_id,
                           StatsQ.oldest_request_created,
                           StatsQ.instrument_group_first,
                           StatsQ.instrument_group_last,
                           StatsQ.separation_group_first,
                           StatsQ.separation_group_last,
                           ActiveStatsQ.active_requests,
                           ActiveStatsQ.first_active_request,
                           ActiveStatsQ.last_active_request,
                           ActiveStatsQ.oldest_active_request_created,
                           CASE
                               WHEN ActiveStatsQ.active_requests = 0 THEN public.get_requested_run_batch_max_days_in_queue(StatsQ.batch_id)
                               ELSE ROUND(EXTRACT(epoch FROM
                                            (statement_timestamp() - (COALESCE(ActiveStatsQ.oldest_active_request_created, StatsQ.oldest_request_created)))) / (86400)::numeric)
                           END AS days_in_queue
                    FROM ( SELECT batch_id
                           FROM Tmp_BatchIDs
                         ) BatchQ
                         LEFT OUTER JOIN
                         ( SELECT RR.batch_id AS batch_id,
                                  MIN(RR.created) AS oldest_request_created,
                                  MIN(RR.instrument_group) AS instrument_group_first,
                                  MAX(RR.instrument_group) AS instrument_group_last,
                                  MIN(RR.separation_group) AS separation_group_first,
                                  MAX(RR.separation_group) AS separation_group_last
                           FROM t_requested_run RR
                                INNER JOIN Tmp_BatchIDs
                                  ON RR.batch_id = Tmp_BatchIDs.batch_id
                           GROUP BY RR.batch_id
                         ) StatsQ ON BatchQ.batch_id = StatsQ.batch_id
                         LEFT OUTER JOIN
                         ( SELECT RR.batch_id AS batch_id,
                                  COUNT(RR.request_id) AS active_requests,
                                  MIN(RR.request_id)   AS first_active_request,
                                  MAX(RR.request_id)   AS last_active_request,
                                  MIN(RR.created)      AS oldest_active_request_created
                           FROM t_requested_run RR
                                INNER JOIN Tmp_BatchIDs
                                  ON RR.batch_id = Tmp_BatchIDs.batch_id
                           WHERE RR.state_name = 'Active'
                           GROUP BY RR.batch_id
                         ) ActiveStatsQ ON BatchQ.batch_id = ActiveStatsQ.batch_id
                  ) AS s
            ON ( t.batch_id = s.batch_id )
            WHEN MATCHED AND
                 ( t.instrument_group_first        IS DISTINCT FROM s.instrument_group_first OR
                   t.instrument_group_last         IS DISTINCT FROM s.instrument_group_last OR
                   t.separation_group_first        IS DISTINCT FROM s.separation_group_first OR
                   t.separation_group_last         IS DISTINCT FROM s.separation_group_last OR
                   t.active_requests               IS DISTINCT FROM s.active_requests OR
                   t.first_active_request          IS DISTINCT FROM s.first_active_request OR
                   t.last_active_request           IS DISTINCT FROM s.last_active_request OR
                   t.oldest_active_request_created IS DISTINCT FROM s.oldest_active_request_created OR
                   t.oldest_request_created        IS DISTINCT FROM s.oldest_request_created OR
                   t.days_in_queue                 IS DISTINCT FROM s.days_in_queue
                 ) THEN
                UPDATE SET
                    instrument_group_first        = s.instrument_group_first,
                    instrument_group_last         = s.instrument_group_last,
                    separation_group_first        = s.separation_group_first,
                    separation_group_last         = s.separation_group_last,
                    active_requests               = s.active_requests,
                    first_active_request          = s.first_active_request,
                    last_active_request           = s.last_active_request,
                    oldest_active_request_created = s.oldest_active_request_created,
                    oldest_request_created        = s.oldest_request_created,
                    days_in_queue                 = s.days_in_queue,
                    last_affected                 = statement_timestamp()
            WHEN NOT MATCHED THEN
                INSERT ( batch_id,
                         instrument_group_first, instrument_group_last,
                         separation_group_first, separation_group_last,
                         active_requests, first_active_request, last_active_request,
                         oldest_active_request_created, oldest_request_created,
                         days_in_queue, last_affected )
                VALUES ( s.batch_id,
                         s.instrument_group_first, s.instrument_group_last,
                         s.separation_group_first, s.separation_group_last,
                         s.active_requests, s.first_active_request, s.last_active_request,
                         s.oldest_active_request_created, s.oldest_request_created,
                         s.days_in_queue, statement_timestamp() )
            ;

        END;

        _runtimeStep1 := (1000 * extract(epoch FROM (clock_timestamp() - _startTime)))::int;

        ------------------------------------------------
        -- Step 2: Update completed requested run stats
        -- (requested runs that have a Dataset ID value)
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestedRunStats (
            batch_id int NOT NULL,
            datasets int NULL,
            min_days_in_queue int NULL,
            max_days_in_queue int NULL,
            instrument_first varchar(24) NULL,
            instrument_last varchar(24) NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_RequestedRunStats On Tmp_RequestedRunStats (batch_id);

        INSERT INTO Tmp_RequestedRunStats (batch_id, datasets, min_days_in_queue, max_days_in_queue, instrument_first, instrument_last)
        SELECT BatchQ.batch_id,
               StatsQ.datasets,
               StatsQ.min_days_in_queue,
               StatsQ.max_days_in_queue,
               StatsQ.instrument_first,
               StatsQ.instrument_last
        FROM ( SELECT batch_id
               FROM Tmp_BatchIDs
             ) BatchQ
             LEFT OUTER JOIN ( SELECT RR.batch_id AS batch_id,
                                      Count(RR.dataset_id) AS datasets,
                                      MIN(QT.days_in_queue) AS min_days_in_queue,
                                      MAX(QT.days_in_queue) AS max_days_in_queue,
                                      MIN(InstName.instrument) AS instrument_first,
                                      MAX(InstName.instrument) AS instrument_last
                               FROM T_Requested_Run RR
                                    INNER JOIN Tmp_BatchIDs
                                      ON RR.batch_id = Tmp_BatchIDs.batch_id
                                    INNER JOIN v_requested_run_queue_times AS QT
                                      ON QT.requested_run_id = RR.request_id
                                    INNER JOIN T_Dataset DS
                                      ON RR.dataset_id = DS.dataset_id
                                    INNER JOIN t_instrument_name InstName
                                      ON DS.instrument_id = InstName.instrument_id
                               GROUP BY RR.batch_id ) StatsQ
                ON BatchQ.batch_id = StatsQ.batch_id;

        BEGIN

            MERGE INTO t_cached_requested_run_batch_stats AS t
            USING ( SELECT batch_id,
                           datasets,
                           min_days_in_queue,
                           max_days_in_queue,
                           instrument_first,
                           instrument_last
                    FROM Tmp_RequestedRunStats
                  ) AS s
            ON ( t.batch_id = s.batch_id )
            WHEN MATCHED AND
                 ( t.datasets               IS DISTINCT FROM s.datasets OR
                   t.min_days_in_queue      IS DISTINCT FROM s.min_days_in_queue OR
                   t.max_days_in_queue      IS DISTINCT FROM s.max_days_in_queue OR
                   t.instrument_first       IS DISTINCT FROM s.instrument_first OR
                   t.instrument_last        IS DISTINCT FROM s.instrument_last
                 ) THEN
                UPDATE SET
                    datasets          = s.datasets,
                    min_days_in_queue = s.min_days_in_queue,
                    max_days_in_queue = s.max_days_in_queue,
                    instrument_first  = s.instrument_first,
                    instrument_last   = s.instrument_last,
                    last_affected     = statement_timestamp()
            WHEN NOT MATCHED THEN
                INSERT ( batch_id, datasets, min_days_in_queue, max_days_in_queue, instrument_first, instrument_last, last_affected )
                VALUES ( s.batch_id, s.datasets, s.min_days_in_queue, s.max_days_in_queue, s.instrument_first, s.instrument_last, statement_timestamp() )
            ;

        END;

        Drop Table Tmp_RequestedRunStats;

        _runtimeStep2 := (1000 * extract(epoch FROM (clock_timestamp() - _startTime)))::int - _runtimeStep1;

        ------------------------------------------------
        -- Step 3: Update requested run count and sample prep queue stats
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestedRunExperimentStats (
            batch_id int NOT NULL,
            requests int NULL,
            days_in_prep_queue int NULL,
            blocked int NULL,
            block_missing int NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_RequestedRunExperimentStats On Tmp_RequestedRunExperimentStats (batch_id);

        INSERT INTO Tmp_RequestedRunExperimentStats (batch_id, requests, days_in_prep_queue, blocked, block_missing)
        SELECT BatchQ.batch_id,
               StatsQ.requests,
               StatsQ.days_in_prep_queue,
               StatsQ.blocked,
               StatsQ.block_missing
        FROM ( SELECT batch_id
               FROM Tmp_BatchIDs
             ) BatchQ
             LEFT OUTER JOIN ( SELECT RR.batch_id,
                                      COUNT(RR.request_id) AS requests,
                                      MAX(QT.days_in_queue) AS days_in_prep_queue,
                                      SUM(CASE
                                          WHEN ((COALESCE(RR.block, 0) > 0) AND
                                                (COALESCE(RR.run_order, 0) > 0))
                                          THEN 1
                                          ELSE 0
                                          END) AS blocked,
                                      SUM(CASE
                                          WHEN ((LOWER(COALESCE(spr.block_and_randomize_runs, '')) = 'yes') AND
                                               ((COALESCE(RR.block, 0) = 0) OR (COALESCE(RR.run_order, 0) = 0)))
                                          THEN 1
                                          ELSE 0
                                          END) AS block_missing
                               FROM T_Requested_Run RR
                                    INNER JOIN Tmp_BatchIDs
                                      ON RR.batch_id = Tmp_BatchIDs.batch_id
                                    INNER JOIN t_experiments AS E
                                       ON RR.exp_id = E.exp_id
                                    LEFT OUTER JOIN t_sample_prep_request AS SPR
                                       ON E.sample_prep_request_id = SPR.prep_request_id AND
                                          SPR.prep_request_id <> 0
                                    LEFT OUTER JOIN v_sample_prep_request_queue_times AS QT
                                       ON SPR.prep_request_id = QT.request_id
                               GROUP BY RR.batch_id ) StatsQ
               ON BatchQ.batch_id = StatsQ.batch_id;

        BEGIN

            MERGE INTO t_cached_requested_run_batch_stats AS t
            USING ( SELECT batch_id,
                           requests,
                           days_in_prep_queue,
                           blocked,
                           block_missing
                    FROM Tmp_RequestedRunExperimentStats
                  ) AS s
            ON ( t.batch_id = s.batch_id )
            WHEN MATCHED AND
                 ( t.requests           IS DISTINCT FROM s.requests OR
                   t.days_in_prep_queue IS DISTINCT FROM s.days_in_prep_queue OR
                   t.blocked            IS DISTINCT FROM s.blocked OR
                   t.block_missing      IS DISTINCT FROM s.block_missing
                 ) THEN
                UPDATE SET
                    requests           = s.requests,
                    days_in_prep_queue = s.days_in_prep_queue,
                    blocked            = s.blocked,
                    block_missing      = s.block_missing,
                    last_affected      = statement_timestamp()
            WHEN NOT MATCHED THEN
                INSERT ( requests, days_in_prep_queue, blocked, block_missing, last_affected )
                VALUES ( s.requests, s.days_in_prep_queue, s.blocked, s.block_missing, statement_timestamp() )
            ;

        END;

        DROP TABLE Tmp_RequestedRunExperimentStats;

        _runtimeStep3 := (1000 * extract(epoch FROM (clock_timestamp() - _startTime)))::int - _runtimeStep1 - _runtimeStep2;

        -- Overall runtime, in seconds
        _runtimeSeconds := (extract(epoch FROM (clock_timestamp() - _startTime)))::numeric;

        _runtimeMessage := format('Step 1: %s seconds; Step 2: %s seconds; Step 3: %s seconds',
                                    Round(_runtimeStep1 / 1000.0, 2),
                                    Round(_runtimeStep2 / 1000.0, 2),
                                    Round(_runtimeStep3 / 1000.0, 2));

        If _runtimeSeconds > 30 Then
            _message := format('Excessive runtime updating requested run batch stats; %s seconds elapsed overall; %s', _runtimeSeconds, _runtimeMessage);
            CALL post_log_entry ('Error', _message, 'Update_Cached_Requested_Run_Batch_Stats');
        Else
            _message := format('Overall runtime: %s seconds; %s', Round(_runtimeSeconds, 2), Coalesce(_runtimeMessage, '??'));
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
    END;

    DROP TABLE Tmp_BatchIDs;
END
$$;


ALTER PROCEDURE public.update_cached_requested_run_batch_stats(IN _batchid integer, IN _fullrefresh boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_requested_run_batch_stats(IN _batchid integer, IN _fullrefresh boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_requested_run_batch_stats(IN _batchid integer, IN _fullrefresh boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedRequestedRunBatchStats';


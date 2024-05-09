--
-- Name: update_cached_experiment_stats(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_experiment_stats(IN _processingmode integer DEFAULT 0, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_cached_experiment_stats, which is used by the experiment detail report view (v_experiment_detail_report_ex)
**
**  Arguments:
**    _processingMode   Processing mode:
**                      0 to only process new experiments and experiments with update_required = 1
**                      1 to process new experiments, those with update_required = 1, and the 10,000 most recent experiments in DMS
**                      2 to re-process all of the entries in t_cached_experiment_stats (this is the slowest update)
**    _showDebug        When true, show debug info
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   05/05/2024 mem - Initial version
**          05/08/2024 mem - Filter on Experiment ID in the dataset count subquery
**
*****************************************************/
DECLARE
    _matchCount int;
    _updateCount int;
    _rowCountUpdated int := 0;
    _minimumExperimentID int := 0;
    _experimentIdStart int;
    _experimentIdEnd int;
    _experimentIdMax int;
    _experimentBatchSize int;
    _currentBatchExpIdStart int;
    _currentBatchExpIdEnd int;
    _addon text;
    _startTime timestamp;
    _runtimeSeconds numeric;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _processingMode := Coalesce(_processingMode, 0);
    _showDebug      := Coalesce(_showDebug, false);

    _startTime := clock_timestamp();

    If _processingMode IN (0, 1) Then
        SELECT MIN(exp_id)
        INTO _minimumExperimentID
        FROM ( SELECT exp_id
               FROM T_Experiments
               ORDER BY exp_id DESC
               LIMIT 10000) LookupQ;

        If Not FOUND Then
            _minimumExperimentID := 0;
        End If;
    End If;

    If _showDebug Then
        RAISE INFO '';
    End If;

    ------------------------------------------------
    -- Add new experiments to t_cached_experiment_stats
    ------------------------------------------------
    --
    INSERT INTO t_cached_experiment_stats (exp_id, update_required)
    SELECT E.exp_id, 1 AS update_required
    FROM t_experiments E
         LEFT OUTER JOIN t_cached_experiment_stats CES
           ON CES.exp_id = E.exp_id
    WHERE E.exp_id >= _minimumExperimentID AND
          CES.exp_id IS NULL;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _message := format('Added %s new %s', _matchCount, check_plural(_matchCount, 'experiment', 'experiments'));

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
    End If;

    SELECT MAX(exp_id)
    INTO _experimentIdMax
    FROM t_cached_experiment_stats;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If Not FOUND Then
        _experimentIdMax := 2147483647;
    End If;

    If _processingMode >= 2 And _experimentIdMax < 2147483647 Then
        _experimentBatchSize := 50000;
    Else
        _experimentBatchSize := 0;
    End If;

    -- Cache the Experiment IDs to update
    CREATE TEMP TABLE Tmp_Experiment_IDs (
        Exp_ID int NOT NULL PRIMARY KEY
    );

    If _processingMode IN (0, 1) Then
        ------------------------------------------------
        -- Find experiments with update_required > 0
        -- If _processingMode is 1, also process the 10,000 most recent experiments, regardless of the value of update_required
        --
        -- Notes regarding t_dataset
        --   Trigger trig_t_dataset_after_insert     will set update_required to 1 when a dataset is added to t_dataset
        --   Trigger trig_t_dataset_after_update_row will set update_required to 1 when the exp_id column is updated in t_dataset
        --   Trigger trig_t_dataset_after_delete_row will set update_required to 1 when a dataset is deleted from t_dataset
        ------------------------------------------------

        If _processingMode = 0 Then
            INSERT INTO Tmp_Experiment_IDs (Exp_ID)
            SELECT exp_id
            FROM t_cached_experiment_stats
            WHERE update_required > 0;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;
        Else
            INSERT INTO Tmp_Experiment_IDs (Exp_ID)
            SELECT exp_id
            FROM t_cached_experiment_stats
            WHERE update_required > 0
            UNION
            SELECT exp_id
            FROM t_experiments
            WHERE exp_id >= _minimumExperimentID;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;
        End If;

        If _matchCount > 50000 And _experimentBatchSize = 0 Then
            _experimentBatchSize := 50000;
        End If;

        If _showDebug Then
            RAISE INFO 'Updating cached stats for % % in T_Cached_Experiment_Stats where %',
                     _matchCount,
                     public.check_plural(_matchCount, 'row', 'rows'),
                     CASE WHEN _processingMode = 0
                          THEN 'update_required is 1'
                          ELSE format('exp_id >= %s Or update_required is 1', _minimumExperimentID)
                     END;
        End If;
    Else
        ------------------------------------------------
        -- Process all experiments in t_cached_experiment_stats since _processingMode is 2
        ------------------------------------------------

        INSERT INTO Tmp_Experiment_IDs (Exp_ID)
        SELECT exp_id
        FROM t_cached_experiment_stats;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _showDebug Then
            If _experimentBatchSize > 0 Then
                RAISE INFO 'Updating cached stats for all rows in t_cached_experiment_stats, processing % experiments at a time', _experimentBatchSize;
            Else
                RAISE INFO 'Updating cached stats for all rows in t_cached_experiment_stats; note that batch size is 0, which should never be the case';
            End If;
        End If;
    End If;

    If Not Exists (SELECT Exp_ID FROM Tmp_Experiment_IDs) Then
        If _showDebug Then
            RAISE INFO 'Exiting, since nothing to do';
        End If;

        DROP TABLE Tmp_Experiment_IDs;
        RETURN;
    End If;

    _experimentIdStart := 0;

    If _experimentBatchSize > 0 Then
        _experimentIdEnd := _experimentIdStart + _experimentBatchSize - 1;
    Else
        _experimentIdEnd := _experimentIdMax;
    End If;

    WHILE true
    LOOP
        If _experimentBatchSize > 0 Then
            _currentBatchExpIdStart := _experimentIdStart;
            _currentBatchExpIdEnd   := _experimentIdEnd;

            If _showDebug Then
                RAISE INFO 'Updating Experiment IDs % to %', _experimentIdStart, _experimentIdEnd;
            End If;
        Else
            SELECT Min(Exp_ID),
                   Max(Exp_ID)
            INTO _currentBatchExpIdStart, _currentBatchExpIdEnd
            FROM Tmp_Experiment_IDs;

            If _showDebug Then
                RAISE INFO 'Updating Experiment IDs % to %', _currentBatchExpIdStart, _currentBatchExpIdEnd;
            End If;
        End If;

        ------------------------------------------------
        -- Update dataset info for entries in Tmp_Experiment_IDs
        ------------------------------------------------

        UPDATE t_cached_experiment_stats
        SET Dataset_Count       = Coalesce(StatsQ.Dataset_Count, 0),
            Most_Recent_Dataset = StatsQ.Most_Recent_Dataset
        FROM ( SELECT E.Exp_ID,
                      DSCountQ.Dataset_Count,
                      DSCountQ.Most_Recent_Dataset
               FROM Tmp_Experiment_IDs E
                    LEFT OUTER JOIN ( SELECT exp_id,
                                             COUNT(dataset_id) AS Dataset_Count,
                                             MAX(created) AS Most_Recent_Dataset
                                      FROM t_dataset
                                      WHERE exp_id BETWEEN _currentBatchExpIdStart AND _currentBatchExpIdEnd
                                      GROUP BY exp_id ) AS DSCountQ
                      ON DSCountQ.exp_id = E.Exp_ID
               WHERE E.Exp_ID BETWEEN _currentBatchExpIdStart AND _currentBatchExpIdEnd
             ) StatsQ
        WHERE t_cached_experiment_stats.exp_id = StatsQ.Exp_ID AND
              (t_cached_experiment_stats.dataset_count       <> Coalesce(StatsQ.dataset_count, 0) OR
               t_cached_experiment_stats.most_recent_dataset IS DISTINCT FROM StatsQ.most_recent_dataset);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _rowCountUpdated := _rowCountUpdated + _matchCount;

        ------------------------------------------------
        -- Update factor counts for entries in Tmp_Experiment_IDs
        -- A Left Outer Join is not required because view V_Factor_Count_By_Experiment includes all experiments
        ------------------------------------------------

        UPDATE t_cached_experiment_stats
        SET Factor_Count = Coalesce(StatsQ.Factor_Count, 0)
        FROM ( SELECT E.Exp_ID,
                      FC.Factor_Count
               FROM Tmp_Experiment_IDs E
                    INNER JOIN V_Factor_Count_By_Experiment FC
                      ON FC.exp_id = E.Exp_ID
               WHERE E.Exp_ID BETWEEN _currentBatchExpIdStart AND _currentBatchExpIdEnd
             ) StatsQ
        WHERE t_cached_experiment_stats.exp_id = StatsQ.Exp_ID AND
              t_cached_experiment_stats.factor_count <> Coalesce(StatsQ.Factor_Count, 0);
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _rowCountUpdated := _rowCountUpdated + _matchCount;

        If _experimentBatchSize <= 0 Then
            UPDATE T_Cached_Experiment_Stats
            SET update_required = 0
            WHERE update_required > 0 AND
                  exp_id IN (SELECT E.Exp_ID FROM Tmp_Experiment_IDs E);

            -- Break out of the while loop
            EXIT;
        End If;

        UPDATE T_Cached_Experiment_Stats
        SET update_required = 0
        WHERE update_required > 0 AND
              exp_id IN (SELECT E.Exp_ID
                         FROM Tmp_Experiment_IDs E
                         WHERE E.Exp_ID BETWEEN _experimentIdStart AND _experimentIdEnd);

        _experimentIdStart := _experimentIdStart + _experimentBatchSize;
        _experimentIdEnd   := _experimentIdEnd   + _experimentBatchSize;

        If _experimentIdStart > _experimentIdMax Then
            -- Break out of the while loop
            EXIT;
        End If;

    END LOOP;

    If _rowCountUpdated > 0 Then
        _addon := format('Updated %s %s in t_cached_experiment_stats', _rowCountUpdated, public.check_plural(_rowCountUpdated, 'row', 'rows'));
        _message := public.append_to_text(_message, _addon);

        -- CALL post_log_entry ('Debug', _message, 'update_cached_experiment_stats');
    End If;

    _runtimeSeconds := Round(Extract(epoch from (clock_timestamp() - _startTime)), 3);

    If _showDebug Or _runtimeSeconds > 5 Then
        RAISE INFO 'Processing time: % seconds', _runtimeSeconds;
    End If;

    DROP TABLE Tmp_Experiment_IDs;
END
$$;


ALTER PROCEDURE public.update_cached_experiment_stats(IN _processingmode integer, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


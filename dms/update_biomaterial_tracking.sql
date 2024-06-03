--
-- Name: update_biomaterial_tracking(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_biomaterial_tracking(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update summary stats in t_biomaterial_tracking
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          08/30/2018 mem - Use merge instead of truncate
**          02/28/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;

    _addOrUpdateCount int;
    _rowsAdded int;
    _rowsUpdated int;

    _deleteCount int;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------------
    -- Cache the count of the current number of items in t_biomaterial_tracking
    ----------------------------------------------------------

    SELECT COUNT(*)
    INTO _countBeforeMerge
    FROM t_biomaterial_tracking;

    ----------------------------------------------------------
    -- Create a temporary table to hold the stats
    ----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Biomaterial_Stats (
        Biomaterial_ID int NOT NULL,
        Experiment_Count int NOT NULL,
        Dataset_Count int NOT NULL,
        Job_Count int NOT NULL,
        CONSTRAINT PK_Tmp_Biomaterial_Stats PRIMARY KEY (Biomaterial_ID)
    );

    ----------------------------------------------------------
    -- Make entry in results table for each biomaterial
    ----------------------------------------------------------

    INSERT INTO Tmp_Biomaterial_Stats (
        Biomaterial_ID,
        Experiment_Count,
        Dataset_Count,
        Job_Count
    )
    SELECT Biomaterial_ID, 0, 0, 0
    FROM t_biomaterial;

    ----------------------------------------------------------
    -- Update experiment count statistics
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Experiment_Count = StatsQ.Items
    FROM (SELECT Biomaterial_ID,
                 COUNT(Exp_ID) AS Items
          FROM t_experiment_biomaterial
          GROUP BY Biomaterial_ID
         ) AS StatsQ
    WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = StatsQ.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update dataset count statistics
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Dataset_Count = StatsQ.Items
    FROM (SELECT t_experiment_biomaterial.biomaterial_id,
                 COUNT(t_dataset.dataset_id) AS Items
          FROM t_experiment_biomaterial
               INNER JOIN t_experiments
                 ON t_experiment_biomaterial.exp_id = t_experiments.exp_id
               INNER JOIN t_dataset
                 ON t_experiments.exp_id = t_dataset.exp_id
          GROUP BY t_experiment_biomaterial.biomaterial_id
         ) AS StatsQ
    WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = StatsQ.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update analysis count statistics for results table
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Job_Count = StatsQ.Items
    FROM (SELECT t_experiment_biomaterial.biomaterial_id,
                 COUNT(t_analysis_job.job) AS Items
          FROM t_experiment_biomaterial
               INNER JOIN t_experiments
                 ON t_experiment_biomaterial.exp_id = t_experiments.exp_id
               INNER JOIN t_dataset
                 ON t_experiments.exp_id = t_dataset.exp_id
               INNER JOIN t_analysis_job
                 ON t_dataset.dataset_id = t_analysis_job.dataset_id
          GROUP BY t_experiment_biomaterial.biomaterial_id
         ) AS StatsQ
    WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = StatsQ.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update t_biomaterial_tracking using Tmp_Biomaterial_Stats
    ----------------------------------------------------------

    MERGE INTO t_biomaterial_tracking AS Target
    USING (SELECT Biomaterial_ID,
                  Experiment_Count,
                  Dataset_Count,
                  Job_Count
           FROM Tmp_Biomaterial_Stats
          ) AS Src
    ON (Target.biomaterial_id = Src.biomaterial_id)
    WHEN MATCHED AND
         (Target.Experiment_Count <> Src.Experiment_Count OR
          Target.Dataset_Count <> Src.Dataset_Count OR
          Target.Job_Count <> Src.Job_Count) THEN
        UPDATE SET
            Experiment_Count = Src.Experiment_Count,
            Dataset_Count = Src.Dataset_Count,
            Job_Count = Src.Job_Count
    WHEN NOT MATCHED THEN
        INSERT (Biomaterial_ID, Experiment_Count, Dataset_Count, Job_Count)
        VALUES (Src.Biomaterial_ID, Src.Experiment_Count, Src.Dataset_Count, Src.Job_Count);

    GET DIAGNOSTICS _addOrUpdateCount = ROW_COUNT;

    SELECT COUNT(*)
    INTO _countAfterMerge
    FROM t_biomaterial_tracking;

    _rowsAdded    := _countAfterMerge - _countBeforeMerge;
    _rowsUpdated := _addOrUpdateCount - _rowsAdded;

    If _rowsAdded > 0 Then
        _message := format('added %s %s', _rowsAdded, public.check_plural(_rowsAdded, 'row', 'rows'));
    End If;

    If _rowsUpdated > 0 Then
        _message := public.append_to_text(
                            _message,
                            format('updated %s %s', _rowsUpdated, public.check_plural(_rowsUpdated, 'row', 'rows')));
    End If;

    -- Delete rows in t_biomaterial_type_name that are not in Tmp_Biomaterial_Stats

    DELETE FROM t_biomaterial_tracking target
    WHERE NOT EXISTS (SELECT 1
                      FROM Tmp_Biomaterial_Stats source
                      WHERE target.biomaterial_id = source.biomaterial_id
                     );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := public.append_to_text(
                            _message,
                            format('deleted %s extra %s', _deleteCount, public.check_plural(_deleteCount, 'row', 'rows')));
    End If;

    If _message <> '' Then
        _message := format('Updated t_biomaterial_tracking: %s', _message);
        RAISE INFO '%', _message;
    Else
        RAISE INFO 'Table t_biomaterial_tracking is already up-to-date';
    End If;

    DROP TABLE Tmp_Biomaterial_Stats;
END
$$;


ALTER PROCEDURE public.update_biomaterial_tracking(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_biomaterial_tracking(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_biomaterial_tracking(INOUT _message text, INOUT _returncode text) IS 'UpdateBiomaterialTracking or UpdateCellCultureTracking';


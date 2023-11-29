--
CREATE OR REPLACE PROCEDURE public.update_biomaterial_tracking()
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates summary stats in t_biomaterial_type_name
**
**  Arguments:
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          08/30/2018 mem - Use merge instead of truncate
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
BEGIN
    _message := '';

    ----------------------------------------------------------
    -- Create a temporary table to hold the stats
    ----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Biomaterial_Stats (
        Biomaterial_ID int NOT NULL,
        Experiment_Count int NOT NULL,
        Dataset_Count int NOT NULL,
        Job_Count int NOT NULL,
        CONSTRAINT PK_Tmp_Biomaterial_Stats PRIMARY KEY ( Biomaterial_ID Asc)
    )

    ----------------------------------------------------------
    -- Make entry in results table for each biomaterial
    ----------------------------------------------------------

    INSERT INTO Tmp_Biomaterial_Stats( Biomaterial_ID,
                                       Experiment_Count,
                                       Dataset_Count,
                                       Job_Count )
    SELECT Biomaterial_ID, 0, 0, 0
    FROM t_biomaterial;

    ----------------------------------------------------------
    -- Update experiment count statistics
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Experiment_Count = S.Cnt
    FROM ( SELECT Biomaterial_ID,
                  COUNT(Exp_ID) AS Cnt
           FROM t_experiment_biomaterial
           GROUP BY Biomaterial_ID
          ) AS S
    WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = S.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update dataset count statistics
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Dataset_Count = S.Cnt
    FROM ( SELECT t_experiment_biomaterial.biomaterial_id,
                  COUNT(t_dataset.dataset_id) AS Cnt
           FROM t_experiment_biomaterial
                INNER JOIN t_experiments
                  ON t_experiment_biomaterial.exp_id = t_experiments.exp_id
                INNER JOIN t_dataset
                  ON t_experiments.exp_id = t_dataset.exp_id
           GROUP BY t_experiment_biomaterial.biomaterial_id
          ) AS S
     WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = S.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update analysis count statistics for results table
    ----------------------------------------------------------

    UPDATE Tmp_Biomaterial_Stats
    SET Job_Count = S.Cnt
    FROM ( SELECT t_experiment_biomaterial.biomaterial_id,
                  COUNT(t_analysis_job.job) AS Cnt
           FROM t_experiment_biomaterial
                INNER JOIN t_experiments
                  ON t_experiment_biomaterial.exp_id = t_experiments.exp_id
                INNER JOIN t_dataset
                  ON t_experiments.exp_id = t_dataset.exp_id
                INNER JOIN t_analysis_job
                  ON t_dataset.dataset_id = t_analysis_job.dataset_id
           GROUP BY t_experiment_biomaterial.biomaterial_id
          ) AS S
    WHERE Tmp_Biomaterial_Stats.Biomaterial_ID = S.Biomaterial_ID;

    ----------------------------------------------------------
    -- Update T_Biomaterial_Type_Name using Tmp_Biomaterial_Stats
    ----------------------------------------------------------

    MERGE INTO t_biomaterial_type_name AS t
    USING ( SELECT * FROM Tmp_Biomaterial_Stats
          ) AS s
    ON (t.biomaterial_id = s.biomaterial_id)
    WHEN MATCHED AND
         (t.Experiment_Count <> s.Experiment_Count OR
          t.Dataset_Count <> s.Dataset_Count OR
          t.Job_Count <> s.Job_Count) THEN
        UPDATE SET
            Experiment_Count = s.Experiment_Count,
            Dataset_Count = s.Dataset_Count,
            Job_Count = s.Job_Count
    WHEN NOT MATCHED THEN
        INSERT (Biomaterial_ID, Experiment_Count, Dataset_Count, Job_Count)
        VALUES (s.Biomaterial_ID, s.Experiment_Count, s.Dataset_Count, s.Job_Count);

    -- Delete rows in T_Biomaterial_Type_Name that are not in Tmp_Biomaterial_Stats

    DELETE FROM t_biomaterial_type_name target
    WHERE NOT EXISTS (SELECT source.biomaterial_id
                      FROM Tmp_Biomaterial_Stats source
                      WHERE target.biomaterial_id = source.biomaterial_id
                     );

    DROP TABLE Tmp_Biomaterial_Stats;
END
$$;

COMMENT ON PROCEDURE public.update_biomaterial_tracking IS 'UpdateCellCultureTracking';

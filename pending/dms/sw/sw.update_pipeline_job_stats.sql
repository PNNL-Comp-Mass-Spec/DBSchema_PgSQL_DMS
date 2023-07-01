--
CREATE OR REPLACE PROCEDURE sw.update_pipeline_job_stats
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update processing statistics in T_Pipeline_Job_Stats
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create a temp table to hold the statistics
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Pipeline_Job_Stats (
        Script     text NOT NULL,
        Instrument_Group text NOT NULL,
        Year     int NOT NULL,
        Jobs       int NOT NULL,
        PRIMARY KEY CLUSTERED ( Script, Instrument_Group, Year )
    )

    ---------------------------------------------------
    -- Summarize jobs by script, instrument group, and year
    ---------------------------------------------------

    INSERT INTO Tmp_Pipeline_Job_Stats( script, Instrument_Group, Year, Jobs )
    SELECT JH.script,
           Coalesce(InstName.instrument_group, '') AS Instrument_Group,
           Extract(year from JH.start) AS Year,
           COUNT(*) AS Jobs
    FROM sw.t_jobs_history JH
         LEFT OUTER JOIN public.t_analysis_job J
           ON JH.job = J.job
         LEFT OUTER JOIN public.t_dataset DS
           ON J.dataset_id = DS.dataset_id
         LEFT OUTER JOIN public.t_instrument_name InstName
           ON DS.instrument_name_ID = InstName.Instrument_ID
    WHERE NOT JH.start IS NULL
    GROUP BY JH.script, Coalesce(InstName.Instrument_Group, ''), Extract(year from JH.start)

    If Not FOUND Then
        _message := 'No rows were added to Tmp_Pipeline_Job_Stats; exiting';

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_Pipeline_Job_Stats;
        RETURN;
    End If;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT Script,
               Instrument_Group,
               Year,
               Jobs
        FROM Tmp_Pipeline_Job_Stats
        ORDER BY Script, Instrument_Group, Year

        DROP TABLE Tmp_Pipeline_Job_Stats;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update cached stats in sw.t_pipeline_job_stats
    --
    -- Since old jobs get deleted from sw.t_jobs_history,
    -- assure that the maximum value is used for each row
    ---------------------------------------------------

    MERGE sw.t_pipeline_job_stats AS t
    USING ( SELECT script, instrument_group, year, Jobs
            FROM Tmp_Pipeline_Job_Stats
          ) AS s
    ON ( t.instrument_group = s.instrument_group AND t.script = s.script AND t.year = s.year)
    WHEN MATCHED AND t.jobs < s.jobs THEN
        UPDATE SET jobs = s.jobs
    WHEN NOT MATCHED THEN
        INSERT (script, instrument_group, year, Jobs)
        VALUES (s.script, s.instrument_group, s.year, s.Jobs);
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    _message := format('Updated %s %s in sw.t_pipeline_job_stats', _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

    If _returnCode <> '' Then
        If _message = '' Then
            _message := 'Error in UpdatePipelineJobStats';
        End If;

        _message := format('%s; error code = %s', _message, _returnCode);

        If Not _infoOnly Then
            CALL public.post_log_entry ('Error', _message, 'Update_Pipeline_Job_Stats', 'sw');
        End If;
    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Pipeline_Job_Stats;
END
$$;

COMMENT ON PROCEDURE sw.update_pipeline_job_stats IS 'UpdatePipelineJobStats';

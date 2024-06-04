--
-- Name: update_pipeline_job_stats(boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_pipeline_job_stats(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update processing statistics in sw.t_pipeline_job_stats
**
**  Arguments:
**    _infoOnly     When true, preview the processing statistics
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          08/14/2023 mem - Ported to PostgreSQL
**          01/04/2024 mem - Check for empty strings instead of using char_length()
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

    ---------------------------------------------------
    -- Create a temp table to hold the statistics
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Pipeline_Job_Stats (
        Script text NOT NULL,
        Instrument_Group text NOT NULL,
        Year int NOT NULL,
        Jobs int NOT NULL,
        PRIMARY KEY (Script, Instrument_Group, Year)
    );

    ---------------------------------------------------
    -- Summarize jobs by script, instrument group, and year
    ---------------------------------------------------

    INSERT INTO Tmp_Pipeline_Job_Stats (
        Script,
        Instrument_Group,
        Year,
        Jobs
    )
    SELECT JH.Script,
           Coalesce(InstName.instrument_group, '') AS Instrument_Group,
           Extract(year from JH.start) AS Year,
           COUNT(JH.job) AS Jobs
    FROM sw.t_jobs_history JH
         LEFT OUTER JOIN public.t_analysis_job J
           ON JH.job = J.job
         LEFT OUTER JOIN public.t_dataset DS
           ON J.dataset_id = DS.dataset_id
         LEFT OUTER JOIN public.t_instrument_name InstName
           ON DS.instrument_ID = InstName.Instrument_ID
    WHERE NOT JH.start IS NULL
    GROUP BY JH.script, Coalesce(InstName.Instrument_Group, ''), Extract(year from JH.start);

    If Not FOUND Then
        _message := 'No rows were added to Tmp_Pipeline_Job_Stats; exiting';

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_Pipeline_Job_Stats;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-35s %-25s %-5s %-6s';

        _infoHead := format(_formatSpecifier,
                            'Script',
                            'Instrument_Group',
                            'Year',
                            'Jobs'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------------------------------',
                                     '-------------------------',
                                     '----',
                                     '------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Script,
                   Instrument_Group,
                   Year,
                   Jobs
            FROM Tmp_Pipeline_Job_Stats
            ORDER BY Script, Instrument_Group, Year
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Script,
                                _previewData.Instrument_Group,
                                _previewData.Year,
                                _previewData.Jobs
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Pipeline_Job_Stats;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update cached stats in sw.t_pipeline_job_stats
    --
    -- Since old jobs get deleted from sw.t_jobs_history,
    -- assure that the maximum value is used for each row
    ---------------------------------------------------

    MERGE INTO sw.t_pipeline_job_stats AS t
    USING (SELECT Script, Instrument_Group, Year, Jobs
           FROM Tmp_Pipeline_Job_Stats
          ) AS s
    ON (t.instrument_group = s.instrument_group AND t.script = s.script AND t.year = s.year)
    WHEN MATCHED AND t.jobs < s.jobs THEN
        UPDATE SET jobs = s.jobs
    WHEN NOT MATCHED THEN
        INSERT (script, instrument_group, year, Jobs)
        VALUES (s.script, s.instrument_group, s.year, s.Jobs);
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    _message := format('Updated %s %s in sw.t_pipeline_job_stats', _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

    RAISE INFO '%', _message;

    DROP TABLE Tmp_Pipeline_Job_Stats;
END
$$;


ALTER PROCEDURE sw.update_pipeline_job_stats(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_pipeline_job_stats(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_pipeline_job_stats(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdatePipelineJobStats';


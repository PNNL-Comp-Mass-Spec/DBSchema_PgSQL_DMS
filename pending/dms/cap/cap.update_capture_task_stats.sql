--
CREATE OR REPLACE PROCEDURE cap.update_capture_task_stats
(
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update processing statistics in T_Capture_Task_Stats
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _statItem record;
    _myRowCount int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';

    ---------------------------------------------------
    -- Create a temp table to hold the statistics
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Capture_Task_Stats (
        Script     text NOT NULL,
        Instrument text NOT NULL,
        Year       int NOT NULL,
        Jobs       int NOT NULL,
        PRIMARY KEY ( Script, Instrument, [Year] )
    )

    ---------------------------------------------------
    -- Summarize capture task jobs by script, instrument, and year
    ---------------------------------------------------

    INSERT INTO Tmp_Capture_Task_Stats( Script, Instrument, Year, Jobs )
    SELECT JH.Script,
           Coalesce(InstName.In_Name, '') AS Instrument,
           Extract(year from JH.Start) AS Year,
           COUNT(*) AS Jobs
    FROM cap.t_tasks_history JH
         LEFT OUTER JOIN public.T_Dataset DS
           ON JH.Dataset_ID = DS.Dataset_ID
         LEFT OUTER JOIN public.T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
    WHERE NOT JH.Start IS NULL
    GROUP BY JH.Script, Coalesce(InstName.In_Name, ''), Extract(year from JH.Start)

    If Not FOUND Then
        _message := 'No rows were added to Tmp_Capture_Task_Stats; exiting';
        RETURN;
    End If;

    If _infoOnly Then
        FOR _statItem IN
            SELECT Script,
                   Instrument,
                   Year,
                   Jobs
            FROM Tmp_Capture_Task_Stats
            ORDER BY Script, Instrument, Year
        LOOP
            RAISE INFO 'Script: %, Instrument: %, Year: %, Jobs: %', _statItem.Script, _statItem.Instrument, _statItem.Year, _statItem.Jobs;
        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update cached stats in cap.t_capture_task_stats
    --
    -- Since old capture task jobs get deleted from t_tasks_history,
    -- assure that the maximum value is used for each row
    ---------------------------------------------------

    If Exists (SELECT t.script
               FROM cap.t_capture_task_stats t INNER JOIN
                    Tmp_Capture_Task_Stats s ON
                      t.instrument = s.instrument AND t.script = s.script AND t.year = s.year) Then

        UPDATE cap.t_capture_task_stats
        SET jobs = s.jobs
        FROM Tmp_Capture_Task_Stats s
        WHERE t.instrument = s.instrument AND t.script = s.script AND t.year = s.year AND
              t.jobs < s.jobs;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := format('Updated %s rows in cap.t_capture_task_stats', _myRowCount);

    Else
        INSERT INTO cap.t_capture_task_stats (script, instrument, year, jobs)
        SELECT script, instrument, year, Jobs
        FROM Tmp_Capture_Task_Stats
        ON CONFLICT (script, instrument, year)
        DO UPDATE SET
          jobs = Tmp_Capture_Task_Stats.jobs
          WHERE jobs < Tmp_Capture_Task_Stats.jobs;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _message := format('Added %s rows in cap.t_capture_task_stats', _myRowCount);

    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Capture_Task_Stats;
END
$$;

COMMENT ON PROCEDURE cap.update_capture_task_stats IS 'UpdateCaptureTaskStats';

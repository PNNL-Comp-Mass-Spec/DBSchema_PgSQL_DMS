--
-- Name: update_capture_task_stats(integer, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_capture_task_stats(IN _year integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update processing statistics in cap.t_capture_task_stats
**
**  Arguments:
**    _year         Optional year to filter on; use all years if 0
**    _infoOnly     When true, preview updates
**    _message      Output message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/29/2022 mem - Initial version
**          06/28/2023 mem - Add option to filter by year
***                        - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countAtStart int;
    _countAtEnd int;
    _countAddedOrUpdated int;
    _updateCount int;
    _insertCount int;

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

    _year := Coalesce(_year, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temp table to hold the statistics
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Capture_Task_Stats (
        Script     text NOT NULL,
        Instrument text NOT NULL,
        Year       int NOT NULL,
        Jobs       int NOT NULL,
        PRIMARY KEY ( Script, Instrument, Year )
    );

    ---------------------------------------------------
    -- Summarize capture task jobs by script, instrument, and year
    ---------------------------------------------------

    INSERT INTO Tmp_Capture_Task_Stats( Script, Instrument, Year, Jobs )
    SELECT JH.Script,
           Coalesce(InstName.Instrument, '') AS Instrument,
           Extract(year from JH.Start) AS Year,
           COUNT(*) AS Jobs
    FROM cap.t_tasks_history JH
         LEFT OUTER JOIN public.t_dataset DS
           ON JH.Dataset_ID = DS.Dataset_ID
         LEFT OUTER JOIN public.t_instrument_name InstName
           ON DS.Instrument_ID = InstName.Instrument_ID
    WHERE NOT JH.Start IS NULL AND
          (_year = 0 OR date_part('year', JH.Start)::int = _year)
    GROUP BY JH.Script, Coalesce(InstName.Instrument, ''), Extract(year from JH.Start);

    If Not FOUND Then
        _message := 'No rows were added to Tmp_Capture_Task_Stats; exiting';
        DROP TABLE Tmp_Capture_Task_Stats;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-26s %-25s %-5s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Script',
                            'Instrument',
                            'Year',
                            'Jobs'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------------',
                                     '-------------------------',
                                     '-----',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Script,
                   Instrument,
                   Year,
                   Jobs
            FROM Tmp_Capture_Task_Stats
            ORDER BY Script, Instrument, Year
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Script,
                                _previewData.Instrument,
                                _previewData.Year,
                                _previewData.Jobs
                    );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Capture_Task_Stats;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update cached stats in cap.t_capture_task_stats
    --
    -- Since old capture task jobs get deleted from t_tasks_history,
    -- assure that the maximum value is used for each row
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _countAtStart
    FROM cap.t_capture_task_stats;

    INSERT INTO cap.t_capture_task_stats (script, instrument, year, jobs)
    SELECT Src.script, Src.instrument, Src.year, Src.Jobs
    FROM Tmp_Capture_Task_Stats Src
    ON CONFLICT (script, instrument, year)
    DO UPDATE SET
      jobs = CASE WHEN cap.t_capture_task_stats.jobs < EXCLUDED.jobs
                  THEN EXCLUDED.jobs
                  ELSE cap.t_capture_task_stats.jobs
             END;
    --
    GET DIAGNOSTICS _countAddedOrUpdated = ROW_COUNT;

    SELECT COUNT(*)
    INTO _countAtEnd
    FROM cap.t_capture_task_stats;

    _insertCount := _countAtEnd - _countAtStart;
    _updateCount := _countAddedOrUpdated - _insertCount;

    _message := format('Added %s rows and updated %s rows in cap.t_capture_task_stats', _insertCount, _updateCount);

    RAISE INFO '%', _message;

    DROP TABLE Tmp_Capture_Task_Stats;
END
$$;


ALTER PROCEDURE cap.update_capture_task_stats(IN _year integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_capture_task_stats(IN _year integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_capture_task_stats(IN _year integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCaptureTaskStats';


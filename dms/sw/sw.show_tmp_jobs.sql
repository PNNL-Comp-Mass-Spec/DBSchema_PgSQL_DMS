--
-- Name: show_tmp_jobs(); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.show_tmp_jobs()
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the contents of temporary table Tmp_Jobs
**      This procedure is called from cap.create_task_steps and sw.create_job_steps
**
**  Required table format:
**
**      CREATE TEMP TABLE Tmp_Jobs (
**          Job int NOT NULL,
**          Script citext NULL,
**          Dataset citext NULL
**      );
**
**  Auth:   mem
**  Date:   11/30/2022 mem - Initial release
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN

    RAISE INFO '';

    If Not Exists (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Jobs'
    ) Then
        RAISE WARNING 'Temporary table Tmp_Jobs does not exist; nothing to preview';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM Tmp_Jobs) Then
        RAISE INFO 'Temp table Tmp_Jobs is empty; nothing to preview';
        RETURN;
    End If;

    -- Show contents of Tmp_Jobs
    --

    _formatSpecifier := '%-10s %-15s %-40s';

    _infoHead := format(_formatSpecifier,
                        'Job',
                        'Script',
                        'Dataset'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '----------',
                                 '---------------',
                                 '----------------------------------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT Job, Script, Dataset
        FROM Tmp_Jobs
        ORDER BY Job
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Job,
                            _previewData.Script,
                            _previewData.Dataset
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

END
$$;


ALTER PROCEDURE sw.show_tmp_jobs() OWNER TO d3l243;


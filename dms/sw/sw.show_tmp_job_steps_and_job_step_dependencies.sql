--
-- Name: show_tmp_job_steps_and_job_step_dependencies(); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.show_tmp_job_steps_and_job_step_dependencies()
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the contents of temporary tables Tmp_Job_Steps and Tmp_Job_Step_Dependencies
**      This procedure is called from cap.create_task_steps and sw.create_job_steps
**
**  Required table formats:
**
**      CREATE TEMP TABLE Tmp_Job_Steps (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          Step_Tool citext NOT NULL
**      );
**
**      CREATE TEMP TABLE Tmp_Job_Step_Dependencies (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          Target_Step int NOT NULL
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
    _infoData text;
    _previewSteps record;
    _previewDependencies record;
BEGIN

    RAISE INFO ' ';

    If Not EXISTS (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Job_Steps'
    ) Then
        RAISE WARNING 'Temporary table Tmp_Job_Steps does not exist; nothing to preview';
        RETURN;
    End If;

    If Not EXISTS (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Job_Step_Dependencies'
    ) Then
        RAISE WARNING 'Temporary table Tmp_Job_Step_Dependencies does not exist; nothing to preview';
        RETURN;
    End If;

    _formatSpecifier := '%-10s %-10s %-20s';

    _infoHead := format(_formatSpecifier,
                        'Job',
                        'Step',
                        'Step_Tool'
                    );

    _infoHeadSeparator := format(_formatSpecifier,
                        '----------',
                        '----------',
                        '--------------------'
                    );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewSteps IN
        SELECT Job, Step, Step_Tool
        FROM Tmp_Job_Steps
        ORDER BY Job, Step
    LOOP
        _infoData := format(_formatSpecifier,
                                _previewSteps.Job,
                                _previewSteps.Step,
                                _previewSteps.Step_Tool
                        );

        RAISE INFO '%', _infoData;

    END LOOP;

    -- Show contents of Tmp_Job_Step_Dependencies
    --
    RAISE INFO ' ';

    _formatSpecifier := '%-10s %-10s %-20s';

    _infoHead := format(_formatSpecifier,
                        'Job',
                        'Step',
                        'Target_Step'
                    );

    _infoHeadSeparator := format(_formatSpecifier,
                        '----------',
                        '----------',
                        '--------------------'
                    );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewDependencies IN
        SELECT Job, Step, Target_Step
        FROM Tmp_Job_Step_Dependencies
        ORDER BY Job, Step
    LOOP
        _infoData := format(_formatSpecifier,
                                _previewDependencies.Job,
                                _previewDependencies.Step,
                                _previewDependencies.Target_Step
                        );

        RAISE INFO '%', _infoData;

    END LOOP;
END
$$;


ALTER PROCEDURE sw.show_tmp_job_steps_and_job_step_dependencies() OWNER TO d3l243;


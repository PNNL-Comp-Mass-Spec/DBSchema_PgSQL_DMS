--
-- Name: show_tmp_job_steps_and_job_step_dependencies(boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.show_tmp_job_steps_and_job_step_dependencies(IN _capturetaskjob boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the contents of temporary tables Tmp_Job_Steps and Tmp_Job_Step_Dependencies
**      This procedure is called from cap.create_task_steps and sw.create_job_steps
**
**  Arguments:
**    _captureTaskJob boolean    When false, show columns used by sw.create_job_steps; when true, show columns used by cap.create_task_steps
**
**  Required table formats:
**
**      CREATE TEMP TABLE Tmp_Job_Steps (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          Tool citext NOT NULL
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
**          06/21/2023 mem - Use Tool for the step tool column in Tmp_Job_Steps
**          08/01/2023 mem - Add parameter _captureTaskJob, which controls which columns in Tmp_Job_Steps are displayed
**          03/04/2024 mem - Adjust preview data column widths
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

    _captureTaskJob := Coalesce(_captureTaskJob, false);

    RAISE INFO '';

    If Not Exists (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Job_Steps'
    ) Then
        RAISE WARNING 'Temporary table Tmp_Job_Steps does not exist; nothing to preview';
        RETURN;
    End If;

    If Not Exists (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_Job_Step_Dependencies'
    ) Then
        RAISE WARNING 'Temporary table Tmp_Job_Step_Dependencies does not exist; nothing to preview';
        RETURN;
    End If;

    If _captureTaskJob Then

        _formatSpecifier := '%-10s %-4s %-20s %-8s %-12s %-14s %-9s %-5s %-30s %-30s %-24s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Step_Tool',
                            'CPU_Load',
                            'Dependencies',
                            'Filter_Version',
                            'Signature',
                            'State',
                            'Input_Directory_Name',
                            'Output_Directory_Name',
                            'Holdoff_Interval_Minutes'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----',
                                     '--------------------',
                                     '--------',
                                     '------------',
                                     '--------------',
                                     '---------',
                                     '-----',
                                     '------------------------------',
                                     '------------------------------',
                                     '------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewSteps IN
            SELECT Job, Step, Tool, CPU_Load, Dependencies, Filter_Version, Signature,
                   State, Input_Directory_Name, Output_Directory_Name, Holdoff_Interval_Minutes
            FROM Tmp_Job_Steps
            ORDER BY Job, Step
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewSteps.Job,
                                _previewSteps.Step,
                                _previewSteps.Tool,
                                _previewSteps.CPU_Load,
                                _previewSteps.Dependencies,
                                _previewSteps.Filter_Version,
                                _previewSteps.Signature,
                                _previewSteps.State,
                                _previewSteps.Input_Directory_Name,
                                _previewSteps.Output_Directory_Name,
                                _previewSteps.Holdoff_Interval_Minutes
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        _formatSpecifier := '%-10s %-4s %-20s %-8s %-15s %-12s %-21s %-9s %-5s %-25s %-25s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Step',
                            'Step_Tool',
                            'CPU_Load',
                            'Memory_Usage_MB',
                            'Dependencies',
                            'Shared_Result_Version',
                            'Signature',
                            'State',
                            'Input_Directory_Name',
                            'Output_Directory_Name'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----',
                                     '--------------------',
                                     '--------',
                                     '---------------',
                                     '------------',
                                     '---------------------',
                                     '---------',
                                     '-----',
                                     '-------------------------',
                                     '-------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewSteps IN
            SELECT Job, Step, Tool, CPU_Load, Memory_Usage_MB, Dependencies, Shared_Result_Version, Signature,
                   State, Input_Directory_Name, Output_Directory_Name
            FROM Tmp_Job_Steps
            ORDER BY Job, Step
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewSteps.Job,
                                _previewSteps.Step,
                                _previewSteps.Tool,
                                _previewSteps.CPU_Load,
                                _previewSteps.Memory_Usage_MB,
                                _previewSteps.Dependencies,
                                _previewSteps.Shared_Result_Version,
                                _previewSteps.Signature,
                                _previewSteps.State,
                                _previewSteps.Input_Directory_Name,
                                _previewSteps.Output_Directory_Name
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    -- Show contents of Tmp_Job_Step_Dependencies

    RAISE INFO '';

    _formatSpecifier := '%-10s %-4s %-11s';

    _infoHead := format(_formatSpecifier,
                        'Job',
                        'Step',
                        'Target_Step'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '----------',
                                 '----',
                                 '-----------'
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


ALTER PROCEDURE sw.show_tmp_job_steps_and_job_step_dependencies(IN _capturetaskjob boolean) OWNER TO d3l243;


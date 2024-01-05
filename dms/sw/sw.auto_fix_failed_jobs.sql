--
-- Name: auto_fix_failed_jobs(text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.auto_fix_failed_jobs(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Automatically deal with certain types of failed job situations
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**    _infoOnly     When true, preview job steps that would be updated
**
**  Auth:   mem
**  Date:   05/01/2015 mem - Initial version
**          05/08/2015 mem - Added support for 'Cannot run BuildSA since less than'
**          05/26/2017 mem - Add step state 16 (Failed_Remote)
**          03/30/2018 mem - Reset MSGF+ steps with 'Timeout expired'
**          06/05/2018 mem - Add support for Formularity
**          07/29/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    CREATE TEMP TABLE Tmp_JobsToFix (
        Job int not null,
        Step int not null
    );

    CREATE INDEX IX_Tmp_JobsToFix_Job ON Tmp_JobsToFix (Job, Step);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    _formatSpecifier := '%-55s %-10s %-80s %-4s %-25s %-20s %-10s %-5s %-20s %-20s %-20s %-15s %-30s %-15s %-30s %-11s';

    _infoHead := format(_formatSpecifier,
                        'Action',
                        'Job',
                        'Dataset',
                        'Step',
                        'Script',
                        'Tool',
                        'State_name',
                        'State',
                        'Start',
                        'Finish',
                        'Processor',
                        'Completion_Code',
                        'Completion_Message',
                        'Evaluation_Code',
                        'Evaluation_Message',
                        'Data_Pkg_ID'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '-------------------------------------------------------',
                                 '----------',
                                 '--------------------------------------------------------------------------------',
                                 '----',
                                 '-------------------------',
                                 '--------------------',
                                 '----------',
                                 '-----',
                                 '--------------------',
                                 '--------------------',
                                 '--------------------',
                                 '---------------',
                                 '------------------------------',
                                 '---------------',
                                 '------------------------------',
                                 '-----------'
                                );

    ---------------------------------------------------
    -- Look for Bruker_DA_Export jobs that failed with error 'No spectra were exported'
    ---------------------------------------------------

    INSERT INTO Tmp_JobsToFix (job, step)
    SELECT job, step
    FROM sw.t_job_steps
    WHERE tool = 'Bruker_DA_Export' AND
          state IN (6, 16) AND
          completion_message = 'No spectra were exported';

    If FOUND Then
        If _infoOnly Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JS.Job,
                       JS.Dataset,
                       JS.Step,
                       JS.Script,
                       JS.Tool,
                       JS.State_name,
                       JS.State,
                       public.timestamp_text(JS.Start) As Start,
                       public.timestamp_text(JS.Finish) As Finish,
                       JS.Processor,
                       JS.Completion_Code,
                       JS.Completion_Message,
                       JS.Evaluation_Code,
                       JS.Evaluation_Message,
                       JS.Data_Pkg_ID
                FROM V_Job_Steps JS
                     INNER JOIN Tmp_JobsToFix F
                       ON JS.Job = F.Job AND
                          JS.Step = F.Step
                ORDER BY JS.Job, JS.Step
            LOOP
                _infoData := format(_formatSpecifier,
                                    'Change step state to 3',
                                    _previewData.Job,
                                    _previewData.Dataset,
                                    _previewData.Step,
                                    _previewData.Script,
                                    _previewData.Tool,
                                    _previewData.State_name,
                                    _previewData.State,
                                    _previewData.Start,
                                    _previewData.Finish,
                                    _previewData.Processor,
                                    _previewData.Completion_Code,
                                    _previewData.Completion_Message,
                                    _previewData.Evaluation_Code,
                                    _previewData.Evaluation_Message,
                                    _previewData.Data_Pkg_ID
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            -- We will leave these jobs as 'failed' in public.T_Analysis_Job since there are no results to track

            -- Change the step state to 3 (Skipped) for all of the steps in this job

            UPDATE sw.t_job_steps Target
            SET state = 3
            FROM Tmp_JobsToFix F
            WHERE Target.Job = F.Job;

        End If;
    End If;

    ---------------------------------------------------
    -- Look for Formularity or NOMSI jobs that failed with error 'No peaks found'
    ---------------------------------------------------

    DELETE FROM Tmp_JobsToFix;

    INSERT INTO Tmp_JobsToFix( job, step )
    SELECT job,
           step
    FROM sw.t_job_steps
    WHERE tool In ('Formularity', 'NOMSI') AND
          state IN (6, 16) AND
          completion_message = 'No peaks found';

    If FOUND Then
        If _infoOnly Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JS.Job,
                       JS.Dataset,
                       JS.Step,
                       JS.Script,
                       JS.Tool,
                       JS.State_name,
                       JS.State,
                       public.timestamp_text(JS.Start) As Start,
                       public.timestamp_text(JS.Finish) As Finish,
                       JS.Processor,
                       JS.Completion_Code,
                       JS.Completion_Message,
                       JS.Evaluation_Code,
                       JS.Evaluation_Message,
                       JS.Data_Pkg_ID
                FROM V_Job_Steps JS
                     INNER JOIN Tmp_JobsToFix F
                       ON JS.Job = F.Job AND
                          JS.Step = F.Step
                ORDER BY JS.Job, JS.Step
            LOOP
                _infoData := format(_formatSpecifier,
                                    'Change step state to 3 and propagation mode to 1',
                                    _previewData.Job,
                                    _previewData.Dataset,
                                    _previewData.Step,
                                    _previewData.Script,
                                    _previewData.Tool,
                                    _previewData.State_name,
                                    _previewData.State,
                                    _previewData.Start,
                                    _previewData.Finish,
                                    _previewData.Processor,
                                    _previewData.Completion_Code,
                                    _previewData.Completion_Message,
                                    _previewData.Evaluation_Code,
                                    _previewData.Evaluation_Message,
                                    _previewData.Data_Pkg_ID
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            -- Change the Propagation Mode to 1 (so that the job will be set to state 14 (No Export)

            UPDATE public.t_analysis_job Target
            SET propagation_mode = 1,
                job_state_id = 2
            FROM Tmp_JobsToFix F
            WHERE Target.job = F.Job;

            -- Change the job state back to 'In Progress'

            UPDATE sw.t_jobs Target
            SET state = 2
            FROM Tmp_JobsToFix F
            WHERE Target.Job = F.Job;

            -- Change the step state to 3 (Skipped)

            UPDATE sw.t_job_steps Target
            SET state = 3
            FROM Tmp_JobsToFix F
            WHERE Target.Job = F.Job AND
                  Target.Step = F.Step;

        End If;
    End If;

    ---------------------------------------------------
    -- Look for MSGFPlus jobs where Completion_Message is similar to
    -- "; Cannot run BuildSA since less than 12000 MB of free memory"
    -- or
    -- Error retrieving protein collection or legacy FASTA file: Timeout expired
    ---------------------------------------------------

    DELETE FROM Tmp_JobsToFix;

    INSERT INTO Tmp_JobsToFix (job, step)
    SELECT job, step
    FROM sw.t_job_steps
    WHERE tool = 'MSGFPlus' AND
          state IN (6, 16) AND
          (completion_message LIKE '%Cannot run BuildSA since less than % MB of free memory%' OR
           completion_message LIKE '%Timeout expired%');

    If FOUND Then
        If _infoOnly Then

            RAISE INFO '';
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JS.Job,
                       JS.Dataset,
                       JS.Step,
                       JS.Script,
                       JS.Tool,
                       JS.State_name,
                       JS.State,
                       public.timestamp_text(JS.Start) As Start,
                       public.timestamp_text(JS.Finish) As Finish,
                       JS.Processor,
                       JS.Completion_Code,
                       JS.Completion_Message,
                       JS.Evaluation_Code,
                       JS.Evaluation_Message,
                       JS.Data_Pkg_ID
                FROM V_Job_Steps JS
                     INNER JOIN Tmp_JobsToFix F
                       ON JS.Job = F.Job AND
                          JS.Step = F.Step
                ORDER BY JS.Job, JS.Step
            LOOP
                _infoData := format(_formatSpecifier,
                                    'Change step state to 2 and clear the completion msg',
                                    _previewData.Job,
                                    _previewData.Dataset,
                                    _previewData.Step,
                                    _previewData.Script,
                                    _previewData.Tool,
                                    _previewData.State_name,
                                    _previewData.State,
                                    _previewData.Start,
                                    _previewData.Finish,
                                    _previewData.Processor,
                                    _previewData.Completion_Code,
                                    _previewData.Completion_Message,
                                    _previewData.Evaluation_Code,
                                    _previewData.Evaluation_Message,
                                    _previewData.Data_Pkg_ID
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else
            -- Clear the completion_message and update the step state

            UPDATE sw.t_job_steps Target
            SET state = 2,
                completion_message = '',
                tool_version_id = 1,        -- 1=Unknown
                next_try = CURRENT_TIMESTAMP,
                retry_count = 0,
                remote_info_id = 1,         -- 1=Unknown
                remote_timestamp = NULL,
                remote_start = NULL,
                remote_finish = NULL,
                remote_progress = NULL
            FROM Tmp_JobsToFix F
            WHERE Target.Job = F.Job AND
                  Target.Step = F.Step;

            -- Update the job to state 2 and remove the error message
            UPDATE public.t_analysis_job Target
            SET job_state_id = 2,
                comment = CASE WHEN Target.comment LIKE 'Auto predefined%' AND Position(';' In Target.comment) > 0
                                    THEN Substring(Target.comment, 1, Position(';' In Target.comment) - 1)
                               WHEN Target.comment LIKE 'Auto predefined%'
                                    THEN Target.comment
                               ELSE ''
                          END
            FROM Tmp_JobsToFix F
            WHERE Target.job = F.Job;

            -- Change the job state back to 'In Progress'

            UPDATE sw.t_jobs Target
            SET state = 2
            FROM Tmp_JobsToFix F
            WHERE Target.Job = F.Job;

        End If;
    End If;

    DROP TABLE Tmp_JobsToFix;
END
$$;


ALTER PROCEDURE sw.auto_fix_failed_jobs(INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_fix_failed_jobs(INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.auto_fix_failed_jobs(INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'AutoFixFailedJobs';


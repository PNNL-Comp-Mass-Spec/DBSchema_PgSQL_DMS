--
-- Name: update_analysis_job_state_name_cached_work(boolean, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_job_state_name_cached_work(IN _infoonly boolean DEFAULT false, INOUT _jobcountupdated integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update column state_name_cached in t_analysis_job for the jobs in temp table Tmp_JobsToUpdate
**
**      The calling procedure must create and populate temporary table Tmp_JobsToUpdate
**         CREATE TEMP TABLE Tmp_JobsToUpdate (
**            Job int NOT NULL
**          );
**
**  Arguments:
**    _infoOnly         When true, preview updates
**    _jobCountUpdated  Output: number of updated jobs
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   09/05/2024 mem - Initial version, using code refactored from update_analysis_job_state_name_cached
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly        := Coalesce(_infoOnly, false);
    _jobCountUpdated := 0;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview the jobs
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-32s %-32s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'State_Name_Cached',
                            'New_State_Name_Cached'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '--------------------------------',
                                     '--------------------------------'
                                    );

        If Exists (SELECT Job FROM Tmp_JobsToUpdate) Then
            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT AJ.Job,
                       AJ.State_Name_Cached,
                       Coalesce(AJDAS.Job_State, '') AS New_State_Name_Cached
                FROM t_analysis_job AJ INNER JOIN
                     V_Analysis_Job_and_Dataset_Archive_State AJDAS
                       ON AJ.job = AJDAS.job
                     INNER JOIN Tmp_JobsToUpdate U
                       ON AJ.job = U.job
                ORDER BY AJ.Job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.State_Name_Cached,
                                    _previewData.New_State_Name_Cached
                                   );

                RAISE INFO '%', _infoData;

                If _previewData.State_Name_Cached IS DISTINCT FROM _previewData.New_State_Name_Cached Then
                    _jobCountUpdated := _jobCountUpdated + 1;
                End If;
            END LOOP;

            RAISE INFO '';
        End If;

        If _jobCountUpdated = 0 Then
            _message := 'All jobs have up-to-date cached job state names';
        Else
            _message := format('Found %s %s to update',
                               _jobCountUpdated, public.check_plural(_jobCountUpdated, 'job', 'jobs'));
        End If;

        RAISE INFO '%', _message;

    ElsIf Exists (SELECT job FROM Tmp_JobsToUpdate) Then
        ---------------------------------------------------
        -- Update the jobs
        ---------------------------------------------------

        UPDATE t_analysis_job Target
        SET state_name_cached = Coalesce(AJDAS.Job_State, '')
        FROM V_Analysis_Job_and_Dataset_Archive_State AJDAS
        WHERE Target.job = AJDAS.Job AND
              Target.State_Name_Cached IS DISTINCT FROM Coalesce(AJDAS.Job_State, '') AND
              EXISTS (SELECT 1
                      FROM Tmp_JobsToUpdate Source
                      WHERE Target.job = Source.job);
        --
        GET DIAGNOSTICS _jobCountUpdated = ROW_COUNT;

        If _jobCountUpdated = 0 Then
            _message := '';
        Else
            _message := format('Updated the cached job state name for %s %s',
                               _jobCountUpdated, public.check_plural(_jobCountUpdated, 'job', 'jobs'));
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.update_analysis_job_state_name_cached_work(IN _infoonly boolean, INOUT _jobcountupdated integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


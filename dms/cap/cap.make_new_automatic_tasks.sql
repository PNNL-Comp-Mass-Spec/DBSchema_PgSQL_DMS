--
-- Name: make_new_automatic_tasks(boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_automatic_tasks(IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create new capture task jobs for capture tasks that are complete and have
**      scripts that have entries in the automatic capture task job creation table
**
**  Auth:   grk
**  Date:   09/11/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/26/2017 mem - Add support for column Enabled in T_Automatic_Jobs
**          01/29/2021 mem - Remove unused parameters
**          06/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    -- Find capture task jobs that are complete for which capture task jobs for the same script and dataset don't already exist

    -- In particular, after a DatasetArchive task finishes, create new SourceFileRename and MyEMSLVerify capture task jobs
    -- (since that relationship is defined in cap.t_automatic_jobs)

    If Coalesce(_infoOnly, false) Then
        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-40s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Script',
                            'Comment',
                            'Dataset'
                                );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '----------------------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT AJ.script_for_new_job AS Script,
                   T.dataset,
                   T.dataset_id,
                   format('Created from capture task job %s', T.Job) AS Comment
            FROM cap.t_tasks AS T
                 INNER JOIN cap.t_automatic_jobs AJ
                   ON T.Script = AJ.script_for_completed_job AND
                      AJ.enabled = 1
            WHERE T.State = 3 AND
                  NOT EXISTS ( SELECT *
                               FROM cap.t_tasks
                               WHERE script = script_for_new_job AND
                                     dataset = T.dataset )
            ORDER BY T.dataset, AJ.script_for_new_job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Script,
                                _previewData.Comment,
                                _previewData.Dataset
                            );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    INSERT INTO cap.t_tasks ( Script, Dataset, Dataset_ID, Comment )
    SELECT AJ.script_for_new_job AS Script,
           T.Dataset,
           T.Dataset_ID,
           format('Created from capture task job %s', T.Job) AS comment
    FROM cap.t_tasks AS T
         INNER JOIN cap.t_automatic_jobs AJ
           ON T.Script = AJ.script_for_completed_job AND
              AJ.enabled = 1
    WHERE T.State = 3 AND
          NOT EXISTS ( SELECT *
                       FROM cap.t_tasks
                       WHERE Script = script_for_new_job AND
                             Dataset = T.Dataset );

END
$$;


ALTER PROCEDURE cap.make_new_automatic_tasks(IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_automatic_tasks(IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_automatic_tasks(IN _infoonly boolean) IS 'MakeNewAutomaticTasks or MakeNewAutomaticJobs';


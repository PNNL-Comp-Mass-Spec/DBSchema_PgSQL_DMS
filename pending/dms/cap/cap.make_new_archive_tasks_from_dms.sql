--
CREATE OR REPLACE PROCEDURE cap.make_new_archive_tasks_from_dms
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add dataset archive tasks from DMS for datsets that are in archive 'New' state
**      and are not already in cap.t_tasks
**
**  Arguments:
**    _message                  Output message
**    _maxJobsToProcess         Maximum number of jobs to process
**    _logIntervalThreshold     If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled           Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _infoOnly                 True to preview changes that would be made
**
**  Auth:   grk
**  Date:   01/08/2010 grk - Initial release
**          10/24/2014 mem - Changed priority to 2 (since we want archive tasks to have priority over non-archive jobs)
**          09/17/2015 mem - Added parameter _infoOnly
**          06/13/2018 mem - Remove unused parameter _debugMode
**          06/27/2019 mem - Changed priority to 3 (since default capture task job priority is now 4)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _maxJobsToAddResetOrResume int;
    _startTime timestamp;
    _statusMessage text;

    _formatSpecifier text := '%-20s %-20s %-50s %-10s %-10s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    If _maxJobsToProcess <= 0 Then
        _maxJobsToAddResetOrResume := 1000000;
    Else
        _maxJobsToAddResetOrResume := _maxJobsToProcess;
    End If;

    _startTime := CURRENT_TIMESTAMP;
    _loggingEnabled := Coalesce(_loggingEnabled, false);
    _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);

    If _logIntervalThreshold = 0 Then
        _loggingEnabled := true;
    End If;

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Entering make_new_archive_tasks_from_dms';
        CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
    End If;

    ---------------------------------------------------
    -- Add new capture task jobs
    ---------------------------------------------------

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Querying DMS';
        CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
    End If;

    If Not _infoOnly Then
        INSERT INTO cap.t_tasks (Script,
                                 Comment,
                                 Dataset,
                                 Dataset_ID,
                                 Priority )
        SELECT 'DatasetArchive' AS Script,
               'Created by import from DMS' AS comment,
               Src.Dataset,
               Src.Dataset_ID,
               3 AS Priority
        FROM cap.V_DMS_Get_New_Archive_Datasets Src
             LEFT OUTER JOIN cap.t_tasks Target
               ON Src.Dataset_ID = Target.Dataset_ID AND
                  Target.Script = 'DatasetArchive'
        WHERE Target.Dataset_ID IS NULL

    Else
        -- Preview new jobs

        RAISE INFO ' ';

        _infoHead := format(_formatSpecifier,
                            'Script',
                            'Comment',
                            'Dataset',
                            'Dataset_ID',
                            'Priority'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                            '--------------------',
                            '--------------------',
                            '--------------------------------------------------',
                            '----------',
                            '----------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'DatasetArchive' AS Script,
                   'Created by import from DMS' AS Comment,
                   Src.Dataset,
                   Src.Dataset_ID,
                   3 AS Priority
            FROM cap.V_DMS_Get_New_Archive_Datasets Src
                 LEFT OUTER JOIN cap.t_tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID AND
                      Target.Script = 'DatasetArchive'
            WHERE Target.Dataset_ID IS NULL
        LOOP
            _infoData := format(_formatSpecifier,
                                    _previewData.Script,
                                    _previewData.Comment,
                                    _previewData.Dataset,
                                    _previewData.Dataset_ID,
                                    _previewData.Priority
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    End If;

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Exiting';
        CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
    End If;

END
$$;

COMMENT ON PROCEDURE cap.make_new_archive_tasks_from_dms IS 'MakeNewArchiveJobsFromDMS';

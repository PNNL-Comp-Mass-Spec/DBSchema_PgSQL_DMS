--
-- Name: make_new_archive_tasks_from_dms(text, text, boolean, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_archive_tasks_from_dms(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _loggingenabled boolean DEFAULT false, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add dataset archive tasks from DMS for datasets that are in archive 'New' state
**      and are not already in cap.t_tasks
**
**  Arguments:
**    _message              Output: status message
**    _returnCode           Output: return code
**    _loggingEnabled       Set to true to enable progress logging
**    _infoOnly             True to preview changes that would be made
**
**  Auth:   grk
**  Date:   01/08/2010 grk - Initial release
**          10/24/2014 mem - Changed priority to 2 (since we want archive tasks to have priority over non-archive jobs)
**          09/17/2015 mem - Added parameter _infoOnly
**          06/13/2018 mem - Remove unused parameter _debugMode
**          06/27/2019 mem - Changed priority to 3 (since default capture task job priority is now 4)
**          06/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _statusMessage text;

    _formatSpecifier text;
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

    _loggingEnabled := Coalesce(_loggingEnabled, false);

    If _loggingEnabled Then
        _statusMessage := 'Entering make_new_archive_tasks_from_dms';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
    End If;

    ---------------------------------------------------
    -- Add new capture task jobs
    ---------------------------------------------------

    If _loggingEnabled Then
        _statusMessage := 'Querying DMS';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
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
        WHERE Target.Dataset_ID IS NULL;

    Else
        -- Preview new jobs

        RAISE INFO '';

        _formatSpecifier := '%-14s %-26s %-10s %-8s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Script',
                            'Comment',
                            'Dataset_ID',
                            'Priority',
                            'Dataset'
                        );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------',
                                     '--------------------------',
                                     '----------',
                                     '--------',
                                     '--------------------------------------------------------------------------------'
                        );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'DatasetArchive' AS Script,
                   'Created by import from DMS' AS Comment,
                   Src.Dataset_ID,
                   3 AS Priority,
                   Src.Dataset
            FROM cap.V_DMS_Get_New_Archive_Datasets Src
                 LEFT OUTER JOIN cap.t_tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID AND
                      Target.Script = 'DatasetArchive'
            WHERE Target.Dataset_ID IS NULL
        LOOP
            _infoData := format(_formatSpecifier,
                                    _previewData.Script,
                                    _previewData.Comment,
                                    _previewData.Dataset_ID,
                                    _previewData.Priority,
                                    _previewData.Dataset
                            );

            RAISE INFO '%', _infoData;

        END LOOP;

    End If;

    If _loggingEnabled Then
        _statusMessage := 'Exiting';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Make_New_Archive_Tasks_From_DMS', 'cap');
    End If;

END
$$;


ALTER PROCEDURE cap.make_new_archive_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_archive_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_archive_tasks_from_dms(INOUT _message text, INOUT _returncode text, IN _loggingenabled boolean, IN _infoonly boolean) IS 'MakeNewArchiveTasksFromDMS or MakeNewArchiveJobsFromDMS';


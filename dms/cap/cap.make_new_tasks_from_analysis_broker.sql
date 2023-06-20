--
-- Name: make_new_tasks_from_analysis_broker(boolean, text, text, integer, boolean, integer, integer, boolean, integer); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_tasks_from_analysis_broker(IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _importwindowdays integer DEFAULT NULL::integer, IN _bypassdatasetarchive boolean DEFAULT NULL::boolean, IN _datasetidfiltermin integer DEFAULT NULL::integer, IN _datasetidfiltermax integer DEFAULT NULL::integer, IN _infoonlyshowsnewjobsonly boolean DEFAULT false, IN _timewindowtorequireexisingdatasetarchivejob integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create new ArchiveUpdate tasks for recently completed analysis job broker jobs (in sw.t_jobs)
**
**  Arguments:
**    _infoOnly                                     True to preview the capture task job that would be created
**    _message                                      Output: status message
**    _returnCode                                   Output: return code
**    _importWindowDays                             Default to 10 (via cap.t_default_sp_params)
**    _bypassDatasetArchive                         When true, waive the requirement that there be an existing complete dataset archive capture task job in broker; default to true (via cap.t_default_sp_params)
**    _datasetIDFilterMin                           If non-zero, will be used to filter the candidate datasets
**    _datasetIDFilterMax                           If non-zero, will be used to filter the candidate datasets
**    _infoOnlyShowsNewJobsOnly                     Set to true to only see new capture task jobs that would trigger new capture tasks; only used if _infoOnly is true
**    _timeWindowToRequireExisingDatasetArchiveJob  Default to 30 days (via cap.t_default_sp_params)
**
**  Auth:   grk
**  Date:   09/11/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/15/2010 dac - Changed default values of _bypassDatasetArchive amd _onlyDMSArchiveUpdateReqdDatasets (production DB only)
**          01/20/2010 mem - Added indices on Tmp_New_Jobs
**          01/21/2010 mem - Added parameters _datasetIDFilterMin and _datasetIDFilterMax
**          01/25/2010 dac - Changed default _onlyDMSArchiveUpdateReqdDatasets value to 0. Parameter no longer needed
**          01/28/2010 grk - Added time window for No_Dataset_Archive (only applies to recently completed capture task jobs)
**          02/02/2010 dac - Mods to get defaults input params from database table (in progress)
**          03/15/2010 mem - Now excluding rows from the source view where Input_Folder_Name is Null
**          06/04/2010 dac - Excluding rows where there are any existing capture task jobs that are not in state 3 (complete)
**          05/05/2011 mem - Removed _onlyDMSArchiveUpdateReqdDatasets since it was only required for a short while after we switched over to the DMS_Capture DB in January 2010
**                         - Now using cap.t_default_sp_params to get default input params from database table
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          06/19/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create a temporary table containing defaults for this SP
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Default_Params( param_name text, param_value text );

    INSERT INTO Tmp_Default_Params( param_name, param_value )
    SELECT param_name, param_value
    FROM cap.t_default_sp_params
    WHERE sp_name IN ('make_new_tasks_from_analysis_broker', 'MakeNewJobsFromAnalysisBroker');

    If Not Found Then
        _message := 'Table cap.t_default_sp_params does not have an entry for make_new_tasks_from_analysis_broker or MakeNewJobsFromAnalysisBroker';

        CALL public.post_log_entry('Error', _message, 'Make_New_Tasks_From_Analysis_Broker', 'cap');

        DROP TABLE Tmp_Default_Params;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check input params; replace with values from temp table if any are null
    -- Note that public.try_cast() will convert both '1' and 'true' to true
    ---------------------------------------------------

    -- _importWindowDays
    _importWindowDays := Coalesce(_importWindowDays, (SELECT public.try_cast(Param_Value, 10) FROM Tmp_Default_Params WHERE param_name = 'importWindowDays'));

    -- _bypassDatasetArchive
    _bypassDatasetArchive := Coalesce(_bypassDatasetArchive, (SELECT public.try_cast(Param_Value, true)  FROM Tmp_Default_Params WHERE param_name = 'bypassDatasetArchive'));

    -- _datasetIDFilterMin
    _datasetIDFilterMin := Coalesce(_datasetIDFilterMin, (SELECT public.try_cast(Param_Value, 0) FROM Tmp_Default_Params WHERE param_name = 'datasetIDFilterMin'));

    -- _datasetIDFilterMax
    _datasetIDFilterMax := Coalesce(_datasetIDFilterMax, (SELECT public.try_cast(Param_Value, 0) FROM Tmp_Default_Params WHERE param_name = 'datasetIDFilterMax'));

    -- _timeWindowToRequireExisingDatasetArchiveJob
    _timeWindowToRequireExisingDatasetArchiveJob := Coalesce(_timeWindowToRequireExisingDatasetArchiveJob, (SELECT public.try_cast(Param_Value, 30) FROM Tmp_Default_Params WHERE param_name = 'timeWindowToRequireExisingDatasetArchiveJob'));

    ---------------------------------------------------
    -- Create a temporary table to hold capture task jobs from the analysis broker
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_New_Jobs (
        Dataset text,
        Dataset_ID int,
        Results_Folder_Name text,
        Finish timestamp,
        No_Dataset_Archive boolean,
        Pending_Archive_Update boolean,
        Archive_Update_Current boolean
    );

    CREATE INDEX IX_Tmp_New_Jobs_Dataset_ID ON Tmp_New_Jobs (Dataset_ID);
    CREATE INDEX IX_Tmp_New_Jobs_Results_Folder ON Tmp_New_Jobs (Results_Folder_Name);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode := '';

    _importWindowDays := Abs(Coalesce(_importWindowDays, 10));
    If _importWindowDays < 1 Then
        _importWindowDays := 1;
    End If;

    _bypassDatasetArchive := Coalesce(_bypassDatasetArchive, true);
    _datasetIDFilterMin := Coalesce(_datasetIDFilterMin, 0);
    _datasetIDFilterMax := Coalesce(_datasetIDFilterMax, 0);
    _infoOnlyShowsNewJobsOnly := Coalesce(_infoOnlyShowsNewJobsOnly, false);

    _timeWindowToRequireExisingDatasetArchiveJob := Coalesce(_timeWindowToRequireExisingDatasetArchiveJob, 30);
    If _timeWindowToRequireExisingDatasetArchiveJob < 1 Then
        _timeWindowToRequireExisingDatasetArchiveJob := 1;
    End If;

    ---------------------------------------------------
    -- Get sucessfully completed results transfer steps
    -- from analysis broker with a completion date
    -- within the number of days in the import window
    ---------------------------------------------------

    INSERT INTO Tmp_New_Jobs (
        Dataset,
        Dataset_ID,
        Results_Folder_Name,
        Finish,
        No_Dataset_Archive,
        Pending_Archive_Update,
        Archive_Update_Current
    )
    SELECT Dataset,
           Dataset_ID,
           Input_Folder_Name,
           Finish,
           false AS No_Dataset_Archive,
           false AS Pending_Archive_Update,
           false AS Archive_Update_Current
    FROM cap.V_DMS_Pipeline_Get_Completed_Results_Transfer AS TS
    WHERE NOT Input_Folder_Name IS NULL AND
          Finish > CURRENT_TIMESTAMP - make_interval(days => _importWindowDays)
    ORDER BY Finish DESC;

    If _datasetIDFilterMin > 0 Then
        DELETE FROM Tmp_New_Jobs
        WHERE Dataset_ID < _datasetIDFilterMin;
    End If;

    If _datasetIDFilterMax > 0 Then
        DELETE FROM Tmp_New_Jobs
        WHERE Dataset_ID > _datasetIDFilterMax;
    End If;

    ---------------------------------------------------
    -- Find dataset archive tasks that have a recent finish time
    -- that falls within the _timeWindowToRequireExisingDatasetArchiveJob
    --
    -- For these, mark any for which there is not
    -- a completed DatasetArchive capture task job for the dataset
    --
    -- If _bypassDatasetArchive = true, the value of No_Dataset_Archive will be ignored
    ---------------------------------------------------

    UPDATE Tmp_New_Jobs
    SET No_Dataset_Archive = true
    WHERE Tmp_New_Jobs.Finish >= CURRENT_TIMESTAMP - make_interval(days => _timeWindowToRequireExisingDatasetArchiveJob) AND
          NOT EXISTS ( SELECT Dataset_ID
                       FROM cap.t_tasks
                       WHERE Script = 'DatasetArchive' AND
                             State = 3 AND
                             t_tasks.Dataset_ID = Tmp_New_Jobs.Dataset_ID
                     );

    ---------------------------------------------------
    -- Mark entries for which there is an existing ArchiveUpdate capture task job
    -- for the same results folder that has state <> 3
    ---------------------------------------------------

    UPDATE Tmp_New_Jobs
    SET Pending_Archive_Update = true
    WHERE EXISTS (
            SELECT Dataset
            FROM cap.t_tasks
            WHERE Script = 'ArchiveUpdate' AND
                  t_tasks.Dataset_ID = Tmp_New_Jobs.Dataset_ID AND
                  Coalesce(t_tasks.Results_Folder_Name, '') = Tmp_New_Jobs.Results_Folder_Name AND
                  State <> 3
          );

    ---------------------------------------------------
    -- Mark entries for which there is an existing ArchiveUpdate step
    -- for the same results folder that is complete
    -- with a finsh date later than the analysis broker
    -- job step's finish date
    ---------------------------------------------------

    UPDATE Tmp_New_Jobs
    SET Archive_Update_Current = true
    WHERE EXISTS (
            SELECT Dataset
            FROM cap.t_tasks
            WHERE Script = 'ArchiveUpdate' AND
                  t_tasks.Dataset_ID = Tmp_New_Jobs.Dataset_ID AND
                  Coalesce(t_tasks.Results_Folder_Name, '') = Tmp_New_Jobs.Results_Folder_Name AND
                  State = 3 AND
                  t_tasks.Finish > Tmp_New_Jobs.Finish
          );

    If _infoOnly Then
        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-24s %-24s %-21s %-80s';

        _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'No_Dataset_Archive',
                                'Pending_Archive_Update',
                                'Archive_Update_Current',
                                'Capture_Task_Needed',
                                'Dataset'
                            );

        _infoHeadSeparator := format(_formatSpecifier,
                                '----------',
                                '------------------',
                                '----------------------',
                                '----------------------',
                                '-------------------',
                                '--------------------------------------------------------------------------------'
                            );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   No_Dataset_Archive,
                   Pending_Archive_Update,
                   Archive_Update_Current,
                   Capture_Task_Needed,
                   Dataset
            FROM ( SELECT Dataset_ID,
                          No_Dataset_Archive,
                          Pending_Archive_Update,
                          Archive_Update_Current,
                          CASE
                              WHEN (No_Dataset_Archive = false OR _bypassDatasetArchive) AND
                                   Not Pending_Archive_Update AND
                                   Not Archive_Update_Current
                              THEN 'Yes'
                              ELSE 'No'
                          END AS Capture_Task_Needed,
                          Dataset
                   FROM Tmp_New_Jobs
                   ) LookupQ
            WHERE Not _infoOnlyShowsNewJobsOnly OR
                  Capture_Task_Needed = 'Yes'
            ORDER BY Dataset_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.No_Dataset_Archive,
                                    _previewData.Pending_Archive_Update,
                                    _previewData.Archive_Update_Current,
                                    _previewData.Capture_Task_Needed,
                                    _previewData.Dataset);

            RAISE INFO '%', _infoData;

        END LOOP;

    Else
        ---------------------------------------------------
        -- Create new ArchiveUpdate tasks from
        -- remaining imported
        -- analysis broker results transfer steps
        ---------------------------------------------------

        INSERT INTO cap.t_tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT DISTINCT 'ArchiveUpdate' AS Script,
                        Dataset,
                        Dataset_ID,
                        Results_Folder_Name,
                        'Created from broker import' AS Comment
        FROM Tmp_New_Jobs
        WHERE (No_Dataset_Archive = false OR _bypassDatasetArchive) AND
              Not Pending_Archive_Update AND
              Not Archive_Update_Current;

    End If;

    DROP TABLE Tmp_Default_Params;
    DROP TABLE Tmp_New_Jobs;
END
$$;


ALTER PROCEDURE cap.make_new_tasks_from_analysis_broker(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _importwindowdays integer, IN _bypassdatasetarchive boolean, IN _datasetidfiltermin integer, IN _datasetidfiltermax integer, IN _infoonlyshowsnewjobsonly boolean, IN _timewindowtorequireexisingdatasetarchivejob integer) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_tasks_from_analysis_broker(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _importwindowdays integer, IN _bypassdatasetarchive boolean, IN _datasetidfiltermin integer, IN _datasetidfiltermax integer, IN _infoonlyshowsnewjobsonly boolean, IN _timewindowtorequireexisingdatasetarchivejob integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_tasks_from_analysis_broker(IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _importwindowdays integer, IN _bypassdatasetarchive boolean, IN _datasetidfiltermin integer, IN _datasetidfiltermax integer, IN _infoonlyshowsnewjobsonly boolean, IN _timewindowtorequireexisingdatasetarchivejob integer) IS 'MakeNewTasksFromAnalysisBroker or MakeNewJobsFromAnalysisBroker';


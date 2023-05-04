--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_processor_group_associations
(
    _jobList text,
    _processorGroupID text,
    _newValue text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets jobs in the job list to be associated with the given analysis job processor group
**
**  Arguments:
**    _newValue   ignore for now, may need in future
**    _mode       'add', 'replace', 'remove'
**
**  Auth:   grk
**  Date:   02/15/2007 Ticket #386
**          02/20/2007 grk - fixed references to "Group" column in associations table
**                         - 'add' mode now removes association with any other groups
**          03/28/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          01/24/2014 mem - Added default values to three of the parameters
**          03/30/2015 mem - Tweak warning message grammar
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _list text;
    _alterEnteredByRequired boolean := false;
    _gid int;
    _jobCount int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _jobList = '' Then
        _message := 'Job list is empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve processor group ID
    ---------------------------------------------------
    _gid := CAST(_processorGroupID as int);
    --
/*
    SELECT group_id INTO _gid
    FROM t_analysis_job_processor_group
    WHERE (group_name = _processorGroupName)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    If _gid = 0 Then
        _myError := 5;
        _message := 'Processor group could not be found';
        return _myError
    End If;
*/
    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int
    )

    ---------------------------------------------------
    -- Populate table from job list
    ---------------------------------------------------

    INSERT INTO Tmp_JobList (Job)
    SELECT DISTINCT Item
    FROM public.parse_delimited_list(_jobList)

    ---------------------------------------------------
    -- Verify that all jobs exist
    ---------------------------------------------------
    --
    _list := '';
    --
    SELECT
        _list = _list + CASE
        WHEN _list = '' THEN cast(Job as text)
        ELSE ', ' || cast(Job as text)
        END
    FROM Tmp_JobList
    WHERE
        NOT job IN (SELECT job FROM t_analysis_job)

    If _list <> '' Then
        _message := 'The following jobs were not in the database: "' || _list || '"';
        _returnCode := 'U5202';
        RETURN;
    End If;

    _jobCount := 0;

    SELECT COUNT(*) INTO _jobCount
    FROM Tmp_JobList

    _message := 'Number of affected jobs: ' || cast(_jobCount as text);

    ---------------------------------------------------
    -- Get rid of existing associations if we are
    -- replacing them with jobs in list
    ---------------------------------------------------
    --
    If _mode = 'replace' Then
        DELETE FROM t_analysis_job_processor_group_associations
        WHERE (group_id = _gid);
    End If;

    ---------------------------------------------------
    -- Remove selected jobs from associations
    ---------------------------------------------------
    If _mode = 'remove' or _mode = 'add' Then
        DELETE FROM t_analysis_job_processor_group_associations
        WHERE job IN (SELECT job FROM Tmp_JobList);
            -- AND Group_ID = _gid  -- will need this in future if multiple associations allowed per job

    End If;

    ---------------------------------------------------
    -- Add associations for new jobs to list
    ---------------------------------------------------
    --
    If _mode = 'replace' or _mode = 'add' Then
        INSERT INTO t_analysis_job_processor_group_associations
            (job, group_id)
        SELECT job, _gid
        FROM Tmp_JobList

        _alterEnteredByRequired := true;
    End If;

    -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group_associations
    If char_length(_callingUser) > 0 And _alterEnteredByRequired Then
        -- Call public.alter_entered_by_user for each processor job in Tmp_JobList

        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        )

        CREATE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT Job
        FROM Tmp_JobList

        Call alter_entered_by_user_multi_id ('t_analysis_job_processor_group_associations', 'job', _callingUser);

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := _jobCount::text || ' jobs updated';
    Call post_usage_log_entry ('UpdateAnalysisJobProcessorGroupAssociations', _usageMessage);

    DROP TABLE Tmp_JobList;
    DROP TABLE Tmp_ID_Update_List;
END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_processor_group_associations IS 'UpdateAnalysisJobProcessorGroupAssociations';
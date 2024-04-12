--
-- Name: update_analysis_job_processor_group_associations(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_job_processor_group_associations(IN _joblist text, IN _processorgroupid text, IN _newvalue text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update analysis jobs in the job list to be associated with the given analysis job processor group
**
**      Note: when mode is 'replace', all jobs are removed from the given processor group, prior to adding the jobs in _jobList
**
**  Arguments:
**    _jobList              Comma-separated list of job numbers
**    _processorGroupID     Processor group ID (as text)
**    _newValue             Ignore for now, may need in future
**    _mode                 Mode: 'add', 'replace', 'remove'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   02/15/2007 grk - Ticket #386
**          02/20/2007 grk - Fixed references to "Group" column in associations table
**                         - 'add' mode now removes association with any other groups
**          03/28/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          01/24/2014 mem - Added default values to three of the parameters
**          03/30/2015 mem - Tweak warning message grammar
**          02/25/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _alterEnteredByRequired boolean := false;
    _groupID int;
    _jobCount int;
    _updateCount int;
    _usageMessage text;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _jobList           := Trim(Coalesce(_jobList, ''));
    _processorGroupID  := Trim(Coalesce(_processorGroupID, ''));
    _newValue          := Trim(Coalesce(_newValue, ''));
    _mode              := Trim(Lower(Coalesce(_mode, '')));

    If _jobList = '' Then
        _message := 'Job list must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not _mode In ('add', 'replace', 'remove') Then
        _message := format('"%s" is an invalid mode; it should be "add", "replace", or "remove"', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve processor group ID
    ---------------------------------------------------

    _groupID := public.try_cast(_processorGroupID, 0);

/*
    SELECT group_id
    INTO _groupID
    FROM t_analysis_job_processor_group
    WHERE (group_name = _processorGroupName);

    If Not FOUND Then
        _message := 'Processor group could not be found';
        _returnCode := 'U5203';
        RETURN;
    End If;
*/
    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int
    );

    ---------------------------------------------------
    -- Populate table from job list
    ---------------------------------------------------

    INSERT INTO Tmp_Jobs (Job)
    SELECT DISTINCT Value
    FROM public.parse_delimited_integer_list(_jobList);

    ---------------------------------------------------
    -- Verify that all jobs exist
    ---------------------------------------------------

    SELECT string_agg(Job::text, ', ' ORDER BY Job)
    INTO _list
    FROM Tmp_Jobs
    WHERE NOT job IN (SELECT job FROM t_analysis_job);

    If _list <> '' Then
        If Position(',' In _list) > 0 Then
            _message := format('The following jobs do not exist: %s', _list);
        Else
            _message := format('Job %s does not exist', _list);
        End If;

        _returnCode := 'U5204';

        DROP TABLE Tmp_Jobs;
        RETURN;
    End If;

    SELECT COUNT(*)
    INTO _jobCount
    FROM Tmp_Jobs;

    _message := format('Number of affected jobs: %s', _jobCount);

    ---------------------------------------------------
    -- Get rid of existing associations if we are replacing them with jobs in list
    ---------------------------------------------------

    If _mode = 'replace' And _groupID > 0 Then
        DELETE FROM t_analysis_job_processor_group_associations
        WHERE group_id = _groupID;
    End If;

    ---------------------------------------------------
    -- Remove selected jobs from associations
    ---------------------------------------------------

    If _mode In ('remove', 'add') Then
        DELETE FROM t_analysis_job_processor_group_associations
        WHERE job IN (SELECT job FROM Tmp_Jobs);
              -- AND Group_ID = _groupID      -- This would be needed if multiple associations were allowed per job
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        /*
            -- Alternative delete query
            DELETE FROM t_analysis_job_processor_group_associations target
            WHERE NOT EXISTS (SELECT source.job
                              FROM Tmp_Jobs source
                              WHERE target.job = source.job);
        */

        If _groupID <= 0 Then
            RAISE INFO 'Removed the associated processor group from % %',
                           _updateCount,
                           public.check_plural(_updateCount, 'job', 'jobs');

        ElsIf _mode = 'remove' And _updateCount > 0 Then
            RAISE INFO 'Removed % % from group %',
                           _updateCount,
                           public.check_plural(_updateCount, 'job', 'jobs'),
                          _groupID;
        End If;
    End If;

    ---------------------------------------------------
    -- Add associations for new jobs to list
    ---------------------------------------------------

    If _mode In ('replace', 'add') And _groupID > 0 Then
        INSERT INTO t_analysis_job_processor_group_associations (job, group_id)
        SELECT job, _groupID
        FROM Tmp_Jobs;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Associated % % with group %',
                       _updateCount,
                       public.check_plural(_updateCount, 'job', 'jobs'),
                       _groupID;

        _alterEnteredByRequired := true;
    End If;

    -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group_associations
    If char_length(Coalesce(_callingUser, '')) > 0 And _alterEnteredByRequired Then
        -- Call public.alter_entered_by_user for each processor job in Tmp_Jobs

        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT Job
        FROM Tmp_Jobs;

        CALL public.alter_entered_by_user_multi_id ('public', 't_analysis_job_processor_group_associations', 'job', _callingUser, _message => _alterEnteredByMessage);

        DROP TABLE Tmp_ID_Update_List;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('%s %s updated', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));
    CALL post_usage_log_entry ('update_analysis_job_processor_group_associations', _usageMessage);

    DROP TABLE Tmp_Jobs;
END
$$;


ALTER PROCEDURE public.update_analysis_job_processor_group_associations(IN _joblist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_job_processor_group_associations(IN _joblist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_job_processor_group_associations(IN _joblist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateAnalysisJobProcessorGroupAssociations';


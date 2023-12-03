--
CREATE OR REPLACE PROCEDURE public.update_analysis_job_processor_group_membership
(
    _processorNameList text,
    _processorGroupID text,
    _newValue text,
    _mode text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates analysis job processor group membership for the specified group for the processors in the list according to the mode
**
**  Arguments:
**    _processorNameList    Comma-separated list of processor names
**    _processorGroupID     Processor group ID
**    _newValue             New value: 'Y' or 'N' (only used when _mode is 'set_membership_enabled')
**    _mode                 Mode: 'set_membership_enabled', 'add_processors', 'remove_processors',
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   grk
**  Date:   02/13/2007 (Ticket #384)
**          02/20/2007 grk - Fixed reference to group ID
**          02/12/2008 grk - Modified temp table Tmp_Processors to have explicit NULL columns for DMS2 upgrade
**          03/28/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          03/30/2015 mem - Tweak warning message grammar
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _alterEnteredByRequired boolean := false;
    _pgid int;
    _localMembership text;
    _nonLocalMembership text;
    _usageMessage text;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _processorNameList = '' and _mode <> 'add_processors' Then
        _message := 'Processor name list was empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _processorGroupID = '' Then
        _message := 'Processor group name was empty';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create temporary table to hold list of processors
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Processors (
        ID int NULL,
        Processor_Name text
    );

    ---------------------------------------------------
    -- Populate table from processor list
    ---------------------------------------------------

    INSERT INTO Tmp_Processors (Processor_Name)
    SELECT DISTINCT Value
    FROM public.parse_delimited_list(_processorNameList);

    ---------------------------------------------------
    -- Resolve processor names to IDs
    ---------------------------------------------------

    UPDATE Tmp_Processors
    SET ID = AJP.ID
    FROM t_analysis_job_processors AJP
    WHERE Tmp_Processors.processor_name = AJP.processor_name;

    ---------------------------------------------------
    -- Verify that all processors exist
    ---------------------------------------------------

    SELECT string_agg(Processor_Name, ', ' ORDER BY Processor_Name)
    INTO _list
    FROM Tmp_Processors
    WHERE ID is null;

    If _list <> '' Then
        _message := format('The following processors were not in the database: "%s"', _list);
        _returnCode := 'U5203';
        RETURN;
    End If;

    _pgid := CAST(_processorGroupID As int);

    ---------------------------------------------------
    -- Mode set_membership_enabled
    ---------------------------------------------------

    If _mode Like 'set_membership_enabled_%' Then
        -- Get membership enabled value for this group
        --
        _localMembership := Replace (_mode, 'set_membership_enabled_' , '' );

        -- Get membership enabled value for groups other than this group
        --
        _nonLocalMembership := _newValue;

        -- Set memebership enabled value in this group

        UPDATE t_analysis_job_processor_group_membership
        SET membership_enabled = _localMembership
        WHERE group_id = _pgid AND processor_id IN (SELECT ID FROM Tmp_Processors);

        If _nonLocalMembership <> '' Then
            -- Set membership enabled value in groups other than this group

            UPDATE t_analysis_job_processor_group_membership
            SET membership_enabled = _nonLocalMembership
            WHERE group_id <> _pgid AND processor_id IN (SELECT ID FROM Tmp_Processors);

        End If;

        _alterEnteredByRequired := true;
    End If;

/*
    -- If mode is 'set_membership_enabled', set Membership_Enabled column for member processors in _processorNameList to the value of _newValue

    If _mode = 'set_membership_enabled' Then
        UPDATE t_analysis_job_processor_group_membership
        SET membership_enabled = _newValue
        WHERE group_id = _pgid AND processor_id IN (SELECT ID FROM Tmp_Processors)

    End If;
*/
    ---------------------------------------------------
    -- If mode is 'add_processors', add processors in _processorNameList to existing membership of group
    -- (be careful not to make duplicates)
    ---------------------------------------------------

    If _mode = 'add_processors' Then
        INSERT INTO t_analysis_job_processor_group_membership (processor_id, group_id)
        SELECT ID, _pgid
        FROM Tmp_Processors
        WHERE NOT Tmp_Processors.ID IN (
                        SELECT processor_id
                        FROM  t_analysis_job_processor_group_membership
                        WHERE group_id = _pgid
                    );

        _alterEnteredByRequired := true;
    End If;

    ---------------------------------------------------
    -- If mode is 'remove_processors', remove processors in _processorNameList from existing membership of group
    ---------------------------------------------------

    If _mode = 'remove_processors' Then
        DELETE FROM t_analysis_job_processor_group_membership
        WHERE
            group_id = _pgid AND
            (processor_id IN (SELECT ID FROM  Tmp_Processors))
    End If;

    -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group
    --
    If char_length(_callingUser) > 0 And _alterEnteredByRequired Then
        -- Call public.alter_entered_by_user for each processor ID in Tmp_Processors

        -- If the mode was 'add_processors', this will possibly match some rows that
        -- were previously present in the table.  However, those rows should be excluded since
        -- the Last_Affected time will have changed more than 5 seconds ago (defined using _entryTimeWindowSeconds below)

        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT ID
        FROM Tmp_Processors;

        CALL public.alter_entered_by_user_multi_id ('public', 't_analysis_job_processor_group_membership', 'processor_id', _callingUser,
                                                    _entryTimeWindowSeconds => 5, _entryDateColumnName => 'last_affected', _message => _alterEnteredByMessage);

        DROP TABLE Tmp_ID_Update_List;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Processor group: %s', _pgid);
    CALL post_usage_log_entry ('update_analysis_job_processor_group_membership', _usageMessage);

    DROP TABLE Tmp_Processors;
END
$$;

COMMENT ON PROCEDURE public.update_analysis_job_processor_group_membership IS 'UpdateAnalysisJobProcessorGroupMembership';

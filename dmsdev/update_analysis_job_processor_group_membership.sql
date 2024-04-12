--
-- Name: update_analysis_job_processor_group_membership(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_analysis_job_processor_group_membership(IN _processornamelist text, IN _processorgroupid text, IN _newvalue text, IN _mode text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update analysis job processor group membership for the specified group for the processors in the list according to the mode
**
**  Arguments:
**    _processorNameList    Comma-separated list of processor names
**    _processorGroupID     Processor group ID (as text)
**    _newValue             New membership value for processors not associated with the given processor group
**                          (only used when _mode is 'set_membership_enabled_y' or 'set_membership_enabled_n')
**                          Allowed values: 'Y', 'N', or ''
**    _mode                 Mode: 'set_membership_enabled_y', 'set_membership_enabled_n', 'add_processors', 'remove_processors'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   02/13/2007 grk - Ticket #384
**          02/20/2007 grk - Fixed reference to group ID
**          02/12/2008 grk - Modified temp table Tmp_Processors to have explicit NULL columns for DMS2 upgrade
**          03/28/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          03/30/2015 mem - Tweak warning message grammar
**          02/25/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _alterEnteredByRequired boolean := false;
    _groupID int;
    _localMembership text;
    _nonLocalMembership text;
    _updateCount int;
    _usageMessage text;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _processorNameList := Trim(Coalesce(_processorNameList, ''));
    _processorGroupID  := Trim(Coalesce(_processorGroupID, ''));
    _newValue          := Trim(Upper(Coalesce(_newValue, '')));
    _mode              := Trim(Lower(Coalesce(_mode, '')));

    If _processorNameList = '' And _mode <> 'add_processors' Then
        _message := 'Processor name list must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _processorGroupID = '' Then
        _message := 'Processor group name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Not _mode In ('set_membership_enabled_y', 'set_membership_enabled_n', 'add_processors', 'remove_processors') Then
        _message := format('"%s" is an invalid mode; it should be "set_membership_enabled_y", "set_membership_enabled_n", "add_processors", or "remove_processors"', _mode);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create temporary table to hold list of processors
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Processors (
        Processor_ID int NULL,
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
    SET Processor_ID = AJP.processor_id
    FROM t_analysis_job_processors AJP
    WHERE Tmp_Processors.processor_name = AJP.processor_name;

    ---------------------------------------------------
    -- Verify that all processors exist
    ---------------------------------------------------

    SELECT string_agg(Processor_Name, ', ' ORDER BY Processor_Name)
    INTO _list
    FROM Tmp_Processors
    WHERE Processor_ID IS NULL;

    If _list <> '' Then
        If Position(',' In _list) > 0 Then
            _message := format('The following processors do not exist: %s', _list);
        Else
            _message := format('Processor %s does not exist', _list);
        End If;

        RAISE WARNING '%', _message;
        _returnCode := 'U5204';

        DROP TABLE Tmp_Processors;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve processor group ID
    ---------------------------------------------------

    _groupID := public.try_cast(_processorGroupID, 0);

    ---------------------------------------------------
    -- Mode set_membership_enabled
    ---------------------------------------------------

    If _mode Like 'set_membership_enabled_%' And _groupID > 0 Then
        -- Get membership enabled value for this group

        _localMembership := Upper(Replace(_mode, 'set_membership_enabled_' , ''));

        If Not _localMembership IN ('Y', 'N') Then
            _message := format('Invalid mode "%s"; should be either "set_membership_enabled_y" or "set_membership_enabled_n"', _mode);

            RAISE WARNING '%', _message;
            _returnCode := 'U5205';

            DROP TABLE Tmp_Processors;
            RETURN;
        End If;

        -- Get membership enabled value for groups other than this group

        _nonLocalMembership := Upper(_newValue);

        If Not _nonLocalMembership IN ('Y', 'N', '') Then
            _message := format('"%s" is an invalid non-local membership value; _newValue should be "Y", "N", or ""', _newValue);

            RAISE WARNING '%', _message;
            _returnCode := 'U5206';

            DROP TABLE Tmp_Processors;
            RETURN;
        End If;

        -- Set membership enabled value in this group

        UPDATE t_analysis_job_processor_group_membership
        SET membership_enabled = _localMembership
        WHERE group_id = _groupID AND processor_id IN (SELECT Processor_ID FROM Tmp_Processors);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Set membership_enabled to "%" for % % associated with group %',
                       _localMembership,
                       _updateCount,
                       public.check_plural(_updateCount, 'processor', 'processors'),
                       _groupID;

        If _nonLocalMembership <> '' Then
            -- Set membership enabled value in groups other than this group

            UPDATE t_analysis_job_processor_group_membership
            SET membership_enabled = _nonLocalMembership
            WHERE group_id <> _groupID AND processor_id IN (SELECT Processor_ID FROM Tmp_Processors);
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            RAISE INFO 'Set membership_enabled to "%" for groups other than % for % %',
                           _nonLocalMembership,
                           _groupID,
                           _updateCount,
                           public.check_plural(_updateCount, 'processor', 'processors');

        End If;

        _alterEnteredByRequired := true;
    End If;

/*
    -- If mode is 'set_membership_enabled', set Membership_Enabled column for member processors in _processorNameList to the value of _newValue

    If _mode = 'set_membership_enabled' Then
        UPDATE t_analysis_job_processor_group_membership
        SET membership_enabled = _newValue
        WHERE group_id = _groupID AND processor_id IN (SELECT Processor_ID FROM Tmp_Processors)

    End If;
*/
    ---------------------------------------------------
    -- If mode is 'add_processors', add processors in _processorNameList to existing membership of group
    -- (be careful not to make duplicates)
    ---------------------------------------------------

    If _mode = 'add_processors' And _groupID > 0 Then
        INSERT INTO t_analysis_job_processor_group_membership (processor_id, group_id)
        SELECT Processor_ID, _groupID
        FROM Tmp_Processors
        WHERE NOT Tmp_Processors.Processor_ID IN (
                        SELECT processor_id
                        FROM t_analysis_job_processor_group_membership
                        WHERE group_id = _groupID
                    );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Associated % % with group %',
                       _updateCount,
                       public.check_plural(_updateCount, 'processor', 'processors'),
                       _groupID;

        _alterEnteredByRequired := true;
    End If;

    ---------------------------------------------------
    -- If mode is 'remove_processors', remove processors in _processorNameList from existing membership of group
    ---------------------------------------------------

    If _mode = 'remove_processors' And _groupID > 0 Then
        DELETE FROM t_analysis_job_processor_group_membership
        WHERE group_id = _groupID AND
              processor_id IN (SELECT Processor_ID FROM Tmp_Processors);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        RAISE INFO 'Removed % % from group %',
                       _updateCount,
                       public.check_plural(_updateCount, 'processor', 'processors'),
                       _groupID;
    End If;

    -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group

    If Trim(Coalesce(_callingUser, '')) <> '' And _alterEnteredByRequired Then
        -- Call public.alter_entered_by_user for each processor ID in Tmp_Processors

        -- If the mode was 'add_processors', this will possibly match some rows that
        -- were previously present in the table.  However, those rows should be excluded since
        -- the Last_Affected time will have changed more than 5 seconds ago (defined using _entryTimeWindowSeconds below)

        CREATE TEMP TABLE Tmp_ID_Update_List (
            TargetID int NOT NULL
        );

        CREATE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

        INSERT INTO Tmp_ID_Update_List (TargetID)
        SELECT Processor_ID
        FROM Tmp_Processors;

        CALL public.alter_entered_by_user_multi_id ('public', 't_analysis_job_processor_group_membership', 'processor_id', _callingUser,
                                                    _entryTimeWindowSeconds => 5, _entryDateColumnName => 'last_affected', _message => _alterEnteredByMessage);

        DROP TABLE Tmp_ID_Update_List;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Processor group: %s', _groupID);
    CALL post_usage_log_entry ('update_analysis_job_processor_group_membership', _usageMessage);

    DROP TABLE Tmp_Processors;
END
$$;


ALTER PROCEDURE public.update_analysis_job_processor_group_membership(IN _processornamelist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_analysis_job_processor_group_membership(IN _processornamelist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_analysis_job_processor_group_membership(IN _processornamelist text, IN _processorgroupid text, IN _newvalue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateAnalysisJobProcessorGroupMembership';


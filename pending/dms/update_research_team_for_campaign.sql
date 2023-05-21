--
CREATE OR REPLACE PROCEDURE public.update_research_team_for_campaign
(
    _campaignName text,
    _progmgrUsername text,
    _piUsername text,
    _technicalLead text,
    _samplePreparationStaff text,
    _datasetAcquisitionStaff text,
    _informaticsStaff text,
    _collaborators text,
    INOUT _researchTeamID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates membership of research team for given campaign
**
**  Arguments:
**    _campaignName              Campaign name (required if _researchTeamID is 0)
**    _progmgrUsername           Project Manager Username (required)
**    _piUsername                Principal Investigator Username (required)
**    _technicalLead             Technical Lead
**    _samplePreparationStaff    Sample Prep Staff
**    _datasetAcquisitionStaff   Dataset acquisition staff
**    _informaticsStaff          Informatics staff
**    _collaborators             Collaborators
**
**  Auth:   grk
**  Date:   02/05/2010 grk - Initial version
**          02/07/2010 mem - Added code to try to auto-resolve cases where a team member's name was entered instead of a username (PRN)
**                         - Since a Like clause is used, % characters in the name will be treated as wildcards
**                         - However, 'anderson, gordon' will be split into two entries: 'anderson' and 'gordon' when parse_delimited_list() is called
**                         - Thus, use 'anderson%gordon' to match the 'anderson, gordon' entry in T_Users
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/22/2017 mem - Validate _campaignName
**          08/20/2021 mem - Use Select Distinct to avoid duplicates
**          02/17/2022 mem - Update error message and convert tabs to spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _entryID int;
    _matchCount int;
    _unknownUsername text;
    _newUsername text;
    _newUserID int;
    _list text := '';
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _campaignName := Coalesce(_campaignName, '');

    ---------------------------------------------------
    -- Make new research team if ID is 0
    ---------------------------------------------------

    If _researchTeamID = 0 Then
        If _campaignName = '' Then
            _returnCode := 'U5102';
            _message := 'Campaign name is blank; cannot create a new research team';
            RETURN;
        End If;

        INSERT INTO t_research_team (
            team,
            description,
            collaborators
        ) VALUES (
            _campaignName,
            'Research team for campaign ' || _campaignName,
            _collaborators
        )
        RETURNING team_id
        INTO _researchTeamID;

    Else
        -- Update Collaborators

        UPDATE t_research_team
        SET collaborators = _collaborators
        WHERE team_id = _researchTeamID;

    End If;

    If _researchTeamID = 0 Then
        _message := 'Research team ID was not valid';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Temp table to hold new membership for team
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_TeamMembers (
        Username text,
        Role text,
        Role_ID int null,
        USER_ID int null,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    )

    ---------------------------------------------------
    -- Populate temp membership table from lists
    ---------------------------------------------------
    --
    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'Project Mgr' AS Role
    FROM public.parse_delimited_list(_progmgrUsername) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'PI' AS Role
    FROM public.parse_delimited_list(_piUsername) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'Technical Lead' AS Role
    FROM public.parse_delimited_list(_technicalLead) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'Sample Preparation' AS Role
    FROM public.parse_delimited_list(_samplePreparationStaff) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'Dataset Acquisition' AS Role
    FROM public.parse_delimited_list(_datasetAcquisitionStaff) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Item AS Username, 'Informatics' AS Role
    FROM public.parse_delimited_list(_informaticsStaff) AS member

    ---------------------------------------------------
    -- Resolve user username and role to respective IDs
    ---------------------------------------------------
    --
    UPDATE Tmp_TeamMembers
    SET user_id = t_users.user_id
    FROM t_users
    WHERE Tmp_TeamMembers.Username = t_users.username;

    UPDATE Tmp_TeamMembers
    SET role_id = t_research_team_roles.role_id
    FROM t_research_team_roles
    WHERE t_research_team_roles.role = Tmp_TeamMembers.role;

    UPDATE Tmp_TeamMembers
    SET role_id = t_research_team_roles.role_id
    FROM t_research_team_roles
    WHERE t_research_team_roles.role = Tmp_TeamMembers.role;

    ---------------------------------------------------
    -- Look for entries in Tmp_TeamMembers where Username did not resolve to a user_id
    -- In case a name was entered (instead of a username), try-to auto-resolve using the name column in t_users
    ---------------------------------------------------

    _entryID := 0;

    WHILE true
    LOOP
        -- This While loop can probably be converted to a For loop; for example:
        --    FOR _itemName IN
        --        SELECT item_name
        --        FROM TmpSourceTable
        --        ORDER BY entry_id
        --    LOOP
        --        ...
        --    END LOOP;

        SELECT EntryID,
               Username
        INTO _entryID, _unknownUsername
        FROM Tmp_TeamMembers
        WHERE EntryID > _entryID AND USER_ID IS NULL
        ORDER BY EntryID
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        _matchCount := 0;

        CALL auto_resolve_name_to_username (_unknownUsername, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

        If _matchCount = 1 Then
            -- Single match was found; update Username in Tmp_TeamMembers
            UPDATE Tmp_TeamMembers
            SET Username = _newUsername,
                User_ID = _newUserID
            WHERE EntryID = _entryID

        End If;

    END LOOP;

    ---------------------------------------------------
    -- Error if any username or role did not resolve to ID
    ---------------------------------------------------
    --
    --
    SELECT string_agg(Username, ', ' ORDER BY Username)
    INTO _list
    FROM Tmp_TeamMembers
    WHERE USER_ID IS NULL

    If _list <> '' Then
        _message := 'Could not resolve following usernames (or last names) to user ID: ' || _list;
        _returnCode := 'U5201';
        RETURN;
    End If;

    SELECT string_agg(Role, ', ' ORDER BY Role)
    INTO _list
    FROM ( SELECT DISTINCT Role
           FROM Tmp_TeamMembers
           WHERE Role_ID IS NULL ) LookupQ;

    If _list <> '' Then
        _message := 'Unknown role names: ' || _list;
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Clean out any existing membership
    ---------------------------------------------------
    --
    DELETE FROM t_research_team_membership
    WHERE team_id = _researchTeamID AND
          role_id BETWEEN 1 AND 6;       -- Restrict to roles that are editable via campaign

    ---------------------------------------------------
    -- Replace with new membership
    ---------------------------------------------------
    --
    INSERT INTO t_research_team_membership( team_id,
                                            role_id,
                                            user_id )
    SELECT DISTINCT _researchTeamID,
           role_id,
           user_id
    FROM Tmp_TeamMembers;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Campaign: ' || _campaignName;

    CALL post_usage_log_entry ('Update_Research_Team_For_Campaign', _usageMessage);

    DROP TABLE Tmp_TeamMembers;
END
$$;

COMMENT ON PROCEDURE public.update_research_team_for_campaign IS 'UpdateResearchTeamForCampaign';

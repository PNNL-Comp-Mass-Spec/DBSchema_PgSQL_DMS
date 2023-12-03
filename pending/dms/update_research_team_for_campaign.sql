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
**    _campaignName             Campaign name (required if _researchTeamID is 0)
**    _progmgrUsername          Project Manager Username (required)
**    _piUsername               Principal Investigator Username (required)
**    _technicalLead            Technical Lead
**    _samplePreparationStaff   Sample Prep Staff
**    _datasetAcquisitionStaff  Dataset acquisition staff
**    _informaticsStaff         Informatics staff
**    _collaborators            Collaborators
**    _researchTeamID           Output: research team ID
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   02/05/2010 grk - Initial version
**          02/07/2010 mem - Added code to try to auto-resolve cases where a team member's name was entered instead of a username (PRN)
**                         - Since a Like clause is used, % characters in the name will be treated as wildcards
**                         - However, 'anderson, gordon' will be split into two entries: 'anderson' and 'gordon' when parse_delimited_list() is called
**                         - Thus, use 'anderson%gordon' to match the 'anderson, gordon' entry in T_Users
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/22/2017 mem - Validate _campaignName
**          08/20/2021 mem - Use Select Distinct to avoid duplicates
**          02/17/2022 mem - Update error message and convert tabs to spaces
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
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
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _campaignName := Trim(Coalesce(_campaignName, ''));

    ---------------------------------------------------
    -- Make new research team if ID is 0
    ---------------------------------------------------

    If _researchTeamID = 0 Then
        If _campaignName = '' Then
            _returnCode := 'U5102';
            _message := 'Campaign name was not specified; cannot create a new research team';
            RETURN;
        End If;

        INSERT INTO t_research_team( team,
                                     description,
                                     collaborators )
        ) VALUES (
            _campaignName,
            format('Research team for campaign %s', _campaignName),
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

    CREATE TEMP TABLE Tmp_TeamMembers (
        Username text,
        Role text,
        Role_ID int null,
        User_ID int null,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    )

    ---------------------------------------------------
    -- Populate temp membership table from lists
    ---------------------------------------------------

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'Project Mgr' AS Role
    FROM public.parse_delimited_list(_progmgrUsername) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'PI' AS Role
    FROM public.parse_delimited_list(_piUsername) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'Technical Lead' AS Role
    FROM public.parse_delimited_list(_technicalLead) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'Sample Preparation' AS Role
    FROM public.parse_delimited_list(_samplePreparationStaff) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'Dataset Acquisition' AS Role
    FROM public.parse_delimited_list(_datasetAcquisitionStaff) AS member

    INSERT INTO Tmp_TeamMembers ( Username, Role )
    SELECT DISTINCT Value AS Username, 'Informatics' AS Role
    FROM public.parse_delimited_list(_informaticsStaff) AS member

    ---------------------------------------------------
    -- Resolve user username and role to respective IDs
    ---------------------------------------------------

    UPDATE Tmp_TeamMembers
    SET User_ID = t_users.user_id
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

    FOR _entryID, _unknownUsername IN
        SELECT EntryID, Username
        INTO _unknownUsername
        FROM Tmp_TeamMembers
        WHERE User_ID IS NULL
        ORDER BY EntryID
    LOOP

        CALL public.auto_resolve_name_to_username (
                        _unknownUsername,
                        _matchCount       => _matchCount,   -- Output
                        _matchingUsername => _newUsername,  -- Output
                        _matchingUserID   => _userID);      -- Output

        If _matchCount = 1 Then
            -- Single match was found; update Username in Tmp_TeamMembers
            UPDATE Tmp_TeamMembers
            SET Username = _newUsername,
                User_ID = _newUserID
            WHERE EntryID = _entryID;

        End If;

    END LOOP;

    ---------------------------------------------------
    -- Error if any username or role did not resolve to ID
    ---------------------------------------------------

    --
    SELECT string_agg(Username, ', ' ORDER BY Username)
    INTO _list
    FROM Tmp_TeamMembers
    WHERE User_ID IS NULL

    If _list <> '' Then
        _message := format('Could not resolve following usernames (or last names) to user ID: %s', _list);
        _returnCode := 'U5201';
        RETURN;
    End If;

    SELECT string_agg(Role, ', ' ORDER BY Role)
    INTO _list
    FROM ( SELECT DISTINCT Role
           FROM Tmp_TeamMembers
           WHERE Role_ID IS NULL ) LookupQ;

    If _list <> '' Then
        _message := format('Unknown role names: %s', _list);
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Clean out any existing membership
    ---------------------------------------------------

    DELETE FROM t_research_team_membership
    WHERE team_id = _researchTeamID AND
          role_id BETWEEN 1 AND 6;       -- Restrict to roles that are editable via campaign

    ---------------------------------------------------
    -- Replace with new membership
    ---------------------------------------------------

    INSERT INTO t_research_team_membership( team_id,
                                            role_id,
                                            user_id )
    SELECT DISTINCT _researchTeamID,
           Role_ID,
           User_ID
    FROM Tmp_TeamMembers;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Campaign: %s', _campaignName);

    CALL post_usage_log_entry ('update_research_team_for_campaign', _usageMessage);

    DROP TABLE Tmp_TeamMembers;
END
$$;

COMMENT ON PROCEDURE public.update_research_team_for_campaign IS 'UpdateResearchTeamForCampaign';

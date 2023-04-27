--
CREATE OR REPLACE PROCEDURE public.update_research_team_observer
(
    _campaignName text,
    _mode text = 'add',
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Sets user registration for notification entities
**
**  Arguments:
**    _mode     'add' or 'remove'
**
**  Auth:   grk
**  Date:   04/03/2010
**          04/03/2010 grk - initial release
**          04/04/2010 grk - callable as operatons_sproc
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/20/2021 mem - Reformat queries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _observerRoleID int := 10;
    _username text := @callingUser;
    _campaignID int := 0;
    _researchTeamID int := 0;
    _userID int := 0;
    _membershipExists int;
    _usageMessage text := '';
BEGIN
    _message := '';

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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- User id
    ---------------------------------------------------
    --
    If _callingUser = '' Then
        _returnCode := 'U5101';
        _message := 'User ID is missing';
        RETURN;
    End If;
    --

    ---------------------------------------------------
    -- Resolve
    ---------------------------------------------------
    --
    --
    --
    SELECT campaign_id, INTO _campaignID
           _researchTeamID = Coalesce(research_team, 0)
    FROM t_campaign
    WHERE campaign = _campaignName

    --
    If _campaignID = 0 Then
        _returnCode := 'U5102';
        _message := 'Campaign "' || _campaignName || '" is not valid';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve
    ---------------------------------------------------
    --
    --
    SELECT user_id INTO _userID
    FROM t_users
    WHERE username = _username
    --
    If _userID = 0 Then
        _returnCode := 'U5103';
        _message := 'User "' || _username || '" is not valid';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is user already an observer?
    ---------------------------------------------------
    --
    --
    SELECT COUNT(*) INTO _membershipExists
    FROM t_research_team_membership
    WHERE team_id = _researchTeamID AND
          role_id = _observerRoleID AND
          user_id = _userID

    ---------------------------------------------------
    -- Add / update the user
    ---------------------------------------------------
    --
    If _membershipExists > 0 AND _mode = 'remove' Then
        DELETE FROM t_research_team_membership
        WHERE team_id = _researchTeamID AND
              role_id = _observerRoleID AND
              user_id = _userID
    End If;

    If _membershipExists = 0 AND _mode = 'add' Then
      INSERT INTO t_research_team_membership( team_id,
                                                  role_id,
                                                  user_id )
      VALUES(_researchTeamID, _observerRoleID, _userID)
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Campaign: ' || _campaignName || '; user: ' || _username || '; mode: ' || _mode;
    Call post_usage_log_entry ('UpdateResearchTeamObserver', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_research_team_observer IS 'UpdateResearchTeamObserver';

--
CREATE OR REPLACE PROCEDURE public.update_research_team_observer
(
    _campaignName text,
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
**      Sets user registration for notification entities
**
**  Arguments:
**    _mode     'add' or 'remove'
**
**  Auth:   grk
**  Date:   04/03/2010
**          04/03/2010 grk - Initial release
**          04/04/2010 grk - Callable as operatons_sproc
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/20/2021 mem - Reformat queries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _observerRoleID int := 10;
    _username text;
    _campaignID int := 0;
    _researchTeamID int := 0;
    _userID int := 0;
    _membershipExists int;
    _usageMessage text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- User id
    ---------------------------------------------------
    --
    If _callingUser = '' Then
        _returnCode := 'U5201';
        _message := 'User ID is missing';
        RETURN;
    End If;

    _username := _callingUser;

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
        _returnCode := 'U5202';
        _message := format('Campaign "%s" is not valid', _campaignName);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve
    ---------------------------------------------------
    --
    --
    SELECT user_id
    INTO _userID
    FROM t_users
    WHERE username = _username;

    If Not FOUND Then
        _returnCode := 'U5203';
        _message := format('User "%s" is not valid', _username);
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

    _usageMessage := format('Campaign: %s; user: %s; mode: %s',
                            _campaignName, _username, _mode);

    CALL post_usage_log_entry ('Update_Research_Team_Observer', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_research_team_observer IS 'UpdateResearchTeamObserver';

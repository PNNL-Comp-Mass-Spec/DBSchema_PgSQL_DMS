--
-- Name: update_research_team_observer(text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_research_team_observer(IN _campaignname text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**     Add or remove user _callingUser as a research team observer on a campaign
**
**  Arguments:
**    _campaignName     Campaign name
**    _mode             Mode: 'add' or 'remove'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the user to add/remove
**
**  Auth:   grk
**  Date:   04/03/2010
**          04/03/2010 grk - Initial version
**          04/04/2010 grk - Callable as operatons_sproc
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/20/2021 mem - Reformat queries
**          03/07/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _observerRoleID int := 10;
    _username text;
    _campaignID int := 0;
    _researchTeamID int := 0;
    _userID int := 0;
    _membershipExists boolean;
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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _campaignName := Trim(Coalesce(_campaignName, ''));
    _callingUser  := Trim(Coalesce(_callingUser, ''));
    _mode         := Trim(Lower(Coalesce(_mode, '')));

    If _campaignName = '' Then
        _message := 'Campaign name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _callingUser = '' Then
        _message := 'Username must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    Else
        _username := _callingUser;
    End If;

    ---------------------------------------------------
    -- Resolve campaign name to ID
    ---------------------------------------------------

    SELECT campaign_id,
           Coalesce(research_team, 0)
    INTO _campaignID, _researchTeamID
    FROM t_campaign
    WHERE campaign = _campaignName::citext;

    If Not FOUND Then
         _message := format('Unrecognized campaign name: %s', _campaignName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve username to ID
    ---------------------------------------------------

    SELECT user_id
    INTO _userID
    FROM t_users
    WHERE username = _username::citext;

    If Not FOUND Then
         _message := format('Unrecognized username: %s', _username);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is user already an observer?
    ---------------------------------------------------

    If Exists (SELECT user_id
               FROM t_research_team_membership
               WHERE team_id = _researchTeamID AND
                     role_id = _observerRoleID AND
                     user_id = _userID)
    Then
        _membershipExists := true;
    Else
        _membershipExists := false;
    End If;

    ---------------------------------------------------
    -- Add / update the user
    ---------------------------------------------------

    If _mode = 'add' And Not _membershipExists Then
        INSERT INTO t_research_team_membership (team_id, role_id, user_id)
        VALUES (_researchTeamID, _observerRoleID, _userID);
    End If;

    If _mode = 'remove' And _membershipExists Then
        DELETE FROM t_research_team_membership
        WHERE team_id = _researchTeamID AND
              role_id = _observerRoleID AND
              user_id = _userID;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := format('Campaign: %s; user: %s; mode: %s',
                            _campaignName, _username, _mode);

    CALL post_usage_log_entry ('update_research_team_observer', _usageMessage);

END
$$;


ALTER PROCEDURE public.update_research_team_observer(IN _campaignname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_research_team_observer(IN _campaignname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_research_team_observer(IN _campaignname text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateResearchTeamObserver';


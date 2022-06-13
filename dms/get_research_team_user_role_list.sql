--
-- Name: get_research_team_user_role_list(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_research_team_user_role_list(_researchteamid integer, _userid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of roles for given user for the given research team
**
**  Auth:   grk
**  Date:   03/28/2010
**          06/12/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(T_Research_Team_Roles.role, '|' ORDER BY T_Research_Team_Roles.role)
    INTO _result
    FROM T_Research_Team_Roles
             INNER JOIN T_Research_Team_Membership
               ON T_Research_Team_Roles.role_id = T_Research_Team_Membership.role_id
             INNER JOIN T_Users
               ON T_Research_Team_Membership.User_ID = T_Users.user_id
        WHERE T_Research_Team_Membership.Team_ID = _researchTeamID AND
              T_Research_Team_Membership.User_ID = _userID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_research_team_user_role_list(_researchteamid integer, _userid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_research_team_user_role_list(_researchteamid integer, _userid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_research_team_user_role_list(_researchteamid integer, _userid integer) IS 'GetResearchTeamUserRoleList';


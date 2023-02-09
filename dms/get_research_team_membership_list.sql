--
-- Name: get_research_team_membership_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_research_team_membership_list(_researchteamid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of role:person pairs
**      for the given research team
**
**  Auth:   grk
**  Date:   02/03/2010
**          12/08/2014 mem - Now using name_with_username to obtain each user's name and username
**          06/10/2022 mem - Ported to PostgreSQL
**          06/12/2022 mem - Rename name_with_username to name_with_username
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(T_Research_Team_Roles.role || ':' || T_Users.name_with_username,
                      '|' ORDER BY T_Research_Team_Roles.role, T_Users.name_with_username)
    INTO _result
    FROM T_Research_Team_Roles
             INNER JOIN T_Research_Team_Membership
               ON T_Research_Team_Roles.role_id = T_Research_Team_Membership.role_id
             INNER JOIN T_Users
               ON T_Research_Team_Membership.User_ID = T_Users.user_id
        WHERE T_Research_Team_Membership.Team_ID = _researchTeamID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_research_team_membership_list(_researchteamid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_research_team_membership_list(_researchteamid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_research_team_membership_list(_researchteamid integer) IS 'GetResearchTeamMembershipList';


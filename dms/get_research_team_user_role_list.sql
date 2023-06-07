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
**          05/24/2023 mem - Alias table names
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(R.role, '|' ORDER BY R.role)
    INTO _result
    FROM T_Research_Team_Roles R
         INNER JOIN T_Research_Team_Membership M
           ON R.role_id = M.role_id
         INNER JOIN T_Users U
           ON M.User_ID = U.user_id
    WHERE M.Team_ID = _researchTeamID AND
          M.User_ID = _userID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_research_team_user_role_list(_researchteamid integer, _userid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_research_team_user_role_list(_researchteamid integer, _userid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_research_team_user_role_list(_researchteamid integer, _userid integer) IS 'GetResearchTeamUserRoleList';


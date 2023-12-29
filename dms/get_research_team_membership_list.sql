--
-- Name: get_research_team_membership_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_research_team_membership_list(_researchteamid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of role:person pairs for the given research team
**
**  Auth:   grk
**  Date:   02/03/2010
**          12/08/2014 mem - Now using name_with_username to obtain each user's name and username
**          06/10/2022 mem - Ported to PostgreSQL
**          06/12/2022 mem - Rename name_with_username to name_with_username
**          05/24/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(format('%s:%s', R.role, U.name_with_username), '|' ORDER BY R.role, U.name_with_username)
    INTO _result
    FROM T_Research_Team_Roles R
         INNER JOIN T_Research_Team_Membership M
           ON R.role_id = M.role_id
         INNER JOIN T_Users U
           ON M.User_ID = U.user_id
    WHERE M.Team_ID = _researchTeamID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_research_team_membership_list(_researchteamid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_research_team_membership_list(_researchteamid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_research_team_membership_list(_researchteamid integer) IS 'GetResearchTeamMembershipList';


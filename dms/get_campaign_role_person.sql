--
-- Name: get_campaign_role_person(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return person for given role for the given campaign
**
**  Return value: person name and username
**
**  Auth:   grk
**  Date:   02/03/2010
**          12/08/2014 mem - Now using name_with_username to obtain the user's name and username
**          07/07/2022 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          01/20/2024 mem - Ignore case when filtering by role
**
*****************************************************/
DECLARE
    _person text;
BEGIN
    If Not _campaignID Is Null And Not _role Is Null Then
        SELECT t_users.name_with_username
        INTO _person
        FROM t_research_team_roles
             INNER JOIN t_research_team_membership
               ON t_research_team_roles.role_id = t_research_team_membership.role_id
             INNER JOIN t_users
               ON t_research_team_membership.user_id = t_users.user_id
             INNER JOIN t_campaign
               ON t_research_team_membership.team_id = t_campaign.research_team
        WHERE t_campaign.campaign_id = _campaignID AND
              t_research_team_roles.role = _role::citext;
    End If;

    RETURN Coalesce(_person, '');
END
$$;


ALTER FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_role_person(_campaignid integer, _role text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) IS 'GetCampaignRolePerson';


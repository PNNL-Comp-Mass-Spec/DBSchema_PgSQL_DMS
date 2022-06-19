--
-- Name: get_campaign_role_person(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns person for given role for the given campaign
**
**  Return value: person name and username
**
**  Auth:   grk
**  Date:   02/03/2010
**          12/08/2014 mem - Now using Name_with_PRN to obtain the user's name and PRN
**          06/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _person text;
BEGIN
    IF NOT _campaignID IS NULL AND NOT _role IS NULL Then
        SELECT t_users.name_with_username
        INTO _person
        FROM t_research_team_roles
             INNER JOIN t_research_team_membership
               ON t_research_team_roles.user_id = t_research_team_membership.role_id
             INNER JOIN t_users
               ON t_research_team_membership.user_id = t_users.user_id
             INNER JOIN t_campaign
               ON t_research_team_membership.team_id = t_campaign.research_team
        WHERE t_campaign.campaign_id = _campaignID AND
              t_research_team_roles.role = _role;
    End If;

    RETURN Coalesce(_person, '');
END
$$;


ALTER FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_role_person(_campaignid integer, _role text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_role_person(_campaignid integer, _role text) IS 'GetCampaignRolePerson';


--
-- Name: get_campaign_role_person_list(integer, public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role public.citext, _mode public.citext DEFAULT 'PRN'::public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns list of people for given role for the given campaign
**
**  Return value: comma separated list
**
**  Arguments:
**    _campaignID   Campaign ID
**    _role         Role name
**    _mode         Name mode; if 'PRN' or 'USERNAME', return the username; otherwise return person's name and username
**
**  Auth:   grk
**  Date:   02/04/2010
**          12/08/2014 mem - Now using Name_with_PRN to obtain each user's name and PRN
**          07/07/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN

    IF NOT _campaignID IS NULL AND NOT _role IS NULL Then
        SELECT string_agg(LookupQ.Value, ', ' ORDER BY LookupQ.Value)
        INTO _result
        FROM (  SELECT CASE WHEN _mode = 'PRN'
                            THEN t_users.username
                            ELSE t_users.name_with_username
                       END as Value
                FROM t_research_team_roles
                     INNER JOIN t_research_team_membership
                       ON t_research_team_roles.role_id = t_research_team_membership.role_id
                     INNER JOIN t_users
                       ON t_research_team_membership.user_id = t_users.user_id
                     INNER JOIN t_campaign
                       ON t_research_team_membership.team_id = t_campaign.research_team
                WHERE t_campaign.campaign_id = _campaignID AND
                      t_research_team_roles.role = _role
             ) LookupQ;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role public.citext, _mode public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_role_person_list(_campaignid integer, _role public.citext, _mode public.citext); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role public.citext, _mode public.citext) IS 'GetCampaignRolePersonList';


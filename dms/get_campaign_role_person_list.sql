--
-- Name: get_campaign_role_person_list(integer, public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role public.citext, _mode public.citext DEFAULT 'USERNAME'::public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns list of people for given role for the given campaign
**
**  Return value: comma-separated list
**
**  Arguments:
**    _campaignID   Campaign ID
**    _role         Role name: 'Project Mgr', 'PI', 'Dataset Acquisition', 'Technical Lead', 'Sample Preparation', 'Informatics', or 'Observer'
**    _mode         Name mode; if 'PRN' or 'USERNAME', return the username; otherwise return person's name and username
**
**  Auth:   grk
**  Date:   02/04/2010
**          12/08/2014 mem - Now using name_with_username to obtain each user's name and PRN
**          07/07/2022 mem - Ported to PostgreSQL
**          11/14/2022 mem - Allow mode to be either PRN or USERNAME
**          02/09/2023 mem - Change default value for _mode to 'USERNAME'
**          05/24/2023 mem - Alias table names
**
*****************************************************/
DECLARE
    _result text;
BEGIN

    IF NOT _campaignID IS NULL AND NOT _role IS NULL Then
        SELECT string_agg(LookupQ.Value, ', ' ORDER BY LookupQ.Value)
        INTO _result
        FROM (  SELECT CASE WHEN _mode IN ('PRN', 'USERNAME')
                            THEN U.username
                            ELSE U.name_with_username
                       END as Value
                FROM T_Research_Team_Roles R
                     INNER JOIN T_Research_Team_Membership M
                       ON R.role_id = M.role_id
                     INNER JOIN T_Users U
                       ON M.user_id = U.user_id
                     INNER JOIN T_Campaign C
                       ON M.team_id = C.research_team
                WHERE C.campaign_id = _campaignID AND
                      R.role = _role
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


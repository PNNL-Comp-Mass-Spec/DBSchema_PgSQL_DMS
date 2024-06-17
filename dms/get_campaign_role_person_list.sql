--
-- Name: get_campaign_role_person_list(integer, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role text, _mode text DEFAULT 'USERNAME'::text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return list of people for given role for the given campaign
**
**  Arguments:
**    _campaignID   Campaign ID
**    _role         Role name: 'Project Mgr', 'PI', 'Dataset Acquisition', 'Technical Lead', 'Sample Preparation', 'Informatics', or 'Observer'
**    _mode         Name mode; if 'PRN' or 'USERNAME', return the username; otherwise return person's name and username
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   02/04/2010
**          12/08/2014 mem - Now using name_with_username to obtain each user's name and PRN
**          07/07/2022 mem - Ported to PostgreSQL
**          11/14/2022 mem - Allow mode to be either PRN or USERNAME
**          02/09/2023 mem - Change default value for _mode to 'USERNAME'
**          05/24/2023 mem - Alias table names
**          09/08/2023 mem - Adjust capitalization of keywords
**          01/20/2024 mem - Change data type of _role and _mode to text
**
*****************************************************/
DECLARE
    _result text;
BEGIN

    If Not _campaignID Is Null And Not _role Is Null Then
        SELECT string_agg(LookupQ.Value, ', ' ORDER BY LookupQ.Value)
        INTO _result
        FROM (SELECT CASE WHEN _mode::citext IN ('PRN', 'USERNAME')
                          THEN U.username
                          ELSE U.name_with_username
                     END AS Value
              FROM T_Research_Team_Roles R
                   INNER JOIN T_Research_Team_Membership M
                     ON R.role_id = M.role_id
                   INNER JOIN T_Users U
                     ON M.user_id = U.user_id
                   INNER JOIN T_Campaign C
                     ON M.team_id = C.research_team
              WHERE C.campaign_id = _campaignID AND
                    R.role = _role::citext
             ) LookupQ;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role text, _mode text) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_role_person_list(_campaignid integer, _role text, _mode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_role_person_list(_campaignid integer, _role text, _mode text) IS 'GetCampaignRolePersonList';


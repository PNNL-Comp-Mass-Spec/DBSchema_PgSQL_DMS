--
-- Name: get_material_container_campaign_list(integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_material_container_campaign_list(_containerid integer, _count integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of campaigns represented by items in the given container
**
**      This function was previously used by views V_Material_Containers_List_Report and V_Material_Containers_Detail_Report
**      but is no longer used, since column Campaign_ID was added to table T_Material_Containers in November 2023
**
**  Arguments:
**    _containerID  Container ID
**    _count        Number of items in the container; if 0, return an empty string without querying any tables, otherwise, if null or non-zero query the database
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   08/24/2010 grk
**          12/04/2017 mem - Use Coalesce instead of a Case statement
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN

    If Coalesce(_count, 0) = 0 Then
        RETURN '';
    End If;

    If _containerID < 1000 Then
       _result := '(temporary)';
    Else
        SELECT string_agg(LookupQ.campaign, ', ' ORDER BY LookupQ.campaign)
        INTO _result
        FROM (SELECT DISTINCT Campaigns.campaign
              FROM (SELECT t_campaign.campaign
                    FROM t_biomaterial
                         INNER JOIN t_campaign
                           ON t_biomaterial.campaign_id = t_campaign.campaign_id
                    WHERE t_biomaterial.container_id = _containerID
                    UNION
                    SELECT t_campaign.campaign
                    FROM t_experiments
                         INNER JOIN t_campaign
                           ON t_experiments.campaign_id = t_campaign.campaign_id
                    WHERE t_experiments.container_id = _containerID
                   ) Campaigns
             ) LookupQ;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_material_container_campaign_list(_containerid integer, _count integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_material_container_campaign_list(_containerid integer, _count integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_material_container_campaign_list(_containerid integer, _count integer) IS 'GetMaterialContainerCampaignList';


--
-- Name: get_campaign_work_package_list(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_work_package_list(_campaignname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of work packages for the given campaign
**
**  Return value: semicolon-separated list
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial version
**          06/11/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(LookupQ.WorkPackage, ';' ORDER BY LookupQ.WorkPackage)
    INTO _result
    FROM ( SELECT DISTINCT RR.work_package AS WorkPackage
               FROM t_requested_run RR
                    INNER JOIN t_dataset DS
                      ON RR.dataset_id = DS.dataset_id
                    INNER JOIN t_experiments E
                      ON DS.exp_id = E.exp_id
                    INNER JOIN t_campaign C
                      ON E.campaign_id = C.campaign_id
               WHERE C.campaign = _campaignName
         ) LookupQ;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_campaign_work_package_list(_campaignname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_work_package_list(_campaignname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_work_package_list(_campaignname text) IS 'GetCampaignWorkPackageList';


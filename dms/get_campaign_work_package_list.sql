--
-- Name: get_campaign_work_package_list(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_work_package_list(_campaignname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of work packages for the given campaign
**
**  Auth:   grk
**  Date:   06/07/2019 mem - Initial version
**          06/11/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(LookupQ.work_package, ';' ORDER BY LookupQ.work_package)
    INTO _result
    FROM ( SELECT DISTINCT RR.work_package
           FROM T_Requested_Run RR
                INNER JOIN T_Dataset DS
                  ON RR.Dataset_ID = DS.Dataset_ID
                INNER JOIN T_Experiments E
                  ON DS.Exp_ID = E.Exp_ID
                INNER JOIN T_Campaign C
                  ON E.campaign_ID = C.Campaign_ID
           WHERE C.campaign = _campaignName And
                 Length(Trim(Coalesce(RR.work_package, ''))) > 0
         ) LookupQ;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_campaign_work_package_list(_campaignname text) OWNER TO d3l243;


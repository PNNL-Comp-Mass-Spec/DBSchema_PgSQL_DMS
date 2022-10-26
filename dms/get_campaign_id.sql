--
-- Name: get_campaign_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_campaign_id(_campaignname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Gets campaignID for given campaign name
**
**  Return values: campaign ID if found, otherwise 0
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _campaignID int;
BEGIN
    SELECT campaign_id
    INTO _campaignID
    FROM t_campaign
    WHERE campaign = _campaignName::citext;

    If FOUND Then
        RETURN _campaignID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_campaign_id(_campaignname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_campaign_id(_campaignname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_campaign_id(_campaignname text) IS 'GetCampaignID';


--
-- Name: populate_campaign_filter_table(text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.populate_campaign_filter_table(IN _campaignidfilterlist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populate temp table Tmp_CampaignFilter based on the comma-separated campaign IDs in _campaignIDFilterList
**
**      The calling procedure must create the temporary table:
**
**          CREATE TEMP TABLE Tmp_CampaignFilter (
**              Campaign_ID int NOT NULL,
**              Fraction_EMSL_Funded numeric NULL
**          );
**
**  Arguments:
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   07/22/2019 mem - Initial version
**          02/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidCampaignIDs text;
BEGIN
    _message := '';
    _returnCode := '';

    _campaignIDFilterList := Trim(Coalesce(_campaignIDFilterList, ''));

    If _campaignIDFilterList = '' Then
        INSERT INTO Tmp_CampaignFilter (Campaign_ID)
        SELECT C.campaign_id
        FROM t_campaign C
             LEFT OUTER JOIN Tmp_CampaignFilter Target
                   ON C.campaign_id = Target.campaign_id
        WHERE Target.campaign_id IS NULL
        ORDER BY C.campaign_id;

        RETURN;
    End If;

    INSERT INTO Tmp_CampaignFilter (Campaign_ID)
    SELECT DISTINCT Src.Value
    FROM public.parse_delimited_integer_list(_campaignIDFilterList) Src
         LEFT OUTER JOIN Tmp_CampaignFilter Target
               ON Src.Value = Target.campaign_id
    WHERE Target.campaign_id IS NULL
    ORDER BY Src.Value;

    -- Look for invalid Campaign ID values

    SELECT string_agg(CF.campaign_id::text, ',' ORDER BY CF.campaign_id)
    INTO _invalidCampaignIDs
    FROM Tmp_CampaignFilter CF
         LEFT OUTER JOIN t_campaign C
           ON CF.campaign_id = C.campaign_id
    WHERE C.campaign_id IS NULL;

    If Coalesce(_invalidCampaignIDs, '') <> '' Then
        _message := format('Invalid Campaign ID(s): %s', _invalidCampaignIDs);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;
END
$$;


ALTER PROCEDURE public.populate_campaign_filter_table(IN _campaignidfilterlist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE populate_campaign_filter_table(IN _campaignidfilterlist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.populate_campaign_filter_table(IN _campaignidfilterlist text, INOUT _message text, INOUT _returncode text) IS 'PopulateCampaignFilterTable';


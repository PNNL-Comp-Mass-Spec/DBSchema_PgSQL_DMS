--
CREATE OR REPLACE PROCEDURE public.populate_campaign_filter_table
(
    _campaignIDFilterList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populates temp table Tmp_CampaignFilter
**      based on the comma-separated campaign IDs in _campaignIDFilterList
**
**  The calling procedure must create the temporary table:
**
**    CREATE TEMP TABLE Tmp_CampaignFilter (
**        Campaign_ID int NOT NULL,
**        Fraction_EMSL_Funded numeric NULL
**    );
**
**  Arguments:
**    _campaignIDFilterList   Comma-separated list of campaign IDs
**
**  Auth:   mem
**  Date:   07/22/2019 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidCampaignIDs text;
BEGIN
    _message := '';
    _returnCode := '';

    _campaignIDFilterList := Trim(Coalesce(_campaignIDFilterList, ''));

    If _campaignIDFilterList <> '' Then
        INSERT INTO Tmp_CampaignFilter (Campaign_ID)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_campaignIDFilterList)
        ORDER BY Value

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

    Else
        INSERT INTO Tmp_CampaignFilter (campaign_id)
        SELECT campaign_id
        FROM t_campaign
        ORDER BY campaign_id;
    End If;

END
$$;

COMMENT ON PROCEDURE public.populate_campaign_filter_table IS 'PopulateCampaignFilterTable';

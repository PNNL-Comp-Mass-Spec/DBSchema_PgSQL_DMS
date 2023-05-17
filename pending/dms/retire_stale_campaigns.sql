--
CREATE OR REPLACE PROCEDURE public.retire_stale_campaigns
(
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Automatically retires (sets inactive) campaigns that have not been used recently
**
**  Auth:   mem
**  Date:   06/11/2022
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    -----------------------------------------------------------
    -- Create a temporary table to track the campaigns to retire
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Campaigns (
        Campaign_ID int not null primary key,
        Campaign text Not Null,
        Created timestamp Not Null,
        Most_Recent_Activity timestamp Null,
        Most_Recent_Dataset timestamp Null,
        Most_Recent_Analysis_Job timestamp Null
    )

    -----------------------------------------------------------
    -- Find LC columns that have been used with a dataset, but not in the last 9 months
    -----------------------------------------------------------
    --
    INSERT INTO Tmp_Campaigns (Campaign_ID, Campaign, Created, Most_Recent_Activity, Most_Recent_Dataset, Most_Recent_Analysis_Job)
    SELECT Campaign_ID,
           Campaign,
           Created,
           Most_Recent_Activity,
           Most_Recent_Dataset,
           Most_Recent_Analysis_Job
    FROM V_Campaign_List_Stale
    WHERE State = 'Active'
    ORDER BY Campaign_ID

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        -----------------------------------------------------------
        -- Preview the campaigns that would be retired
        -----------------------------------------------------------
        --
        SELECT *
        FROM Tmp_Campaigns
        ORDER BY Campaign_ID
    Else
        -----------------------------------------------------------
        -- Change the campaign states to 'Inactive'
        -----------------------------------------------------------
        --
        UPDATE t_campaign
        SET state = 'Inactive'
        WHERE campaign_id IN ( SELECT campaign_id FROM Tmp_Campaigns )
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Retired %s %s that have not been used in at last 18 months and were created over 7 years ago',
                                _updateCount, public.check_plural(_updateCount, 'campaigns', 'campaigns'));

            Call post_log_entry ('Normal', _message, 'Retire_Stale_Campaigns');
        End If;
    End If;

    DROP TABLE Tmp_Campaigns;
END
$$;

COMMENT ON PROCEDURE public.retire_stale_campaigns IS 'RetireStaleCampaigns';

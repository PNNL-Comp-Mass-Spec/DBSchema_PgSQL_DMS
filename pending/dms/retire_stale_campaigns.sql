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

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
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

        -----------------------------------------------------------
        -- Preview the campaigns that would be retired
        -----------------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-11s %-50s %-20s %-20s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Campaign_ID',
                            'Campaign',
                            'Created',
                            'Most_Recent_Activity',
                            'Most_Recent_Dataset',
                            'Most_Recent_Analysis_Job'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------',
                                     '--------------------------------------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Campaign_ID,
                   Campaign,
                   public.timestamp_text(Created) As Created,
                   public.timestamp_text(Most_Recent_Activity) As Most_Recent_Activity,
                   public.timestamp_text(Most_Recent_Dataset) As Most_Recent_Dataset,
                   public.timestamp_text(Most_Recent_Analysis_Job) As Most_Recent_Analysis_Job
            FROM Tmp_Campaigns
            ORDER BY Campaign_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Campaign_ID,
                                _previewData.Campaign,
                                _previewData.Created,
                                _previewData.Most_Recent_Activity,
                                _previewData.Most_Recent_Dataset,
                                _previewData.Most_Recent_Analysis_Job
                               );

            RAISE INFO '%', _infoData;
        END LOOP;
    Else
        -----------------------------------------------------------
        -- Change the campaign states to 'Inactive'
        -----------------------------------------------------------

        UPDATE t_campaign
        SET state = 'Inactive'
        WHERE campaign_id IN ( SELECT campaign_id FROM Tmp_Campaigns )
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Retired %s %s that have not been used in at last 18 months and were created over 7 years ago',
                                _updateCount, public.check_plural(_updateCount, 'campaigns', 'campaigns'));

            CALL post_log_entry ('Normal', _message, 'Retire_Stale_Campaigns');
        End If;
    End If;

    DROP TABLE Tmp_Campaigns;
END
$$;

COMMENT ON PROCEDURE public.retire_stale_campaigns IS 'RetireStaleCampaigns';

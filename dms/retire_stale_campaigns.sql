--
-- Name: retire_stale_campaigns(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.retire_stale_campaigns(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Automatically retires (sets inactive) campaigns that have not been used recently
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   06/11/2022
**          02/22/2024 mem - Ported to PostgreSQL
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
        Campaign_ID int NOT NULL PRIMARY KEY,
        Campaign text NOT NULL,
        Created timestamp NOT NULL,
        Most_Recent_Activity timestamp NULL,
        Most_Recent_Dataset timestamp NULL,
        Most_Recent_Analysis_Job timestamp NULL
    );

    -----------------------------------------------------------
    -- Find campaigns that meet each of these conditions (as defined in the view)
    --   The campaign was created more than 7 years ago
    --   Most recent sample prep request updated more than 18 months ago
    --   Most recent experiment created more than 18 months ago
    --   Most recent requested run created more than 18 months ago
    --   Most recent dataset created more than 18 months ago
    --   Most recent analysis job created started more than 18 months ago
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
    ORDER BY Campaign_ID;

    If Not FOUND Then
        _message := 'Did not find any stale campaigns to retire';
        RAISE INFO '%', _message;
        DROP TABLE Tmp_Campaigns;
        RETURN;
    End If;

    If _infoOnly Then

        -----------------------------------------------------------
        -- Preview the campaigns that would be retired
        -----------------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-11s %-50s %-11s %-20s %-20s %-24s';

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
                                     '-----------',
                                     '--------------------',
                                     '--------------------',
                                     '------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Campaign_ID,
                   Campaign,
                   Created::date                  AS Created,
                   Most_Recent_Activity::date     AS Most_Recent_Activity,
                   Most_Recent_Dataset::date      AS Most_Recent_Dataset,
                   Most_Recent_Analysis_Job::date AS Most_Recent_Analysis_Job
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

        DROP TABLE Tmp_Campaigns;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Change the campaign states to 'Inactive'
    -----------------------------------------------------------

    UPDATE t_campaign Target
    SET state = 'Inactive'
    WHERE EXISTS (SELECT 1
                  FROM Tmp_Campaigns
                  WHERE Target.campaign_id = Tmp_Campaigns.campaign_id);
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _message := format('Retired %s %s that %s not been used in at last 18 months and %s created over 7 years ago',
                           _updateCount,
                           public.check_plural(_updateCount, 'campaign', 'campaigns'),
                           public.check_plural(_updateCount, 'has', 'have'),
                           public.check_plural(_updateCount, 'was', 'were'));

        CALL post_log_entry ('Normal', _message, 'Retire_Stale_Campaigns');

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Campaigns;
END
$$;


ALTER PROCEDURE public.retire_stale_campaigns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE retire_stale_campaigns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.retire_stale_campaigns(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'RetireStaleCampaigns';


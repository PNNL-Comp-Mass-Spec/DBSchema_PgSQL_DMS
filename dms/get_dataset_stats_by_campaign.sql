--
-- Name: get_dataset_stats_by_campaign(integer, timestamp without time zone, timestamp without time zone, integer, integer, integer, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dataset_stats_by_campaign(_mostrecentweeks integer DEFAULT 20, _startdate timestamp without time zone DEFAULT NULL::timestamp without time zone, _enddate timestamp without time zone DEFAULT NULL::timestamp without time zone, _includeinstrument integer DEFAULT 0, _excludeqcandblankwithoutwp integer DEFAULT 1, _excludeallqcandblank integer DEFAULT 0, _campaignnamefilter text DEFAULT ''::text, _campaignnameexclude text DEFAULT ''::text, _instrumentbuilding text DEFAULT ''::text, _previewsql boolean DEFAULT false) RETURNS TABLE(campaign public.citext, work_package public.citext, pct_emsl_funded numeric, runtime_hours numeric, datasets integer, building public.citext, instrument public.citext, request_min integer, request_max integer, pct_total_runtime numeric)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table summarizing datasets stats, grouped by campaign, work package, and instrument over the given time frame
**
**  Arguments:
**    _mostRecentWeeks              Summarize datasets created within this many weeks
**                                  - If this is 0, uses _startDate and _endDate
**                                  - However, if _startDate is not a valid date, CURRENT_TIMESTAMP - INTERVAL '20 weeks'
**                                  - Also, if _endDate is not a valid date, uses CURRENT_TIMESTAMP
**    _startDate                    Start date; ignored if _mostRecentWeeks is non-zero
**    _endDate                      End date;   ignored if _mostRecentWeeks is non-zero
**    _includeInstrument            When 1, include instrument name in the output (and group the stats by instrument); when 0, ignore instrument names
**    _excludeQCAndBlankWithoutWP   When 1, exclude QC and Blank datasets that don't have a work package
**    _excludeAllQCAndBlank         When 1, exclude all QC and Blank datasets
**    _campaignNameFilter           Campaign next text to filter on
**    _campaignNameExclude
**    _instrumentBuilding
**    _previewSql boolean
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial release
**          06/10/2019 mem - Add parameters _excludeQCAndBlankWithoutWP, _campaignNameExclude, and _instrumentBuilding
**          03/24/2020 mem - Add parameter _excludeAllQCAndBlank
**          07/13/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          02/16/2024 mem - Prevent divide by zero errors
**
*****************************************************/
DECLARE
    _msg text;
    _sql text;
    _optionalCampaignNot text := '';
    _optionalBuildingNot text := '';
    _totalRuntimeHours real;
BEGIN

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _mostRecentWeeks            := Coalesce(_mostRecentWeeks, 0);
    _includeInstrument          := Coalesce(_includeInstrument, 0);
    _excludeQCAndBlankWithoutWP := Coalesce(_excludeQCAndBlankWithoutWP, 1);
    _excludeAllQCAndBlank       := Coalesce(_excludeAllQCAndBlank, 0);
    _campaignNameFilter         := Trim(Coalesce(_campaignNameFilter, ''));
    _campaignNameExclude        := Trim(Coalesce(_campaignNameExclude, ''));
    _instrumentBuilding         := Trim(Coalesce(_instrumentBuilding, ''));
    _previewSql                 := Coalesce(_previewSql, false);

    If _previewSql Then
        RAISE INFO '';
    End If;

    If _mostRecentWeeks < 1 Then
        _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - INTERVAL '20 weeks');
        _endDate   := Coalesce(_endDate,   CURRENT_TIMESTAMP);

        If _previewSql Then
            RAISE INFO 'Filtering on date range % to %', _startDate, _endDate;
        End If;
    Else
        If _previewSql Then
            RAISE INFO 'Filtering on datasets acquired within the last % weeks', _mostRecentWeeks;
        End If;
    End If;

    If _campaignNameFilter Like ':%' And char_length(_campaignNameFilter) > 1 Then
        -- The campaign name filter starts with a colon; exclude campaigns with the given name, instead of including

        _campaignNameFilter := Substring(_campaignNameFilter, 2, char_length(_campaignNameFilter) - 1);
        _optionalCampaignNot := 'Not';
    End If;

    If _instrumentBuilding Like ':%' And char_length(_instrumentBuilding) > 1 Then
        -- The instrument name filter starts with a colon; exclude instruments with the given name, instead of including

        _instrumentBuilding := Substring(_instrumentBuilding, 2, char_length(_instrumentBuilding) - 1);
        _optionalBuildingNot := 'Not';
    End If;

    _campaignNameFilter  := validate_wildcard_filter(_campaignNameFilter);
    _campaignNameExclude := validate_wildcard_filter(_campaignNameExclude);
    _instrumentBuilding  := validate_wildcard_filter(_instrumentBuilding);

    If _previewSql And _campaignNameFilter <> '' Then
        RAISE INFO 'Filtering on campaign name matching ''%''', _campaignNameFilter;
    End If;

    If _previewSql And _campaignNameExclude <> '' Then
        RAISE INFO 'Excluding campaigns matching ''%''', _campaignNameExclude;
    End If;

    If _previewSql And _instrumentBuilding <> '' Then
        RAISE INFO 'Filtering on building matching ''%''', _instrumentBuilding;
    End If;

    -----------------------------------------
    -- Create a temporary table to cache the results
    -----------------------------------------

    CREATE TEMP TABLE Tmp_CampaignDatasetStats (
        Campaign citext NOT NULL,
        Work_Package citext NULL,
        FractionEMSLFunded numeric(3,2) NULL,
        Runtime_Hours numeric(9,1) NOT NULL,
        Datasets int NOT NULL,
        Building citext NOT NULL,
        Instrument citext NOT NULL,
        Request_Min int NOT NULL,
        Request_Max int NOT NULL
    );

    -----------------------------------------
    -- Construct the query to retrieve the results
    -----------------------------------------

    _sql := 'INSERT INTO Tmp_CampaignDatasetStats (Campaign, Work_Package, FractionEMSLFunded, Runtime_Hours, Datasets, Building, Instrument, Request_Min, Request_Max) '
            'SELECT C.Campaign, '
                   'RR.work_package, '
                   'C.Fraction_EMSL_Funded, '
                   '(Sum(DS.Acq_Length_Minutes) / 60.0)::numeric(9,1) AS Runtime_Hours, '
                   'COUNT(DS.dataset_id) AS Datasets, '
                   'InstName.Building, ';

    If _includeInstrument > 0 Then
        _sql := _sql || 'InstName.instrument, ';
    Else
        _sql := _sql || ''''' AS Instrument, ';
    End If;

    _sql := _sql ||
                   'MIN(RR.request_id) AS Request_Min, '
                   'MAX(RR.request_id) AS Request_Max '
            'FROM t_dataset DS '
                 'INNER JOIN t_experiments E ON DS.exp_id = E.exp_id '
                 'INNER JOIN t_campaign C ON E.campaign_id = C.campaign_id '
                 'INNER JOIN t_requested_run RR ON DS.dataset_id = RR.dataset_id '
                 'INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id ';

    If _mostRecentWeeks > 0 Then
        _sql := _sql || format('WHERE DS.Date_Sort_Key > CURRENT_TIMESTAMP - INTERVAL ''%s weeks''', _mostRecentWeeks);
    Else
        _sql := _sql || format('WHERE DS.Date_Sort_Key BETWEEN ''%s'' AND ''%s''', _startDate, _endDate);
    End If;

    If _campaignNameFilter <> '' Then
        _sql := _sql || format(' AND %s C.Campaign SIMILAR TO ''%s''', _optionalCampaignNot, _campaignNameFilter);
    End If;

    If _campaignNameExclude <> '' Then
        _sql := _sql || format(' AND NOT C.Campaign SIMILAR TO ''%s''', _campaignNameExclude);
    End If;

    If _instrumentBuilding <> '' Then
        _sql := _sql || format(' AND %s InstName.Building SIMILAR TO ''%s''', _optionalBuildingNot, _instrumentBuilding);
    End If;

    If _excludeQCAndBlankWithoutWP > 0 Then
        _sql := _sql || ' AND NOT (C.Campaign SIMILAR TO ''QC[-_]%'' AND RR.work_package = ''None'') '
                        ' AND NOT (C.Campaign IN (''Blank'', ''DataUpload'', ''DMS_Pipeline_Jobs'', ''Tracking'') AND RR.work_package = ''None'') '
                        ' AND NOT (InstName.instrument LIKE ''External%'' AND RR.work_package = ''None'') ';
    End If;

    If _excludeAllQCAndBlank > 0 Then
        _sql := _sql || ' AND NOT C.Campaign SIMILAR TO ''QC[-_]%'' '
                        ' AND NOT C.Campaign IN (''Blank'', ''DataUpload'', ''DMS_Pipeline_Jobs'', ''Tracking'') ';
    End If;

    _sql := _sql || ' GROUP BY Campaign, RR.work_package, C.Fraction_EMSL_Funded, InstName.Building';

    If _includeInstrument > 0 Then
        _sql := _sql ||    ', InstName.instrument';
    End If;

    -----------------------------------------
    -- Preview or execute the query
    -----------------------------------------

    If _previewSql Then
        RAISE INFO '%', _sql;
    Else
        EXECUTE _sql;

        -----------------------------------------
        -- Determine the total runtime
        -----------------------------------------

        SELECT Sum(Src.Runtime_Hours)
        INTO _totalRuntimeHours
        FROM Tmp_CampaignDatasetStats Src;

        -----------------------------------------
        -- Return the results
        -----------------------------------------

        RETURN QUERY
        SELECT Src.Campaign,
               Src.Work_Package,
               Src.FractionEMSLFunded * 100 AS Pct_EMSL_Funded,
               Src.Runtime_Hours,
               Src.Datasets,
               Src.Building,
               Src.Instrument,
               Src.Request_Min,
               Src.Request_Max,
               CASE WHEN _totalRuntimeHours > 0
                    THEN (Src.Runtime_Hours / _totalRuntimeHours * 100)::numeric(9,3)
                    ELSE 0::numeric(9,3)
               END AS Pct_Total_Runtime
        FROM Tmp_CampaignDatasetStats Src
        ORDER BY Src.Runtime_Hours DESC;

    End If;

    DROP TABLE Tmp_CampaignDatasetStats;
END
$$;


ALTER FUNCTION public.get_dataset_stats_by_campaign(_mostrecentweeks integer, _startdate timestamp without time zone, _enddate timestamp without time zone, _includeinstrument integer, _excludeqcandblankwithoutwp integer, _excludeallqcandblank integer, _campaignnamefilter text, _campaignnameexclude text, _instrumentbuilding text, _previewsql boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_dataset_stats_by_campaign(_mostrecentweeks integer, _startdate timestamp without time zone, _enddate timestamp without time zone, _includeinstrument integer, _excludeqcandblankwithoutwp integer, _excludeallqcandblank integer, _campaignnamefilter text, _campaignnameexclude text, _instrumentbuilding text, _previewsql boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dataset_stats_by_campaign(_mostrecentweeks integer, _startdate timestamp without time zone, _enddate timestamp without time zone, _includeinstrument integer, _excludeqcandblankwithoutwp integer, _excludeallqcandblank integer, _campaignnamefilter text, _campaignnameexclude text, _instrumentbuilding text, _previewsql boolean) IS 'GetDatasetStatsByCampaign';


--
CREATE OR REPLACE FUNCTION public.get_dataset_stats_by_campaign
(
    _mostRecentWeeks int = 20,
    _startDate timestamp = null,
    _endDate timestamp = null,
    _includeInstrument int = 0,
    _excludeQCAndBlankWithoutWP int = 1,
    _excludeAllQCAndBlank int = 0,
    _campaignNameFilter text = '',
    _campaignNameExclude text = '',
    _instrumentBuilding text = '',
    _previewSql boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
RETURNS TABLE
(
	Campaign citext,
	Work_Package citext,
	Pct_EMSL_Funded numeric(3,2),
	Runtime_Hours numeric(9,1),
	Datasets int,
	Building citext,
	Instrument citext,
	Request_Min int,
	Request_Max int,
	Pct_Total_Runtime numeric(9,3)
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns a table summarizing datasets stats,
**      grouped by campaign, work package, and instrument over the given time frame
**
**  Arguments:
**    _startDate   Ignored if _mostRecentWeeks is non-zero
**    _endDate     Ignored if _mostRecentWeeks is non-zero
**
**  Auth:   mem
**  Date:   06/07/2019 mem - Initial release
**          06/10/2019 mem - Add parameters _excludeQCAndBlankWithoutWP, _campaignNameExclude, and _instrumentBuilding
**          03/24/2020 mem - Add parameter _excludeAllQCAndBlank
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _sql text;
    _optionalCampaignNot text := '';
    _optionalBuildingNot text := '';
    _totalRuntimeHours real;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _mostRecentWeeks := Coalesce(_mostRecentWeeks, 0);
    _includeInstrument := Coalesce(_includeInstrument, 0);
    _excludeQCAndBlankWithoutWP := Coalesce(_excludeQCAndBlankWithoutWP, 1);
    _excludeAllQCAndBlank := Coalesce(_excludeAllQCAndBlank, 0);
    _campaignNameFilter := Coalesce(_campaignNameFilter, '');
    _campaignNameExclude := Coalesce(_campaignNameExclude, '');
    _instrumentBuilding := Coalesce(_instrumentBuilding, '');
    _previewSql := Coalesce(_previewSql, false);

    If _mostRecentWeeks < 1 Then
        _startDate := Coalesce(_startDate, CURRENT_TIMESTAMP - INTERVAL '20 weeks');
        _endDate := Coalesce(_endDate, CURRENT_TIMESTAMP);

        If _previewSql Then
            RAISE INFO 'Filtering on date range % to %', _startDate, _endDate;
        End If;
    Else
        If _previewSql Then
            RAISE INFO 'Filtering on datasets acquired within the last % weeks', _mostRecentWeeks;
        End If;
    End If;

    If _campaignNameFilter Like ':%' And char_length(_campaignNameFilter) > 1 Then
        _campaignNameFilter := Substring(_campaignNameFilter, 2, char_length(_campaignNameFilter) - 1);
        _optionalCampaignNot := 'Not';
    End If;

    If _instrumentBuilding Like ':%' And char_length(_instrumentBuilding) > 1 Then
        _instrumentBuilding := Substring(_instrumentBuilding, 2, char_length(_instrumentBuilding) - 1);
        _optionalBuildingNot := 'Not';
    End If;

    _campaignNameFilter := validate_wildcard_filter(_campaignNameFilter);
    _campaignNameExclude := validate_wildcard_filter(_campaignNameExclude);
    _instrumentBuilding := validate_wildcard_filter(_instrumentBuilding);

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
        Campaign citext Not Null,
        WorkPackage citext Null,
        FractionEMSLFunded numeric(3,2) Null,
        RuntimeHours numeric(9,1) Not Null,
        Datasets int Not Null,
        Building citext Not Null,
        Instrument citext Not Null,
        RequestMin int Not Null,
        RequestMax int Not Null
    );

    -----------------------------------------
    -- Construct the query to retrieve the results
    -----------------------------------------

    _sql := 'INSERT INTO Tmp_CampaignDatasetStats (Campaign, WorkPackage, FractionEMSLFunded, RuntimeHours, Datasets, Building, Instrument, RequestMin, RequestMax) '
            'SELECT C.Campaign, '
                   'RR.work_package, '
                   'C.Fraction_EMSL_Funded, '
                   'Cast(Sum(DS.Acq_Length_Minutes) / 60.0 AS numeric(9,1)) AS RuntimeHours, '
                   'COUNT(DS.dataset_id) AS Datasets, '
                   'InstName.Building, ';

    If _includeInstrument > 0 Then
        _sql := _sql || 'InstName.instrument As Instrument, ';
    Else
        _sql := _sql || ''''' As Instrument, ';
    End If;

    _sql := _sql ||
                   'MIN(RR.request_id) AS RequestMin, '
                   'MAX(RR.request_id) AS RequestMax '
            'FROM t_dataset DS '
                 'INNER JOIN t_experiments E ON DS.exp_id = E.exp_id '
                 'INNER JOIN t_campaign C ON E.campaign_id = C.campaign_id '
                 'INNER JOIN t_requested_run RR ON DS.dataset_id = RR.dataset_id '
                 'INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id ';

    If _mostRecentWeeks > 0 Then
        _sql := _sql || format('WHERE DS.DateSortKey > CURRENT_TIMESTAMP - INTERVAL ''%s weeks''', _mostRecentWeeks);
    Else
        _sql := _sql || format('WHERE DS.DateSortKey BETWEEN ''%s'' AND ''%s''', _startDate, _endDate;
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

    _sql := _sql || ' GROUP BY Campaign, RR.work_package, C.CM_Fraction_EMSL_Funded, InstName.Building';

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

        SELECT Sum(RuntimeHours)
        INTO _totalRuntimeHours
        FROM Tmp_CampaignDatasetStats AS StatsQ

        -----------------------------------------
        -- Return the results
        -----------------------------------------

        -- ToDo: Convert this procedure to a function

		RETURN QUERY
        SELECT Campaign,
               WorkPackage AS Work_Package,
               FractionEMSLFunded * 100 As Pct_EMSL_Funded,
               RuntimeHours AS Runtime_Hours,
               Datasets,
               Building,
               Instrument,
               RequestMin AS Request_Min,
               RequestMax AS Request_Max,
               (RuntimeHours / _totalRuntimeHours * 100)::numeric(9,3)) AS Pct_Total_Runtime
        FROM Tmp_CampaignDatasetStats
        ORDER BY RuntimeHours DESC

    End If;

    DROP TABLE Tmp_CampaignDatasetStats;
END
$$;

COMMENT ON FUNCTION public.get_dataset_stats_by_campaign IS 'GetDatasetStatsByCampaign';


--
-- Name: report_tissue_usage_stats(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.report_tissue_usage_stats(_startdate text, _enddate text, _campaignidfilterlist text DEFAULT ''::text, _organismidfilterlist text DEFAULT ''::text, _instrumentfilterlist text DEFAULT ''::text) RETURNS TABLE(tissue_id public.citext, tissue public.citext, experiments integer, datasets integer, instruments integer, instrument_first public.citext, instrument_last public.citext, dataset_or_exp_created_min timestamp without time zone, dataset_or_exp_created_max timestamp without time zone, organism_first public.citext, organism_last public.citext, campaign_first public.citext, campaign_last public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate tissue usage statistics for experiments
**
**      Used by web page https://dms2.pnl.gov/tissue_stats/param
**      when it calls report_tissue_usage_stats_proc
**
**  Arguments:
**    _startDate                Start date; if an empty string, use 2 weeks before _endDate
**    _endDate                  End date;   if an empty string, use today as end date
**                              If _instrumentFilterList is empty, filters on experiment creation date; if _instrumentFilterList is not empty, filters on dataset acquisition time (or t_dataset.created if acquisition time is null)
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _organismIDFilterList     Comma separated list of organism IDs
**    _instrumentFilterList     Comma-separated list of instrument names; % and * wildcards are allowed ('*' is auto-changed to '%'); if empty, dataset stats are not returned
**
**  Auth:   mem
**  Date:   07/23/2019 mem - Initial version
**          02/20/2024 mem - Ported to PostgreSQL
**          05/29/2024 mem - For data validation errors, return a single row that has the error message in the instrument_last column
**
*****************************************************/
DECLARE
    _result int;
    _stDate timestamp;
    _eDate timestamp;
    _message text;
    _returnCode text;
    _invalidOrganismIDs text;
    _nullDate timestamp := null;
    _logErrors boolean := true;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _msg citext;
BEGIN

    BEGIN

        --------------------------------------------------------------------
        -- Validate the inputs
        --------------------------------------------------------------------

        _startDate            := Trim(Coalesce(_startDate, ''));
        _endDate              := Trim(Coalesce(_endDate, ''));
        _campaignIDFilterList := Trim(Coalesce(_campaignIDFilterList, ''));
        _organismIDFilterList := Trim(Coalesce(_organismIDFilterList, ''));
        _instrumentFilterList := Trim(Coalesce(_instrumentFilterList, ''));

        --------------------------------------------------------------------
        -- Populate a temporary table with the campaign IDs to filter on
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_CampaignFilter (
            Campaign_ID int NOT NULL,
            Fraction_EMSL_Funded numeric NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_CampaignFilter ON Tmp_CampaignFilter (Campaign_ID);

        CALL public.populate_campaign_filter_table (
                        _campaignIDFilterList,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the Instrument IDs to filter on
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentFilter (
            Instrument_ID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_InstrumentFilter ON Tmp_InstrumentFilter (Instrument_ID);

        If _instrumentFilterList <> '' Then
            CALL public.populate_instrument_filter_table (
                            _instrumentFilterList,
                            _message    => _message,        -- Output
                            _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _logErrors := false;
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the organisms to filter on
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_OrganismFilter (
            Organism_ID int NOT NULL,
            Organism_Name text NULL
        );

        CREATE INDEX IX_Tmp_OrganismFilter ON Tmp_OrganismFilter (Organism_ID);

        If _organismIDFilterList <> '' Then
            INSERT INTO Tmp_OrganismFilter (Organism_ID)
            SELECT DISTINCT Value
            FROM public.parse_delimited_integer_list(_organismIDFilterList)
            ORDER BY Value;

            -- Look for invalid organism ID values

            SELECT string_agg(OrgFilter.organism_id::text, ',' ORDER BY OrgFilter.organism_id)
            INTO _invalidOrganismIDs
            FROM Tmp_OrganismFilter OrgFilter
                 LEFT OUTER JOIN t_organisms Org
                   ON OrgFilter.organism_id = Org.organism_id
            WHERE Org.organism_id IS NULL;

            If Coalesce(_invalidOrganismIDs, '') <> '' Then
                _logErrors := false;

                If _invalidOrganismIDs Like '%,%' Then
                    RAISE EXCEPTION 'Invalid organism IDs: %', _invalidOrganismIDs;
                Else
                    RAISE EXCEPTION 'Invalid organism ID: %', _invalidOrganismIDs;
                End If;
            End If;
        Else
            INSERT INTO Tmp_OrganismFilter (Organism_ID, Organism_Name)
            SELECT organism_id, organism
            FROM t_organisms
            ORDER BY organism_id;
        End If;

        --------------------------------------------------------------------
        -- Determine the start and end dates
        --------------------------------------------------------------------

        CALL public.resolve_start_and_end_dates (
                        _startDate  => _startDate,      -- Start date, as text
                        _endDate    => _endDate,        -- End date, as text
                        _stDate     => _stDate,         -- Output: start date, as a timestamp
                        _eDate      => _eDate,          -- Output: end date, as a timestamp
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Generate the report
        ---------------------------------------------------

        If _instrumentFilterList <> '' Then
            -- Filter on instrument and use dataset acquisition times for the date filter

            If Not Exists (SELECT Instrument_ID FROM Tmp_InstrumentFilter) Then

                RETURN QUERY
                SELECT ''::citext AS Tissue_ID,
                       ''::citext AS Tissue,
                       0 AS Experiments,
                       0 AS Datasets,
                       0 AS Instruments,
                       'Warning'::citext AS Instrument_First,
                       'No instruments matched the instrument name filter'::citext AS Instrument_Last,
                       _nullDate AS Dataset_or_Exp_Created_Min,
                       _nullDate AS Dataset_or_Exp_Created_Max,
                       ''::citext AS Organism_First,
                       ''::citext AS Organism_Last,
                       ''::citext AS Campaign_First,
                       ''::citext AS Campaign_Last;
            Else
                -- Use dataset acquisition time (or creation time) for the date filter
                RETURN QUERY
                SELECT E.tissue_id AS Tissue_ID,
                       BTO.tissue AS Tissue,
                       COUNT(DISTINCT E.exp_id)::int AS Experiments,
                       COUNT(DISTINCT DS.dataset_id)::int AS Datasets,
                       COUNT(DISTINCT InstName.instrument_id)::int AS Instruments,
                       MIN(InstName.instrument) AS Instrument_First,
                       MAX(InstName.instrument) AS Instrument_Last,
                       MIN(Coalesce(DS.acq_time_start, DS.created)) AS Dataset_or_Exp_Created_Min,  -- Oldest dataset acq time or created date
                       MAX(Coalesce(DS.acq_time_start, DS.created)) AS Dataset_or_Exp_Created_Max,  -- Newest dataset acq time or created date
                       MIN(Org.organism) AS Organism_First,
                       MAX(Org.organism) AS Organism_Last,
                       MIN(C.campaign) AS Campaign_First,
                       MAX(C.campaign) AS Campaign_Last
                FROM t_dataset DS
                     INNER JOIN t_experiments E
                       ON E.exp_id = DS.exp_id
                     INNER JOIN t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                     INNER JOIN Tmp_InstrumentFilter InstFilter
                       ON DS.instrument_id = InstFilter.instrument_id
                     INNER JOIN Tmp_CampaignFilter CampaignFilter
                       ON E.campaign_id = CampaignFilter.campaign_id
                     INNER JOIN Tmp_OrganismFilter OrgFilter
                       ON E.organism_id = OrgFilter.organism_id
                     INNER JOIN t_campaign C
                       ON E.campaign_id = C.campaign_id
                     INNER JOIN t_organisms Org
                       ON E.organism_id = Org.organism_id
                     LEFT OUTER JOIN ont.V_BTO_ID_to_Name BTO
                       ON E.tissue_id = BTO.Identifier
                WHERE Coalesce(DS.acq_time_start, DS.created) BETWEEN _stDate AND _eDate
                GROUP BY E.tissue_id, BTO.tissue;

            End If;
        Else
            -- Use experiment creation time for the date filter
            RETURN QUERY
            SELECT E.tissue_id AS Tissue_ID,
                   BTO.tissue,
                   COUNT(E.exp_id)::int AS Experiments,
                   0 AS Datasets,
                   0 AS Instruments,
                   ''::citext Instrument_First,
                   ''::citext AS Instrument_Last,
                   MIN(E.created) AS Dataset_or_Exp_Created_Min,    -- Oldest experiment created date
                   MAX(E.created) AS Dataset_or_Exp_Created_Max,    -- Newest experiment created date
                   MIN(Org.organism) AS Organism_First,
                   MAX(Org.organism) AS Organism_Last,
                   MIN(C.campaign) AS Campaign_First,
                   MAX(C.campaign) AS Campaign_Last
            FROM t_experiments E
                 INNER JOIN Tmp_CampaignFilter CampaignFilter
                   ON E.campaign_id = CampaignFilter.campaign_id
                 INNER JOIN Tmp_OrganismFilter OrgFilter
                   ON E.organism_id = OrgFilter.organism_id
                 INNER JOIN t_campaign C
                   ON E.campaign_id = C.campaign_id
                 INNER JOIN t_organisms Org
                   ON E.organism_id = Org.organism_id
                 LEFT OUTER JOIN ont.V_BTO_ID_to_Name BTO
                   ON E.tissue_id = BTO.Identifier
            WHERE E.created BETWEEN _stDate AND _eDate
            GROUP BY E.tissue_id, BTO.tissue;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _msg := _exceptionMessage;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;

            -- There was a data validation error
            -- Return a single row, displaying the error message in the instrument_last column

            RETURN QUERY
            SELECT ''::citext,         -- tissue_id
                   ''::citext,         -- tissue
                   0,                  -- experiments
                   0,                  -- datasets
                   0,                  -- instruments
                   'Warning'::citext,  -- instrument_first
                   _msg,               -- instrument_last
                   null::timestamp,    -- dataset_or_exp_created_min
                   null::timestamp,    -- dataset_or_exp_created_max
                   ''::citext,         -- organism_first
                   ''::citext,         -- organism_last
                   ''::citext,         -- campaign_first
                   ''::citext;         -- campaign_last
        End If;

        RAISE WARNING '%', _message;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_CampaignFilter;
    DROP TABLE IF EXISTS Tmp_InstrumentFilter;
    DROP TABLE IF EXISTS Tmp_OrganismFilter;
END
$$;


ALTER FUNCTION public.report_tissue_usage_stats(_startdate text, _enddate text, _campaignidfilterlist text, _organismidfilterlist text, _instrumentfilterlist text) OWNER TO d3l243;

--
-- Name: FUNCTION report_tissue_usage_stats(_startdate text, _enddate text, _campaignidfilterlist text, _organismidfilterlist text, _instrumentfilterlist text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.report_tissue_usage_stats(_startdate text, _enddate text, _campaignidfilterlist text, _organismidfilterlist text, _instrumentfilterlist text) IS 'ReportTissueUsageStats';


--
CREATE OR REPLACE PROCEDURE public.report_tissue_usage_stats
(
    _startDate text,
    _endDate text,
    _campaignIDFilterList text = '',
    _organismIDFilterList text = '',
    _instrumentFilterList text = '',
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Generates tissue usage statistics for experiments
**
**  Arguments:
**    _startDate              If _instrumentFilterList is empty, filter on experiment creation date.  If _instrumentFilterList is not empty, filter on dataset date
**    _campaignIDFilterList   Comma separated list of campaign IDs
**    _organismIDFilterList   Comma separate list of organism IDs
**    _instrumentFilterList   Comma separated list of instrument names (% and * wild cards are allowed); if empty, dataset stats are not returned
**
**  Auth:   mem
**  Date:   07/23/2019 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _result int;
    _stDate timestamp;
    _eDate timestamp;
    _msg text;
    _nullDate timestamp := Null;
    _logErrors boolean := true;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        --------------------------------------------------------------------
        -- Validate the inputs
        --------------------------------------------------------------------
        --
        _campaignIDFilterList := Trim(Coalesce(_campaignIDFilterList, ''));
        _organismIDFilterList := Trim(Coalesce(_organismIDFilterList, ''));
        _instrumentFilterList := Trim(Coalesce(_instrumentFilterList, ''));

        _message := '';

        --------------------------------------------------------------------
        -- Populate a temporary table with the Campaign IDs to filter on
        --------------------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_CampaignFilter (
            Campaign_ID int NOT NULL,
            Fraction_EMSL_Funded numeric NULL
        )

        CREATE UNIQUE INDEX IX_Tmp_CampaignFilter ON Tmp_CampaignFilter (Campaign_ID);

        Call populate_campaign_filter_table (_campaignIDFilterList, _message => _message, _returnCode => _returnCode);

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the Instrument IDs to filter on
        --------------------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_InstrumentFilter (
            Instrument_ID int NOT NULL
        )

        CREATE UNIQUE INDEX IX_Tmp_InstrumentFilter ON Tmp_InstrumentFilter (Instrument_ID);

        If char_length(_instrumentFilterList) > 0 Then
            Call populate_instrument_filter_table (_instrumentFilterList, _message => _message, _returnCode => _returnCode);

            If _returnCode <> '' Then
                _logErrors := false;
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the organisms to filter on
        --------------------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_OrganismFilter (
            Organism_ID int NOT NULL,
            Organism_Name text NULL
        )

        CREATE INDEX IX_Tmp_OrganismFilter ON Tmp_OrganismFilter (Organism_ID);

        If _organismIDFilterList <> '' Then
            INSERT INTO Tmp_OrganismFilter (Organism_ID)
            SELECT DISTINCT Value
            FROM public.parse_delimited_integer_list(_organismIDFilterList, ',')
            ORDER BY Value

            -- Look for invalid Organism ID values

            SELECT string_agg(OrgFilter.organism_id::text, ',')
            INTO _msg
            FROM Tmp_OrganismFilter OrgFilter
                 LEFT OUTER JOIN t_organisms Org
                   ON OrgFilter.organism_id = Org.organism_id
            WHERE Org.organism_id IS NULL

            If Coalesce(_msg, '') <> '' Then

                If _msg Like '%,%' Then
                    _msg := 'Invalid Organism IDs: ' || _msg;
                Else
                    _msg := 'Invalid Organism ID: ' || _msg;
                End If;

                _logErrors := false;
                RAISE EXCEPTION '%', _msg;
            End If;
        Else
            INSERT INTO Tmp_OrganismFilter (organism_id, Organism_Name)
            SELECT organism_id, organism
            FROM t_organisms
            order BY organism_id
        End If;

        --------------------------------------------------------------------
        -- Determine the start and end dates
        --------------------------------------------------------------------

        Call resolve_start_and_end_dates (
            _startDate,
            _endDate,
            _stDate => _stDate,             -- Output
            _eDate => _eDate,               -- Output
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Generate the report
        ---------------------------------------------------

        If char_length(_instrumentFilterList) > 0 Then
            -- Filter on instrument and use dataset acq times for the date filter

            If Not Exists (Select * From Tmp_InstrumentFilter) Then
                SELECT '' AS Tissue_ID,
                       '' AS Tissue,
                       0 AS Experiments,
                       0 AS Datasets,
                       0 AS Instruments,
                       'Warning' AS Instrument_First,
                       'No instruments matched the instrument name filter' AS Instrument_Last,
                       _nullDate AS Dataset_Acq_Time_Min,
                       _nullDate AS Dataset_Acq_Time_Max,
                       '' AS Organism_First,
                       '' AS Organism_Last,
                       '' AS Campaign_First,
                       '' AS Campaign_Last
            Else
                SELECT E.tissue_id AS Tissue_ID,
                       BTO.Tissue AS Tissue,
                       COUNT(DISTINCT E.exp_id) AS Experiments,
                       COUNT(DISTINCT D.dataset_id) AS Datasets,
                       COUNT(DISTINCT InstName.instrument_id) AS Instruments,
                       MIN(InstName.instrument) AS Instrument_First,
                       MAX(InstName.instrument) AS Instrument_Last,
                       MIN(Coalesce(D.acq_time_start, D.created)) AS Dataset_Acq_Time_Min,
                       MAX(Coalesce(D.acq_time_start, D.created)) AS Dataset_Acq_Time_Max,
                       MIN(Org.organism) AS Organism_First,
                       MAX(Org.organism) AS Organism_Last,
                       MIN(C.campaign) AS Campaign_First,
                       MAX(C.campaign) AS Campaign_Last
                FROM t_dataset D
                     INNER JOIN t_experiments E
                       ON E.exp_id = D.exp_id
                     INNER JOIN t_instrument_name InstName
                       ON D.instrument_id = InstName.instrument_id
                     INNER JOIN Tmp_InstrumentFilter InstFilter
                       ON D.instrument_id = InstFilter.instrument_id
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
                WHERE Coalesce(D.acq_time_start, D.created) BETWEEN _stDate AND _eDate
                GROUP BY tissue_id, BTO.Tissue;

            End If;
        Else
            -- Use experiment creation time for the date filter

            SELECT E.tissue_id AS Tissue_ID,
                   BTO.Tissue,
                   COUNT(E.exp_id) AS Experiments,
                   MIN(E.created) AS Exp_Created_Min,
                   MAX(E.created) AS Exp_Created_Max,
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
            GROUP BY tissue_id, BTO.Tissue;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_CampaignFilter;
    DROP TABLE IF EXISTS Tmp_InstrumentFilter;
    DROP TABLE IF EXISTS Tmp_OrganismFilter;
END
$$;

COMMENT ON PROCEDURE public.report_tissue_usage_stats IS 'ReportTissueUsageStats';

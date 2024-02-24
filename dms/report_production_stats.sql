--
-- Name: report_production_stats(text, text, integer, text, text, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.report_production_stats(_startdate text, _enddate text, _productiononly integer DEFAULT 1, _campaignidfilterlist text DEFAULT ''::text, _eususagefilterlist text DEFAULT ''::text, _instrumentfilterlist text DEFAULT ''::text, _includeproposaltype integer DEFAULT 0, _showdebug boolean DEFAULT false) RETURNS TABLE(instrument public.citext, total_datasets numeric, days_in_range integer, datasets_per_day numeric, blank_datasets numeric, qc_datasets numeric, bad_datasets numeric, study_specific_datasets numeric, study_specific_datasets_per_day numeric, emsl_funded_study_specific_datasets numeric, ef_study_specific_datasets_per_day numeric, total_acqtimedays numeric, study_specific_acqtimedays numeric, ef_total_acqtimedays numeric, ef_study_specific_acqtimedays numeric, hours_acqtime_per_day numeric, inst_ public.citext, pct_inst_emsl_owned integer, ef_total_datasets numeric, ef_datasets_per_day numeric, pct_blank_datasets numeric, pct_qc_datasets numeric, pct_bad_datasets numeric, pct_study_specific_datasets numeric, pct_ef_study_specific_datasets numeric, pct_ef_study_specific_by_acqtime numeric, proposal_type public.citext, inst public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate dataset statistics for production instruments
**
**      Used by web page https://dms2.pnl.gov/production_instrument_stats/param
**      when it calls report_production_stats_proc
**
**  Arguments:
**    _startDate                Start date; if an empty string, use 2 weeks before _endDate
**    _endDate                  End date;   if an empty string, use today as end date
**    _productionOnly           When 0 then shows all instruments; otherwise limits the report to production instruments only (operations_role = 'Production'); leave as an integer for compatibility with the website
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _eusUsageFilterList       Comma-separated list of EUS usage types, from table t_eus_usage_type: CAP_DEV, MAINTENANCE, BROKEN, USER_ONSITE, USER_REMOTE, RESOURCE_OWNER
**    _instrumentFilterList     Comma-separated list of instrument names; % and * wildcards are allowed ('*' is auto-changed to '%')
**    _includeProposalType      When 1, include proposal type in the results; leave as an integer for compatibility with the website
**    _showDebug                When true, summarize the contents of Tmp_Datasets
**
**  Auth:   grk
**  Date:   02/25/2005
**          03/01/2005 grk - Added column for instrument name at end
**          12/19/2005 grk - Added 'MD' and 'TS' prefixes (ticket #345)
**          08/17/2007 mem - Updated to examine Dataset State and Dataset Rating when counting Bad and Blank datasets (ticket #520)
**                         - Now excluding TS datasets from the Study Specific Datasets total (in addition to excluding Blank, QC, and Bad datasets)
**                         - Now extending the end date to 11:59:59 pm on the given day if _endDate does not contain a time component
**          04/25/2008 grk - Added "% Blank Datasets" column
**          08/30/2010 mem - Added parameter _productionOnly and updated to allow _startDate and/or _endDate to be blank
**                         - Add try/catch error handling
**          09/08/2010 mem - Now grouping Method Development (MD) datasets in with Troubleshooting datasets
**                         - Added checking for invalid dates
**          09/09/2010 mem - Now reporting % Study Specific datasets
**          09/26/2010 grk - Added accounting for reruns
**          02/03/2011 mem - Now using Dataset Acq Time (Acq_Time_Start) instead of Dataset Created (Created), provided Acq_Time_Start is not null
**          03/30/2011 mem - Now reporting number of Unreviewed datasets
**                         - Removed the Troubleshooting column since datasets are no longer being updated that start with TS or MD
**          11/30/2011 mem - Added parameter _campaignIDFilterList
**                         - Added column "% EMSL Owned"
**                         - Added new columns, including '% EMSL Owned', 'EMSL-Funded Study Specific Datasets', and 'EF Study Specific Datasets per day'
**          03/15/2012 mem - Added parameter _eusUsageFilterList
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to Parse_Delimited_List
**          04/05/2017 mem - Determine whether a dataset is EMSL funded using EUS usage type (previously used Fraction_EMSL_Funded, which is estimated by the user for each campaign)
**                         - No longer differentiate reruns or unreviewed
**                         - Added parameter _instrumentFilterList
**                         - Changed [% EF Study Specific] to be based on Total instead of EF_Total
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Report AcqTimeDay, columns [Total AcqTimeDays], [Study Specific AcqTimeDays], [EF Total AcqTimeDays], [EF Study Specific AcqTimeDays], and [Hours AcqTime per Day]
**          04/13/2017 mem - If the work package for a dataset has Wiley Environmental, flag the dataset as EMSL funded
**                         - If the campaign for a dataset has Fraction_EMSL_Funded of 0.75 or more, flag the dataset as EMSL Funded
**          04/20/2018 mem - Allow Request_ID to be null
**          04/27/2018 mem - Add column [% EF Study Specific by AcqTime]
**          07/22/2019 mem - Refactor code into PopulateCampaignFilterTable, PopulateInstrumentFilterTable, and ResolveStartAndEndDates
**          05/16/2022 mem - Treat 'Resource Owner' proposals as not EMSL funded
**          05/18/2022 mem - Treat additional proposal types as not EMSL funded
**          10/12/2022 mem - Add _showDebug
**                         - No longer use Fraction_EMSL_Funded from t_campaign to determine EMSL funding status
**          02/25/2023 bcg - Update output table column names to lower-case and no special characters
**          03/17/2023 mem - Add @includeProposalType
**          03/20/2023 mem - Treat proposal types 'Capacity' and 'Staff Time' as EMSL funded
**          02/19/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result int;
    _daysInRange numeric;
    _stDate timestamp;
    _eDate timestamp;
    _message text;
    _returnCode text;
    _valueList text;
    _eDateAlternate timestamp;
    _datasetInfo record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        --------------------------------------------------------------------
        -- Validate the inputs
        --------------------------------------------------------------------

        _startDate            := Trim(Coalesce(_startDate, ''));
        _endDate              := Trim(Coalesce(_endDate, ''));
        _productionOnly       := Coalesce(_productionOnly, 1);
        _campaignIDFilterList := Trim(Coalesce(_campaignIDFilterList, ''));
        _eusUsageFilterList   := Trim(Coalesce(_eusUsageFilterList, ''));
        _instrumentFilterList := Trim(Coalesce(_instrumentFilterList, ''));
        _includeProposalType  := Coalesce(_includeProposalType, 0);
        _showDebug            := Coalesce(_showDebug, false);

        --------------------------------------------------------------------
        -- Populate a temporary table with the Campaign IDs to filter on
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
            If _showDebug Then
                RAISE INFO '%', _message;

                DROP TABLE Tmp_CampaignFilter;
                RETURN;
            Else
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the Instrument IDs to filter on
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentFilter (
            Instrument_ID int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_InstrumentFilter ON Tmp_InstrumentFilter (Instrument_ID);

        CALL public.populate_instrument_filter_table (
                        _instrumentFilterList,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            If _showDebug Then
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_CampaignFilter;
                DROP TABLE Tmp_InstrumentFilter;

                RETURN;
            Else
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Populate a temporary table with the EUS Usage types to filter on
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_EUSUsageFilter (
            Usage_ID int NOT NULL,
            Usage_Name citext NOT NULL
        );

        CREATE INDEX IX_Tmp_EUSUsageFilter ON Tmp_EUSUsageFilter (Usage_ID);

        If _eusUsageFilterList <> '' Then
            INSERT INTO Tmp_EUSUsageFilter (Usage_Name, Usage_ID)
            SELECT DISTINCT Value AS Usage_Name, 0 AS ID
            FROM public.parse_delimited_list(_eusUsageFilterList)
            ORDER BY Value;

            -- Look for invalid Usage_Name values

            SELECT string_agg(UF.Usage_Name, ',' ORDER BY UF.Usage_Name)
            INTO _valueList
            FROM Tmp_EUSUsageFilter UF
                 LEFT OUTER JOIN t_eus_usage_type U
                   ON UF.Usage_Name = U.eus_usage_type
            WHERE U.eus_usage_type_id IS NULL;

            If Coalesce(_valueList, '') <> '' Then
                _message := format('Invalid Usage Type(s): %s', _valueList);

                SELECT string_agg(eus_usage_type, ', ' ORDER BY eus_usage_type)
                INTO _valueList
                FROM t_eus_usage_type
                WHERE eus_usage_type_id <> 1;   -- EUS usage type 1 is 'Undefined'

                _message := format('%s; known types are: %s', _message, _valueList);

                RAISE INFO '%', _message;

                If _showDebug Then
                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_CampaignFilter;
                    DROP TABLE Tmp_InstrumentFilter;
                    DROP TABLE Tmp_EUSUsageFilter;

                    RETURN;
                Else
                    RAISE EXCEPTION '%', _message;
                End If;
            End If;

            -- Update column Usage_ID

            UPDATE Tmp_EUSUsageFilter
            SET Usage_ID = U.eus_usage_type_id
            FROM t_eus_usage_type U
            WHERE Usage_Name = U.eus_usage_type;

        Else
            INSERT INTO Tmp_EUSUsageFilter (Usage_ID, Usage_Name)
            SELECT eus_usage_type_id, eus_usage_type
            FROM t_eus_usage_type
            ORDER BY eus_usage_type_id;
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
            If _showDebug Then
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_CampaignFilter;
                DROP TABLE Tmp_InstrumentFilter;
                DROP TABLE Tmp_EUSUsageFilter;

                RETURN;
            Else
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Compute the number of days to be examined
        --------------------------------------------------------------------

        _daysInRange := Round(Extract(epoch from _eDate - _stDate) / 86400);

        --------------------------------------------------------------------
        -- Populate a temporary table with the datasets to use
        --------------------------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
            Dataset_ID int NOT NULL,
            Campaign_ID int NOT NULL,
            Request_ID int NULL,            -- Every dataset should have a Request ID, but on rare occasions a dataset gets created without a RequestID; thus, allow this field to have null values
            EMSL_Funded int NOT NULL,       -- 0 if not EMSL-funded, 1 if EMSL-funded
            Proposal_Type citext            -- Resource Owner, Intramural S&T, Capacity, Staff Time, Large-Scale EMSL Research, FICUS Research, etc.
        );

        CREATE INDEX IX_Tmp_Datasets ON Tmp_Datasets (Dataset_ID, Campaign_ID);

        CREATE INDEX IX_Tmp_Datasets_RequestID ON Tmp_Datasets (Request_ID);

        If _eusUsageFilterList <> '' Then
            -- Filter on the EMSL usage types defined in Tmp_EUSUsageFilter

            INSERT INTO Tmp_Datasets( Dataset_ID,
                                      Campaign_ID,
                                      Request_ID,
                                      EMSL_Funded,
                                      Proposal_Type )
            SELECT DS.dataset_id,
                   E.campaign_id,
                   RR.request_id,
                   CASE
                       WHEN Coalesce(EUP.Proposal_Type, 'PROPRIETARY')
                            IN ('Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') THEN 0  -- Not EMSL Funded
                       ELSE 1             -- EMSL Funded:
                                          -- 'Exploratory Research', 'FICUS JGI-EMSL', 'FICUS Research', 'Intramural S&T',
                                          -- 'Large-Scale EMSL Research', 'Limited Scope', 'Science Area Research',
                                          -- 'Capacity', 'Staff Time'
                   END AS EMSL_Funded,
                   EUP.Proposal_Type
            FROM t_dataset DS
                 INNER JOIN t_experiments E
                   ON E.exp_id = DS.exp_id
                 INNER JOIN Tmp_InstrumentFilter InstFilter
                   ON DS.instrument_id = InstFilter.instrument_id
                 INNER JOIN t_requested_run RR
                   ON DS.dataset_id = RR.dataset_id
                 INNER JOIN t_eus_proposals EUP
                   ON RR.eus_proposal_id = EUP.proposal_id
            WHERE Coalesce(DS.acq_time_start, DS.created) BETWEEN _stDate AND _eDate
                  AND
                  RR.eus_usage_type_id IN ( SELECT Usage_ID
                                            FROM Tmp_EUSUsageFilter );

        Else
            -- Note that this query uses a left outer join against t_requested_run
            -- because datasets acquired before 2006 were not required to have a requested run

            INSERT INTO Tmp_Datasets( Dataset_ID,
                                      Campaign_ID,
                                      Request_ID,
                                      EMSL_Funded,
                                      Proposal_Type )
            SELECT DS.dataset_id,
                   E.campaign_id,
                   RR.request_id,
                   CASE
                       WHEN Coalesce(EUP.Proposal_Type, 'PROPRIETARY')
                            IN ('Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') THEN 0  -- Not EMSL Funded
                       ELSE 1             -- EMSL Funded:
                                          -- 'Exploratory Research', 'FICUS JGI-EMSL', 'FICUS Research', 'Intramural S&T',
                                          -- 'Large-Scale EMSL Research', 'Limited Scope', 'Science Area Research',
                                          -- 'Capacity', 'Staff Time'
                   END AS EMSL_Funded,
                   EUP.Proposal_Type
            FROM t_dataset DS
                 INNER JOIN t_experiments E
                   ON E.exp_id = DS.exp_id
                 INNER JOIN Tmp_InstrumentFilter InstFilter
                   ON DS.instrument_id = InstFilter.instrument_id
                 LEFT OUTER JOIN t_requested_run RR
                   ON DS.dataset_id = RR.dataset_id
                 LEFT OUTER JOIN t_eus_proposals EUP
                   ON RR.eus_proposal_id = EUP.proposal_id
            WHERE Coalesce(DS.acq_time_start, DS.created) BETWEEN _stDate AND _eDate;

        End If;

        If _showDebug Then

            RAISE INFO '';
            RAISE INFO 'Initial contents of Tmp_Datasets';

            FOR _datasetInfo IN
                SELECT EMSL_Funded AS EmslFunded,
                       COUNT(Dataset_ID) AS DatasetCount,
                       MIN(Dataset_ID) AS IdFirst,
                       MAX(Dataset_ID) AS IdLast
                FROM Tmp_Datasets
                GROUP BY EMSL_Funded
                ORDER BY EMSL_Funded
            LOOP
                RAISE INFO '% datasets with EMSL_Funded = %; dataset IDs from % to %',
                            _datasetInfo.DatasetCount, _datasetInfo.EmslFunded, _datasetInfo.IdFirst, _datasetInfo.IdLast;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Examine the work package associated with datasets in Tmp_Datasets
        -- to find additional datasets that are EMSL-Funded
        ---------------------------------------------------

        UPDATE Tmp_Datasets DS
        SET EMSL_Funded = 1
        FROM t_requested_run RR
             INNER JOIN t_charge_code CC
               ON RR.work_package = CC.charge_code
        WHERE DS.request_id = RR.request_id AND
              DS.EMSL_Funded = 0 AND
              CC.sub_account_title LIKE '%Wiley Environmental%';

        If _showDebug And FOUND Then

            RAISE INFO '';
            RAISE INFO 'After updating EMSL_Funded for work packages with SubAccount containing "Wiley Environmental"';

            FOR _datasetInfo IN
                SELECT EMSL_Funded AS EmslFunded,
                       COUNT(Dataset_ID) AS DatasetCount,
                       MIN(Dataset_ID) AS IdFirst,
                       MAX(Dataset_ID) AS IdLast
                FROM Tmp_Datasets
                GROUP BY EMSL_Funded
                ORDER BY EMSL_Funded
            LOOP
                RAISE INFO '% datasets with EMSL_Funded = %; dataset IDs from % to %',
                            _datasetInfo.DatasetCount, _datasetInfo.EmslFunded, _datasetInfo.IdFirst, _datasetInfo.IdLast;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Generate report
        ---------------------------------------------------

        If _includeProposalType > 0 Then

            RETURN QUERY
            SELECT
                OuterQ.Instrument,
                OuterQ.Total AS total_datasets,
                _daysInRange::int AS days_in_range,
                Round(OuterQ.Total / _daysInRange, 1) AS datasets_per_day,
                OuterQ.Blank AS blank_datasets,
                OuterQ.QC AS qc_datasets,
                -- OuterQ.TS AS troubleshooting,
                OuterQ.Bad AS bad_datasets,
                OuterQ.Study_Specific AS study_specific_datasets,
                Round(OuterQ.Study_Specific / _daysInRange, 1) AS study_specific_datasets_per_day,
                OuterQ.EF_Study_Specific AS emsl_funded_study_specific_datasets,
                Round(OuterQ.EF_Study_Specific / _daysInRange, 1) AS ef_study_specific_datasets_per_day,

                Round(OuterQ.Total_AcqTimeDays, 1) AS total_acqtimedays,
                Round(OuterQ.Study_Specific_AcqTimeDays, 1) AS study_specific_acqtimedays,
                Round(OuterQ.EF_Total_AcqTimeDays, 1) AS ef_total_acqtimedays,
                Round(OuterQ.EF_Study_Specific_AcqTimeDays, 1) AS ef_study_specific_acqtimedays,
                Round(OuterQ.Hours_AcqTime_per_Day, 1) AS hours_acqtime_per_day,
                OuterQ.Instrument AS inst_,                        -- Yes, this column name ends with an underscore; the website will show this column as "Inst."
                OuterQ.Percent_EMSL_Owned AS pct_inst_emsl_owned,

                -- EMSL Funded Counts:
                Round(OuterQ.EF_Total, 2) AS ef_total_datasets,
                Round(OuterQ.EF_Total/_daysInRange, 1) AS ef_datasets_per_day,
                -- Round(OuterQ.EF_Blank, 2) AS ef_blank_datasets,
                -- Round(OuterQ.EF_QC, 2) AS ef_qc_datasets,
                -- Round(OuterQ.EF_Bad, 2) AS ef_bad_datasets,

                Round(OuterQ.Blank * 100.0 / OuterQ.Total, 1) AS pct_blank_datasets,
                Round(OuterQ.QC    * 100.0 / OuterQ.Total, 1) AS pct_qc_datasets,
                Round(OuterQ.Bad   * 100.0 / OuterQ.Total, 1) AS pct_bad_datasets,
                -- Round(OuterQ.Reruns * 100.0 / Total, 1) AS pct_reruns,
                Round(OuterQ.Study_Specific * 100.0 / OuterQ.Total, 1) AS pct_study_specific_datasets,
                CASE WHEN OuterQ.Total > 0 THEN Round(OuterQ.EF_Study_Specific * 100.0 / OuterQ.Total, 1) ELSE NULL END AS pct_ef_study_specific_datasets,
                CASE WHEN OuterQ.Total_AcqTimeDays > 0 THEN Round(OuterQ.EF_Total_AcqTimeDays * 100.0 / OuterQ.Total_AcqTimeDays, 1) ELSE NULL END AS pct_ef_study_specific_by_acqtime,
                OuterQ.proposal_type,
                OuterQ.Instrument AS inst
            FROM (
                SELECT CombinedStatsQ.Instrument,
                       CombinedStatsQ.Percent_EMSL_Owned,
                       CombinedStatsQ.Proposal_Type,
                       CombinedStatsQ.Total,
                       CombinedStatsQ.Bad,
                       CombinedStatsQ.Blank,
                       CombinedStatsQ.QC,
                       CombinedStatsQ.Total - (CombinedStatsQ.Blank + CombinedStatsQ.QC + CombinedStatsQ.Bad) AS Study_Specific,
                       CombinedStatsQ.Total_AcqTimeDays,
                       CombinedStatsQ.Total_AcqTimeDays - CombinedStatsQ.BadBlankQC_AcqTimeDays AS Study_Specific_AcqTimeDays,
                       CASE WHEN _daysInRange > 0.5 THEN CombinedStatsQ.Total_AcqTimeDays / _daysInRange * 24 ELSE Null END AS Hours_AcqTime_per_Day,
                       CombinedStatsQ.EF_Total,
                       CombinedStatsQ.EF_Bad,
                       CombinedStatsQ.EF_Blank,
                       CombinedStatsQ.EF_QC,
                       CombinedStatsQ.EF_Total - (CombinedStatsQ.EF_Blank + CombinedStatsQ.EF_QC + CombinedStatsQ.EF_Bad) AS EF_Study_Specific,
                       CombinedStatsQ.EF_Total_AcqTimeDays,
                       CombinedStatsQ.EF_Total_AcqTimeDays - CombinedStatsQ.EF_BadBlankQC_AcqTimeDays AS EF_Study_Specific_AcqTimeDays
                FROM
                    (SELECT StatsQ.Instrument,
                            StatsQ.Percent_EMSL_Owned,
                            StatsQ.Proposal_Type,
                            SUM(StatsQ.Total) AS Total,        -- Total (Good + bad)
                            SUM(StatsQ.Bad) AS Bad,            -- Bad (not blank)
                            SUM(StatsQ.Blank) AS Blank,        -- Blank (Good + bad)
                            SUM(StatsQ.QC) AS QC,              -- QC (not bad)

                            SUM(StatsQ.Total_AcqTimeDays) AS Total_AcqTimeDays,            -- Total time acquiring data
                            SUM(StatsQ.BadBlankQC_AcqTimeDays) AS BadBlankQC_AcqTimeDays,  -- Total time acquiring bad/blank/QC data

                            -- EMSL Funded (EF) Counts:
                            SUM(StatsQ.EF_Total) AS EF_Total,        -- EF Total (Good + bad)
                            SUM(StatsQ.EF_Bad) AS EF_Bad,            -- EF Bad (not blank)
                            SUM(StatsQ.EF_Blank) AS EF_Blank,        -- EF Blank (Good + bad)
                            SUM(StatsQ.EF_QC) AS EF_QC,              -- EF QC (not bad)

                            SUM(StatsQ.EF_Total_AcqTimeDays) AS EF_Total_AcqTimeDays,                 -- EF Total time acquiring data
                            SUM(StatsQ.EF_BadBlankQC_AcqTimeDays) AS EF_BadBlankQC_AcqTimeDays        -- EF Total time acquiring bad/blank/QC data

                    FROM
                        (    -- Select Good datasets (excluded Bad, Not Released, Unreviewed, etc.)
                            SELECT
                                I.Instrument,
                                I.Percent_EMSL_Owned,
                                DF.Proposal_Type,
                                COUNT(DS.dataset_id) AS Total,                                        -- Total
                                0 AS Bad,                                                             -- Bad
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN 1 ELSE 0 END) AS Blank,   -- Blank
                                SUM(CASE WHEN DS.Dataset LIKE 'QC%' THEN 1 ELSE 0 END)    AS QC,      -- QC
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS Total_AcqTimeDays,        -- Total time acquiring data, in days
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' OR DS.Dataset LIKE 'QC%'
                                         THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS BadBlankQC_AcqTimeDays,

                                -- EMSL Funded Counts:
                                SUM(DF.EMSL_Funded) AS EF_Total,                                                      -- EF_Total
                                0 AS EF_Bad,                                                                          -- EF_Bad
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Blank,   -- EF_Blank
                                SUM(CASE WHEN DS.Dataset LIKE 'QC%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_QC,         -- EF_QC
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS EF_Total_AcqTimeDays, -- EF Total time acquiring data, in days
                                SUM(CASE WHEN DF.EMSL_Funded = 1 And (DS.Dataset LIKE 'Blank%' OR DS.Dataset LIKE 'QC%')
                                         THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS EF_BadBlankQC_AcqTimeDays
                            FROM Tmp_Datasets DF
                                 INNER JOIN t_dataset DS
                                   ON DF.dataset_id = DS.dataset_id
                                 INNER JOIN t_instrument_name I
                                   ON DS.instrument_id = I.instrument_id
                                 INNER JOIN Tmp_CampaignFilter CF
                                   ON CF.Campaign_ID = DF.Campaign_ID
                            WHERE NOT (DS.dataset LIKE 'Bad%' OR
                                       DS.dataset_rating_id IN (- 1, - 2, - 5) OR
                                       DS.dataset_state_id = 4) AND
                                      (I.operations_role = 'Production' OR
                                       _productionOnly = 0)
                            GROUP BY I.instrument, I.percent_emsl_owned, DF.Proposal_Type
                            UNION
                            -- Select Bad or Not Released datasets
                            SELECT
                                I.Instrument,
                                I.Percent_EMSL_Owned,
                                DF.Proposal_Type,
                                COUNT(DS.dataset_id) AS Total,                                           -- Total
                                SUM(CASE WHEN DS.Dataset NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS Bad,    -- Bad (not blank)
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN 1 ELSE 0 END)     AS Blank,  -- Bad Blank; will be counted as a blank
                                0 AS QC,                                                                 -- Bad QC; simply counted as Bad
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS Total_AcqTimeDays,           -- Total time acquiring data, in days
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS BadBlankQC_AcqTimeDays,

                                -- EMSL Funded Counts:
                                SUM(DF.EMSL_Funded) AS EF_Total,                                                      -- EF_Total
                                SUM(CASE WHEN DS.dataset NOT LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Bad, -- EF_Bad (not blank)
                                SUM(CASE WHEN DS.dataset LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Blank,   -- Bad EF_Blank; will be counted as a blank
                                0 AS EF_QC,                                                                           -- Bad EF_QC; simply counted as 'Bad'
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.acq_length_minutes / 60.0 / 24.0 Else 0 End) AS EF_Total_AcqTimeDays, -- EF Total time acquiring data, in days
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.acq_length_minutes / 60.0 / 24.0 Else 0 End) AS EF_BadBlankQC_AcqTimeDays
                            FROM Tmp_Datasets DF
                                 INNER JOIN t_dataset DS
                                   ON DF.dataset_id = DS.dataset_id
                                 INNER JOIN t_instrument_name I
                                   ON DS.instrument_id = I.instrument_id
                                 INNER JOIN Tmp_CampaignFilter CF
                                   ON CF.Campaign_ID = DF.Campaign_ID
                            WHERE (DS.dataset LIKE 'Bad%' OR
                                   DS.dataset_rating_id IN (- 1, - 2, - 5) OR
                                   DS.dataset_state_id = 4) AND
                                  (I.operations_role = 'Production' OR
                                   _productionOnly = 0)
                            GROUP BY I.instrument, I.percent_emsl_owned, DF.Proposal_Type
                        ) StatsQ
                    GROUP BY StatsQ.instrument, StatsQ.percent_emsl_owned, StatsQ.proposal_type
                    ) CombinedStatsQ
                ) OuterQ
            ORDER BY OuterQ.instrument, OuterQ.proposal_type;

        Else

            RETURN QUERY
            SELECT
                OuterQ.instrument,
                OuterQ.Total AS total_datasets,
                _daysInRange::int AS days_in_range,
                Round(OuterQ.Total / _daysInRange, 1) AS datasets_per_day,
                OuterQ.Blank AS blank_datasets,
                OuterQ.QC AS qc_datasets,
                -- OuterQ.TS AS troubleshooting,
                OuterQ.Bad AS bad_datasets,
                OuterQ.Study_Specific AS study_specific_datasets,
                Round(OuterQ.Study_Specific / _daysInRange, 1) AS study_specific_datasets_per_day,
                OuterQ.EF_Study_Specific AS emsl_funded_study_specific_datasets,
                Round(OuterQ.EF_Study_Specific / _daysInRange, 1) AS ef_study_specific_datasets_per_day,

                Round(OuterQ.Total_AcqTimeDays, 1) AS total_acqtimedays,
                Round(OuterQ.Study_Specific_AcqTimeDays, 1) AS study_specific_acqtimedays,
                Round(OuterQ.EF_Total_AcqTimeDays, 1) AS ef_total_acqtimedays,
                Round(OuterQ.EF_Study_Specific_AcqTimeDays, 1) AS ef_study_specific_acqtimedays,
                Round(OuterQ.Hours_AcqTime_per_Day, 1) AS hours_acqtime_per_day,

                OuterQ.Instrument AS inst_,                        -- The website will show this column as "Inst."
                OuterQ.Percent_EMSL_Owned AS pct_inst_emsl_owned,

                -- EMSL Funded Counts:
                Round(OuterQ.EF_Total, 2) AS ef_total_datasets,
                Round(OuterQ.EF_Total/_daysInRange, 1) AS ef_datasets_per_day,
                -- Round(OuterQ.EF_Blank, 2) AS ef_blank_datasets,
                -- Round(OuterQ.EF_QC, 2) AS ef_qc_datasets,
                -- Round(OuterQ.EF_Bad, 2) AS ef_bad_datasets,

                Round(OuterQ.Blank * 100.0 / OuterQ.Total, 1) AS pct_blank_datasets,
                Round(OuterQ.QC * 100.0 / OuterQ.Total, 1) AS pct_qc_datasets,
                Round(OuterQ.Bad * 100.0 / OuterQ.Total, 1) AS pct_bad_datasets,
                -- Round(OuterQ.Reruns * 100.0 / OuterQ.Total, 1) AS pct_reruns,
                Round(OuterQ.Study_Specific * 100.0 / OuterQ.Total, 1) AS pct_study_specific_datasets,
                CASE WHEN OuterQ.Total > 0 THEN Round(OuterQ.EF_Study_Specific * 100.0 / OuterQ.Total, 1) ELSE NULL END AS pct_ef_study_specific_datasets,
                CASE WHEN OuterQ.Total_AcqTimeDays > 0 THEN Round(OuterQ.EF_Total_AcqTimeDays * 100.0 / OuterQ.Total_AcqTimeDays, 1) ELSE NULL END AS pct_ef_study_specific_by_acqtime,
                ''::citext AS proposal_type,
                OuterQ.Instrument AS inst
            FROM (
                SELECT CombinedStatsQ.Instrument,
                       CombinedStatsQ.Percent_EMSL_Owned,
                       CombinedStatsQ.Total,
                       CombinedStatsQ.Bad,
                       CombinedStatsQ.Blank,
                       CombinedStatsQ.QC,
                       CombinedStatsQ.Total - (CombinedStatsQ.Blank + CombinedStatsQ.QC + CombinedStatsQ.Bad) AS Study_Specific,
                       CombinedStatsQ.Total_AcqTimeDays,
                       CombinedStatsQ.Total_AcqTimeDays - CombinedStatsQ.BadBlankQC_AcqTimeDays AS Study_Specific_AcqTimeDays,
                       CASE WHEN _daysInRange > 0.5 THEN CombinedStatsQ.Total_AcqTimeDays / _daysInRange * 24 ELSE Null END AS Hours_AcqTime_per_Day,
                       CombinedStatsQ.EF_Total,
                       CombinedStatsQ.EF_Bad,
                       CombinedStatsQ.EF_Blank,
                       CombinedStatsQ.EF_QC,
                       CombinedStatsQ.EF_Total - (CombinedStatsQ.EF_Blank + CombinedStatsQ.EF_QC + CombinedStatsQ.EF_Bad) AS EF_Study_Specific,
                       CombinedStatsQ.EF_Total_AcqTimeDays,
                       CombinedStatsQ.EF_Total_AcqTimeDays - CombinedStatsQ.EF_BadBlankQC_AcqTimeDays AS EF_Study_Specific_AcqTimeDays
                FROM
                    (SELECT StatsQ.Instrument,
                            StatsQ.Percent_EMSL_Owned,
                            SUM(StatsQ.Total) AS Total,        -- Total (Good + bad)
                            SUM(StatsQ.Bad) AS Bad,            -- Bad (not blank)
                            SUM(StatsQ.Blank) AS Blank,        -- Blank (Good + bad)
                            SUM(StatsQ.QC) AS QC,              -- QC (not bad)

                            SUM(StatsQ.Total_AcqTimeDays) AS Total_AcqTimeDays,            -- Total time acquiring data
                            SUM(StatsQ.BadBlankQC_AcqTimeDays) AS BadBlankQC_AcqTimeDays,  -- Total time acquiring bad/blank/QC data

                            -- EMSL Funded (EF) Counts:
                            SUM(StatsQ.EF_Total) AS EF_Total,        -- EF Total (Good + bad)
                            SUM(StatsQ.EF_Bad) AS EF_Bad,            -- EF Bad (not blank)
                            SUM(StatsQ.EF_Blank) AS EF_Blank,        -- EF Blank (Good + bad)
                            SUM(StatsQ.EF_QC) AS EF_QC,              -- EF QC (not bad)

                            SUM(StatsQ.EF_Total_AcqTimeDays) AS EF_Total_AcqTimeDays,                 -- EF Total time acquiring data
                            SUM(StatsQ.EF_BadBlankQC_AcqTimeDays) AS EF_BadBlankQC_AcqTimeDays        -- EF Total time acquiring bad/blank/QC data

                    FROM
                        (    -- Select Good datasets (excluded Bad, Not Released, Unreviewed, etc.)
                            SELECT
                                I.Instrument,
                                I.Percent_EMSL_Owned,
                                COUNT(DS.dataset_id) AS Total,                                        -- Total
                                0 AS Bad,                                                             -- Bad
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN 1 ELSE 0 END) AS Blank,   -- Blank
                                SUM(CASE WHEN DS.Dataset LIKE 'QC%' THEN 1 ELSE 0 END)    AS QC,      -- QC
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS Total_AcqTimeDays,        -- Total time acquiring data, in days
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' OR DS.Dataset LIKE 'QC%'
                                         THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS BadBlankQC_AcqTimeDays,

                                -- EMSL Funded Counts:
                                SUM(DF.EMSL_Funded) AS EF_Total,                                                      -- EF_Total
                                0 AS EF_Bad,                                                                          -- EF_Bad
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Blank,   -- EF_Blank
                                SUM(CASE WHEN DS.Dataset LIKE 'QC%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_QC,         -- EF_QC
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS EF_Total_AcqTimeDays, -- EF Total time acquiring data, in days
                                SUM(CASE WHEN DF.EMSL_Funded = 1 And (DS.Dataset LIKE 'Blank%' OR DS.Dataset LIKE 'QC%')
                                         THEN DS.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS EF_BadBlankQC_AcqTimeDays
                            FROM Tmp_Datasets DF
                                 INNER JOIN t_dataset DS
                                   ON DF.dataset_id = DS.dataset_id
                                 INNER JOIN t_instrument_name I
                                   ON DS.instrument_id = I.instrument_id
                                 INNER JOIN Tmp_CampaignFilter CF
                                   ON CF.Campaign_ID = DF.Campaign_ID
                            WHERE NOT (DS.dataset LIKE 'Bad%' OR
                                       DS.dataset_rating_id IN (- 1, - 2, - 5) OR
                                       DS.dataset_state_id = 4) AND
                                  (I.operations_role = 'Production' OR
                                   _productionOnly = 0)
                            GROUP BY I.instrument, I.percent_emsl_owned
                            UNION
                            -- Select Bad or Not Released datasets
                            SELECT
                                I.Instrument,
                                I.Percent_EMSL_Owned,
                                COUNT(DS.dataset_id) AS Total,                                            -- Total
                                SUM(CASE WHEN DS.Dataset NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS Bad,     -- Bad (not blank)
                                SUM(CASE WHEN DS.Dataset LIKE 'Blank%' THEN 1 ELSE 0 END)     AS Blank,   -- Bad Blank; will be counted as a blank
                                0 AS QC,                                                                  -- Bad QC; simply counted as Bad
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS Total_AcqTimeDays,            -- Total time acquiring data, in days
                                SUM(DS.Acq_Length_Minutes / 60.0 / 24.0) AS BadBlankQC_AcqTimeDays,

                                -- EMSL Funded Counts:
                                SUM(DF.EMSL_Funded) AS EF_Total,                                                      -- EF_Total
                                SUM(CASE WHEN DS.dataset NOT LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Bad, -- EF_Bad (not blank)
                                SUM(CASE WHEN DS.dataset LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS EF_Blank,   -- Bad EF_Blank; will be counted as a blank
                                0 AS EF_QC,                                                                           -- Bad EF_QC; simply counted as 'Bad'
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.acq_length_minutes / 60.0 / 24.0 Else 0 End) AS EF_Total_AcqTimeDays, -- EF Total time acquiring data, in days
                                SUM(CASE WHEN DF.EMSL_Funded = 1 THEN DS.acq_length_minutes / 60.0 / 24.0 Else 0 End) AS EF_BadBlankQC_AcqTimeDays
                            FROM Tmp_Datasets DF
                                 INNER JOIN t_dataset DS
                                   ON DF.dataset_id = DS.dataset_id
                                 INNER JOIN t_instrument_name I
                                   ON DS.instrument_id = I.instrument_id
                                 INNER JOIN Tmp_CampaignFilter CF
                                   ON CF.Campaign_ID = DF.Campaign_ID
                            WHERE (DS.dataset LIKE 'Bad%' OR
                                   DS.dataset_rating_id IN (- 1, - 2, - 5) OR
                                   DS.dataset_state_id = 4) AND
                                  (I.operations_role = 'Production' OR
                                   _productionOnly = 0)
                            GROUP BY I.instrument, I.percent_emsl_owned
                        ) StatsQ
                    GROUP BY StatsQ.instrument, StatsQ.percent_emsl_owned
                    ) CombinedStatsQ
                ) OuterQ
            ORDER BY OuterQ.instrument;

        End If;

        DROP TABLE Tmp_CampaignFilter;
        DROP TABLE Tmp_InstrumentFilter;
        DROP TABLE Tmp_EUSUsageFilter;
        DROP TABLE Tmp_Datasets;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        RAISE WARNING '%', _message;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_CampaignFilter;
    DROP TABLE IF EXISTS Tmp_InstrumentFilter;
    DROP TABLE IF EXISTS Tmp_EUSUsageFilter;
    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;


ALTER FUNCTION public.report_production_stats(_startdate text, _enddate text, _productiononly integer, _campaignidfilterlist text, _eususagefilterlist text, _instrumentfilterlist text, _includeproposaltype integer, _showdebug boolean) OWNER TO d3l243;

--
-- Name: FUNCTION report_production_stats(_startdate text, _enddate text, _productiononly integer, _campaignidfilterlist text, _eususagefilterlist text, _instrumentfilterlist text, _includeproposaltype integer, _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.report_production_stats(_startdate text, _enddate text, _productiononly integer, _campaignidfilterlist text, _eususagefilterlist text, _instrumentfilterlist text, _includeproposaltype integer, _showdebug boolean) IS 'ReportProductionStats';


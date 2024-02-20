--
-- Name: report_production_stats_proc(text, text, integer, text, text, text, integer, refcursor, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.report_production_stats_proc(IN _startdate text, IN _enddate text, IN _productiononly integer DEFAULT 1, IN _campaignidfilterlist text DEFAULT ''::text, IN _eususagefilterlist text DEFAULT ''::text, IN _instrumentfilterlist text DEFAULT ''::text, IN _includeproposaltype integer DEFAULT 0, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Generate dataset statistics for production instruments
**
**      The results returned by the cursor only include column proposal_type if _includeProposalType is greater than 0
**
**  Arguments:
**    _startDate                Start date; if an empty string, uses 2 weeks before _endDate
**    _endDate                  End date;   if an empty string, use today as end date
**    _productionOnly           When 0 then shows all instruments; otherwise limits the report to production instruments only (operations_role = 'Production')
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _eusUsageFilterList       Comma-separated list of EUS usage types, from table t_eus_usage_type: CAP_DEV, MAINTENANCE, BROKEN, USER_ONSITE, USER_REMOTE, RESOURCE_OWNER
**    _instrumentFilterList     Comma-separated list of instrument names; % and * wildcards are allowed ('*' is auto-changed to '%')
**    _includeProposalType      When 1, include proposal type in the results
**    _results                  Output: cursor for retrieving production stats
**    _message                  Status message
**    _returnCode               Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.report_production_stats_proc (
**                      _startDate            => '2023-01-01',
**                      _endDate              => '2023-01-30',
**                      _productionOnly       => 1
**                      _campaignIDFilterList => '',
**                      _eusUsageFilterList   => '',
**                      _instrumentFilterList => '',
**                      _includeProposalType  => 0
**               );
**          FETCH ALL FROM _results;
**      END;
**
***  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**      DO
**      LANGUAGE plpgsql
**      $block$
**      DECLARE
**          _results refcursor := '_results'::refcursor;
**          _message text;
**          _returnCode text;
**          _formatSpecifier text;
**          _infoHead text;
**          _infoHeadSeparator text;
**          _currentRow record;
**          _infoData text;
**      BEGIN
**          CALL public.report_production_stats_proc (
**                      _startDate            => '2023-01-01',
**                      _endDate              => '2023-01-30',
**                      _productionOnly       => 1,
**                      _campaignIDFilterList => '',
**                      _eusUsageFilterList   => '',
**                      _instrumentFilterList => '',
**                      _includeProposalType  => 1,
**                      _results              => _results,
**                      _message              => _message,
**                      _returnCode           => _returnCode
**               );
**
**          If Exists (SELECT name FROM pg_cursors WHERE name = '_results') Then
**              RAISE INFO 'Cursor has data';
**
**              RAISE INFO '';
**
**              _formatSpecifier := '%-25s %-14s %-13s %-16s %-14s %-11s %-12s %-23s %-31s %-35s %-34s %-17s %-26s %-20s %-29s %-21s %-19s %-17s %-19s %-18s %-15s %-16s %-27s %-30s %-32s %-26s %-25s';
**
**              _infoHead := format(_formatSpecifier,
**                                  'Instrument',
**                                  'Total_Datasets',
**                                  'Days_In_Range',
**                                  'Datasets_Per_Day',
**                                  'Blank_Datasets',
**                                  'QC_Datasets',
**                                  'Bad_Datasets',
**                                  'Study_Specific_Datasets',
**                                  'Study_Specific_Datasets_Per_Day',
**                                  'EMSL_Funded_Study_Specific_Datasets',
**                                  'EF_Study_Specific_Datasets_Per_Day',
**                                  'Total_AcqTimedays',
**                                  'Study_Specific_AcqTimedays',
**                                  'EF_Total_AcqTimedays',
**                                  'EF_Study_Specific_AcqTimedays',
**                                  'Hours_AcqTime_Per_Day',
**                                  'Pct_Inst_EMSL_Owned',
**                                  'EF_Total_Datasets',
**                                  'EF_Datasets_Per_Day',
**                                  'Pct_Blank_Datasets',
**                                  'Pct_Qc_Datasets',
**                                  'Pct_Bad_Datasets',
**                                  'Pct_Study_Specific_Datasets',
**                                  'Pct_EF_Study_Specific_Datasets',
**                                  'Pct_EF_Study_Specific_By_AcqTime',
**                                  'Proposal_Type',
**                                  'Instrument'
**                                 );
**
**              _infoHeadSeparator := format(_formatSpecifier,
**                                           '-------------------------',
**                                           '--------------',
**                                           '-------------',
**                                           '----------------',
**                                           '--------------',
**                                           '-----------',
**                                           '------------',
**                                           '-----------------------',
**                                           '-------------------------------',
**                                           '-----------------------------------',
**                                           '----------------------------------',
**                                           '-----------------',
**                                           '--------------------------',
**                                           '--------------------',
**                                           '-----------------------------',
**                                           '---------------------',
**                                           '-------------------',
**                                           '-----------------',
**                                           '-------------------',
**                                           '------------------',
**                                           '---------------',
**                                           '----------------',
**                                           '---------------------------',
**                                           '------------------------------',
**                                           '--------------------------------',
**                                           '--------------------------',
**                                           '-------------------------'
**                                          );
**
**              RAISE INFO '%', _infoHead;
**              RAISE INFO '%', _infoHeadSeparator;
**
**              WHILE true
**              LOOP
**                  FETCH NEXT FROM _results
**                  INTO _currentRow;
**
**                  If Not FOUND Then
**                      EXIT;
**                  End If;
**
**                  _infoData := format(_formatSpecifier,
**                                      _currentRow.Instrument,
**                                      _currentRow.Total_Datasets,
**                                      _currentRow.Days_In_Range,
**                                      _currentRow.Datasets_Per_Day,
**                                      _currentRow.Blank_Datasets,
**                                      _currentRow.QC_Datasets,
**                                      _currentRow.Bad_Datasets,
**                                      _currentRow.Study_Specific_Datasets,
**                                      _currentRow.Study_Specific_Datasets_Per_Day,
**                                      _currentRow.EMSL_Funded_Study_Specific_Datasets,
**                                      _currentRow.EF_Study_Specific_Datasets_Per_Day,
**                                      _currentRow.Total_AcqTimedays,
**                                      _currentRow.Study_Specific_AcqTimedays,
**                                      _currentRow.EF_Total_AcqTimedays,
**                                      _currentRow.EF_Study_Specific_AcqTimedays,
**                                      _currentRow.Hours_AcqTime_Per_Day,
**                                      _currentRow.Pct_Inst_EMSL_Owned,
**                                      _currentRow.EF_Total_Datasets,
**                                      _currentRow.EF_Datasets_Per_Day,
**                                      _currentRow.Pct_Blank_Datasets,
**                                      _currentRow.Pct_Qc_Datasets,
**                                      _currentRow.Pct_Bad_Datasets,
**                                      _currentRow.Pct_Study_Specific_Datasets,
**                                      _currentRow.Pct_EF_Study_Specific_Datasets,
**                                      _currentRow.Pct_EF_Study_Specific_By_AcqTime,
**                                      _currentRow.Proposal_Type,
**                                      _currentRow.Inst
**                                     );
**
**                  RAISE INFO '%', _infoData;
**              END LOOP;
**          Else
**              RAISE INFO 'Cursor is not open';
**          End If;
**      END
**      $block$;
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        _includeProposalType := Coalesce(_includeProposalType, 0);

        ---------------------------------------------------
        -- Generate report
        --
        -- Note that report_production_stats() converts:
        --   start date to the first day of the month
        --   end date to the first day of the next month
        ---------------------------------------------------

        If _includeProposalType > 0 Then
            Open _results For
                SELECT Src.instrument,
                       Src.total_datasets,
                       Src.days_in_range,
                       Src.datasets_per_day,
                       Src.blank_datasets,
                       Src.qc_datasets,
                       Src.bad_datasets,
                       Src.study_specific_datasets,
                       Src.study_specific_datasets_per_day,
                       Src.emsl_funded_study_specific_datasets,
                       Src.ef_study_specific_datasets_per_day,
                       Src.total_acqtimedays,
                       Src.study_specific_acqtimedays,
                       Src.ef_total_acqtimedays,
                       Src.ef_study_specific_acqtimedays,
                       Src.hours_acqtime_per_day,
                       Src.inst_,                   -- Yes, this column name ends with an underscore
                       Src.pct_inst_emsl_owned,
                       Src.ef_total_datasets,
                       Src.ef_datasets_per_day,
                       Src.pct_blank_datasets,
                       Src.pct_qc_datasets,
                       Src.pct_bad_datasets,
                       Src.pct_study_specific_datasets,
                       Src.pct_ef_study_specific_datasets,
                       Src.pct_ef_study_specific_by_acqtime,
                       Src.proposal_type,
                       Src.inst
                FROM report_production_stats(_startDate, _endDate, _productionOnly, _campaignIDFilterList, _eusUsageFilterList, _instrumentFilterList, _includeProposalType) AS Src
                ORDER BY Src.instrument;
        Else
            -- Do not include the proposal_type column
            Open _results For
                SELECT Src.instrument,
                       Src.total_datasets,
                       Src.days_in_range,
                       Src.datasets_per_day,
                       Src.blank_datasets,
                       Src.qc_datasets,
                       Src.bad_datasets,
                       Src.study_specific_datasets,
                       Src.study_specific_datasets_per_day,
                       Src.emsl_funded_study_specific_datasets,
                       Src.ef_study_specific_datasets_per_day,
                       Src.total_acqtimedays,
                       Src.study_specific_acqtimedays,
                       Src.ef_total_acqtimedays,
                       Src.ef_study_specific_acqtimedays,
                       Src.hours_acqtime_per_day,
                       Src.inst_,                   -- Yes, this column name ends with an underscore
                       Src.pct_inst_emsl_owned,
                       Src.ef_total_datasets,
                       Src.ef_datasets_per_day,
                       Src.pct_blank_datasets,
                       Src.pct_qc_datasets,
                       Src.pct_bad_datasets,
                       Src.pct_study_specific_datasets,
                       Src.pct_ef_study_specific_datasets,
                       Src.pct_ef_study_specific_by_acqtime,
                       Src.inst
                FROM report_production_stats(_startDate, _endDate, _productionOnly, _campaignIDFilterList, _eusUsageFilterList, _instrumentFilterList, _includeProposalType) AS Src
                ORDER BY Src.instrument;
        End If;

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

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$_$;


ALTER PROCEDURE public.report_production_stats_proc(IN _startdate text, IN _enddate text, IN _productiononly integer, IN _campaignidfilterlist text, IN _eususagefilterlist text, IN _instrumentfilterlist text, IN _includeproposaltype integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


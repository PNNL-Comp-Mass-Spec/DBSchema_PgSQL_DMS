--
CREATE OR REPLACE PROCEDURE public.report_production_stats_proc
(
    _startDate text,
    _endDate text,
    _productionOnly int = 1,
    _campaignIDFilterList text = '',
    _eusUsageFilterList text = '',
    _instrumentFilterList text = '',
    _includeProposalType int = 0,
    INOUT _results refcursor DEFAULT '_results'::refcursor,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Generate dataset statistics for production instruments
**
**      The results returned by the cursor only include column proposal_type if _includeProposalType is greater than 0
**
**  Arguments:
**    _startDate                Start date; if an empty string, will use 2 weeks before _endDate
**    _endDate                  End date;   if an empty string, will use today as end date
**    _productionOnly           When 0 then shows all instruments; otherwise limits the report to production instruments only (operations_role = 'Production')
**    _campaignIDFilterList     Comma-separated list of campaign IDs
**    _eusUsageFilterList       Comma separated list of EUS usage types, from table t_eus_usage_type: CAP_DEV, MAINTENANCE, BROKEN, USER_ONSITE, USER_REMOTE, RESOURCE_OWNER
**    _instrumentFilterList     Comma-separated list of instrument names% and * wildcards are allowed ('*' is auto-changed to '%')
**    _includeProposalType      When 1, include proposal type in the results
**    _results                  Output: cursor for retrieving production stats
**    _message                  Status message
**    _returnCode               Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**      CALL public.report_production_stats_proc (
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
**  Auth:   mem
**  Date:   12/15/2024 mem - Initial version
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
                       Src.troubleshooting,
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
                       Src.inst_
                       Src.pct_inst_emsl_owned,
                       Src.ef_total_datasets,
                       Src.ef_datasets_per_day,
                       Src.ef_blank_datasets,
                       Src.ef_qc_datasets,
                       Src.ef_bad_datasets,
                       Src.pct_blank_datasets,
                       Src.pct_qc_datasets,
                       Src.pct_bad_datasets,
                       Src.pct_reruns,
                       Src.pct_study_specific_datasets,
                       Src.pct_ef_study_specific_datasets,
                       Src.pct_ef_study_specific_by_acqtime,
                       Src.proposal_type,
                       Src.inst
                FROM report_production_stats(_startDate, _endDate, _productionOnly, _campaignIDFilterList, _eusUsageFilterList, _instrumentFilterList, _includeProposalType) As Src
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
                       Src.troubleshooting,
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
                       Src.inst_
                       Src.pct_inst_emsl_owned,
                       Src.ef_total_datasets,
                       Src.ef_datasets_per_day,
                       Src.ef_blank_datasets,
                       Src.ef_qc_datasets,
                       Src.ef_bad_datasets,
                       Src.pct_blank_datasets,
                       Src.pct_qc_datasets,
                       Src.pct_bad_datasets,
                       Src.pct_reruns,
                       Src.pct_study_specific_datasets,
                       Src.pct_ef_study_specific_datasets,
                       Src.pct_ef_study_specific_by_acqtime,
                       Src.inst
                FROM report_production_stats(_startDate, _endDate, _productionOnly, _campaignIDFilterList, _eusUsageFilterList, _instrumentFilterList, _includeProposalType) As Src
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
$$;

COMMENT ON PROCEDURE public.report_dataset_instrument_runtime IS 'ReportDatasetInstrumentRunTime';

BEGIN;
    CALL public.report_production_stats_proc (
                _startDate => '2023-01-01',
                _endDate => '2023-01-30',
                _productionOnly => 1
                _campaignIDFilterList => '',
                _eusUsageFilterList => '',
                _instrumentFilterList => '',
                _includeProposalType => 0
         );
    FETCH ALL FROM _results;
END;



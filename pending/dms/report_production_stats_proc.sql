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
    _results refcursor DEFAULT '_results'::refcursor,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _showDebug boolean = false,
)
...


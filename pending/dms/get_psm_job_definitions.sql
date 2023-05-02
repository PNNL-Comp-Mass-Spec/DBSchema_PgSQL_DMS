--
CREATE OR REPLACE PROCEDURE public.get_psm_job_definitions
(
    INOUT _datasets text,
    INOUT _metadata text,
    INOUT _defaults text,
    _mode text = 'PSM',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns sets of parameters for setting up a PSM-type job request entry page
**
**      Used by the analysis_job_request_psm page family
**
**  Arguments:
**    _datasets   Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
**    _metadata   Output parameter: table of metadata with columns separated by colons and rows separated by vertical bars
**    _defaults   Output parameter: default values, as a vertical bar delimited list (using colons between parameter name and value)
**    _mode       'PSM' (unused)
**
**  Auth:   grk
**  Date:   11/15/2012 grk - Initial version
**          11/20/2012 mem - Now returning organism name, protein collection list, and protein options list
**          11/20/2012 grk - removed extra RETURN that was blocking error return
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _toolName text,
    _jobTypeName text,
    _jobTypeDesc text,
    _dynMetOxEnabled int,
    _statCysAlkEnabled int,
    _dynSTYPhosEnabled int,
    _organismName text,
    _protCollNameList text,
    _protCollOptionsList text

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        Call get_psm_job_defaults (
                _datasets => _datasets,                         -- Output
                _metadata => _metadata,                         -- Output
                _toolName => _toolName,                         -- Output
                _jobTypeName => _jobTypeName,                   -- Output
                _jobTypeDesc => _jobTypeDesc,                   -- Output
                _dynMetOxEnabled => _dynMetOxEnabled,           -- Output
                _statCysAlkEnabled => _statCysAlkEnabled,       -- Output
                _dynSTYPhosEnabled => _dynSTYPhosEnabled,       -- Output
                _organismName => _organismName,                 -- Output
                _protCollNameList => _protCollNameList,         -- Output
                _protCollOptionsList => _protCollOptionsList,   -- Output
                _message => _message,                           -- Output
                _returnCode => _returnCode);                    -- Output

        _defaults := '';
        _defaults := _defaults || 'ToolName' ||              ':' || _toolName                                || '|';
        _defaults := _defaults || 'JobTypeName' ||           ':' || _jobTypeName                             || '|';
        _defaults := _defaults || 'JobTypeDesc' ||           ':' || _jobTypeDesc                             || '|';
        _defaults := _defaults || 'DynMetOxEnabled' ||       ':' || _dynMetOxEnabled::text   || '|';
        _defaults := _defaults || 'StatCysAlkEnabled' ||     ':' || _statCysAlkEnabled::text || '|';
        _defaults := _defaults || 'DynSTYPhosEnabled' ||     ':' || _dynSTYPhosEnabled::text || '|';
        _defaults := _defaults || 'OrganismName' ||          ':' || _organismName                            || '|';
        _defaults := _defaults || 'ProteinCollectionList' || ':' || _protCollNameList                        || '|';
        _defaults := _defaults || 'ProteinOptionsList' ||    ':' || _protCollOptionsList                     || '|';

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

COMMENT ON PROCEDURE public.get_psm_job_definitions IS 'GetPSMJobDefinitions';

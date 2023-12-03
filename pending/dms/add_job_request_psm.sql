
CREATE OR REPLACE PROCEDURE public.add_job_request_psm
(
    INOUT _requestID int,
    _requestName text,
    INOUT _datasets text,
    _comment text,
    _ownerUsername text,
    _organismName text,
    _protCollNameList text,
    _protCollOptionsList text,
    _toolName text,
    _jobTypeName text,
    _modificationDynMetOx text,
    _modificationStatCysAlk text,
    _modificationDynSTYPhos text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Used by the MS/MS job wizard to create a new analysis job request
**      https://dms2.pnl.gov/analysis_job_request_psm/create
**
**  Arguments:
**    _requestID                Output: ID of the new analysis job request
**    _requestName              Job request name
**    _datasets                 Input/output:  comma-separated list of datasets; will be alphabetized after removing duplicates
**    _comment                  Job request comment
**    _ownerUsername            Job request owner username
**    _organismName             Organism name
**    _protCollNameList         Comma-separated list of protein collection names
**    _protCollOptionsList      Protein collection options
**    _toolName                 Analysis tool name
**    _jobTypeName              Analysis job type name
**    _modificationDynMetOx     When 'Yes', look for a parameter file with dynamic oxidized methionine
**    _modificationStatCysAlk   When 'Yes', look for a parameter file with static alkylated cysteine
**    _modificationDynSTYPhos   When 'Yes', look for a parameter file with dynamic phosphorylated STY
**    _mode                     Mode: 'add', 'preview', or 'debug'
**    _message                  Output message
**    _returnCode               Return code
**    _callingUser              Calling user username
**
**  Auth:   grk
**  Date:   11/14/2012 grk - Initial release
**          11/16/2012 grk - Added
**          11/20/2012 grk - Added _organismName
**          11/21/2012 mem - Now calling Create_PSM_Job_Request
**          12/13/2012 mem - Added support for _mode='preview'
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/23/2018 mem - Use a non-zero return code when _mode is 'preview'
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _debugMode boolean;
    _infoOnly boolean := false;
    _dynMetOxEnabled int;
    _statCysAlkEnabled int;
    _dynSTYPhosEnabled int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = 'debug' Then
            _message := 'Debug mode; nothing to do';
        End If;

        ---------------------------------------------------
        -- Add mode
        ---------------------------------------------------

        If _mode::citext In ('add', 'preview') Then

            If _mode = 'preview' Then
                _infoOnly := true;
            End If;

            _dynMetOxEnabled   := CASE WHEN _modificationDynMetOx::citext   = 'Yes' Then 1 ELSE 0 END;
            _statCysAlkEnabled := CASE WHEN _modificationStatCysAlk::citext = 'Yes' Then 1 ELSE 0 END;
            _dynSTYPhosEnabled := CASE WHEN _modificationDynSTYPhos::citext = 'Yes' Then 1 ELSE 0 END;

            CALL public.create_psm_job_request (
                            _requestID           => _requestID,         -- Output
                            _requestName         => _requestName,
                            _datasets            => _datasets,          -- Output
                            _toolName            => _toolName,
                            _jobTypeName         => _jobTypeName,
                            _protCollNameList    => _protCollNameList,
                            _protCollOptionsList => _protCollOptionsList,
                            _dynMetOxEnabled     => _dynMetOxEnabled,
                            _statCysAlkEnabled   => _statCysAlkEnabled,
                            _dynSTYPhosEnabled   => _dynSTYPhosEnabled,
                            _comment             => _comment,
                            _ownerUsername       => _ownerUsername,
                            _infoOnly            => _infoOnly,
                            _message             => _message ,          -- Output
                            _returnCode          => _returnCode,        -- Output
                            _callingUser         => _callingUser);

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; ID %s', _exceptionMessage, compoundIdAndName);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    If _infoOnly And _returnCode = '' Then
        -- Use a non-zero error code to assure that the calling page shows the message at the top and bottom of the web page
        -- i.e., make it look like an error occurred, when no error has actually occurred
        -- See https://dms2.pnl.gov/analysis_job_request_psm/create
        _returnCode := 'U5201';
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_job_request_psm IS 'AddJobRequestPSM';

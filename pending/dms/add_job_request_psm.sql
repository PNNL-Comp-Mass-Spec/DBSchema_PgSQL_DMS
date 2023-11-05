
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
**      Create a job from simplified interface
**
**  Arguments:
**    _mode   'add', 'preview', or 'debug'
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
**          12/15/2023 mem - Ported to PostgreSQL
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

            _dynMetOxEnabled   := CASE WHEN _modificationDynMetOx   = 'Yes' Then 1 ELSE 0 END;
            _statCysAlkEnabled := CASE WHEN _modificationStatCysAlk = 'Yes' Then 1 ELSE 0 END;
            _dynSTYPhosEnabled := CASE WHEN _modificationDynSTYPhos = 'Yes' Then 1 ELSE 0 END;

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

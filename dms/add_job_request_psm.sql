--
-- Name: add_job_request_psm(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_job_request_psm(INOUT _requestid integer, IN _requestname text, INOUT _datasets text, IN _comment text, IN _ownerusername text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _toolname text, IN _jobtypename text, IN _modificationdynmetox text, IN _modificationstatcysalk text, IN _modificationdynstyphos text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
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
**    _protCollNameList         Comma-separated list of protein collection names
**    _protCollOptionsList      Protein collection options
**    _toolName                 Analysis tool name
**    _jobTypeName              Analysis job type name
**    _modificationDynMetOx     When 'Yes', look for a parameter file with dynamic oxidized methionine
**    _modificationStatCysAlk   When 'Yes', look for a parameter file with static alkylated cysteine
**    _modificationDynSTYPhos   When 'Yes', look for a parameter file with dynamic phosphorylated STY
**    _mode                     Mode: 'add', 'preview', or 'debug'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
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
**          12/12/2023 mem - Remove procedure argument _organismName since unused
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _debugMode boolean;
    _infoOnly boolean := false;

    -- These are integers because columns dyn_met_ox, stat_cys_alk, and dyn_sty_phos
    -- in table t_default_psm_job_parameters are integers
    _dynMetOxEnabled int;
    _statCysAlkEnabled int;
    _dynSTYPhosEnabled int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        _modificationDynMetOx   := Trim(Lower(Coalesce(_modificationDynMetOx,   '')));
        _modificationStatCysAlk := Trim(Lower(Coalesce(_modificationStatCysAlk, '')));
        _modificationDynSTYPhos := Trim(Lower(Coalesce(_modificationDynSTYPhos, '')));
        _mode                   := Trim(Lower(Coalesce(_mode, '')));

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

            _dynMetOxEnabled   := CASE WHEN _modificationDynMetOx   = 'yes' Then 1 ELSE 0 END;
            _statCysAlkEnabled := CASE WHEN _modificationStatCysAlk = 'yes' Then 1 ELSE 0 END;
            _dynSTYPhosEnabled := CASE WHEN _modificationDynSTYPhos = 'yes' Then 1 ELSE 0 END;

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


ALTER PROCEDURE public.add_job_request_psm(INOUT _requestid integer, IN _requestname text, INOUT _datasets text, IN _comment text, IN _ownerusername text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _toolname text, IN _jobtypename text, IN _modificationdynmetox text, IN _modificationstatcysalk text, IN _modificationdynstyphos text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_job_request_psm(INOUT _requestid integer, IN _requestname text, INOUT _datasets text, IN _comment text, IN _ownerusername text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _toolname text, IN _jobtypename text, IN _modificationdynmetox text, IN _modificationstatcysalk text, IN _modificationdynstyphos text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_job_request_psm(INOUT _requestid integer, IN _requestname text, INOUT _datasets text, IN _comment text, IN _ownerusername text, IN _protcollnamelist text, IN _protcolloptionslist text, IN _toolname text, IN _jobtypename text, IN _modificationdynmetox text, IN _modificationstatcysalk text, IN _modificationdynstyphos text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddJobRequestPSM';


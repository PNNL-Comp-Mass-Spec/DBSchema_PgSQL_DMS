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
**  Example usage:
**    CALL get_psm_job_definitions ('QC_Mam_23_01_Run01_FAIMS_Merry_02June23_WBEH-23-05-13',
**                                  _metadata,      -- Output
**                                  _defaults,      -- Output
**                                  _mode,
**                                  _message,       -- Output
**                                  _returnCode);   -- Output
**
**    Output values:
**      _metadata = 'Metadata:Description:Datasets|HMS-HCD-HMSn:High res MS with high res HCD MSn:1|Alkylated:Sample (experiment) marked as alkylated in DMS:1|Labeling:none:1|Enzyme:Trypsin:1|'
**      _defaults = 'ToolName:MSGFPlus_MzML|JobTypeName:High Res MS1|JobTypeDesc:Data acquired with high resolution MS1 spectra, typically an Orbitrap or LTQ-FT|DynMetOxEnabled:1|StatCysAlkEnabled:1|DynSTYPhosEnabled:0|OrganismName:Mus_musculus|ProteinCollectionList:M_musculus_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov|ProteinOptionsList:seq_direction=decoy|'
**
**  Auth:   grk
**  Date:   11/15/2012 grk - Initial version
**          11/20/2012 mem - Now returning organism name, protein collection list, and protein options list
**          11/20/2012 grk - Removed extra RETURN that was blocking error return
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
    _message := '';
    _returnCode := '';

    BEGIN

        CALL get_psm_job_defaults (
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

        _defaults := format('ToolName:%s|',               _toolName)              ||
                     format('JobTypeName:%s|',            _jobTypeName)           ||
                     format('JobTypeDesc:%s|',            _jobTypeDesc)           ||
                     format('DynMetOxEnabled:%s|',        _dynMetOxEnabled)       ||
                     format('StatCysAlkEnabled:%s|',      _statCysAlkEnabled)     ||
                     format('DynSTYPhosEnabled:%s|',      _dynSTYPhosEnabled)     ||
                     format('OrganismName:%s|',           _organismName)          ||
                     format('ProteinCollectionList:%s|',  _protCollNameList)      ||
                     format('ProteinOptionsList:%s|',     _protCollOptionsList);

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

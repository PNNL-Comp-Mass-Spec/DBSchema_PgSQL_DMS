--
-- Name: get_psm_job_definitions(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_psm_job_definitions(INOUT _datasets text, INOUT _metadata text DEFAULT ''::text, INOUT _defaults text DEFAULT ''::text, IN _mode text DEFAULT 'PSM'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return sets of parameters for setting up a PSM-type job request entry page
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
**          08/02/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _psmJobDefaults record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        SELECT datasets,
               metadata,
               tool_name,
               job_type_name,
               job_type_desc,
               dyn_met_ox_enabled,
               stat_cys_alk_enabled,
               dyn_sty_phos_enabled,
               organism_name,
               prot_coll_name_list,
               prot_coll_options_list,
               error_message
        INTO _psmJobDefaults
        FROM public.get_psm_job_defaults(_datasets);

        If _psmJobDefaults.error_message <> '' Then
            RAISE EXCEPTION '%', _psmJobDefaults.error_message;
        End If;

        _datasets := _psmJobDefaults.datasets;

        _metadata := _psmJobDefaults.metadata;

        _defaults := format('ToolName:%s|',               _psmJobDefaults.tool_name)               ||
                     format('JobTypeName:%s|',            _psmJobDefaults.job_type_name)           ||
                     format('JobTypeDesc:%s|',            _psmJobDefaults.job_type_desc)           ||
                     format('DynMetOxEnabled:%s|',        _psmJobDefaults.dyn_met_ox_enabled)      ||
                     format('StatCysAlkEnabled:%s|',      _psmJobDefaults.stat_cys_alk_enabled)    ||
                     format('DynSTYPhosEnabled:%s|',      _psmJobDefaults.dyn_sty_phos_enabled)    ||
                     format('OrganismName:%s|',           _psmJobDefaults.organism_name)           ||
                     format('ProteinCollectionList:%s|',  _psmJobDefaults.prot_coll_name_list)     ||
                     format('ProteinOptionsList:%s|',     _psmJobDefaults.prot_coll_options_list);

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


ALTER PROCEDURE public.get_psm_job_definitions(INOUT _datasets text, INOUT _metadata text, INOUT _defaults text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_psm_job_definitions(INOUT _datasets text, INOUT _metadata text, INOUT _defaults text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.get_psm_job_definitions(INOUT _datasets text, INOUT _metadata text, INOUT _defaults text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'GetPSMJobDefinitions';


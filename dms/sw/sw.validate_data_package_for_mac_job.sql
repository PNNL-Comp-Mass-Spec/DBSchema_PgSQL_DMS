--
-- Name: validate_data_package_for_mac_job(integer, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.validate_data_package_for_mac_job(IN _datapackageid integer, IN _scriptname text, INOUT _tool text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Verify configuration and contents of a data package for given pipeline script
**
**  Arguments:
**    _dataPackageID    Data package id
**    _scriptName       Pipeline script name, e.g., MaxQuant, MSFragger, DiaNN, PRIDE_Converter, Phospho_FDR_Aggregator, MAC_iTRAQ, MAC_TMT10Plex
**    _tool             Output: tool
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   10/29/2012 grk - Initial release
**          11/01/2012 grk - Eliminated job template
**          01/31/2013 mem - Renamed MSGFDB to MSGFPlus
**                         - Updated error messages shown to user
**          02/13/2013 mem - Fix misspelled word
**          02/18/2013 mem - Fix misspelled word
**          08/13/2013 mem - Now validating required analysis tools for the MAC_iTRAQ script
**          08/14/2013 mem - Now validating datasets and jobs for script Global_Label-Free_AMT_Tag
**          04/20/2014 mem - Now mentioning ReporterTol parameter file when MASIC counts are not correct for an Isobaric_Labeling or MAC_iTRAQ script
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          11/15/2017 mem - Use Append_To_Text to combine strings
**                         - Include data package ID in log messages
**          01/11/2018 mem - Allow PRIDE_Converter jobs to have multiple MSGF+ jobs for each dataset
**          04/06/2018 mem - Allow Phospho_FDR_Aggregator jobs to have multiple MSGF+ jobs for each dataset
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          05/01/2019 mem - Fix typo counting SEQUEST jobs
**          03/09/2021 mem - Add support for MaxQuant
**          08/26/2021 mem - Add support for MSFragger
**          10/02/2021 mem - No longer require that DeconTools jobs exist for MAC_iTRAQ jobs (similarly, MAC_TMT10Plex jobs don't need DeconTools)
**          06/30/2022 mem - Use new parameter file column name
**          12/07/2022 mem - Include script name in the error message
**          03/27/2023 mem - Add support for DiaNN
**          07/27/2023 mem - Ported to PostgreSQL
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/03/2023 mem - Obtain dataset name from public.t_dataset since it is no longer in dpkg.t_data_package_analysis_jobs
**                         - Obtain dataset name from public.t_dataset since the name in dpkg.t_data_package_datasets is a cached name and could be an old dataset name
**
*****************************************************/
DECLARE
    _errMsg text = '';
    _datasetCount int;
    _deconToolsCountNotOne int;
    _masicCountNotOne int;
    _msgfPlusCountExactlyOne int;
    _msgfPlusCountNotOne int;
    _msgfPlusCountOneOrMore int;
    _sequestCountExactlyOne int;
    _sequestCountNotOne int;
    _sequestCountOneOrMore int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _tool := '';

    BEGIN
        ---------------------------------------------------
        -- Create table to hold data package datasets
        -- and job counts
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DataPackageItems (
            Dataset_ID int,
            Dataset text,
            Decon2LS_V2 int NULL,
            MASIC int NULL,
            MSGFPlus int NULL,
            SEQUEST int NULL
        );

        ---------------------------------------------------
        -- Populate with package datasets
        ---------------------------------------------------

        INSERT INTO Tmp_DataPackageItems (
            Dataset_ID,
            Dataset
        )
        SELECT DISTINCT DS.dataset_id,
                        DS.dataset
        FROM dpkg.t_data_package_datasets AS DPD
             INNER JOIN public.t_dataset DS
               ON DPD.dataset_id = DS.dataset_id
        WHERE DPD.data_pkg_id = _dataPackageID;

        ---------------------------------------------------
        -- Determine job counts per dataset for required tools
        ---------------------------------------------------

        UPDATE Tmp_DataPackageItems
        SET Decon2LS_V2 = SourceQ.Decon2LS_V2,
            MASIC = SourceQ.MASIC,
            MSGFPlus = SourceQ.MSGFPlus,
            SEQUEST = SourceQ.SEQUEST
        FROM (SELECT DS.dataset,
                     SUM(CASE WHEN T.analysis_tool = 'Decon2LS_V2' THEN 1 ELSE 0 END) AS Decon2LS_V2,
                     SUM(CASE WHEN T.analysis_tool = 'MASIC_Finnigan' AND J.param_file_name ILIKE '%ReporterTol%' THEN 1 ELSE 0 END) AS MASIC,
                     SUM(CASE WHEN T.analysis_tool ILIKE 'MSGFPlus%' THEN 1 ELSE 0 END) AS MSGFPlus,
                     SUM(CASE WHEN T.analysis_tool ILIKE 'SEQUEST%' THEN 1 ELSE 0 END) AS SEQUEST
              FROM dpkg.t_data_package_analysis_jobs AS DPD
                   INNER JOIN public.t_analysis_job J
                     ON DPD.job = J.job
                   INNER JOIN public.t_dataset DS
                     ON J.dataset_id = DS.dataset_id
                   INNER JOIN public.t_analysis_tool T
                     ON J.analysis_tool_id = T.analysis_tool_id
              WHERE DPD.data_pkg_id = _dataPackageID
              GROUP BY DS.dataset
             ) SourceQ
        WHERE Tmp_DataPackageItems.Dataset = SourceQ.dataset;

        ---------------------------------------------------
        -- Assess job/tool coverage of datasets
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DataPackageItems;

        SELECT COUNT(*)
        INTO _deconToolsCountNotOne
        FROM Tmp_DataPackageItems
        WHERE Decon2LS_V2 <> 1;

        SELECT COUNT(*)
        INTO _masicCountNotOne
        FROM Tmp_DataPackageItems
        WHERE MASIC <> 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountExactlyOne
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus = 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountNotOne
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus <> 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountOneOrMore
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus >= 1;

        SELECT COUNT(*)
        INTO _sequestCountExactlyOne
        FROM Tmp_DataPackageItems
        WHERE SEQUEST = 1;

        SELECT COUNT(*)
        INTO _sequestCountNotOne
        FROM Tmp_DataPackageItems
        WHERE SEQUEST <> 1;

        SELECT COUNT(*)
        INTO _sequestCountOneOrMore
        FROM Tmp_DataPackageItems
        WHERE SEQUEST >= 1;

        If _scriptName ILike 'MaxQuant%' Or _scriptName ILike 'MSFragger%' Or _scriptName ILike 'DiaNN%' Then
            If _datasetCount = 0 Then
                _errMsg := format('Data package currently does not have any datasets (script %s)', _scriptName);
            End If;
        End If;

        If Not _scriptName::citext In ('Global_Label-Free_AMT_Tag') And Not _scriptName ILike 'MaxQuant%' And Not _scriptName ILike 'MSFragger%' And Not _scriptName ILike 'DiaNN%' Then
            If _scriptName::citext = 'PRIDE_Converter' Then
                If _msgfPlusCountOneOrMore > 0 Then
                    _tool := 'msgfplus';
                ElsIf _sequestCountOneOrMore > 0 Then
                    _tool := 'sequest';
                End If;
            End If;

            If _tool = '' And _msgfPlusCountOneOrMore > 0 Then
                If _msgfPlusCountNotOne = 0 And _msgfPlusCountExactlyOne = _msgfPlusCountOneOrMore Then
                    _tool := 'msgfplus';
                Else
                    If _scriptName::citext In ('Phospho_FDR_Aggregator') Then
                        -- Allow multiple MS-GF+ jobs for each dataset;
                        _tool := 'msgfplus';
                    Else
                        _errMsg := format('Data package does not have exactly one MSGFPlus job for each dataset (%s invalid datasets); script %s',
                                          _msgfPlusCountNotOne, _scriptName);
                    End If;
                End If;
            End If;

            If _tool = '' And _sequestCountOneOrMore > 0 Then
                If _sequestCountNotOne = 0 And _sequestCountExactlyOne = _sequestCountOneOrMore Then
                    _tool := 'sequest';
                Else
                    If _scriptName::citext In ('Phospho_FDR_Aggregator') Then
                        -- Allow multiple Sequest jobs for each dataset;
                        _tool := 'sequest';
                    Else
                        _errMsg := format('Data package does not have exactly one Sequest job for each dataset (%s invalid datasets); script %s',
                                          _sequestCountNotOne, _scriptName);
                    End If;
                End If;
            End If;

            If _tool = '' Then
                _errMsg := public.append_to_text(
                                _errMsg,
                                format('Data package must have one or more MSGFPlus jobs; error validating script %s', _scriptName),
                                _delimiter => '; ',
                                _maxlength => 1024);
            End If;
        End If;

        ---------------------------------------------------
        -- Determine if job/tool coverage is acceptable for
        -- given job template
        ---------------------------------------------------

        If _scriptName::citext In ('Isobaric_Labeling') Then
            If _deconToolsCountNotOne > 0 Then
                _errMsg := public.append_to_text(
                                _errMsg,
                                format('There must be exactly one Decon2LS_V2 job per dataset for script %s', scriptName),
                                _delimiter => '; ',
                                _maxlength => 1024);
            End If;

            If _masicCountNotOne > 0 Then
                _errMsg := public.append_to_text(
                                _errMsg,
                                format('There must be exactly one MASIC_Finnigan job per dataset (and that job must use a parameter file with ReporterTol in the name) for script %s', scriptName),
                                _delimiter => '; ',
                                _maxlength => 1024);
            End If;
        End If;

        If _scriptName::citext In ('MAC_iTRAQ', 'MAC_TMT10Plex') Then
            If _masicCountNotOne > 0 Then
                _errMsg := public.append_to_text(
                                    _errMsg,
                                    format('There must be exactly one MASIC_Finnigan job per dataset (and that job must use a parameter file with ReporterTol in the name) for script %s', scriptName),
                                    _delimiter => '; ',
                                    _maxlength => 1024);
            End If;
        End If;

        If _scriptName::citext In ('Global_Label-Free_AMT_Tag') Then
            If _deconToolsCountNotOne > 0 Then
                _errMsg := public.append_to_text(
                                    _errMsg,
                                    format('There must be exactly one Decon2LS_V2 job per dataset for script %s', scriptName),
                                    _delimiter => '; ',
                                    _maxlength => 1024);
            End If;
        End If;

        If _errMsg <> '' Then
            _message := format('Data package %s is not configured correctly for this job: %s', _dataPackageID, _errMsg);
             RAISE WARNING '%', _message;
            _returnCode := 'U5251';
        End If;

        DROP TABLE Tmp_DataPackageItems;
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

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_DataPackageItems;
END
$$;


ALTER PROCEDURE sw.validate_data_package_for_mac_job(IN _datapackageid integer, IN _scriptname text, INOUT _tool text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_data_package_for_mac_job(IN _datapackageid integer, IN _scriptname text, INOUT _tool text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.validate_data_package_for_mac_job(IN _datapackageid integer, IN _scriptname text, INOUT _tool text, INOUT _message text, INOUT _returncode text) IS 'ValidateDataPackageForMACJob';


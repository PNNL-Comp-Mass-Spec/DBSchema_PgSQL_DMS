--
-- Name: verify_job_parameters(text, text, integer, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.verify_job_parameters(INOUT _jobparam text, IN _scriptname text, IN _datapackageid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Check input parameters against the definition for the script
**
**  Arguments:
**    _jobParam         XML job parameters, as text (input/output parameter)
**    _scriptName       Script name
**    _dataPackageID    Data package ID
**    _message          Status message
**    _returnCode       Return code
**    _debugMode        When true, set _debugMode to true when calling pc.validate_protein_collection_params()
**
**  Example contents of _jobParam
**      Note that element and attribute names are case sensitive (use Value= and not value=)
**      Default parameters for each job script are defined in the Parameters column of table T_Scripts
**
**      <Param Section="JobParameters" Name="CreateMzMLFiles" Value="False" />
**      <Param Section="JobParameters" Name="CacheFolderRootPath" Value="\\protoapps\MaxQuant_Staging" />        (or \\proto-9\MSFragger_Staging)
**      <Param Section="JobParameters" Name="DatasetName" Value="Aggregation" />
**      <Param Section="PeptideSearch" Name="ParamFileName" Value="MaxQuant_Tryp_Stat_CysAlk_Dyn_MetOx_NTermAcet_20ppmParTol.xml" />
**      <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MaxQuant" />
**      <Param Section="PeptideSearch" Name="OrganismName" Value="Homo_Sapiens" />
**      <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="H_sapiens_UniProt_SPROT_2021-06-20,Tryp_Pig_Bov" />
**      <Param Section="PeptideSearch" Name="ProteinOptions" Value="seq_direction=forward,filetype=fasta" />
**      <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="na" />
**
**  Auth:   grk
**  Date:   10/06/2010 grk - Initial release
**          11/25/2010 mem - Now validating that the script exists in T_Scripts
**          12/10/2013 grk - Problem inserting null values into Tmp_ParamDefinition
**          04/08/2016 mem - Clear _message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add arguments _dataPackageID and _debugMode
**          01/31/2022 mem - Add support for MSFragger
**          04/11/2022 mem - Use varchar(4000) when populating temporary tables
**          03/22/2023 mem - Add support for DiaNN
**          05/10/2023 mem - Do not update _protCollOptionsList when using a legacy FASTA file
**          07/27/2023 mem - Ported to PostgreSQL
**          07/28/2023 mem - Trim leading and trailing whitespace from parameter values
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/12/2023 mem - Use new argument name when calling validate_protein_collection_list_for_data_package
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          02/19/2024 mem - Query tables directly instead of using a view
**
*****************************************************/
DECLARE
    _parameterFileName text;
    _protCollNameList text := '';
    _protCollOptionsList text := '';
    _organismName text := '';
    _organismDBName text := '';             -- Aka legacy FASTA file;
    _usingLegacyFASTA boolean := false;
    _paramFileType text := '';
    _paramFileValid int;
    _collectionCountAdded int;
    _scriptBaseName citext := '';
    _paramDefinition xml;
    _jobParamXML xml;
    _missingParameters text := '';
BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    _scriptName    := Trim(Coalesce(_scriptName, ''));
    _dataPackageID := Coalesce(_dataPackageID, 0);

    ---------------------------------------------------
    -- Get parameter definition
    -- This is null for most scripts
    ---------------------------------------------------

    SELECT parameters
    INTO _paramDefinition
    FROM t_scripts
    WHERE script = _scriptName::citext;

    If Not FOUND Then
        _message := format('Script not found in sw.t_scripts: %s', Coalesce(_scriptName, '??'));
        _returnCode := 'U5201';

        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Extract parameter definitions (if any) into temp table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ParamDefinition (
        Section text,
        Name text,
        Value text NULL,
        Reqd citext NULL
    );

    INSERT INTO Tmp_ParamDefinition (Section, Name, Value, Reqd)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value, Coalesce(XmlQ.required, 'No') AS Requied
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _paramDefinition::text || '</params>')::xml AS rooted_xml ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section  citext PATH '@Section',
                              name     citext PATH '@Name',
                              value    citext PATH '@Value',
                              required citext PATH '@Reqd')
         ) XmlQ;

    ---------------------------------------------------
    -- Extract input parameters into temp table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobParameters (
        Section text,
        Name text,
        Value text
    );

    _jobParamXML := public.try_cast(_jobParam, null::XML);

    INSERT INTO Tmp_JobParameters (Section, Name, Value)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _jobParamXML::text || '</params>')::xml AS rooted_xml ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    ---------------------------------------------------
    -- Cross check to make sure required parameters are defined in Tmp_JobParameters (populated using _paramInput)
    ---------------------------------------------------

    SELECT string_agg(format('%s/%s', Tmp_ParamDefinition.Section, Tmp_ParamDefinition.Name), ', ' ORDER BY Tmp_ParamDefinition.Section, Tmp_ParamDefinition.Name)
    INTO _missingParameters
    FROM Tmp_ParamDefinition
         LEFT OUTER JOIN Tmp_JobParameters
             ON Tmp_ParamDefinition.Name = Tmp_JobParameters.Name AND
                Tmp_ParamDefinition.Section = Tmp_JobParameters.Section
    WHERE Tmp_ParamDefinition.Reqd = 'Yes' AND
          Coalesce(Tmp_JobParameters.Value, '') = '';

    If _missingParameters <> '' Then
        _message := format('Missing required parameters: %s', _missingParameters);
        RAISE INFO '%', _message;

        _returnCode := 'U5202';
        DROP TABLE Tmp_ParamDefinition;
        DROP TABLE Tmp_JobParameters;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Cross check to make sure required parameters are defined in Tmp_JobParameters (populated using _paramInput)
    ---------------------------------------------------

    If _scriptName ILike 'MaxQuant%' Or _scriptName ILike 'MSFragger%' Or _scriptName ILike 'DiaNN%' Then
        -- Verify the MaxQuant, MSFragger, or DiaNN parameter file name

        -- Also verify the protein collection (or legacy FASTA file)
        -- For protein collections, will auto-add contaminants if needed

        If _scriptName ILike 'MaxQuant%' Then
            _scriptBaseName := 'MaxQuant';
        End If;

        If _scriptName ILike 'MSFragger%' Then
            _scriptBaseName := 'MSFragger';
        End If;

        If _scriptName ILike 'DiaNN%' Then
            _scriptBaseName := 'DiaNN';
        End If;

        If _scriptBaseName = '' Then
            _message := format('Unrecognized script name: %s', _scriptName);
            RAISE INFO '%', _message;

            _returnCode := 'U5203';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        SELECT Trim(Value)
        INTO _parameterFileName
        FROM Tmp_JobParameters
        WHERE Name = 'ParamFileName';

        SELECT Trim(Value)
        INTO _protCollNameList
        FROM Tmp_JobParameters
        WHERE Name = 'ProteinCollectionList';

        SELECT Trim(Value)
        INTO _protCollOptionsList
        FROM Tmp_JobParameters
        WHERE Name = 'ProteinOptions';

        SELECT Trim(Value)
        INTO _organismName
        FROM Tmp_JobParameters
        WHERE Name = 'OrganismName';

        SELECT Trim(Value)
        INTO _organismDBName
        FROM Tmp_JobParameters
        WHERE Name = 'LegacyFastaFileName';

        _protCollNameList    := Trim(Coalesce(_protCollNameList, ''));
        _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, ''));
        _organismDBName      := Trim(Coalesce(_organismDBName, ''));

        If _organismDBName <> '' And
           public.validate_na_parameter(_protCollNameList) = 'na' And
           public.validate_na_parameter(_protCollOptionsList) = 'na' Then
            _usingLegacyFASTA := true;
        End If;

        If _protCollOptionsList = '' And Not _usingLegacyFASTA Then
            If _scriptBaseName In ('MaxQuant', 'DiaNN') Then
                _protCollOptionsList := 'seq_direction=forward,filetype=fasta';
            Else
                _protCollOptionsList := 'seq_direction=decoy,filetype=fasta';
            End If;
        End If;

        If _scriptBaseName In ('MaxQuant', 'DiaNN') And _protCollOptionsList <> 'seq_direction=forward,filetype=fasta' And Not _usingLegacyFASTA Then
            _message := format('The ProteinOptions parameter must be "seq_direction=forward,filetype=fasta" for %s jobs', _scriptBaseName);
            RAISE INFO '%', _message;

            _returnCode := 'U5204';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        If _scriptBaseName = 'MSFragger' And _protCollOptionsList <> 'seq_direction=decoy,filetype=fasta' And Not _usingLegacyFASTA Then
            _message := 'The ProteinOptions parameter must be "seq_direction=decoy,filetype=fasta" for MSFragger jobs';
            RAISE INFO '%', _message;

            _returnCode := 'U5205';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        SELECT pft.param_file_type, pf.valid
        INTO _paramFileType, _paramFileValid
        FROM public.t_param_files pf
             INNER JOIN public.t_param_file_types pft
               ON pf.param_file_type_id = pft.param_file_type_id
        WHERE pf.param_file_name = _parameterFileName::citext;

        If Not FOUND Then
            _message := format('Parameter file not found: %s', _parameterFileName);
            RAISE INFO '%', _message;

            _returnCode := 'U5206';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        If _paramFileValid = 0 Then
            _message := format('Parameter file is not active: %s', _parameterFileName);
            RAISE INFO '%', _message;

            _returnCode := 'U5207';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        If _paramFileType <> _scriptBaseName Then
            _message := format('Parameter file is for %s, and not %s: %s',
                                _paramFileType, _scriptBaseName, _parameterFileName);

            RAISE INFO '%', _message;

            _returnCode := 'U5208';
            DROP TABLE Tmp_ParamDefinition;
            DROP TABLE Tmp_JobParameters;
            RETURN;
        End If;

        CALL public.validate_protein_collection_params (
                        _scriptBaseName,
                        _organismDBName,                -- Output
                        _organismName,
                        _protCollNameList,              -- Output
                        _protCollOptionsList,           -- Output
                        _ownerUsername => '',
                        _message       => _message,     -- Output
                        _returncode    => _returnCode,  -- Output
                        _debugMode     => _debugMode);

        If _returncode = '' And Trim(Coalesce(_protCollNameList, '')) <> '' And public.validate_na_parameter(_protCollNameList) <> 'na' Then
            ---------------------------------------------------
            -- Validate _protCollNameList
            --
            -- Note that setting _listAddedCollections to true means that validate_protein_collection_list_for_dataset_table
            -- will populate _message with an explanatory note if _protCollNameList is updated
            ---------------------------------------------------

            CALL sw.validate_protein_collection_list_for_data_package (
                        _dataPackageID,
                        _protCollNameList     => _protCollNameList,         -- Output
                        _collectionCountAdded => _collectionCountAdded,     -- Output
                        _listAddedCollections => true,
                        _message              => _message,                  -- Output
                        _returnCode           => _returnCode);              -- Output
        End If;

        If _returnCode = '' Then
            -- Make sure values in Tmp_JobParameters are up-to-date, then re-generate _jobParamXML

            UPDATE Tmp_JobParameters
            SET Value = _protCollNameList
            WHERE Name = 'ProteinCollectionList';

            UPDATE Tmp_JobParameters
            SET Value = _protCollOptionsList
            WHERE Name = 'ProteinOptions';

            UPDATE Tmp_JobParameters
            SET Value = _organismName
            WHERE Name = 'OrganismName';

            UPDATE Tmp_JobParameters
            SET Value = _organismDBName
            WHERE Name = 'LegacyFastaFileName';

            SELECT xml_item
            INTO _jobParamXML
            FROM ( SELECT
                     XMLAGG(XMLELEMENT(
                            NAME "Param",
                            XMLATTRIBUTES(
                                section AS "Section",
                                name AS "Name",
                                value AS "Value"))
                            ORDER BY section, name
                           ) AS xml_item
                   FROM Tmp_JobParameters
                ) AS LookupQ;

            _jobParam := _jobParamXML::text;
        End If;
    End If;

    DROP TABLE Tmp_ParamDefinition;
    DROP TABLE Tmp_JobParameters;
END
$$;


ALTER PROCEDURE sw.verify_job_parameters(INOUT _jobparam text, IN _scriptname text, IN _datapackageid integer, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE verify_job_parameters(INOUT _jobparam text, IN _scriptname text, IN _datapackageid integer, INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.verify_job_parameters(INOUT _jobparam text, IN _scriptname text, IN _datapackageid integer, INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'VerifyJobParameters';


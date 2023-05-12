--

CREATE OR REPLACE PROCEDURE sw.verify_job_parameters
(
    INOUT _jobParam text,
    _scriptName text,
    _dataPackageID int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Check input parameters against the definition for the script
**
**  Arguments:
**    _jobParam   Input / output parameter
**
**  Auth:   grk
**  Date:   10/06/2010 grk - Initial release
**          11/25/2010 mem - Now validating that the script exists in T_Scripts
**          12/10/2013 grk - problem inserting null values into Tmp_ParamDefinition
**          04/08/2016 mem - Clear _message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add arguments _dataPackageID and _debugMode
**          01/31/2022 mem - Add support for MSFragger
**          04/11/2022 mem - Use varchar(4000) when populating temporary tables
**          03/22/2023 mem - Add support for DiaNN
**          05/10/2023 mem - Do not update _protCollOptionsList when using a legacy FASTA file
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
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
    _jobParamXML XML;
    _missingParameters text := '';
BEGIN
    _message := Coalesce(_message, '');
    _returnCode := Coalesce(_returnCode, '');

    _scriptName := Coalesce(_scriptName, '');
    _dataPackageID := Coalesce(_dataPackageID, 0);

    ---------------------------------------------------
    -- Get parameter definition
    -- This is null for most scripts
    ---------------------------------------------------

    --
    SELECT parameters
    INTO _paramDefinition
    FROM t_scripts
    WHERE script = _scriptName;

    If Not FOUND Then
        _message := 'script not found in sw.t_scripts: ' || Coalesce(_scriptName, '??');
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
    )

    INSERT INTO Tmp_ParamDefinition (Section, Name, Value, Reqd)
    SELECT
        xmlNode.value('@Section', 'text') Section,
        xmlNode.value('@Name', 'text') Name,
        xmlNode.value('@Value', 'text') VALUE,
        Coalesce(xmlNode.value('@Reqd', 'text'), 'No') as Reqd
    FROM
        _paramDefinition.nodes('//Param') AS R(xmlNode)

    ---------------------------------------------------
    -- Extract input parameters into temp table
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobParameters (
        Section text,
        Name text,
        Value text
    )

    _jobParamXML := _jobParam::XML;

    INSERT INTO Tmp_JobParameters (Section, Name, Value)
    SELECT
        xmlNode.value('@Section', 'text') Section,
        xmlNode.value('@Name', 'text') Name,
        xmlNode.value('@Value', 'text') Value
    FROM
        _jobParamXML.nodes('//Param') AS R(xmlNode)

    ---------------------------------------------------
    -- Cross check to make sure required parameters are defined in Tmp_JobParameters (populated using _paramInput)
    ---------------------------------------------------
    --

    SELECT string_agg(Tmp_ParamDefinition.Section || '/' || Tmp_ParamDefinition.Name, ',')
    INTO _missingParameters
    FROM Tmp_ParamDefinition
         LEFT OUTER JOIN Tmp_JobParameters
             ON Tmp_ParamDefinition.Name = Tmp_JobParameters.Name AND
                Tmp_ParamDefinition.Section = Tmp_JobParameters.Section
    WHERE Tmp_ParamDefinition.Reqd = 'Yes' AND
          Coalesce(Tmp_JobParameters.Value, '') = '';

    If _missingParameters <> '' Then
        _message := 'Missing required parameters: ' || _missingParameters;
        RAISE INFO '%', _message;

        _returnCode := 'U5202';
        DROP TABLE Tmp_ParamDefinition;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Cross check to make sure required parameters are defined in Tmp_JobParameters (populated using _paramInput)
    ---------------------------------------------------
    --
    If _scriptName ILIKE 'MaxQuant%' Or _scriptName ILIKE 'MSFragger%' Or _scriptName ILIKE 'DiaNN%' Then
        -- Verify the MaxQuant, MSFragger, or DiaNN parameter file name

        -- Also verify the protein collection (or legacy FASTA file)
        -- For protein collections, will auto-add contaminants if needed

        If _scriptName ILIKE 'MaxQuant%' Then
            _scriptBaseName := 'MaxQuant';
        End If;

        If _scriptName ILIKE 'MSFragger%' Then
            _scriptBaseName := 'MSFragger';
        End If;

        If _scriptName ILIKE 'DiaNN%' Then
            _scriptBaseName := 'DiaNN';
        End If;

        If _scriptBaseName = '' Then
            _message := 'Unrecognized script name: ' || _scriptName;
            RAISE INFO '%', _message;

            _returnCode := 'U5203';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End


        SELECT Value INTO _parameterFileName
        FROM Tmp_JobParameters
        WHERE Name = 'ParamFileName'
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        SELECT Value INTO _protCollNameList
        FROM Tmp_JobParameters
        WHERE Name = 'ProteinCollectionList'

        SELECT Value INTO _protCollOptionsList
        FROM Tmp_JobParameters
        WHERE Name = 'ProteinOptions'

        SELECT Value INTO _organismName
        FROM Tmp_JobParameters
        WHERE Name = 'OrganismName'

        SELECT Value INTO _organismDBName
        FROM Tmp_JobParameters
        WHERE Name = 'LegacyFastaFileName'

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
            _message := 'The ProteinOptions parameter must be "seq_direction=forward,filetype=fasta" for ' || _scriptBaseName || ' jobs';
            RAISE INFO '%', _message;

            _returnCode := 'U5204';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End If;

        If _scriptBaseName = 'MSFragger' And _protCollOptionsList <> 'seq_direction=decoy,filetype=fasta' And Not _usingLegacyFASTA Then
            _message := 'The ProteinOptions parameter must be "seq_direction=decoy,filetype=fasta" for MSFragger jobs';
            RAISE INFO '%', _message;

            _returnCode := 'U5205';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End If;

        SELECT Valid
        INTO _paramFileValid
        FROM public.V_Param_File_Export
        WHERE Param_File_Name = _parameterFileName;

        If Not FOUND Then
            _message := 'Parameter file not found: ' || _parameterFileName;
            RAISE INFO '%', _message;

            _returnCode := 'U5206';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End If;

        If _paramFileValid = 0 Then
            _message := 'Parameter file is not active: ' || _parameterFileName;
            RAISE INFO '%', _message;

            _returnCode := 'U5207';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End If;

        If _paramFileType <> _scriptBaseName Then
            _message := 'Parameter file is for ' || _paramFileType || ', and not ' || _scriptBaseName || ': ' || _parameterFileName;
            RAISE INFO '%', _message;

            _returnCode := 'U5208';
            DROP TABLE Tmp_ParamDefinition;
            RETURN;
        End If;

        Call pc.validate_protein_collection_params (
                        _scriptBaseName,
                        _organismDBName,            -- Output
                        _organismName,
                        _protCollNameList,          -- Output
                        _protCollOptionsList,       -- Output
                        _ownerUsername => '',
                        _message => _message,       -- Output
                        _returncode => _returnCode, -- Output
                        _debugMode => _debugMode);

        If _returncode = '' AND char_length(_protCollNameList) > 0 And public.validate_na_parameter(_protCollNameList) <> 'na' Then
            ---------------------------------------------------
            -- Validate _protCollNameList
            --
            -- Note that validate_protein_collection_list_for_dataset_table
            -- will populate _message with an explanatory note
            -- if _protCollNameList is updated
            ---------------------------------------------------
            --
            Call sw.validate_protein_collection_list_for_data_package (
                                _dataPackageID,
                                _protCollNameList => _protCollNameList,             -- Output
                                _collectionCountAdded => _collectionCountAdded,     -- Output
                                _showMessages => true,
                                _message => _message);                              -- Output
        End If;

        If _returnCode = '' Then
            -- Make sure values in Tmp_JobParameters are up-to-date, then re-generate _jobParamXML

            UPDATE Tmp_JobParameters
            SET Value = _protCollNameList
            WHERE Name = 'ProteinCollectionList'

            UPDATE Tmp_JobParameters
            SET Value = _protCollOptionsList
            WHERE Name = 'ProteinOptions'

            UPDATE Tmp_JobParameters
            SET Value = _organismName
            WHERE Name = 'OrganismName'

            UPDATE Tmp_JobParameters
            SET Value = _organismDBName
            WHERE Name = 'LegacyFastaFileName'

            -- ToDo: update this to use XMLAGG(XMLELEMENT(
            --       Look for similar capture task code in cap.*

            _jobParamXML := ( SELECT * FROM Tmp_JobParameters AS Param FOR XML AUTO, TYPE);

            _jobParam := CAST(_jobParamXML as text);
        End If;
    End If;

    DROP TABLE Tmp_ParamDefinition;
    DROP TABLE Tmp_JobParameters;
END
$$;

COMMENT ON PROCEDURE sw.verify_job_parameters IS 'VerifyJobParameters';


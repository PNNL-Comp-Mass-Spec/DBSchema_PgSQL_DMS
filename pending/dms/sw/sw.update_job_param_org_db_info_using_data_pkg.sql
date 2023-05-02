--
CREATE OR REPLACE PROCEDURE sw.update_job_param_org_db_info_using_data_pkg
(
    _job int,
    _dataPackageID int,
    _deleteIfInvalid boolean = false,
    _debugMode boolean = false,
    _scriptNameForDebug text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create or update entries for OrganismName, LegacyFastaFileName,
**      ProteinOptions, and ProteinCollectionList in T_Job_Parameters
**      for the specified job using the specified data package
**
**  Arguments:
**    _deleteIfInvalid   When true, deletes entries for OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList if _dataPackageID = 0, or _dataPackageID points to a non-existent data package, or if the data package doesn't have any Peptide_Hit jobs (MAC Jobs) or doesn't have any datasets (MaxQuant, MSFragger, or DiaNN)
**
**  Auth:   mem
**  Date:   03/20/2012 mem - Initial version
**          09/11/2012 mem - Updated warning message used when data package does not have any jobs with a protein collection or legacy fasta file
**          08/14/2013 mem - Now using the job script name which is used to decide whether or not to report a warning via _message
**          03/09/2021 mem - Add support for MaxQuant
**          01/31/2022 mem - Add support for MSFragger
**                         - Add parameters _debugMode and _scriptNameForDebug
**          03/27/2023 mem - Add support for DiaNN
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _messageAddon text;
    _scriptName text := '';
    _organismName text := '';
    _legacyFastaFileName text := '';
    _proteinCollectionList text := '';
    _proteinOptions text := '';
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --

    If _job Is Null Or _dataPackageID Is Null Then
        _message := '_job and _dataPackageID are required';
        _returnCode := 'U5201';
        RETURN;
    End If;

    _deleteIfInvalid := Coalesce(_deleteIfInvalid, false);
    _debugMode := Coalesce(_debugMode, false);
    _message := '';
    _returnCode:= '';

    If _debugMode Then
        RAISE INFO '%', '';
        RAISE INFO '%', 'Examining parameters for job ' || Cast(_job As text) || ', script ' || _scriptNameForDebug;

        _scriptName := _scriptNameForDebug;
    Else
        ---------------------------------------------------
        -- Lookup the name of the job script
        ---------------------------------------------------
        --
        SELECT script
        INTO _scriptName
        FROM sw.t_jobs
        WHERE job = _job;

        _scriptName := Coalesce(_scriptName, '??');
    End If;

    ---------------------------------------------------
    -- Validate _dataPackageID
    ---------------------------------------------------
    --

    If Not Exists (SELECT * FROM dpkg.t_data_package WHERE data_pkg_id = _dataPackageID) Then
        _message := 'Data package ' || _dataPackageID::text || ' not found in the Data_Package database';
        _dataPackageID := -1;

        If _debugMode Then
            RAISE INFO '%', 'UpdateJobParamOrgDbInfoUsingDataPkg: ' || _message;
        End If;
    End If;

    If _dataPackageID > 0 AND NOT _scriptName ILIKE 'MaxQuant%' AND NOT _scriptName ILIKE 'MSFragger%' AND NOT _scriptName ILIKE 'DiaNN%' Then

        If _debugMode Then
            RAISE INFO 'UpdateJobParamOrgDbInfoUsingDataPkg: update OrgDB info for jobs associated with data package % for script %', _dataPackageID, _scriptName;
        End If;

        CREATE TEMP TABLE Tmp_OrgDBInfo (
            EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            OrganismName text NULL,
            LegacyFastaFileName text NULL,
            ProteinCollectionList text NULL,
            ProteinOptions text NULL,
            UseCount int NOT NULL
        )

        ---------------------------------------------------
        -- Lookup the OrgDB info for jobs associated with data package _dataPackageID
        ---------------------------------------------------
        --
        INSERT INTO Tmp_OrgDBInfo( OrganismName,
                                   LegacyFastaFileName,
                                   ProteinCollectionList,
                                   ProteinOptions,
                                   UseCount )
        SELECT Organism,
               CASE
                   WHEN Coalesce(ProteinCollectionList, 'na') <> 'na' AND
                        Coalesce(ProteinOptionsList, 'na') <> 'na' THEN 'na'
                   ELSE OrganismDBName
               END AS LegacyFastaFileName,
               ProteinCollectionList,
               ProteinOptionsList,
               COUNT(*) AS UseCount
        FROM PUBLIC.V_GetPipelineJobParameters J
        WHERE Job IN ( SELECT Job
                       FROM dpkg.T_Data_Package_Analysis_Jobs
                       WHERE Data_Package_ID = _dataPackageID ) AND
              J.OrgDBRequired <> 0
        GROUP BY Organism, OrganismDBName, ProteinCollectionList, ProteinOptionsList
        ORDER BY COUNT(*) DESC;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        ---------------------------------------------------
        -- Check for invalid data
        ---------------------------------------------------
        --
        If _myRowCount = 0 Then
            If _scriptName Not In ('Global_Label-Free_AMT_Tag', 'MultiAlign', 'MultiAlign_Aggregator') Then
                _message := 'Note: Data package ' || _dataPackageID::text || ' either has no jobs or has no jobs with a protein collection or legacy fasta file; pipeline job parameters will not contain organism, fasta file, or protein collection';
            End If;

            _dataPackageID := -1;
        Else

            If _myRowCount > 1 Then
                -- Mix of protein collections / fasta files defined

                _organismName := 'InvalidData';
                _legacyFastaFileName := 'na';
                _proteinCollectionList := 'MixOfOrgDBs_DataPkg_' || _dataPackageID::text || '_UniqueComboCount_' || _myRowCount::text;
                _proteinOptions := 'seq_direction=forward,filetype=fasta';

            Else
                -- _myRowCount is 1

                SELECT OrganismName,
                       LegacyFastaFileName,
                       ProteinCollectionList,
                       ProteinOptions
                INTO _organismName, _legacyFastaFileName, _proteinCollectionList, _proteinOptions
                FROM Tmp_OrgDBInfo;

            End If;

            If _debugMode Then
                RAISE INFO '%', '';
                RAISE INFO '%', 'UpdateJobParamOrgDbInfoUsingDataPkg would update the following parameters for job ' || Cast (_job As text);
                RAISE INFO '%', '  OrganismName=         ' || _organismName;
                RAISE INFO '%', '  LegacyFastaFileName=  ' || _legacyFastaFileName;
                RAISE INFO '%', '  ProteinCollectionList=' || _proteinCollectionList;
                RAISE INFO '%', '  ProteinOptions=       ' || _proteinOptions;
            Else
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'OrganismName',          _value => _organismName,          _deleteParam => false);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'LegacyFastaFileName',   _value => _legacyFastaFileName,   _deleteParam => false);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinCollectionList', _value => _proteinCollectionList, _deleteParam => false);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinOptions',        _value => _proteinOptions,        _deleteParam => false);
            End If;

            _message := 'Defined OrgDb related parameters for job ' || _job::text;

            DROP TABLE Tmp_OrgDBInfo;

        End If;

    End If; -- </a>

    If _dataPackageID <= 0 Then
        ---------------------------------------------------
        -- One of the following is tue:
        --   Data package ID was invalid
        --   For MAC jobs, the data package does not have any jobs with a protein collection or legacy fasta file
        --   For MaxQuant, MSFragger, or DiaNN jobs, the data package does not have any datasets
        ---------------------------------------------------
        --

        If _deleteIfInvalid Then
            If _debugMode Then
                RAISE INFO '%', '';
                RAISE INFO '%', 'UpdateJobParamOrgDbInfoUsingDataPkg would delete following parameters for job ' || Cast (_job As text) || ' since the data package ID is 0';
                RAISE INFO '%', '  OrganismName';
                RAISE INFO '%', '  LegacyFastaFileName';
                RAISE INFO '%', '  ProteinCollectionList';
                RAISE INFO '%', '  ProteinOptions';
            Else
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'OrganismName',          _value => '',  _deleteParam => true);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'LegacyFastaFileName',   _value => '',  _deleteParam => true);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinCollectionList', _value => '',  _deleteParam => true);
                Call sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinOptions',        _value => '',  _deleteParam => true);
            End If;

            _messageAddon := 'Deleted OrgDb related parameters from the PeptideSearch section of the job parameters for job ' || _job::text;

            If Coalesce(_message, '') = '' Then
                _message := _messageAddon;
            Else
                _message := _message || '; ' || _messageAddon;
            End If;

        End If;
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --

$$;

COMMENT ON PROCEDURE sw.update_job_param_org_db_info_using_data_pkg IS 'UpdateJobParamOrgDbInfoUsingDataPkg';

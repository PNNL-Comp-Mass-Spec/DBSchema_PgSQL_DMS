--
-- Name: update_job_param_org_db_info_using_data_pkg(integer, integer, boolean, boolean, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_param_org_db_info_using_data_pkg(IN _job integer, IN _datapackageid integer, IN _deleteifinvalid boolean DEFAULT false, IN _debugmode boolean DEFAULT false, IN _scriptnamefordebug text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
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
**    _job                  Job Number
**    _dataPackageID        Data package ID
**    _deleteIfInvalid      When true, delete entries for OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList if any of these conditions is true:
**                          - Data package ID (_dataPackageID) is 0
**                          - Data package ID references a non-existent data package,
**                          - The data package doesn't have any Peptide_Hit jobs (MAC Jobs)
**    _debugMode            When true, preview the job parameters that would be updated
**    _scriptNameForDebug   Script name to use if _job is not found in sw.t_jobs
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   mem
**  Date:   03/20/2012 mem - Initial version
**          09/11/2012 mem - Updated warning message used when data package does not have any jobs with a protein collection or standalone (legacy) fasta file
**          08/14/2013 mem - Now using the job script name which is used to decide whether or not to report a warning via _message
**          03/09/2021 mem - Add support for MaxQuant
**          01/31/2022 mem - Add support for MSFragger
**                         - Add parameters _debugMode and _scriptNameForDebug
**          03/27/2023 mem - Add support for DiaNN
**          07/26/2023 mem - Ported to PostgreSQL
**          07/27/2023 mem - Switch from using view V_Get_Pipeline_Job_Parameters to directly querying tables
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _insertCount int;
    _messageAddon text;
    _scriptName citext := '';
    _organismName text := '';
    _legacyFastaFileName text := '';
    _proteinCollectionList text := '';
    _proteinOptions text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _job Is Null Or _dataPackageID Is Null Then
        _message := '_job and _dataPackageID are required';
        _returnCode := 'U5201';
        RETURN;
    End If;

    _deleteIfInvalid := Coalesce(_deleteIfInvalid, false);
    _debugMode       := Coalesce(_debugMode, false);

    If _debugMode Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Lookup the name of the job script
    ---------------------------------------------------

    SELECT script
    INTO _scriptName
    FROM sw.t_jobs
    WHERE job = _job;

    If Not FOUND Then
        If _debugMode Then
            If Coalesce(_scriptNameForDebug, '') = '' Then
                _message := format('Job %s not found in sw.t_jobs; use _scriptNameForDebug to specify the script to use', _job);
                RAISE WARNING '%', _message;
                RETURN;
            Else
                _scriptName := _scriptNameForDebug;
            End If;
        Else
            _message := format('Update_Job_Param_Org_Db_Info_Using_Data_Pkg: job %s not found in sw.t_jobs', _job);
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;
    End If;

    If _debugMode Then
        RAISE INFO '';
        RAISE INFO 'Examining parameters for job %, script %', _job, _scriptName;
    End If;

    ---------------------------------------------------
    -- Validate _dataPackageID
    ---------------------------------------------------

    If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _dataPackageID) Then
        _message := format('Data package %s not found in dpkg.t_data_package', _dataPackageID);
        _dataPackageID := -1;

        If _debugMode Then
            RAISE INFO 'Update_Job_Param_Org_Db_Info_Using_Data_Pkg: %', _message;
        End If;
    End If;

    If _dataPackageID > 0 And Not _scriptName ILike 'MaxQuant%' And Not _scriptName ILike 'MSFragger%' And Not _scriptName ILike 'DiaNN%' Then
        -- The script is one of the following:
        --   MAC_iTRAQ
        --   MAC_TMT10Plex
        --   Phospho_FDR_Aggregator
        --   PRIDE_Converter

        -- Auto-add job parameters OrganismName, LegacyFastaFileName, ProteinCollectionList, and ProteinOptions

        If _debugMode Then
            RAISE INFO 'Update_Job_Param_Org_Db_Info_Using_Data_Pkg: update OrgDB info for jobs associated with data package % for script %', _dataPackageID, _scriptName;
        End If;

        CREATE TEMP TABLE Tmp_OrgDBInfo (
            EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            OrganismName text NULL,
            LegacyFastaFileName text NULL,
            ProteinCollectionList text NULL,
            ProteinOptions text NULL,
            UseCount int NOT NULL
        );

        ---------------------------------------------------
        -- Lookup the OrgDB info for jobs associated with data package _dataPackageID
        ---------------------------------------------------

        INSERT INTO Tmp_OrgDBInfo (
            OrganismName,
            LegacyFastaFileName,
            ProteinCollectionList,
            ProteinOptions,
            UseCount
        )
        SELECT Org.Organism,
               CASE
                   WHEN Coalesce(J.Protein_Collection_List, 'na') <> 'na' AND
                        Coalesce(J.Protein_Options_List,    'na') <> 'na'
                   THEN 'na'
                   ELSE J.Organism_DB_Name
               END AS Legacy_Fasta_File_Name,
               J.Protein_Collection_List,
               J.Protein_Options_List,
               COUNT(J.job) AS Use_Count
        FROM public.t_analysis_job J
             INNER JOIN public.t_organisms Org
               ON J.organism_id = Org.organism_id
             INNER JOIN public.t_analysis_tool Tool
               ON J.analysis_tool_id = Tool.analysis_tool_id
        WHERE J.Job IN (SELECT Job
                        FROM dpkg.t_data_package_analysis_jobs
                        WHERE Data_Pkg_ID = _dataPackageID) AND
              Tool.Org_DB_Required <> 0
        GROUP BY Org.Organism, J.Organism_DB_Name, J.Protein_Collection_List, J.Protein_Options_List
        ORDER BY COUNT(J.job) DESC;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        ---------------------------------------------------
        -- Check for invalid data
        ---------------------------------------------------

        If _insertCount = 0 Then
            If Not _scriptName In ('Global_Label-Free_AMT_Tag', 'MultiAlign', 'MultiAlign_Aggregator') Then
                _message := format('Note: Data package %s either has no jobs or has no jobs with a protein collection or standalone fasta file; pipeline job parameters will not contain organism, fasta file, or protein collection', _dataPackageID);
            End If;

            _dataPackageID := -1;
        Else

            If _insertCount > 1 Then
                -- Mix of protein collections / FASTA files defined

                _organismName := 'InvalidData';
                _legacyFastaFileName := 'na';
                _proteinCollectionList := format('MixOfOrgDBs_DataPkg_%s_UniqueComboCount_%s', _dataPackageID, _insertCount);
                _proteinOptions := 'seq_direction=forward,filetype=fasta';

            Else
                -- _insertCount is 1

                SELECT OrganismName,
                       LegacyFastaFileName,
                       ProteinCollectionList,
                       ProteinOptions
                INTO _organismName, _legacyFastaFileName, _proteinCollectionList, _proteinOptions
                FROM Tmp_OrgDBInfo;

            End If;

            If _debugMode Then
                RAISE INFO '';
                RAISE INFO 'Update_Job_Param_Org_Db_Info_Using_Data_Pkg would update the following parameters for job %', _job;
                RAISE INFO '  OrganismName=         %', _organismName;
                RAISE INFO '  LegacyFastaFileName=  %', _legacyFastaFileName;
                RAISE INFO '  ProteinCollectionList=%', _proteinCollectionList;
                RAISE INFO '  ProteinOptions=       %', _proteinOptions;

                _message := format('Would define OrgDb related parameters for job %s', _job);
            Else
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'OrganismName',          _value => _organismName,          _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'LegacyFastaFileName',   _value => _legacyFastaFileName,   _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinCollectionList', _value => _proteinCollectionList, _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinOptions',        _value => _proteinOptions,        _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);

                _message := format('Defined OrgDb related parameters for job %s', _job);
            End If;

            DROP TABLE Tmp_OrgDBInfo;

        End If;

    End If;

    If _dataPackageID <= 0 Then
        ---------------------------------------------------
        -- One of the following is true:
        --   Data package ID was invalid
        --   For MAC jobs, the data package does not have any jobs with a protein collection or standalone (legacy) FASTA file
        ---------------------------------------------------

        If _deleteIfInvalid Then
            If _debugMode Then
                RAISE INFO '';
                RAISE INFO 'Update_Job_Param_Org_Db_Info_Using_Data_Pkg would delete following parameters for job % since the data package ID is 0', _job;
                RAISE INFO '  OrganismName';
                RAISE INFO '  LegacyFastaFileName';
                RAISE INFO '  ProteinCollectionList';
                RAISE INFO '  ProteinOptions';
            Else
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'OrganismName',          _value => '',  _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'LegacyFastaFileName',   _value => '',  _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinCollectionList', _value => '',  _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
                CALL sw.add_update_job_parameter (_job, 'PeptideSearch', 'ProteinOptions',        _value => '',  _deleteParam => false, _message => _message, _returncode => _returncode, _infoOnly => false);
            End If;

            _messageAddon := format('Deleted OrgDb related parameters from the PeptideSearch section of the job parameters for job %s', _job);

            If Coalesce(_message, '') = '' Then
                _message := _messageAddon;
            Else
                _message := format('%s; %s', _message, _messageAddon);
            End If;

        End If;
    End If;

END
$$;


ALTER PROCEDURE sw.update_job_param_org_db_info_using_data_pkg(IN _job integer, IN _datapackageid integer, IN _deleteifinvalid boolean, IN _debugmode boolean, IN _scriptnamefordebug text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_param_org_db_info_using_data_pkg(IN _job integer, IN _datapackageid integer, IN _deleteifinvalid boolean, IN _debugmode boolean, IN _scriptnamefordebug text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_param_org_db_info_using_data_pkg(IN _job integer, IN _datapackageid integer, IN _deleteifinvalid boolean, IN _debugmode boolean, IN _scriptnamefordebug text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateJobParamOrgDbInfoUsingDataPkg';


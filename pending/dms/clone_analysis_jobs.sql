--
CREATE OR REPLACE PROCEDURE public.clone_analysis_jobs
(
    _sourceJobs text,
    _newParamFileName text = '',
    _newSettingsFileName text = '',
    _newProteinCollectionList text = '',
    _supersedeOldJob boolean = false,
    _updateOldJobComment boolean = true,
    _allowDuplicateJob boolean = false,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Clone a series of related analysis jobs to create new jobs with a
**      new parameter file, new settings file, and/or new protein collection list
**
**      The source jobs must all have the same parameter file and settings file (this is a safety feature)
**      The source jobs do not have to use the same protein collection
**
**      If _newProteinCollectionList is empty, each new job will have the same protein collection as the old job
**      If _newProteinCollectionList is not empty, all new jobs will have the same protein collection
**
**  Arguments:
**    _sourceJobs                   Comma-separated list of jobs to copy
**    _newParamFileName             New parameter file to use
**    _newSettingsFileName          New settings file to use
**    _newProteinCollectionList     New protein collection to use (if empty, use the same protein collection as teh old job)
**    _supersedeOldJob              When true, change the state of old jobs to 14
**    _updateOldJobComment          When true, add the new job number to the old job comment
**    _allowDuplicateJob            When true, allow the new jobs to be duplicates of the old jobs (useful for testing a new version of a tool or updated .UIMF)
**    _infoOnly                     When true, preview updates
**    _message                      Output message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   07/12/2016 mem - Initial version
**          07/19/2016 mem - Add parameter _allowDuplicateJob
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/29/2022 mem - Use Coalesce instead of Coalesce
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _invalidJobs boolean;
    _result int;
    _newJobIdStart int;
    _jobCount int;
    _jobCountCompare int;
    _mostCommonParamFile text;
    _mostCommonSettingsFile text;
    _errorMessage text;
    _cloneJobs text := 'Clone jobs';
    _action text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        -----------------------------------------
        -- Validate the inputs
        -----------------------------------------

        _sourceJobs               := Trim(Coalesce(_sourceJobs, ''));
        _newParamFileName         := Trim(Coalesce(_newParamFileName, ''));
        _newSettingsFileName      := Trim(Coalesce(_newSettingsFileName, ''));
        _newProteinCollectionList := Trim(Coalesce(_newProteinCollectionList, ''));

        _supersedeOldJob          := Coalesce(_supersedeOldJob, false);
        _updateOldJobComment      := Coalesce(_updateOldJobComment, true);
        _allowDuplicateJob        := Coalesce(_supersedeOldJob, false);
        _infoOnly                 := Coalesce(_infoOnly, true);

        If _sourceJobs = '' Then
            _message := '_sourceJobs cannot both be empty';
            RETURN;
        End If;

        If _newProteinCollectionList <> '' Then
            -- Validate _newProteinCollectionList

            CALL sw.validate_analysis_job_protein_parameters (
                                _organismName => 'None',
                                _ownerUsername => 'H09090911',
                                _organismDBFileName => 'na',
                                _protCollNameList => _newProteinCollectionList,
                                _protCollOptionsList => 'seq_direction=forward,filetype=fasta',
                                _message => _message,           -- Output
                                _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                If Coalesce(_message, '') = '' Then
                    _message := format('Protein collection list validation error, result code %s', _returnCode);
                End If;

                RETURN;
            End If;

        End If;

        -----------------------------------------
        -- Create some temporary tables
        -----------------------------------------

        CREATE TEMP TABLE Tmp_SourceJobs (
            JobId int NOT NULL,
            Valid int NOT NULL,
            StateID int NOT NULL,
            RowNum int NOT NULL
        );

        CREATE TEMP TABLE Tmp_NewJobInfo(
            JobId_Old int NOT NULL,
            JobId_New int NOT NULL,
            Batch_ID int NOT NULL,
            Priority int NOT NULL,
            Analysis_Tool_id int NOT NULL,
            Param_File_Name text NOT NULL,
            Settings_File_Name text NULL,
            Organism_DB_Name text NULL,
            Organism_ID int NOT NULL,
            Dataset_ID int NOT NULL,
            Comment text NULL,
            Owner_Username text NULL,
            Protein_Collection_List text NULL,
            Protein_Options_List text NOT NULL,
            Request_ID int NOT NULL,
            Propagation_Mode int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_NewJobInfo ON Tmp_NewJobInfo (JobId_New);

        -----------------------------------------
        -- Find the source jobs
        -----------------------------------------

        INSERT INTO Tmp_SourceJobs (JobId, Valid, StateID, RowNum)
        SELECT Value, 0 As Valid, 0 AS StateID, Row_Number() Over (Order By Value) As RowNum
        FROM public.parse_delimited_integer_list(_sourceJobs)

        If Not Exists (SELECT * FROM Tmp_SourceJobs) Then
            _message := format('_sourceJobs did not have any valid Job IDs: %s', _sourceJobs);

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        End If;

        -----------------------------------------
        -- Validate the source job IDs
        -----------------------------------------

        UPDATE Tmp_SourceJobs
        SET Valid = 1,
            StateID = J.job_state_id
        FROM t_analysis_job J
        WHERE J.job = Tmp_SourceJobs.JobID;

        If Exists (SELECT JobId FROM Tmp_SourceJobs WHERE Valid = 0) Then
            _message := 'One or more Job IDs are invalid';
            _invalidJobs := true;
        ElsIf Exists (SELECT JobId FROM Tmp_SourceJobs WHERE NOT StateID IN (4, 14)) Then
            _message := 'One or more Job IDs are not in state 4 or 14';
            _invalidJobs := true;
        Else
            _invalidJobs := false;
        End If;

        If _invalidJobs Then

            RAISE INFO '';

            RAISE WARNING '%', _message;
            RAISE INFO '';

            _formatSpecifier := '%-10s %-5s %-8s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Valid',
                                'State_ID'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId,
                       Valid,
                       StateID
                FROM Tmp_SourceJobs
                ORDER BY JobId
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId,
                                    _previewData.Valid,
                                    _previewData.StateID
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        End If;

        -----------------------------------------
        -- Count the source jobs
        -----------------------------------------

        SELECT COUNT(*)
        INTO _jobCount
        FROM Tmp_SourceJobs;

        -----------------------------------------
        -- Validate that all the source jobs have the same parameter file
        -----------------------------------------

        SELECT param_file_name,
               NumJobs
        INTO _mostCommonParamFile, _jobCountCompare
        FROM ( SELECT J.param_file_name AS param_file_name,
                      COUNT(J.job) AS NumJobs
               FROM Tmp_SourceJobs
                    INNER JOIN t_analysis_job J
                      ON Tmp_SourceJobs.JobID = J.job
               GROUP BY J.param_file_name ) StatsQ
        ORDER BY NumJobs DESC
        LIMIT 1;

        If _jobCountCompare < _jobCount Then

            RAISE INFO '';

            _message := 'The source jobs must all have the same parameter file';
            RAISE WARNING '%', _message;

            _formatSpecifier := '%-10s %-5s %-80s %-60s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Valid',
                                'Param_File_Name',
                                'Settings_File_Name',
                                'Warning'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId,
                       Valid,
                       J.param_file_name,
                       J.settings_file_name,
                       CASE WHEN J.param_file_name = _mostCommonParamFile THEN ''
                            ELSE 'Mismatched param file'
                       END AS Warning
                FROM Tmp_SourceJobs
                     INNER JOIN t_analysis_job J
                       ON Tmp_SourceJobs.JobID = J.job
                ORDER BY CASE WHEN J.param_file_name = _mostCommonParamFile THEN 1 ELSE 0 END, J.job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId,
                                    _previewData.Valid,
                                    _previewData.param_file_name,
                                    _previewData.settings_file_name,
                                    _previewData.Warning
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        End If;

        -----------------------------------------
        -- Validate that all the source jobs have the same settings file
        -----------------------------------------

        SELECT settings_file_name,
               NumJobs
        INTO _mostCommonSettingsFile, _jobCountCompare
        FROM ( SELECT J.settings_file_name AS settings_file_name,
                      COUNT(J.job) AS NumJobs
               FROM Tmp_SourceJobs
                    INNER JOIN t_analysis_job J
                      ON Tmp_SourceJobs.JobID = J.job
               GROUP BY J.settings_file_name ) StatsQ
        ORDER BY NumJobs DESC
        LIMIT 1;

        If _jobCountCompare < _jobCount Then

            RAISE INFO '';

            _message := 'The source jobs must all have the same settings file';
            RAISE WARNING '%', _message;

            _formatSpecifier := '%-10s %-5s %-80s %-60s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Valid',
                                'Param_File_Name',
                                'Settings_File_Name',
                                'Warning'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId,
                       Valid,
                       J.param_file_name,
                       J.settings_file_name,
                       CASE WHEN J.settings_file_name = _mostCommonSettingsFile THEN ''
                            ELSE 'Mismatched settings file'
                       END AS Warning
                FROM Tmp_SourceJobs
                     INNER JOIN t_analysis_job J
                       ON Tmp_SourceJobs.JobID = J.job
                ORDER BY CASE WHEN J.settings_file_name = _mostCommonSettingsFile THEN 1 ELSE 0 END, J.job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId,
                                    _previewData.Valid,
                                    _previewData.param_file_name,
                                    _previewData.settings_file_name,
                                    _previewData.Warning
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        End If;

        -----------------------------------------
        -- If _newProteinCollectionList is not empty,
        -- make sure that it was not in use by any of the old jobs
        -----------------------------------------

        If _newProteinCollectionList <> '' Then
            If Exists ( SELECT * Then
                        FROM Tmp_SourceJobs;
                             INNER JOIN t_analysis_job J
                               ON Tmp_SourceJobs.JobID = J.job
                        WHERE J.protein_collection_list = _newProteinCollectionList ) Then

                _message := format('ProteinCollectionList was used by one or more of the existing jobs; not cloning the jobs: %s', _newProteinCollectionList);
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_SourceJobs;
                DROP TABLE Tmp_NewJobInfo;
                RETURN;

            End If;
        End If;

        -----------------------------------------
        -- Make sure that something is changing
        -----------------------------------------

        If _newParamFileName = '' And _newSettingsFileName = '' And _newProteinCollectionList = '' Then
            _message := '_newParamFileName, _newSettingsFileName, and _newProteinCollectionList cannot all be empty';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        Else
            If Not _allowDuplicateJob Then
                If _newParamFileName <> '' And _mostCommonParamFile = _newParamFileName Then
                    _message := format('The new parameter file name matches the old name; not cloning the jobs: %s', _newParamFileName);
                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_SourceJobs;
                    DROP TABLE Tmp_NewJobInfo;
                    RETURN;
                End If;

                If _newSettingsFileName <> '' And _mostCommonSettingsFile = _newSettingsFileName Then
                    _message := format('The new settings file name matches the old name; not cloning the jobs: %s', _newSettingsFileName);
                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_SourceJobs;
                    DROP TABLE Tmp_NewJobInfo;
                    RETURN;
                End If;
            End If;
        End If;

        -----------------------------------------
        -- Determine the starting JobID for the new jobs
        -----------------------------------------

        If Not _infoOnly Then
            -- Reserve a block of Job Ids
            -- This procedure populates temporary table Tmp_NewJobIDs

            CREATE TEMP TABLE Tmp_NewJobIDs (
                ID int NOT NULL
            );

            INSERT INTO Tmp_NewJobIDs (ID)
            SELECT Job
            FROM public.get_new_job_id_block(_jobCount, 'Clone_Analysis_Jobs');

            SELECT MIN(Id)
            INTO _newJobIdStart
            FROM Tmp_NewJobIDs;

            DROP TABLE Tmp_NewJobIDs;
        Else
            -- Pretend that the new Jobs will start at job 100,000,000
            --
            _newJobIdStart := 100000000;
        End If;

        -----------------------------------------
        -- Populate Tmp_NewJobInfo with the new job info
        -----------------------------------------

        INSERT INTO Tmp_NewJobInfo( JobId_Old,
                                    JobId_New,
                                    Batch_ID,
                                    Priority,
                                    Analysis_tool_ID,
                                    Param_File_Name,
                                    Settings_File_Name,
                                    Organism_DB_Name,
                                    Organism_ID,
                                    Dataset_ID,
                                    Comment,
                                    Owner_Username,
                                    Protein_Collection_List,
                                    Protein_Options_List,
                                    Request_ID,
                                    Propagation_Mode )
        SELECT SrcJobs.JobId,
               _newJobIdStart + SrcJobs.RowNum AS JobId_New,
               0 AS batch_id,
               J.priority,
               J.analysis_tool_id,
               CASE
                   WHEN Coalesce(_newParamFileName, '') = '' THEN J.param_file_name
                   ELSE _newParamFileName
               END AS param_file_name,
               CASE
                   WHEN Coalesce(_newSettingsFileName, '') = '' THEN J.settings_file_name
                   ELSE _newSettingsFileName
               END AS settings_file_name,
               J.organism_db_name,
               J.organism_id,
               J.dataset_id,
               format('Rerun of job %s', J.job) AS comment,
               J.owner_username,
               CASE
                   WHEN Coalesce(_newProteinCollectionList, '') = '' THEN J.protein_collection_list
                   ELSE _newProteinCollectionList
               END AS protein_collection_list,
               J.protein_options_list,
               J.request_id,
               J.propagation_mode
        FROM t_analysis_job J
             INNER JOIN Tmp_SourceJobs SrcJobs
               ON J.job = SrcJobs.JobId

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-10s %-8s %-8s %-16s %-12s %-80s %-80s %-60s %-11s %-150s %-30s %-16s';

            _infoHead := format(_formatSpecifier,
                                'JobId_Old',
                                'JobId_New',
                                'Request_ID',
                                'Batch_ID',
                                'Priority',
                                'Analysis_Tool_ID',
                                'Dataset_ID',
                                'Param_File_Name',
                                'Settings_File_Name',
                                'Organism_DB_Name',
                                'Organism_ID',
                                'Protein_Collection_List',
                                'Protein_Options_List',
                                'Propagation_Mode'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '----------',
                                         '----------',
                                         '--------',
                                         '--------',
                                         '----------------',
                                         '------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '------------------------------------------------------------',
                                         '-----------',
                                         '------------------------------------------------------------------------------------------------------------------------------------------------------',
                                         '------------------------------',
                                         '----------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId_Old,
                       JobId_New,
                       Batch_ID,
                       Priority,
                       Analysis_Tool_id,
                       Param_File_Name,
                       Settings_File_Name,
                       Organism_DB_Name,
                       Organism_ID,
                       Dataset_ID,
                       Comment,
                       Owner_Username,
                       Protein_Collection_List,
                       Protein_Options_List,
                       Request_ID,
                       Propagation_Mode
                FROM Tmp_NewJobInfo
                ORDER BY JobId_New
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId_Old,
                                    _previewData.JobId_New,
                                    _previewData.Batch_ID,
                                    _previewData.Priority,
                                    _previewData.Analysis_Tool_id,
                                    _previewData.Param_File_Name,
                                    _previewData.Settings_File_Name,
                                    _previewData.Organism_DB_Name,
                                    _previewData.Organism_ID,
                                    _previewData.Dataset_ID,
                                    _previewData.Comment,
                                    _previewData.Owner_Username,
                                    _previewData.Protein_Collection_List,
                                    _previewData.Protein_Options_List,
                                    _previewData.Request_ID,
                                    _previewData.Propagation_Mode
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;

            RETURN;
        End If;

        -----------------------------------------
        -- Make the new jobs
        -----------------------------------------

        INSERT INTO t_analysis_job (
            job, batch_id, priority, created, analysis_tool_id, param_file_name, settings_file_name, organism_db_name,
            organism_id, dataset_id, comment, owner_username, job_state_id, protein_collection_list, protein_options_list,
            request_id, propagation_mode)
        SELECT JobId_New, Batch_ID, Priority, CURRENT_TIMESTAMP, Analysis_tool_ID, Param_File_Name, Settings_File_Name, Organism_DB_Name,
               Organism_ID, Dataset_ID, Comment, Owner_Username, 1 AS job_state_id, Protein_Collection_List, Protein_Options_List,
               Request_ID, Propagation_Mode
        FROM Tmp_NewJobInfo
        ORDER BY JobId_New;

        If _supersedeOldJob Or _updateOldJobComment Then

            If _supersedeOldJob Then
                _action := 'superseded by job';
            Else
                _action := 'compare to job';
            End If;

            UPDATE t_analysis_job
            SET comment = CASE WHEN Not _updateOldJobComment THEN Target.comment
                               ELSE public.append_to_text(Target.comment, format('%s %s', _action, Src.JobId_New), _delimiter => '; ', _maxlength => 512)
                          END,
                job_state_id = CASE WHEN Not _supersedeOldJob THEN Target.job_state_id
                                    ELSE 14
                             END
            FROM Tmp_NewJobInfo Src
            WHERE Src.JobID_Old = t_analysis_job.job;
        End If;

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

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    If _errorMessage <> '' Then
        RAISE WARNING '%', _ErrorMessage;
    End If;

    DROP TABLE IF EXISTS Tmp_SourceJobs;
    DROP TABLE IF EXISTS Tmp_NewJobInfo;
    DROP TABLE IF EXISTS Tmp_NewJobIDs;
END
$$;

COMMENT ON PROCEDURE public.clone_analysis_jobs IS 'CloneAnalysisJobs';

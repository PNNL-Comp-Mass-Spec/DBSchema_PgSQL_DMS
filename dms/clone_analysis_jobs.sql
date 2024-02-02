--
-- Name: clone_analysis_jobs(text, text, text, text, boolean, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.clone_analysis_jobs(IN _sourcejobs text, IN _newparamfilename text DEFAULT ''::text, IN _newsettingsfilename text DEFAULT ''::text, IN _newproteincollectionlist text DEFAULT ''::text, IN _supersedeoldjob boolean DEFAULT false, IN _updateoldjobcomment boolean DEFAULT true, IN _allowduplicatejob boolean DEFAULT false, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
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
**    _newParamFileName             New parameter file to use (empty string to use source job's parameter file)
**    _newSettingsFileName          New settings file to use  (empty string to use source job's settings file)
**    _newProteinCollectionList     New protein collection to use (if empty, use the same protein collection as the old job)
**    _supersedeOldJob              When true, change the state of old jobs to 14
**    _updateOldJobComment          When true, add the new job number to the old job comment
**    _allowDuplicateJob            When true, allow the new jobs to be duplicates of the old jobs (useful for testing a new version of a tool or updated .UIMF)
**    _infoOnly                     When true, preview updates
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   07/12/2016 mem - Initial version
**          07/19/2016 mem - Add parameter _allowDuplicateJob
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/12/2018 mem - Send _maxLength to append_to_text
**          07/29/2022 mem - Use Coalesce instead of Coalesce
**          02/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _protCollOptionsList text;
    _invalidJobs boolean;
    _result int;
    _newJobIdStart int;
    _jobCount int;
    _jobCountCompare int;
    _mostCommonParamFile citext;
    _mostCommonSettingsFile citext;
    _matchingFile text;
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
        _allowDuplicateJob        := Coalesce(_allowDuplicateJob, false);
        _infoOnly                 := Coalesce(_infoOnly, true);

        If _sourceJobs = '' Then
            _message := '_sourceJobs cannot be empty';
            RAISE INFO '';
            RAISE WARNING '%', _message;

            RETURN;
        End If;

        If _newProteinCollectionList <> '' Then
            -- Validate _newProteinCollectionList

            _protCollOptionsList := 'seq_direction=forward,filetype=fasta';

            CALL pc.validate_analysis_job_protein_parameters (
                                _organismName        => 'None',
                                _ownerUsername       => 'H09090911',
                                _organismDBFileName  => 'na',
                                _protCollNameList    => _newProteinCollectionList,  -- Input/output
                                _protCollOptionsList => _protCollOptionsList,       -- Input/output
                                _message             => _message,                   -- Output
                                _returnCode          => _returnCode);               -- Output

            If _returnCode <> '' Then
                If Coalesce(_message, '') = '' Then
                    _message := format('Protein collection list validation error, result code %s', _returnCode);
                End If;

                RAISE INFO '';
                RAISE WARNING '%', _message;

                RETURN;
            End If;

        End If;

        -----------------------------------------
        -- Create some temporary tables
        -----------------------------------------

        CREATE TEMP TABLE Tmp_SourceJobs (
            JobId int NOT NULL,
            Valid boolean NOT NULL,
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
        SELECT Value,
               false AS Valid,
               0 AS StateID,
               Row_Number() OVER (ORDER BY Value) As RowNum
        FROM public.parse_delimited_integer_list(_sourceJobs);

        If Not Exists (SELECT * FROM Tmp_SourceJobs) Then
            _message := format('_sourceJobs did not have any valid job IDs: %s', _sourceJobs);

            RAISE INFO '';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        End If;

        -----------------------------------------
        -- Validate the source job IDs
        -----------------------------------------

        UPDATE Tmp_SourceJobs
        SET Valid   = true,
            StateID = J.job_state_id
        FROM t_analysis_job J
        WHERE J.job = Tmp_SourceJobs.JobID;

        If Exists (SELECT JobId FROM Tmp_SourceJobs WHERE Not Valid) Then
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
            _message := 'The source jobs must all have the same parameter file';

            RAISE INFO '';
            RAISE WARNING '%', _message;
            RAISE INFO '';

            _formatSpecifier := '%-10s %-5s %-80s %-80s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Valid',
                                'Warning',
                                'Param_File_Name',
                                'Settings_File_Name'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId,
                       Valid,
                       CASE WHEN J.param_file_name = _mostCommonParamFile THEN ''
                            ELSE 'Mismatched param file'
                       END AS Warning,
                       Substring(J.param_file_name, 1, 80) AS param_file_name,
                       Substring(J.settings_file_name, 1, 80) AS settings_file_name
                FROM Tmp_SourceJobs
                     INNER JOIN t_analysis_job J
                       ON Tmp_SourceJobs.JobID = J.job
                ORDER BY CASE WHEN J.param_file_name = _mostCommonParamFile THEN 1 ELSE 0 END, J.job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId,
                                    _previewData.Valid,
                                    _previewData.Warning,
                                    _previewData.param_file_name,
                                    _previewData.settings_file_name
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
            _message := 'The source jobs must all have the same settings file';

            RAISE INFO '';
            RAISE WARNING '%', _message;
            RAISE INFO '';

            _formatSpecifier := '%-10s %-5s %-80s %-80s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Valid',
                                'Warning',
                                'Param_File_Name',
                                'Settings_File_Name'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId,
                       Valid,
                       CASE WHEN J.settings_file_name = _mostCommonSettingsFile THEN ''
                            ELSE 'Mismatched settings file'
                       END AS Warning,
                       Substring(J.param_file_name, 1, 80) AS param_file_name,
                       Substring(J.settings_file_name, 1, 80) AS settings_file_name
                FROM Tmp_SourceJobs
                     INNER JOIN t_analysis_job J
                       ON Tmp_SourceJobs.JobID = J.job
                ORDER BY CASE WHEN J.settings_file_name = _mostCommonSettingsFile THEN 1 ELSE 0 END, J.job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId,
                                    _previewData.Valid,
                                    _previewData.Warning,
                                    _previewData.param_file_name,
                                    _previewData.settings_file_name
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
            If Exists ( SELECT J.job
                        FROM Tmp_SourceJobs
                             INNER JOIN t_analysis_job J
                               ON Tmp_SourceJobs.JobID = J.job
                        WHERE J.protein_collection_list = _newProteinCollectionList::citext ) Then

                _message := format('The new Protein Collection List was used by one or more of the existing jobs; not cloning the jobs: %s', _newProteinCollectionList);

                RAISE INFO '';
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

            RAISE INFO '';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_SourceJobs;
            DROP TABLE Tmp_NewJobInfo;
            RETURN;
        Else
            If Not _allowDuplicateJob Then
                If _newParamFileName <> '' And _mostCommonParamFile = _newParamFileName::citext Then
                    _message := format('The new parameter file name matches the old name and _allowDuplicateJob is false; not cloning the jobs: %s', _newParamFileName);

                    RAISE INFO '';
                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_SourceJobs;
                    DROP TABLE Tmp_NewJobInfo;
                    RETURN;
                End If;

                If _newSettingsFileName <> '' And _mostCommonSettingsFile = _newSettingsFileName::citext Then
                    _message := format('The new settings file name matches the old name and _allowDuplicateJob is false; not cloning the jobs: %s', _newSettingsFileName);

                    RAISE INFO '';
                    RAISE WARNING '%', _message;

                    DROP TABLE Tmp_SourceJobs;
                    DROP TABLE Tmp_NewJobInfo;
                    RETURN;
                End If;
            End If;
        End If;


        -----------------------------------------
        -- Make sure the parameter file and settings file exist and are properly capitalized
        -----------------------------------------

        If _newParamFileName <> '' Then
            SELECT param_file_name
            INTO _matchingFile
            FROM T_Param_Files
            WHERE param_file_name = _newParamFileName;

            If FOUND Then
                _newParamFileName := _matchingFile;
            Else
                _message := format('Unrecognized parameter file name: %s', _newParamFileName);

                RAISE INFO '';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_SourceJobs;
                DROP TABLE Tmp_NewJobInfo;
                RETURN;
            End If;
        End If;

        If _newSettingsFileName <> '' Then
            SELECT file_name
            INTO _matchingFile
            FROM T_Settings_Files
            WHERE file_name = _newSettingsFileName;

            If FOUND Then
                _newSettingsFileName := _matchingFile;
            Else
                _message := format('Unrecognized settings file name: %s', _newSettingsFileName);

                RAISE INFO '';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_SourceJobs;
                DROP TABLE Tmp_NewJobInfo;
                RETURN;
            End If;
        End If;

        -----------------------------------------
        -- Determine the starting Job ID for the new jobs
        -----------------------------------------

        If Not _infoOnly Then
            -- Reserve a block of Job IDs
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
               format('%s %s',
                   CASE WHEN Coalesce(_newParamFileName, '') = '' OR _newParamFileName = J.param_file_name
                        THEN 'Rerun of job'
                        ELSE 'Compare to job'
                   END,
                   J.job) AS comment,
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
               ON J.job = SrcJobs.JobId;

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-10s %-8s %-8s %-16s %-12s %-80s %-80s %-80s %-11s %-150s %-40s %-16s %-10s %-50s';

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
                                'Propagation_Mode',
                                'Owner',
                                'Comment'
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
                                         '--------------------------------------------------------------------------------',
                                         '-----------',
                                         '------------------------------------------------------------------------------------------------------------------------------------------------------',
                                         '----------------------------------------',
                                         '----------------',
                                         '----------',
                                         '--------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JobId_Old,
                       JobId_New,
                       Request_ID,
                       Batch_ID,
                       Priority,
                       Analysis_Tool_id,
                       Dataset_ID,
                       Substring(Param_File_Name, 1, 80) AS Param_File_Name,
                       Substring(Settings_File_Name, 1, 80) AS Settings_File_Name,
                       Substring(Organism_DB_Name, 1, 80) AS Organism_DB_Name,
                       Organism_ID,
                       Protein_Collection_List,
                       Protein_Options_List,
                       Propagation_Mode,
                       Owner_Username,
                       Comment
                FROM Tmp_NewJobInfo
                ORDER BY JobId_New
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.JobId_Old,
                                    _previewData.JobId_New,
                                    _previewData.Request_ID,
                                    _previewData.Batch_ID,
                                    _previewData.Priority,
                                    _previewData.Analysis_Tool_id,
                                    _previewData.Dataset_ID,
                                    _previewData.Param_File_Name,
                                    _previewData.Settings_File_Name,
                                    _previewData.Organism_DB_Name,
                                    _previewData.Organism_ID,
                                    _previewData.Protein_Collection_List,
                                    _previewData.Protein_Options_List,
                                    _previewData.Propagation_Mode,
                                    _previewData.Owner_Username,
                                    _previewData.Comment
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
            request_id, propagation_mode
        )
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

            UPDATE t_analysis_job Target
            SET comment = CASE WHEN Not _updateOldJobComment THEN Target.comment
                               ELSE public.append_to_text(Target.comment, format('%s %s', _action, Src.JobId_New), _delimiter => '; ', _maxlength => 512)
                          END,
                job_state_id = CASE WHEN Not _supersedeOldJob THEN Target.job_state_id
                                    ELSE 14
                             END
            FROM Tmp_NewJobInfo Src
            WHERE Src.JobID_Old = Target.job;
        End If;

        _message := format('Cloned %s %s', _jobCount, public.check_plural(_jobCount, 'job', 'jobs'));

        RAISE INFO '';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_SourceJobs;
        DROP TABLE Tmp_NewJobInfo;
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

    RAISE INFO '';
    RAISE WARNING '%', _message;

    DROP TABLE IF EXISTS Tmp_SourceJobs;
    DROP TABLE IF EXISTS Tmp_NewJobInfo;
    DROP TABLE IF EXISTS Tmp_NewJobIDs;
END
$$;


ALTER PROCEDURE public.clone_analysis_jobs(IN _sourcejobs text, IN _newparamfilename text, IN _newsettingsfilename text, IN _newproteincollectionlist text, IN _supersedeoldjob boolean, IN _updateoldjobcomment boolean, IN _allowduplicatejob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE clone_analysis_jobs(IN _sourcejobs text, IN _newparamfilename text, IN _newsettingsfilename text, IN _newproteincollectionlist text, IN _supersedeoldjob boolean, IN _updateoldjobcomment boolean, IN _allowduplicatejob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.clone_analysis_jobs(IN _sourcejobs text, IN _newparamfilename text, IN _newsettingsfilename text, IN _newproteincollectionlist text, IN _supersedeoldjob boolean, IN _updateoldjobcomment boolean, IN _allowduplicatejob boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'CloneAnalysisJobs';


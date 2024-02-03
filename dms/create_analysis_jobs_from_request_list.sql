--
-- Name: create_analysis_jobs_from_request_list(text, text, integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.create_analysis_jobs_from_request_list(IN _mode text DEFAULT 'preview'::text, IN _jobrequestlist text DEFAULT ''::text, IN _priority integer DEFAULT 2, IN _associatedprocessorgroup text DEFAULT ''::text, IN _propagationmode text DEFAULT 'Export'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create analysis jobs for a given list of analysis job requests
*
*       This procedure is likely unused in 2024
**
**  Arguments:
**    _mode                     Mode: 'add' or 'preview'
**    _jobRequestList           Comma-separated list of analysis job request IDs
**    _priority                 Priority
**    _associatedProcessorGroup Processor group name; deprecated in May 2015
**    _propagationMode          'Export' or 'No Export'
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   09/17/2007 grk - Initial version (Ticket #534)
**          09/20/2007 mem - Now checks for existing jobs if _mode <> 'add'
**          02/27/2009 mem - Expanded _comment to varchar(512)
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          08/01/2012 mem - Now sending _specialProcessing to Add_Analysis_Job_Group
**                         - Updated _datasetList to be varchar(max)
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          04/08/2015 mem - Now parsing the job request list using Parse_Delimited_Integer_List
**          04/11/2022 mem - Expand _protCollNameList to varchar(4000)
**          06/30/2022 mem - Rename parameter file argument
**          07/01/2022 mem - Rename parameter file column in temporary table
**          02/02/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _requestInfo record;
    _existingJobMsg text;
    _existingJobCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -------------------------------------------------
    -- Validate the inputs
    -------------------------------------------------

    _mode                     := Trim(Lower(Coalesce(_mode, 'preview')));
    _jobRequestList           := Trim(Coalesce(_jobRequestList, ''));
    _associatedProcessorGroup := Trim(Coalesce(_associatedProcessorGroup, ''));
    _propagationMode          := Trim(Coalesce(_propagationMode, 'Export'));
    _priority                 := Coalesce(_priority, 2);

    -------------------------------------------------
    -- Temporary table to hold job requests
    -------------------------------------------------

    CREATE TEMP TABLE Tmp_AnalysisJobRequests (
        Request_ID int,
        Request_State_ID int,
        ToolName text,
        ParamFileName text,
        SettingsFileName text,
        OrganismDBName text,
        OrganismName text,
        DatasetList text,
        Comment text,
        SpecialProcessing text,
        OwnerUsername text,
        ProtCollNameList text,
        ProtCollOptionsList text,
        StateName text
    );

    -------------------------------------------------
    -- Get particulars for requests in list
    -------------------------------------------------

    INSERT INTO Tmp_AnalysisJobRequests (
        Request_ID,
        Request_State_ID,
        ToolName,
        ParamFileName,
        SettingsFileName,
        OrganismDBName,
        OrganismName,
        DatasetList,
        Comment,
        SpecialProcessing,
        OwnerUsername,
        ProtCollNameList,
        ProtCollOptionsList,
        StateName
    )
    SELECT AJR.request_id,
           AJR.request_state_id,
           AJR.analysis_tool,
           AJR.param_file_name,
           AJR.settings_file_name,
           AJR.organism_db_name,
           Org.organism AS organism_name,
           CASE
               WHEN (COALESCE(AJR.data_pkg_id, 0) > 0) THEN ''
               ELSE public.get_job_request_dataset_name_list(AJR.request_id)
           END AS datasets,
           AJR.comment,
           AJR.special_processing,
           U.username AS requester,
           AJR.protein_collection_list AS prot_coll_name_list,
           AJR.protein_options_list AS prot_coll_options_list,
           ARS.request_state AS state
    FROM t_analysis_job_request AJR
         INNER JOIN t_analysis_job_request_state ARS
           ON AJR.request_state_id = ARS.request_state_id
         INNER JOIN t_users U
           ON AJR.user_id = U.user_id
         INNER JOIN t_organisms Org
           ON AJR.organism_id = Org.organism_id
    WHERE AJR.Request_ID IN (SELECT Value FROM public.parse_delimited_integer_list(_jobRequestList));

    -------------------------------------------------
    -- Temporary table to hold results for each request
    -------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestResults (
        Request_ID int,
        Description text,
        Error_Code text
    );

    -------------------------------------------------
    -- Verify that all requests are in 'new' state
    -------------------------------------------------

    INSERT INTO Tmp_RequestResults (Request_ID, Description, Error_Code)
    SELECT AJR.Request_ID, 'Request not in state new; unable to process', 'U5601'
    FROM Tmp_AnalysisJobRequests AJR
    WHERE AJR.request_state_id <> 1;

    If FOUND Then
        -- One or more requests do not have State = 1
        -- Remove them from the temp table

        DELETE FROM Tmp_AnalysisJobRequests
        WHERE request_state_id <> 1;
    End If;

    -------------------------------------------------
    -- Cycle through each request
    -- Convert each into jobs (if _mode is 'add')
    -------------------------------------------------

    FOR _requestInfo IN
        SELECT Request_ID,
               ToolName,
               ParamFileName,
               SettingsFileName,
               OrganismDBName,
               OrganismName,
               DatasetList,
               Comment,
               SpecialProcessing,
               OwnerUsername,
               ProtCollNameList,
               ProtCollOptionsList
        FROM Tmp_AnalysisJobRequests
        ORDER BY Request_ID
    LOOP
        -------------------------------------------------
        -- Check for existing jobs
        -------------------------------------------------

        SELECT COUNT(job)
        INTO _existingJobCount
        FROM t_analysis_job
        WHERE request_id = _requestInfo.Request_ID;

        If _existingJobCount > 0 Then
            If _existingJobCount = 1 Then
                _existingJobMsg := 'Note: 1 job';
            Else
                _existingJobMsg := format('Note: %s jobs', _existingJobCount);
            End If;

            _existingJobMsg := format('%s found matching this request''s parameters', _existingJobMsg);
        Else
            _existingJobMsg := '';
        End If;

        -------------------------------------------------
        -- Convert the analysis job request to analysis jobs
        -------------------------------------------------

        CALL public.add_analysis_job_group (
                        _datasetList              => _requestInfo.DatasetList,
                        _priority                 => 3,
                        _toolName                 => _requestInfo.ToolName,
                        _paramFileName            => _requestInfo.ParamFileName,
                        _settingsFileName         => _requestInfo.SettingsFileName,
                        _organismDBName           => _requestInfo.OrganismDBName,
                        _organismName             => _requestInfo.OrganismName,
                        _protCollNameList         => _requestInfo.ProtCollNameList,
                        _protCollOptionsList      => _requestInfo.ProtCollOptionsList,
                        _ownerUsername            => _requestInfo.OwnerUsername,
                        _comment                  => _requestInfo.Comment,
                        _specialProcessing        => _requestInfo.SpecialProcessing,
                        _requestID                => _requestInfo.Request_ID,
                        _dataPackageID            => 0,
                        _associatedProcessorGroup => '',
                        _propagationMode          => _propagationMode,
                        _removeDatasetsWithJobs   => 'Y',
                        _mode                     => _mode,
                        _message                  => _message,      -- Output
                        _returnCode               => _returnCode);  -- Output

        _message := Coalesce(_message, '');

        If _existingJobCount > 0 Then
            _message := format('%s; %s', _existingJobMsg, _message);
        End If;

        -------------------------------------------------
        -- Keep track of results
        -------------------------------------------------

        INSERT INTO Tmp_RequestResults (Request_ID, Description, Error_Code)
        VALUES (_requestInfo.Request_ID, _message, _returnCode);

        _message := '';
    END LOOP;

    -------------------------------------------------
    -- Report results
    -------------------------------------------------

    RAISE INFO '';

    _formatSpecifier := '%-10s %-80s %-10s';

    _infoHead := format(_formatSpecifier,
                        'Request_ID',
                        'Description',
                        'Error_Code'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '----------',
                                 '--------------------------------------------------------------------------------',
                                 '----------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT Request_ID,
               Description,
               Error_Code
        FROM Tmp_RequestResults
        ORDER BY Request_ID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Request_ID,
                            _previewData.Description,
                            _previewData.Error_Code
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    DROP TABLE Tmp_AnalysisJobRequests;
    DROP TABLE Tmp_RequestResults;
END
$$;


ALTER PROCEDURE public.create_analysis_jobs_from_request_list(IN _mode text, IN _jobrequestlist text, IN _priority integer, IN _associatedprocessorgroup text, IN _propagationmode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE create_analysis_jobs_from_request_list(IN _mode text, IN _jobrequestlist text, IN _priority integer, IN _associatedprocessorgroup text, IN _propagationmode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.create_analysis_jobs_from_request_list(IN _mode text, IN _jobrequestlist text, IN _priority integer, IN _associatedprocessorgroup text, IN _propagationmode text, INOUT _message text, INOUT _returncode text) IS 'CreateAnalysisJobsFromRequestList';


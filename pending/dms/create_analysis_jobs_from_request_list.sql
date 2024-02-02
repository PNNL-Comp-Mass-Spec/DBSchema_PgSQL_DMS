--
CREATE OR REPLACE PROCEDURE public.create_analysis_job_from_request_list
(
    _mode text = 'preview',
    _jobRequestList text,
    _priority int = 2,
    _associatedProcessorGroup text = '',
    _propagationMode text = 'Export'
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create analysis jobs for a given list of analysis job requests
**
**  Arguments:
**    _mode                     Mode: 'add' or 'preview'
**    _jobRequestList           Comma-separated list of analysis job requests
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
**          12/15/2024 mem - Ported to PostgreSQL
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
    -- Temporary table to hold job requests
    -------------------------------------------------

    CREATE TEMP TABLE Tmp_AnalysisJobRequests (
        RequestID int,
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
        RequestID,
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
    SELECT
        Request_ID,
        Analysis_Tool,
        Param_File_Name,
        Settings_File_Name,
        Organism_DB_Name,
        Organism_Name,
        Datasets,
        Comment,
        Special_Processing,
        Requester,
        Prot_Coll_Name_List,
        Prot_Coll_Options_List,
        State
    FROM V_Analysis_Job_Request_Entry
    WHERE Request_ID IN (SELECT Value FROM public.parse_delimited_integer_list(_jobRequestList))

    -------------------------------------------------
    -- Temp table to hold results for each request
    -------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestResults (
        RequestID int,
        Result int,
        Description text
    );

    -------------------------------------------------
    -- Verify all requests in 'new' state
    -------------------------------------------------

    INSERT INTO Tmp_RequestResults (RequestID, Result, Description)
    SELECT RequestID, -1, 'Request not in state new; unable to process'
    FROM Tmp_AnalysisJobRequests INNER JOIN
         t_analysis_job_request AJR ON Tmp_AnalysisJobRequests.RequestID = AJR.RequestID
    WHERE AJR.request_state_id <> 1

    If FOUND Then
        -- One or more requests do not have State = 1
        -- Remove the invalid rows from Tmp_AnalysisJobRequests
        DELETE Tmp_AnalysisJobRequests
        FROM Tmp_RequestResults
        WHERE Tmp_AnalysisJobRequests.RequestID = Tmp_RequestResults.RequestID;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode = 'add' Then
        -------------------------------------------------
        -- Cycle through each request,
        -- and convert each into jobs
        -------------------------------------------------

        _result := 0;

        FOR _requestInfo IN
            SELECT RequestID,
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
            ORDER BY RequestID
        LOOP
            -------------------------------------------------
            -- Check for existing jobs
            -------------------------------------------------
            _existingJobCount := 0;

            SELECT COUNT(job)
            INTO _existingJobCount
            FROM t_analysis_job
            WHERE request_id = _requestInfo.RequestID

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
                            _requestID                => _requestInfo.RequestID,
                            _associatedProcessorGroup => '',
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
            INSERT INTO Tmp_RequestResults (RequestID, Result, Description)
            VALUES (_requestID, _result, _message);

        END LOOP;

    End If;

    -------------------------------------------------
    -- Report results
    -------------------------------------------------

    RAISE INFO '';

    _formatSpecifier := '%-10s %-6s %-60s';

    _infoHead := format(_formatSpecifier,
                        'Request_ID,',
                        'Result,',
                        'Description'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '----------',
                                 '------',
                                 '------------------------------------------------------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT RequestID,
               Result,
               Description
        FROM Tmp_RequestResults
    ORDER BY RequestID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.RequestID,
                            _previewData.Result,
                            _previewData.Description
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    DROP TABLE Tmp_AnalysisJobRequests;
    DROP TABLE Tmp_RequestResults;
END
$$;

COMMENT ON PROCEDURE public.create_analysis_job_from_request_list IS 'CreateAnalysisJobFromRequestList';

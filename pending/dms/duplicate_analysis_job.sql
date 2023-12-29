--
CREATE OR REPLACE PROCEDURE public.duplicate_analysis_job
(
    _job int,
    _newComment text = '',
    _overrideNoExport int = -1,
    _appendOldJobToComment boolean = true,
    _newSettingsFile text = '',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Duplicate an analysis job by calling add_update_analysis_job
**
**  Arguments:
**    _job                      Job number to copy
**    _newComment               New job comment; use old comment if blank
**    _overrideNoExport         0 for export, 1 for No Export, -1 to leave unchanged
**    _appendOldJobToComment    If true, append 'Compare to job 0000' to the comment
**    _newSettingsFile          Use to change the settings file
**    _infoOnly                 When true, preview the job that wouuld be created
**    _message                  Output message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   01/20/2016 mem - Initial version
**          01/28/2016 mem - Added parameter _newSettingsFile
**          06/12/2018 mem - Send _maxLength to append_to_text
**          06/30/2022 mem - Rename parameter file argument
**          07/01/2022 mem - Rename parameter file column when previewing the new job
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobInfo record;
    _oldJobInfo text;
    _propagationMode text;
    _newJob text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job := Coalesce(_job, 0);
    _newComment := Trim(Coalesce(_newComment, ''));
    _overrideNoExport := Coalesce(_overrideNoExport, -1);
    _appendOldJobToComment := Coalesce(_appendOldJobToComment, true);
    _newSettingsFile := Trim(Coalesce(_newSettingsFile, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    If _job = 0 Then
        _message := '_job is invalid';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the job values in t_analysis_job
    ---------------------------------------------------

    SELECT DS.dataset AS Dataset
           J.priority AS Priority,
           t_analysis_tool.analysis_tool AS ToolName,
           J.param_file_name AS ParamFileName,
           J.settings_file_name AS SettingsFileName,
           Org.organism AS OrganismName,
           J.protein_collection_list AS ProtCollNameList,
           J.protein_options_list AS ProtCollOptionsList,
           J.organism_db_name AS OrganismDBName,
           J.owner AS OwnerUsername,
           J.comment AS Comment,
           J.special_processing AS SpecialProcessing,
           J.propagation_mode AS PropMode
    INTO _jobInfo
    FROM t_analysis_job J
         INNER JOIN t_organisms Org
           ON J.organism_id = Org.organism_id
         INNER JOIN t_dataset DS
           ON J.dataset_id = DS.dataset_id
         INNER JOIN t_analysis_tool
           ON J.analysis_tool_id = t_analysis_tool.analysis_tool_id
    WHERE J.job = _job;

    If Not FOUND Then
        _message := format('Job not found: %s', _job);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If _newComment <> '' Then
        _jobInfo.Comment := _newComment;
    End If;

    If _appendOldJobToComment Then
        _oldJobInfo := format('Compare to job %s', _job);
        _jobInfo.Comment := public.append_to_text(_jobInfo.Comment, _oldJobInfo, _delimiter => '; ', _maxlength => 512);
    End If;

    If _newSettingsFile <> '' Then
        _jobInfo.SettingsFileName := _newSettingsFile;
    End If;

    If _overrideNoExport >= 0 Then
        _jobInfo.PropMode := _overrideNoExport;
    End If;

    If _jobInfo.PropMode <> 0 Then
        _propagationMode := 'No Export';
    Else
        _propagationMode := 'Export';
    End If;

    If _infoOnly Then
        RAISE INFO 'Dataset: %, priority: %, tool: %, param file: %, settings file: %', _jobInfo.Dataset, _jobInfo.Priority, _jobInfo.ToolName, _jobInfo.ParamFileName, _jobInfo.SettingsFileName;
        RAISE INFO 'Organism: %, Protein Collection(s): %, Collection Options: %, Organism DB: %', _jobInfo.OrganismName, _jobInfo.ProtCollNameList, _jobInfo.ProtCollOptionsList, _jobInfo.OrganismDBName;
        RAISE INFO 'Owner Username: %, Comment: %, Special Processing: %, Propagation Mode: %', _jobInfo.OwnerUsername, _jobInfo.Comment, _jobInfo.SpecialProcessing, _propagationMode;
    End If;

    -- Call the procedure to create/preview the job creation

    CALL public.add_update_analysis_job (
                    _datasetName              => _jobInfo.Dataset,
                    _priority                 => _jobInfo.Priority,
                    _toolName                 => _jobInfo.ToolName,
                    _paramFileName            => _jobInfo.ParamFileName,
                    _settingsFileName         => _jobInfo.SettingsFileName,
                    _organismName             => _jobInfo.OrganismName,
                    _protCollNameList         => _jobInfo.ProtCollNameList,
                    _protCollOptionsList      => _jobInfo.ProtCollOptionsList,
                    _organismDBName           => _jobInfo.OrganismDBName,
                    _ownerUsername            => _jobInfo.OwnerUsername,
                    _comment                  => _jobInfo.Comment,
                    _specialProcessing        => _jobInfo.SpecialProcessing,
                    _associatedProcessorGroup => '',
                    _propagationMode          => _propagationMode,
                    _stateName                => 'New',
                    _job                      => _newJob,       -- Output
                    _mode                     => 'add',
                    _message                  => _message,      -- Output
                    _returnCode               => _returnCode,   -- Output
                    _callingUser              => '',
                    _preventDuplicateJobs     => false,
                    _infoOnly                 => _infoOnly);

    If Not _infoOnly Then
        If _returnCode = '' Then
            _message := format('Duplicated job %s to create job %s', _job, _newJob);
            Raise Info '%', _message;
        Else
            If Coalesce(_message, '') = '' Then
                _message := format('Add_Update_Analysis_Job returned error code = %s', _returnCode);
            End If;

            RAISE WARNING '%', _message;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE public.duplicate_analysis_job IS 'DuplicateAnalysisJob';

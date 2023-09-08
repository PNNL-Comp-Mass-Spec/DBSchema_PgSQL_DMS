--
-- Name: validate_analysis_job_parameters(text, text, text, text, text, text, text, text, text, integer, integer, integer, integer, boolean, boolean, boolean, text, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_analysis_job_parameters(IN _toolname text, INOUT _paramfilename text, INOUT _settingsfilename text, INOUT _organismdbname text, IN _organismname text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _ownerusername text, IN _mode text, INOUT _userid integer, INOUT _analysistoolid integer, INOUT _organismid integer, IN _job integer DEFAULT 0, IN _autoremovenotreleaseddatasets boolean DEFAULT false, IN _autoupdatesettingsfiletocentroided boolean DEFAULT true, IN _allownewdatasets boolean DEFAULT false, INOUT _warning text DEFAULT ''::text, INOUT _priority integer DEFAULT 3, IN _showdebugmessages boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validates analysis job parameters and returns internal values converted from external values (input arguments)
**
**      The calling procedure must create Tmp_DatasetInfo and populate it with the dataset names;
**      the remaining columns in the table will be populated when this procedure calls validate_analysis_job_request_datasets
**
**      CREATE TEMP TABLE Tmp_DatasetInfo (
**          Dataset_Name citext,
**          Dataset_ID int NULL,
**          Instrument_Class text NULL,
**          Dataset_State_ID int NULL,
**          Archive_State_ID int NULL,
**          Dataset_Type text NULL,
**          Dataset_Rating_ID smallint NULL
**      );
**
**  Arguments:
**    _toolName             Analysis tool name
**    _paramFileName        Input/Output: Parameter file name
**    _settingsFileName     Input/Output: Settings file name
**    _organismDBName       Input/Output: Organism DB name (legacy FASTA file); should be 'na' if using a protein collection list
**    _organismName         Organism name
**    _protCollNameList     Input/Output: Comma-separated list of protein collection names
**                          Procedure validate_protein_collection_params will set _returnCode to 'U5310' and update _message if over 4000 characters long
**                          - This was previously necessary since the Broker DB (DMS_Pipeline) had a 4000 character limit on analysis job parameter values
**                          - While not true for PostgreSQL, excessively long protein collection name lists could lead to issues
**    _protCollOptionsList  Input/Output: Protein collection options list
**    _ownerUsername        Input/Output: Job owner username
**    _mode                 Used to tweak the warning if _analysisToolID is not found in T_Analysis_Tool. If _mode is 'Update' or 'PreviewUpdate', _allowNonReleasedDatasets is auto-set to true
**    _userID               Output: User ID
**    _analysisToolID       Output: Analysis tool ID
**    _organismID           Output: Organism ID
**    _job                  Job number (included in warning message if non-zero)
**    _autoUpdateSettingsFileToCentroided       When true, auto-update the settings file to a centroided version if any of the datasets in Tmp_DatasetInfo are centroided
**    _allowNewDatasets     When false, all datasets must have state 3 (Complete); when true, will also allow datasets with state 1 or 2 (New or Capture In Progress)
**    _warning              Output: Warning
**    _priority             Input/Output: Job priority (typically 3); this procedure changes it to 4 if _organismDBName is over 400 MB and _priority is less than 4
**    _showDebugMessages    When true, show debug messages
**    _message              Output: warning message
**    _returnCode           Output: return code
**
**  Auth:   grk
**  Date:   04/04/2006 grk - Supersedes MakeAnalysisJobX
**          05/01/2006 grk - Modified to conditionally call pc.validate_analysis_job_protein_parameters
**          06/01/2006 grk - Removed dataset archive state restriction
**          08/30/2006 grk - Removed restriction for dataset state verification that limited it to 'add' mode (http://prismtrac.pnl.gov/trac/ticket/219)
**          11/30/2006 mem - Now checking dataset type against AJT_allowedDatasetTypes in T_Analysis_Tool (Ticket #335)
**          12/20/2006 mem - Now assuring dataset rating is not -2=Data Files Missing (Ticket #339)
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          09/12/2008 mem - Now calling validate_na_parameter for the various parameters that can be 'na' (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**                         - Changed _paramFileName and _settingsFileName to be input/output parameters instead of input only
**          01/14/2009 mem - Now raising an error if _protCollNameList is over 2000 characters long (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/28/2009 mem - Now checking for settings files in T_Settings_Files instead of on disk (Ticket #718, http://prismtrac.pnl.gov/trac/ticket/718)
**          12/18/2009 mem - Now using T_Analysis_Tool_Allowed_Dataset_Type to determine valid dataset types for a given analysis tool
**          12/21/2009 mem - Now validating that the parameter file tool and the settings file tool match the tool defined by _toolName
**          02/11/2010 mem - Now assuring dataset rating is not -1 (or -2)
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _ownerUsername contains a person's real name rather than their username
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          08/26/2010 mem - Now calling Validate_Protein_Collection_Params to validate the protein collection info
**          11/12/2010 mem - Now using T_Analysis_Tool_Allowed_Instrument_Class to determine valid instrument classes for a given analysis tool
**          01/12/2012 mem - Now validating that the analysis tool is active (T_Analysis_Tool.AJT_active > 0)
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          11/12/2012 mem - Moved dataset validation logic to validate_analysis_job_request_datasets
**          11/28/2012 mem - Added candidate code to validate that high res MSn datasets are centroided if using MSGFDB
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Added parameter _autoRemoveNotReleasedDatasets
**          04/02/2013 mem - Now updating _message if it is blank yet _result is non-zero
**          02/28/2014 mem - Now throwing an error if trying to search a large Fasta file with a parameter file that will result in a very slow search
**          03/13/2014 mem - Added custom message to be displayed when trying to reset a MAC job
**                         - Added optional parameter _job
**          07/18/2014 mem - Now validating that files over 400 MB in size are using MSGFPlus_SplitFasta
**          03/02/2015 mem - Now validating that files over 500 MB in size are using MSGFPlus_SplitFasta
**          04/08/2015 mem - Now validating that profile mode high res MSn datasets are centroided if using MSGFPlus
**                         - Added optional parameters _autoUpdateSettingsFileToCentroided and _warning
**          04/23/2015 mem - Now passing _toolName to validate_analysis_job_request_datasets
**          05/01/2015 mem - Now preventing the use of parameter files with more than one dynamic mod when the fasta file is over 2 GB in size
**          06/24/2015 mem - Added parameter _showDebugMessages
**          12/16/2015 mem - No longer auto-switching the settings file to a centroided one if high res MSn spectra; only switching if profile mode MSn spectra
**          07/12/2016 mem - Force priority to 4 if using _organismDBName and it has a size over 400 MB
**          07/20/2016 mem - Tweak error messages
**          04/19/2017 mem - Validate the settings file for SplitFasta tools
**          12/06/2017 mem - Add parameter _allowNewDatasets
**          07/19/2018 mem - Increase the threshold for requiring SplitFASTA searches from 400 MB to 600 MB
**          07/11/2019 mem - Auto-change parameter file names from MSGFDB_ to MSGFPlus_
**          07/30/2019 mem - Update comments and capitalization
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          03/10/2021 mem - Add logic for MaxQuant
**          03/15/2021 mem - Validate that the settings file and/or parameter file are defined for tools that require them
**          05/26/2021 mem - Use _allowNonReleasedDatasets when calling validate_analysis_job_request_datasets
**          08/26/2021 mem - Add logic for MSFragger
**          10/05/2021 mem - Show custom message if _toolName contains an inactive _dta.txt based MS-GF+ tool
**          11/08/2021 mem - Allow instrument class 'Data_Folders' and dataset type 'DataFiles' (both used by instrument 'DMS_Pipeline_Data') to apply to all analysis tools
**          06/30/2022 mem - Rename parameter file argument
**          02/28/2023 mem - Update warning message to use MSGFPlus
**          03/22/2023 mem - Trim trailing whitespace from output parameters
**          03/27/2023 mem - Add logic for DiaNN
**          09/01/2023 mem - Ported to PostgreSQL
**          09/05/2023 mem - Add back parameter _autoRemoveNotReleasedDatasets since used by add_update_analysis_job_request
**                         - Assure that parameters are not null
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _datasetList text;
    _paramFileTool text;
    _settingsFileTool text;
    _result int;
    _toolActive int := 0;
    _settingsFileRequired boolean := false;
    _paramFileRequired int := 0;
    _allowNonReleasedDatasets boolean := false;
    _matchCount int;
    _newUsername text;
    _profileModeMSn int := 0;
    _autoCentroidName text;
    _dtaGenerator citext;
    _centroidSetting citext;
    _fileSizeKB real;
    _sizeDescription text := '';
    _fileSizeMB numeric;
    _fileSizeGB numeric;
    _dynModCount int;
    _numberOfClonedSteps text;
    _splitFasta text := '';

    _currentlocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';
    _warning := '';

    _showDebugMessages := Coalesce(_showDebugMessages, false);

    ---------------------------------------------------
    -- Trim whitespace from input/output parameters
    -- Assure that parameters are not null
    ---------------------------------------------------

    _paramFileName       := Trim(Coalesce(_paramFileName, ''));
    _settingsFileName    := Trim(Coalesce(_settingsFileName, ''));
    _organismDBName      := Trim(Coalesce(_organismDBName, ''));
    _protCollNameList    := Trim(Coalesce(_protCollNameList, ''));
    _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, ''));
    _ownerUsername       := Trim(Coalesce(_ownerUsername, ''));

    _job                                := Coalesce(_job, 0);
    _autoRemoveNotReleasedDatasets      := Coalesce(_autoRemoveNotReleasedDatasets, false);
    _autoUpdateSettingsFileToCentroided := Coalesce(_autoUpdateSettingsFileToCentroided, true);
    _allowNewDatasets                   := Coalesce(_allowNewDatasets, false);
    _priority                           := Coalesce(_priority, 3);

    BEGIN

        ---------------------------------------------------
        -- Validate the datasets in Tmp_DatasetInfo
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode::citext In ('Update', 'PreviewUpdate') Then
            _allowNonReleasedDatasets := true;
        End If;

        _currentlocation := 'Call validate_analysis_job_request_datasets';



        CALL public.validate_analysis_job_request_datasets (
                    _autoRemoveNotReleasedDatasets => _autoRemoveNotReleasedDatasets,
                    _toolName => _toolName,
                    _allowNewDatasets => _allowNewDatasets,
                    _allowNonReleasedDatasets => _allowNonReleasedDatasets,
                    _showDebugMessages => _showDebugMessages,
                    _showDatasetInfoTable => false,
                    _message => _message,           -- Output
                    _returnCode => _returnCode     -- Output
                    );

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := format('Error code %s returned by validate_analysis_job_request_datasets in Validate_Analysis_Job_Parameters', _returnCode);

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;
            End If;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Resolve user ID for job owner username
        ---------------------------------------------------

        _currentlocation := 'Resolve user ID for job owner';

        _userID := public.get_user_id (_ownerUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _ownerUsername contains simply the username
            --
            SELECT username
            INTO _ownerUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            ---------------------------------------------------
            -- _ownerUsername did not resolve to a user_id
            --
            -- In case a name was entered (instead of a username),
            -- try to auto-resolve using the name column in t_users
            ---------------------------------------------------

            CALL public.auto_resolve_name_to_username (
                    _ownerUsername,
                    _matchCount => _matchCount,         -- Output
                    _matchingUsername => _newUsername,  -- Output
                    _matchingUserID => _userID);        -- Output

            If _matchCount = 1 Then
                -- Single match was found; update _ownerUsername
                _ownerUsername := _newUsername;
            Else
                _message := format('Could not find entry in database for owner username "%s"', _ownerUsername);

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                _returnCode = 'U5319';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Get analysis tool ID from tool name
        ---------------------------------------------------

        _currentlocation := 'Determine analysis tool ID';

        _analysisToolID := public.get_analysis_tool_id (_toolName);

        If _analysisToolID = 0 Then
            _message := format('Could not find entry in database for analysis tool "%s"', _toolName);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5320';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Verify the tool name and get its requirements
        ---------------------------------------------------

        _currentlocation := 'Verify tool vs. job parameters';

        SELECT active,
               settings_file_required,
               param_file_required
        INTO _toolActive, _settingsFileRequired, _paramFileRequired
        FROM t_analysis_tool
        WHERE analysis_tool_id = _analysisToolID;

        ---------------------------------------------------
        -- Make sure the analysis tool is active
        ---------------------------------------------------

        If _toolActive = 0 Then
            If _toolName::citext In ('MSGFPlus', 'MSGFPlus_DTARefinery') Then

                _message := 'The MSGFPlus tool used concatenated _dta.txt files, which are PNNL-specific. '
                            'Please use tool MSGFPlus_MzML instead (for example requests, '
                            'see https://dms2.pnl.gov/analysis_job_request/report/-/-/-/-/StartsWith__MSGFPlus_MzML/-/- )';

            ElsIf _toolName::citext In ('MSGFPlus_SplitFasta', 'MSGFPlus_DTARefinery_SplitFasta') Then

                _message := 'The MSGFPlus SplitFasta tool used concatenated _dta.txt files, which are PNNL-specific. '
                            'Please use tool MSGFPlus_MzML instead (for example requests, '
                            'see https://dms2.pnl.gov/analysis_job_request/report/-/-/-/-/StartsWith__MSGFPlus_MzML_SplitFasta/-/- )';

            ElsIf _mode = 'reset' And ( _toolName::citext SIMILAR TO 'MAC[_]%' Or
                                        _toolName::citext = 'MaxQuant_DataPkg' Or
                                        _toolName::citext = 'MSFragger_DataPkg' Or
                                        _toolName::citext = 'DiaNN_DataPkg'
                                      ) Then

                _message := format('%s %s must be reset by clicking Edit on the Pipeline Job Detail report',
                                    _toolName, public.check_plural(_toolName, 'job', 'jobs'));

                If _job > 0 Then
                    _message := format('%s; see https://dms2.pnl.gov/pipeline_jobs/show/%s', _message, _job);
                Else
                    _message := format('%s; see https://dms2.pnl.gov/pipeline_jobs/report/-/-/~Aggregation', _message);
                End If;
            Else
                _message := format('Analysis tool "%s" is not active and thus cannot be used for this operation (Tool ID %s)', _toolName, _analysisToolID);
            End If;

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5323';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Get organism ID using organism name
        ---------------------------------------------------

        _currentlocation := 'Determine organism ID';

        _organismID := public.get_organism_id(_organismName);

        If _organismID = 0 Then
            _message := format('Could not find entry in database for organism "%s"', _organismName);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5325';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Check tool/instrument compatibility for datasets
        ---------------------------------------------------

        _currentlocation := 'Check tool/instrument compatibility for datasets';

        -- Find datasets that are not compatible with the tool due to instrument class

        SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
        INTO _datasetList
        FROM Tmp_DatasetInfo
        WHERE instrument_class::citext <> 'Data_Folders' AND
              NOT instrument_class::citext IN ( SELECT AIC.instrument_class
                                                FROM t_analysis_tool AnTool
                                                     INNER JOIN t_analysis_tool_allowed_instrument_class AIC
                                                       ON AnTool.analysis_tool_id = AIC.analysis_tool_id
                                                WHERE AnTool.analysis_tool = _toolName::citext );

        If Coalesce(_datasetList, '') <> '' Then
            _message := format('The instrument class for the following datasets is not compatible with the analysis tool: "%s"', _datasetList);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5327';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Check tool/dataset type compatibility for datasets
        ---------------------------------------------------

        _currentlocation := 'Check tool/dataset type compatibility for datasets';

        -- Find datasets that are not compatible with the tool due to dataset type

        SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
        INTO _datasetList
        FROM Tmp_DatasetInfo
        WHERE dataset_type::citext <> 'DataFiles' And
              NOT dataset_type::citext IN ( SELECT ADT.dataset_type
                                            FROM t_analysis_tool_allowed_dataset_type ADT
                                                 INNER JOIN t_analysis_tool Tool
                                                   ON ADT.analysis_tool_id = Tool.analysis_tool_id
                                            WHERE Tool.analysis_tool = _toolName::citext );

        If _datasetList <> '' Then
            _message := format('The dataset type for the following datasets is not compatible with the analysis tool: "%s"', _datasetList);

            If _showDebugMessages Then
                RAISE WARNING '%', _message;
            End If;

            _returnCode = 'U5328';

            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
        ---------------------------------------------------

        _currentlocation := 'Check for "na" settings and parameter files';

        _settingsFileName := public.validate_na_parameter(_settingsFileName, _trimwhitespace => 1);
        _paramFileName    := public.validate_na_parameter(_paramFileName,    _trimwhitespace => 1);

        ---------------------------------------------------
        -- Check for settings file or parameter file being 'na' when not allowed
        ---------------------------------------------------

        If _settingsFileRequired And _settingsFileName = 'na' Then
            _message := format('A settings file is required for analysis tool "%s"', _toolName);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5329';
            RETURN;
        End If;

        If _paramFileRequired > 0 And _paramFileName = 'na' Then
            _message := format('A parameter file is required for analysis tool "%s"', _toolName);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode = 'U5330';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate parameter file for tool
        ---------------------------------------------------

        _currentlocation := 'Validate parameter file for tool';

        _result := 0;

        If _paramFileName <> 'na' Then
            If _paramFileName::citext SIMILAR TO 'MSGFDB[_]%' Then
                _paramFileName := format('MSGFPlus_%s', Substring(_paramFileName, 8, 500));
            End If;

            If Exists (SELECT param_file_id FROM t_param_files WHERE param_file_name = _paramFileName::citext AND valid <> 0) Then
                -- The specified parameter file is valid
                -- Make sure the parameter file tool corresponds to _toolName

                If Not Exists ( SELECT param_file_id
                                FROM t_param_files PF
                                     INNER JOIN t_analysis_tool ToolList
                                       ON PF.param_file_type_id = ToolList.param_file_type_id
                                WHERE PF.param_file_name = _paramFileName::citext AND
                                      ToolList.analysis_tool = _toolName::citext
                                ) Then

                    SELECT ToolList.analysis_tool
                    INTO _paramFileTool
                    FROM t_param_files PF
                         INNER JOIN t_analysis_tool ToolList
                           ON PF.param_file_type_id = ToolList.param_file_type_id
                    WHERE PF.param_file_name = _paramFileName::citext
                    ORDER BY ToolList.analysis_tool_id
                    LIMIT 1;

                    If FOUND Then
                        _message := format('Parameter file "%s" is for tool %s; not %s',
                                           Coalesce(_paramFileName, '??'),
                                           Coalesce(_paramFileTool, '??'),
                                           Coalesce(_toolName, '??'));
                    Else
                        _message := format('Unrecognized parameter file name: %s', Coalesce(_paramFileName, '??'));
                    End If;

                    If _showDebugMessages Then
                        RAISE INFO '%', _message;
                    End If;

                    _returnCode = 'U5331';
                    RETURN;
                End If;
            Else
                -- Parameter file either does not exist or is inactive
                --
                If Exists (SELECT param_file_id FROM t_param_files WHERE param_file_name = _paramFileName::citext AND valid = 0) Then
                    _message := format('Parameter file is inactive and cannot be used: "%s"', _paramFileName);
                Else
                    _message := format('Parameter file could not be found: "%s"', _paramFileName);
                End If;

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                _returnCode = 'U5339';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate settings file for tool
        ---------------------------------------------------

        _currentlocation := 'Validate settings file for tool';

        If _settingsFileName <> 'na' Then
            If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _settingsFileName::citext AND active <> 0) Then
                -- Settings file either does not exist or is inactive
                --
                If Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _settingsFileName::citext AND active = 0) Then
                    _message := format('Settings file is inactive and cannot be used: "%s"', _settingsFileName);
                Else
                    _message := format('Settings file could not be found: "%s"', _settingsFileName);
                End If;

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                _returnCode = 'U5338';
            RETURN;
            End If;

            -- The specified settings file is valid
            -- Make sure the settings file tool corresponds to _toolName

            If Not Exists ( SELECT file_name
                            FROM V_Settings_File_Picklist SFP
                            WHERE SFP.File_Name = _settingsFileName::citext AND
                                  SFP.Analysis_Tool = _toolName::citext
                          ) Then

                SELECT SFP.analysis_tool
                INTO _settingsFileTool
                FROM V_Settings_File_Picklist SFP
                     INNER JOIN t_analysis_tool ToolList
                       ON SFP.analysis_tool = ToolList.analysis_tool
                WHERE SFP.File_Name = _settingsFileName::citext
                ORDER BY ToolList.analysis_tool_id
                LIMIT 1;

                If FOUND Then
                    _message := format('Settings file "%s" is for tool %s; not %s', _settingsFileName, _settingsFileTool, _toolName);
                Else
                    _message := format('Unrecognized settings file name: %s', Coalesce(_settingsFileName, '??'));
                End If;

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                _returnCode = 'U5332';
                RETURN;
            End If;

            _currentlocation := 'Possibly auto-switch the settings file';

            If _showDebugMessages Then
                RAISE INFO '  _autoUpdateSettingsFileToCentroided=%', _autoUpdateSettingsFileToCentroided;
            End If;

            If Coalesce(_autoUpdateSettingsFileToCentroided, true) Then
                ---------------------------------------------------
                -- If any of the datasets in Tmp_DatasetInfo have profile mode MS/MS spectra and the search tool is MSGFPlus, we must centroid the spectra
                ---------------------------------------------------

                If Exists (SELECT DI.dataset_id
                           FROM Tmp_DatasetInfo INNER JOIN
                                t_dataset_info DI ON DI.dataset_id = Tmp_DatasetInfo.dataset_id
                           WHERE DI.Profile_Scan_Count_MSn > 0
                          ) Then
                    _profileModeMSn := 1;
                End If;

                If _showDebugMessages Then
                    RAISE INFO '  _profileModeMSn=%', _profileModeMSn;
                    RAISE INFO '  _toolName=%', _toolName;
                End If;

                If _profileModeMSn > 0 And _toolName::citext In ('MSGFPlus', 'MSGFPlus_DTARefinery', 'MSGFPlus_SplitFasta') Then
                    -- The selected settings file must use MSConvert with Centroiding enabled
                    -- DeconMSn potentially works, but it can cause more harm than good

                    SELECT SF.msgfplus_auto_centroid
                    INTO _autoCentroidName
                    FROM t_settings_files SF
                         INNER JOIN t_analysis_tool AnTool
                           ON SF.analysis_tool = AnTool.analysis_tool
                    WHERE SF.file_name = _settingsFileName::citext AND
                          SF.analysis_tool = _toolName::citext;

                    If _showDebugMessages Then
                        RAISE INFO '  _settingsFileName=%', _settingsFileName;
                        RAISE INFO '  _autoCentroidName=%', Coalesce(_autoCentroidName, '<< Not Defined >>');
                    End If;

                    If Coalesce(_autoCentroidName, '') <> '' Then
                        _settingsFileName := _autoCentroidName;

                        _warning := format('Note: Auto-updated the settings file to %s because this job has a profile-mode MSn dataset', _autoCentroidName);

                        If _showDebugMessages Then
                            RAISE INFO '%', _warning;
                        End If;

                    End If;

                    CREATE TEMP TABLE Tmp_SettingsFile_Values (
                        KeyName citext NULL,
                        Value text NULL
                    );

                    INSERT INTO Tmp_SettingsFile_Values (KeyName, Value)
                    SELECT XmlQ.name, XmlQ.value
                    FROM (
                        SELECT xmltable.*
                        FROM ( SELECT contents As settings
                               FROM t_settings_files
                               WHERE file_name = _settingsFileName::citext AND
                                     analysis_tool = _toolName::citext
                             ) Src,
                             XMLTABLE('//sections/section/item'
                                      PASSING Src.settings
                                      COLUMNS section citext PATH '../@name',
                                              name    citext PATH '@key',
                                              value   citext PATH '@value'
                                              )
                         ) XmlQ;

                    SELECT Value
                    INTO _dtaGenerator
                    FROM Tmp_SettingsFile_Values
                    WHERE KeyName = 'DtaGenerator';

                    If Coalesce(_dtaGenerator, '') = '' Then
                        _message := format('Settings file "%s" does not have DtaGenerator defined; unable to verify that centroiding is enabled', _settingsFileName);
                        _returnCode = 'U5333';

                        If _showDebugMessages Then
                            RAISE INFO '%', _message;
                        End If;

                        DROP TABLE Tmp_SettingsFile_Values;
                        RETURN;
                    End If;

                    If _dtaGenerator = 'MSConvert.exe' Then
                        SELECT Value
                        INTO _centroidSetting
                        FROM Tmp_SettingsFile_Values
                        WHERE KeyName = 'CentroidMGF';

                        _centroidSetting := Coalesce(_centroidSetting, 'False');
                    End If;

                    If _dtaGenerator = 'DeconMSN.exe' Then
                        SELECT Value
                        INTO _centroidSetting
                        FROM Tmp_SettingsFile_Values
                        WHERE KeyName = 'CentroidDTAs';

                        _centroidSetting := Coalesce(_centroidSetting, 'False');
                    End If;

                    If _centroidSetting <> 'True' Then
                        If Coalesce(_centroidSetting, '') = '' Then
                            _message := format('MS-GF+ requires that HMS-HMSn spectra be centroided; settings file "%s" does not use MSConvert or DeconMSn for DTA Generation; unable to determine if centroiding is enabled', _settingsFileName);
                        Else
                            _message := format('MS-GF+ requires that HMS-HMSn spectra be centroided; settings file "%s" does not appear to have centroiding enabled', _settingsFileName);
                        End If;

                        If _showDebugMessages Then
                            RAISE INFO '%', _message;
                        End If;
                    End If;
                End If;
            End If;

        End If;

        ---------------------------------------------------
        -- Check protein parameters
        ---------------------------------------------------

        _currentlocation := 'Call validate_protein_collection_params';

        CALL public.validate_protein_collection_params (
                        _toolName,
                        _organismDBName      => _organismDBName,        -- Output
                        _organismName        => _organismName,
                        _protCollNameList    => _protCollNameList,      -- Output
                        _protCollOptionsList => _protCollOptionsList,   -- Output
                        _ownerUsername       => _ownerUsername,
                        _message             => _message,               -- Output
                        _returnCode          => _returnCode,            -- Output
                        _debugMode           => _showDebugMessages);

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := format('Error code %s returned by Validate_Protein_Collection_Params in Validate_Analysis_Job_Parameters', _returnCode);
            End If;

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the user is not scheduling an extremely long MS-GF+ search (with non-compatible settings)
        -- Also possibly alter _priority
        ---------------------------------------------------

        _currentlocation := 'Check parameters if using a large FASTA file';

        If _organismDBName <> 'na' And _organismDBName <> '' Then

            SELECT file_size_kb
            INTO _fileSizeKB
            FROM t_organism_db_file
            WHERE file_name = _organismDBName::text;

            If FOUND And _fileSizeKB > 0 Then
                _fileSizeMB := _fileSizeKB / 1024.0;
                _fileSizeGB := _fileSizeMB / 1024.0;

                If _fileSizeKB > 0 Then
                    _fileSizeMB := _fileSizeKB / 1024.0;
                    _fileSizeGB := _fileSizeMB / 1024.0;

                    If _fileSizeGB < 1 Then
                        If _fileSizeMB < 5 Then
                            _sizeDescription := format('%s MB', round(_fileSizeMB, 1));
                        Else
                            _sizeDescription := format('%s MB', round(_fileSizeMB));
                        End If;
                    Else
                        If _fileSizeGB < 5 Then
                            _sizeDescription := format('%s GB', round(_fileSizeGB, 1));
                        Else
                            _sizeDescription := format('%s GB', round(_fileSizeGB));
                        End If;
                    End If;
                End If;
            End If;

            -- Bump priority if the file is over 400 MB in size
            If Coalesce(_fileSizeKB, 0) > 400 * 1024 Then
                If _priority < 4 Then
                    _priority := 4;
                End If;
            End If;

            If _toolName ILike '%MSGFPlus%' Then
                -- Check for a file over 500 MB in size
                If Coalesce(_fileSizeKB, 0) > 500*1024 Or
                   _organismDBName::citext In (
                        'ORNL_Proteome_Study_Soil_1606Orgnsm2012-08-24.fasta',
                        'ORNL_Proteome_Study_Soil_1606Orgnsm2012-08-24_reversed.fasta',
                        'uniprot_2012_1_combined_bacterial_sprot_trembl_2012-02-20.fasta',
                        'uniprot2012_7_ArchaeaBacteriaFungiSprotTrembl_2012-07-11.fasta',
                        'uniref50_2013-02-14.fasta',
                        'uniref90_2013-02-14.fasta',
                        'BP_Sediment_Genomes_Jansson_stop-to-stop_6frames.fasta',
                        'GOs_PredictedByClustering_2009-02-11.fasta',
                        'Shew_MR1_GOs_Meso_2009-02-11.fasta',
                        'Switchgrass_Rhiz_MG-RAST_metagenome_DecoyWithContams_2013-10-10.fasta') Then

                    If Not ( _paramFileName ILike '%PartTryp_NoMods%' Or
                             _paramFileName ILike '%PartTryp_StatCysAlk.txt' Or
                             _paramFileName::citext SIMILAR TO '%PartTryp_StatCysAlk_[0-9]%ppm%' Or
                             _paramFileName::citext SIMILAR TO '%[_]Tryp[_]%'
                            ) Then

                        _message := format('Legacy fasta file "%s" is very large (%s); you must choose a parameter file that is fully tryptic (MSGFPlus_Tryp_) '
                                           'or is partially tryptic but has no dynamic mods (MSGFPlus_PartTryp_NoMods)',
                                            _organismDBName, _sizeDescription);

                        _returnCode := 'U5350';

                        If _showDebugMessages Then
                            RAISE INFO '%', _message;
                        End If;

                        RETURN;
                    End If;
                End If;

                -- Check for a file over 2 GB in size
                If Coalesce(_fileSizeKB, 0) > 2*1024*1024 Or
                   _organismDBName::citext In (
                    'uniprot_2012_1_combined_bacterial_sprot_trembl_2012-02-20.fasta',
                    'uniprot2012_7_ArchaeaBacteriaFungiSprotTrembl_2012-07-11.fasta',
                    'uniref90_2013-02-14.fasta',
                    'Uniprot_ArchaeaBacteriaFungi_SprotTrembl_2014-4-16.fasta',
                    'Kansas_metagenome_12902_TrypPig_Bov_2014-11-25.fasta',
                    'HoplandAll_assembled_Tryp_Pig_Bov_2015-04-06.fasta') Then

                    SELECT COUNT(mod_entry_id)
                    INTO _dynModCount
                    FROM V_Param_File_Mass_Mods
                    WHERE Param_File_Name = _paramFileName::citext AND
                          Mod_Type_Symbol = 'D';

                    If FOUND And Coalesce(_dynModCount, 0) > 1 Then
                        -- Parameter has more than one dynamic mod; this search will take too long
                        _message := format('Legacy FASTA file %s is very large (%s); you cannot use a parameter file with %s dynamic mods. '
                                           'Preferably use a parameter file with no dynamic mods (though you _might_ get away with 1 dynamic mod).',
                                           _organismDBName, _sizeDescription, _dynModCount);

                        _returnCode := 'U5351';

                        If _showDebugMessages Then
                            RAISE INFO '%', _message;
                        End If;

                        RETURN;
                    End If;
                End If;

                -- If using MS-GF+ and the file is over 600 MB, you must use MSGFPlus_SplitFasta
                If Coalesce(_fileSizeKB, 0) > 600*1024 Then
                    If _toolName ILike '%MSGF%' And Not _toolName ILike '%SplitFasta%' Then
                        _message := format('Legacy fasta file "%s" is very large (%s); you must use analysis tool MSGFPlus_SplitFasta or MSGFPlus_MzML_SplitFasta',
                                            _organismDBName, _sizeDescription);

                        _returnCode := 'U5352';

                        If _showDebugMessages Then
                            RAISE INFO '%', _message;
                        End If;

                        RETURN;
                    End If;
                End If;
            End If;

        End If;

        If _toolName ILike '%SplitFasta%' Then
            -- Assure that the settings file has SplitFasta=True and NumberOfClonedSteps > 1

            _currentlocation := 'Validate Split FASTA settings';

            If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _settingsFileName::citext) Then
                _message := format('Settings file not found: %s', _settingsFileName);
                _returnCode = 'U5333';

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                RETURN;
            End If;

            SELECT XmlQ.value
            INTO _splitFasta
            FROM (
                SELECT xmltable.*
                FROM ( SELECT contents AS settings
                       FROM t_settings_files
                       WHERE file_name = _settingsFileName::citext
                     ) Src,
                     XMLTABLE('//sections/section/item'
                              PASSING Src.settings
                              COLUMNS section citext PATH '../@name',
                                      name    citext PATH '@key',
                                      value   citext PATH '@value'
                                      )
                 ) XmlQ
            WHERE name::citext = 'SplitFasta';

            If Not FOUND Or Trim(Lower(Coalesce(_splitFasta, 'false'))) <> 'true' Then
                _message := format('Search tool %s requires a SplitFasta settings file', _toolName);
                _returnCode = 'U5335';

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                RETURN;
            End If;

            SELECT XmlQ.value
            INTO _numberOfClonedSteps
            FROM (
                SELECT xmltable.*
                FROM ( SELECT contents as settings
                       FROM t_settings_files
                       WHERE file_name = _settingsFileName::citext
                     ) Src,
                     XMLTABLE('//sections/section/item'
                              PASSING Src.settings
                              COLUMNS section citext PATH '../@name',
                                      name    citext PATH '@key',
                                      value   citext PATH '@value'
                                      )
                 ) XmlQ
            WHERE name::citext = 'NumberOfClonedSteps';

            If Not FOUND Or public.try_cast(_numberOfClonedSteps, 0) < 1 Then
                _message := format('Search tool %s requires a SplitFasta settings file', _toolName);
                _returnCode = 'U5336';

                If _showDebugMessages Then
                    RAISE INFO '%', _message;
                End If;

                RETURN;
            End If;

        End If;

        If _returnCode <> '' And _showDebugMessages And Coalesce(_message, '') <> '' Then
            RAISE INFO '%', _message;
        End If;

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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_SettingsFile_Values;
END
$$;


ALTER PROCEDURE public.validate_analysis_job_parameters(IN _toolname text, INOUT _paramfilename text, INOUT _settingsfilename text, INOUT _organismdbname text, IN _organismname text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _ownerusername text, IN _mode text, INOUT _userid integer, INOUT _analysistoolid integer, INOUT _organismid integer, IN _job integer, IN _autoremovenotreleaseddatasets boolean, IN _autoupdatesettingsfiletocentroided boolean, IN _allownewdatasets boolean, INOUT _warning text, INOUT _priority integer, IN _showdebugmessages boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_analysis_job_parameters(IN _toolname text, INOUT _paramfilename text, INOUT _settingsfilename text, INOUT _organismdbname text, IN _organismname text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _ownerusername text, IN _mode text, INOUT _userid integer, INOUT _analysistoolid integer, INOUT _organismid integer, IN _job integer, IN _autoremovenotreleaseddatasets boolean, IN _autoupdatesettingsfiletocentroided boolean, IN _allownewdatasets boolean, INOUT _warning text, INOUT _priority integer, IN _showdebugmessages boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_analysis_job_parameters(IN _toolname text, INOUT _paramfilename text, INOUT _settingsfilename text, INOUT _organismdbname text, IN _organismname text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _ownerusername text, IN _mode text, INOUT _userid integer, INOUT _analysistoolid integer, INOUT _organismid integer, IN _job integer, IN _autoremovenotreleaseddatasets boolean, IN _autoupdatesettingsfiletocentroided boolean, IN _allownewdatasets boolean, INOUT _warning text, INOUT _priority integer, IN _showdebugmessages boolean, INOUT _message text, INOUT _returncode text) IS 'ValidateAnalysisJobParameters';


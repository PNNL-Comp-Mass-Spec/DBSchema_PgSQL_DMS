--
-- Name: add_update_dataset(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, integer, text, text, text, boolean, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_dataset(IN _datasetname text, IN _experimentname text, IN _operatorusername text, IN _instrumentname text, IN _mstype text, IN _lccolumnname text, IN _wellplatename text DEFAULT 'na'::text, IN _wellnumber text DEFAULT 'na'::text, IN _secsep text DEFAULT 'na'::text, IN _internalstandards text DEFAULT 'none'::text, IN _comment text DEFAULT ''::text, IN _rating text DEFAULT 'Unknown'::text, IN _lccartname text DEFAULT ''::text, IN _eusproposalid text DEFAULT 'na'::text, IN _eususagetype text DEFAULT ''::text, IN _eususerslist text DEFAULT ''::text, IN _requestid integer DEFAULT 0, IN _workpackage text DEFAULT 'none'::text, IN _mode text DEFAULT 'add'::text, IN _callinguser text DEFAULT ''::text, IN _aggregationjobdataset boolean DEFAULT false, IN _capturesubfolder text DEFAULT ''::text, IN _lccartconfig text DEFAULT ''::text, IN _logdebugmessages boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This procedure is called from both web pages and from other procedures
**      - The Dataset Entry page (https://dms2.pnl.gov/dataset/create) calls it with _mode = 'add_dataset_create_task'
**      - Dataset Detail Report pages call it with _mode = 'update'
**      - Spreadsheet Loader (https://dms2.pnl.gov/upload/main) calls it with with _mode as 'add_dataset_create_task, 'check_update', or 'check_add'
**      - It is also called with _mode = 'add' when the Data Import Manager (DIM) calls add_new_dataset while processing dataset trigger files
**
**  Arguments:
**    _datasetName              Dataset name
**    _experimentName           Experiment name
**    _operatorUsername         Instrument operator username
**    _instrumentName           Instrument name
**    _msType                   Dataset Type
**    _lcColumnName             LC column name
**    _wellplateName            Wellplate name
**    _wellNumber               Well number
**    _secSep                   LC Separation type
**    _internalStandards        Internal standard names
**    _comment                  Dataset comment
**    _rating                   Dataset rating name (aka interest rating)
**    _lcCartName               LC cart name
**    _eusProposalID            EUS proposal ID
**    _eusUsageType             EUS usage type
**    _eusUsersList             EUS users list
**    _requestID                Only valid if _mode is 'add', 'check_add', or 'add_dataset_create_task'; ignored if _mode is 'update' or 'check_update'
**    _workPackage              Only valid if _mode is 'add', 'check_add', or 'add_dataset_create_task'
**    _mode                     Can be 'add', 'update', 'bad', 'check_update', 'check_add', 'add_dataset_create_task' (deprecated: 'add_trigger')
**    _callingUser              Username of the calling user
**    _aggregationJobDataset    Set to true when creating an in-silico dataset to associate with an aggregation job
**    _captureSubfolder         Only used when _mode is 'add' or 'bad'
**    _lcCartConfig             LC cart config
**    _logDebugMessages         When true, log debug messages
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   02/13/2003
**          01/10/2002
**          12/10/2003 grk - Added wellplate, internal standards, and LC column stuff
**          01/11/2005 grk - Added bad dataset stuff
**          02/23/2006 grk - Added LC cart tracking stuff and EUS stuff
**          01/12/2007 grk - Added verification mode
**          02/16/2007 grk - Added validation of dataset name (Ticket #390)
**          04/30/2007 grk - Added better name validation (Ticket #450)
**          07/26/2007 mem - Now checking dataset type (_msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - Removed _specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          10/08/2007 jds - Added support for new mode 'add_trigger'.  Validation was taken from other stored procs from the 'add' mode
**          12/07/2007 mem - Now disallowing updates for datasets with a rating of -10 = Unreviewed (use update_dataset_dispositions instead)
**          01/08/2008 mem - Added check for _eusProposalID, _eusUsageType, or _eusUsersList being blank or 'no update' when _mode = 'add' and _requestID is 0
**          02/13/2008 mem - Now sending _datasetName to function validate_chars and checking for _badCh = '[space]' (Ticket #602)
**          02/15/2008 mem - Increased size of _folderName to varchar(128) (Ticket #645)
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          04/09/2008 mem - Added call to alter_event_log_entry_user to handle dataset rating entries (event log target type 8)
**          05/23/2008 mem - Now calling schedule_predefined_analysis_jobs if the dataset rating is changed from -5 to 5 and no jobs exist yet for this dataset (Ticket #675)
**          04/08/2009 jds - Added support for the additional parameters _secSep and _mrmAttachment to the Add_Update_Requested_Run procedure (Ticket #727)
**          09/16/2009 mem - Now checking dataset type (_msType) against the Instrument_Allowed_Dataset_Type table (Ticket #748)
**          01/14/2010 grk - Assign storage path on creation of dataset
**          02/28/2010 grk - Added add-auto mode for requested run
**          03/02/2010 grk - Added status field to requested run
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _operatorUsername contains a person's real name rather than their username
**          07/27/2010 grk - Use try-catch for error handling
**          08/26/2010 mem - Now passing _callingUser to schedule_predefined_analysis_jobs
**          08/27/2010 mem - Now calling Validate_Instrument_Group_and_Dataset_Type to validate the instrument type for the selected instrument's instrument group
**          09/01/2010 mem - Now passing _skipTransactionRollback to Add_Update_Requested_Run
**          09/02/2010 mem - Now allowing _msType to be blank or invalid when _mode = 'add'; The assumption is that the dataset type will be auto-updated if needed based on the results from the DatasetQuality tool, which runs during dataset capture
**                         - Expanded _msType to varchar(50)
**          09/09/2010 mem - Now passing _autoPopulateUserListIfBlank to Add_Update_Requested_Run
**                         - Relaxed EUS validation to ignore _eusProposalID, _eusUsageType, and _eusUsersList if _requestID is non-zero
**                         - Auto-updating RequestID, experiment, and EUS information for 'Blank' datasets
**          03/10/2011 mem - Tweaked text added to dataset comment when dataset type is auto-updated or auto-defined
**          05/11/2011 mem - Now calling Get_Instrument_Storage_Path_For_New_Datasets
**          05/12/2011 mem - Now passing _refDate and _autoSwitchActiveStorage to Get_Instrument_Storage_Path_For_New_Datasets
**          05/24/2011 mem - Now checking for change of rating from -5, -6, or -7 to 5
**                         - Now ignoring jobs with dataset_unreviewed = 1 when determining whether or not to call schedule_predefined_analysis_jobs
**          12/12/2011 mem - Updated call to Validate_EUS_Usage to treat _eusUsageType as an input/output parameter
**          12/14/2011 mem - Now passing _callingUser to Add_Update_Requested_Run and Consume_Scheduled_Run
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in _comment
**          01/11/2012 mem - Added parameter _aggregationJobDataset
**          02/29/2012 mem - Now auto-updating the _eus parameters if null
**                         - Now raising an error if other key parameters are null/empty
**          09/12/2012 mem - Now auto-changing HMS-HMSn to IMS-HMS-HMSn for IMS datasets
**                         - Now requiring that the dataset name be 90 characters or less (longer names can lead to 'path-too-long' errors; Windows has a 254 character path limit)
**          11/21/2012 mem - Now requiring that the dataset name be at least 6 characters in length
**          01/22/2013 mem - Now updating the dataset comment if the default dataset type is invalid for the instrument group
**          04/02/2013 mem - Now updating _lcCartName (if not blank) when updating an existing dataset
**          05/08/2013 mem - Now setting _wellplateName and _wellNumber to Null if they are blank or 'na'
**          02/27/2014 mem - Now skipping check for name ending in Raw or Wiff if _aggregationJobDataset is true
**          05/07/2015 mem - Now showing URL http://dms2.pnl.gov/dataset_disposition/search if the user tries to change the rating from Unreleased to something else (previously showed http://dms2.pnl.gov/dataset_disposition/report)
**          05/29/2015 mem - Added parameter _captureSubfolder (only used if _mode is 'add' or 'bad')
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          06/19/2015 mem - Now auto-fixing QC_Shew names, e.g. QC_Shew_15-01 to QC_Shew_15_01
**          10/01/2015 mem - Add support for (ignore) for _eusProposalID, _eusUsageType, and _eusUsersList
**          10/14/2015 mem - Remove double quotes from error messages
**          01/29/2016 mem - Now calling Get_WP_for_EUS_Proposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add Set XACT_ABORT on
**          05/23/2016 mem - Disallow certain dataset names
**          06/10/2016 mem - Try to auto-associate new datasets with an active requested run (only associate if only one active requested run matches the dataset name)
**          06/21/2016 mem - Add additional debug messages
**          08/25/2016 mem - Do not update the dataset comment if the dataset type is changed from 'GC-MS' to 'EI-HMS'
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/21/2016 mem - Pass _logDebugMessages to Consume_Scheduled_Run
**          11/23/2016 mem - Include the dataset name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Pass _logDebugMessages to Add_Update_Requested_Run
**          02/23/2017 mem - Add parameter _lcCartConfig
**          03/06/2017 mem - Decreased maximum dataset name length from 90 characters to 80 characters
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/29/2017 mem - Allow updating EUS info for existing datasets (calls Add_Update_Requested_Run)
**          06/12/2018 mem - Send _maxLength to append_to_text
**                         - Expand _warning to varchar(512)
**          04/15/2019 mem - Add call to Update_Cached_Dataset_Instruments
**          07/19/2019 mem - Change _eusUsageType to 'maintenance' if empty for _Tune_ or TuneMix datasets
**          11/11/2019 mem - Auto change 'Blank-' and 'blank_' to 'Blank'
**          09/15/2020 mem - Now showing 'https://dms2.pnl.gov/dataset_disposition/search' instead of http://
**          10/10/2020 mem - No longer update the comment when auto switching the dataset type
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          12/17/2020 mem - Verify that _captureSubfolder is a relative path and add debug messages
**          02/25/2021 mem - Remove the requested run comment from the dataset comment if the dataset comment starts with the requested run comment
**                         - Use Replace_Character_Codes to replace character codes with punctuation marks
**                         - Use Remove_Cr_Lf to replace linefeeds with semicolons
**          05/26/2021 mem - When _mode is 'add', 'check_add', or 'add_trigger', possibly override the EUSUsageType based on the campaign's EUS Usage Type
**                         - Expand _message to varchar(1024)
**          05/27/2021 mem - Refactor EUS Usage validation code into Validate_EUS_Usage
**          10/01/2021 mem - Also check for a period when verifying that the dataset name does not end with .raw or .wiff
**          11/12/2021 mem - When _mode is update, pass _batch, _block, and _runOrder to Add_Update_Requested_Run
**          02/17/2022 mem - Rename variables and add missing Else clause
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          05/27/2022 mem - Expand _msg to varchar(1024)
**          08/22/2022 mem - Do not log EUS Usage validation errors to T_Log_Entries
**          11/25/2022 mem - Rename parameter to _wellplate
**          02/27/2023 mem - Use new argument name, _requestName
**                         - Use calling user name for the dataset creator user
**          08/02/2023 mem - Prevent adding a dataset for an inactive instrument
**          08/03/2023 mem - Allow creation of datasets for instruments in group 'Data_Folders' (specifically, the DMS_Pipeline_Data instrument)
**          10/24/2023 mem - Use update_cart_parameters to update Cart Config ID in T_Requested_Run
**          10/26/2023 mem - Call add_new_dataset_to_creation_queue instead of create_xml_dataset_trigger_file
**          10/30/2023 mem - Replace mode 'add_trigger' with 'add_dataset_create_task'
**                         - Ported to PostgreSQL
**          11/01/2023 mem - Add missing brackets when checking for '[space]' in the return value from validate_chars()
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user_multi_id()
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/08/2024 mem - Remove procedure name from error message
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _folderName text;
    _addingDataset boolean := false;
    _warning citext := '';
    _warningAddon text;
    _experimentCheck text;
    _debugMsg text;
    _requestName text;
    _reqRunInstSettings text;
    _reqRunComment citext;
    _reqRunInternalStandard text;
    _workPackageFromRequest text;
    _wellplateNameFromRequest text;
    _wellNumberFromRequest text;
    _mrmAttachmentID int;
    _reqRunStatus text;
    _batchID int;
    _block int;
    _runOrder int;
    _resolvedInstrumentInfo text;
    _badCh text;
    _ratingID int;
    _datasetID int;
    _curDSTypeID int;
    _curDSInstID int;
    _curDSStateID int;
    _curDSRatingID int;
    _newDSStateID int;
    _columnID int := -1;
    _cartConfigID int;
    _sepID int := 0;
    _intStdID int := -1;
    _experimentID int;
    _newExperiment text;
    _instrumentID int;
    _instrumentClass citext;
    _instrumentGroup text;
    _instrumentStatus citext;
    _defaultDatasetTypeID int;
    _msTypeOld text;
    _datasetTypeID int;
    _allowedDatasetTypes text;
    _userID int;
    _matchCount int;
    _newUsername text;
    _requestInstGroup text;
    _requestMatchCount int;
    _reqExperimentID int := 0;
    _cartID int := 0;
    _eusUsageTypeID Int;
    _dsCreatorUsername text;
    _runStart text;
    _runFinish text;
    _storagePathID int;
    _refDate timestamp without time zone;
    _datasetIDConfirm int;
    _jobStateID int;
    _warningWithPrefix text;
    _logErrors boolean := false;
    _logMessage text;
    _targetType int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode              := Trim(Lower(Coalesce(_mode, '')));

        _secSep            := Trim(Coalesce(_secSep, ''));
        _lcColumnName      := Trim(Coalesce(_lcColumnName, ''));
        _datasetName       := Trim(Coalesce(_datasetName, ''));

        _experimentName    := Trim(Coalesce(_experimentName, ''));
        _operatorUsername  := Trim(Coalesce(_operatorUsername, ''));
        _instrumentName    := Trim(Coalesce(_instrumentName, ''));
        _rating            := Trim(Coalesce(_rating, ''));

        _internalStandards := Trim(Coalesce(_internalStandards, ''));

        If _internalStandards = '' Or _internalStandards = 'na' Then
            _internalStandards := 'none';
        End If;

        If Coalesce(_mode, '') = '' Then
            RAISE EXCEPTION 'Mode must be specified';
        End If;

        If Coalesce(_secSep, '') = '' Then
            RAISE EXCEPTION 'Separation type must be specified';
        End If;

        If Coalesce(_lcColumnName, '') = '' Then
            RAISE EXCEPTION 'LC Column name must be specified';
        End If;

        If Coalesce(_datasetName, '') = '' Then
            RAISE EXCEPTION 'Dataset name must be specified';
        End If;

        _folderName := _datasetName;

        If Coalesce(_experimentName, '') = '' Then
            RAISE EXCEPTION 'Experiment name must be specified';
        End If;

        If Coalesce(_folderName, '') = '' Then
            RAISE EXCEPTION 'Folder name must be specified';
        End If;

        If Coalesce(_operatorUsername, '') = '' Then
            RAISE EXCEPTION 'Operator payroll number/HID must be specified';
        End If;

        If Coalesce(_instrumentName, '') = '' Then
            RAISE EXCEPTION 'Instrument name must be specified';
        End If;

        _msType := Trim(Coalesce(_msType, ''));

        -- Allow _msType to be blank if _mode is 'add' or 'bad' but not if check_add or add_dataset_create_task or update
        If _msType = '' And Not _mode::citext In ('add', 'bad') Then
            RAISE EXCEPTION 'Dataset type must be specified';
        End If;

        If Coalesce(_lcCartName, '') = '' Then
            RAISE EXCEPTION 'LC Cart name must be specified';
        End If;

        -- Assure that _comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
        _comment := public.replace_character_codes(_comment);

        -- Replace instances of CRLF (or LF) with semicolons
        _comment := public.remove_cr_lf(_comment);

        If Coalesce(_rating, '') = '' Then
            RAISE EXCEPTION 'Rating must be specified';
        End If;

        If Coalesce(_wellplateName, '')::citext In ('', 'na') Then
            _wellplateName := NULL;
        End If;

        If Coalesce(_wellNumber, '')::citext In ('', 'na') Then
            _wellNumber := NULL;
        End If;

        _workPackage           := Trim(Coalesce(_workPackage, ''));
        _eusProposalID         := Trim(Coalesce(_eusProposalID, ''));
        _eusUsageType          := Trim(Coalesce(_eusUsageType, ''));
        _eusUsersList          := Trim(Coalesce(_eusUsersList, ''));

        _requestID             := Coalesce(_requestID, 0);
        _aggregationJobDataset := Coalesce(_aggregationJobDataset, false);
        _captureSubfolder      := Trim(Coalesce(_captureSubfolder, ''));
        _lcCartConfig          := Trim(Coalesce(_lcCartConfig, ''));
        _logDebugMessages      := Coalesce(_logDebugMessages, false);
        _callingUser           := Trim(Coalesce(_callingUser, ''));

        If _captureSubfolder SIMILAR TO '\\%' Or _captureSubfolder::citext SIMILAR TO '[A-Z]:\%' Then
            RAISE EXCEPTION 'Capture subfolder should be a subdirectory name below the source share for this instrument; it is currently a full path';
        End If;

        If _lcCartConfig = '' Then
            _lcCartConfig := null;
        End If;

        ---------------------------------------------------
        -- Determine if we are adding or check_adding a dataset
        ---------------------------------------------------

        If _mode::citext In ('add', 'check_add', 'add_dataset_create_task', 'add_trigger') Then
            _addingDataset := true;
        Else
            _addingDataset := false;
        End If;

        If _logDebugMessages Then
            _debugMsg := format('_mode=%s, _dataset=%s, _requestID=%s, _callingUser=%s', _mode, _datasetName, _requestID, _callingUser);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
        End If;

        ---------------------------------------------------
        -- Validate dataset name
        ---------------------------------------------------

        _badCh := public.validate_chars(_datasetName, '');

        If _badCh <> '' Then
            If _badCh = '[space]' Then
                _msg := 'Dataset name may not contain spaces';
            ElsIf char_length(_badCh) = 1 Then
                _msg := format('Dataset name may not contain the character %s', _badCh);
            Else
                _msg := format('Dataset name may not contain the characters %s', _badCh);
            End If;

            RAISE EXCEPTION '%', _msg;
        End If;

        If Not _aggregationJobDataset And (_datasetName::citext SIMILAR TO '%[.]raw' Or _datasetName::citext SIMILAR TO '%[.]wiff' Or _datasetName::citext SIMILAR TO '%[.]d') Then
            RAISE EXCEPTION 'Dataset name may not end in .raw, .wiff, or .d';
        End If;

        If char_length(_datasetName) > 80 And Not _mode::citext In ('update', 'check_update') Then
            RAISE EXCEPTION 'Dataset name cannot be over 80 characters in length; currently % characters', char_length(_datasetName);
        End If;

        If char_length(_datasetName) < 6 Then
            RAISE EXCEPTION 'Dataset name must be at least 6 characters in length; currently % characters', char_length(_datasetName);
        End If;

        If _datasetName::citext In (
           'Archive', 'Dispositioned', 'Processed', 'Reprocessed', 'Not-Dispositioned',
           'High-pH', 'NotDispositioned', 'Yufeng', 'Uploaded', 'Sequence', 'Sequences',
           'Peptide', 'BadData') Then

            RAISE EXCEPTION 'Dataset name is too generic; be more specific';

        End If;

        ---------------------------------------------------
        -- Resolve ID for rating
        ---------------------------------------------------

        If _mode = 'bad' Then
            _ratingID := -1; -- 'No Data'
            _mode := 'add';
            _addingDataset := true;
        Else
            _ratingID := public.get_dataset_rating_id(_rating);

            If _ratingID = 0 Then
                RAISE EXCEPTION 'Cannot update: dataset rating "%" does not exist', _rating;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT dataset_id, instrument_id,
               dataset_state_id, dataset_rating_id
        INTO _datasetID, _curDSInstID, _curDSStateID, _curDSRatingID
        FROM t_dataset
        WHERE dataset = _datasetName::citext;

        If Not FOUND Then
            -- Cannot update a non-existent entry

            If _mode::citext In ('update', 'check_update') Then
                RAISE EXCEPTION 'Cannot update: dataset % does not exist', _datasetName;
            End If;
        Else
            -- Cannot create an entry that already exists

            If _addingDataset Then
                RAISE EXCEPTION 'Cannot add dataset "%" since it already exists', _datasetName;
            End If;

            -- Do not allow a rating change from 'Unreviewed' to any other rating within this procedure

            If _curDSRatingID = -10 And _rating::citext <> 'Unreviewed' Then
                RAISE EXCEPTION 'Cannot change dataset rating from Unreviewed with this mechanism; use the Dataset Disposition process instead ("https://dms2.pnl.gov/dataset_disposition/search" or SP UpdateDatasetDispositions)';
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve ID for LC Column
        ---------------------------------------------------

        SELECT lc_column_id
        INTO _columnID
        FROM t_lc_column
        WHERE lc_column::citext = _lcColumnName::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unknown LC column name: %', _lcColumnName;
        End If;

        ---------------------------------------------------
        -- Resolve ID for LC Cart Config
        ---------------------------------------------------

        If _lcCartConfig Is Null Then
            _cartConfigID := null;
        Else
            _cartConfigID := -1;

            SELECT cart_config_id
            INTO _cartConfigID
            FROM t_lc_cart_configuration
            WHERE cart_config_name::citext = _lcCartConfig::citext;

            If Not FOUND Then
                RAISE EXCEPTION 'Unknown LC cart config: %', _lcCartConfig;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve ID for _secSep
        ---------------------------------------------------

        SELECT separation_type_id
        INTO _sepID
        FROM t_secondary_sep
        WHERE separation_type::citext = _secSep::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unknown separation type: %', _secSep;
        End If;

        ---------------------------------------------------
        -- Resolve ID for _internalStandards
        ---------------------------------------------------

        SELECT internal_standard_id
        INTO _intStdID
        FROM t_internal_standards
        WHERE name::citext = _internalStandards::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Unknown internal standard name: %', _internalStandards;
        End If;

        ---------------------------------------------------
        -- If Dataset starts with 'Blank', make sure _experimentName contains 'Blank'
        ---------------------------------------------------

        If _datasetName::citext Like 'Blank%' And _addingDataset Then
            If Not _experimentName::citext Like '%blank%' Then
                _experimentName := 'blank';
            End If;

            If _experimentName::citext In ('Blank-', 'Blank_') Then
                _experimentName := 'blank';
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve experiment ID
        ---------------------------------------------------

        _experimentID := public.get_experiment_id(_experimentName);

        If _experimentID = 0 And _experimentName::citext SIMILAR TO 'QC_Shew_[0-9][0-9]_[0-9][0-9]' And _experimentName Like '%-%' Then

            _newExperiment := Replace(_experimentName, '-', '_');
            _experimentID := public.get_experiment_id(_newExperiment);

            If _experimentID > 0 Then
                SELECT experiment
                INTO _experimentName
                FROM t_experiments
                WHERE exp_id = _experimentID;
            End If;
        End If;

        If _experimentID = 0 Then
            RAISE EXCEPTION 'Invalid experiment: "%" does not exist', _experimentName;
        End If;

        ---------------------------------------------------
        -- Resolve instrument ID
        ---------------------------------------------------

        _instrumentID := public.get_instrument_id(_instrumentName);

        If _instrumentID = 0 Then
            RAISE EXCEPTION 'Invalid instrument: "%" does not exist', _instrumentName;
        End If;

        ---------------------------------------------------
        -- Lookup the instrument group and status
        ---------------------------------------------------

        SELECT instrument_class, instrument_group, status
        INTO _instrumentClass, _instrumentGroup, _instrumentStatus
        FROM t_instrument_name
        WHERE instrument_id = _instrumentID;

        If Not FOUND Then
            RAISE EXCEPTION 'Instrument group not defined for instrument %; contact a DMS administrator to fix this', _instrumentName;
        End If;

        If Coalesce(_instrumentStatus, '') <> 'active' And _instrumentClass <> 'Data_Folders' Then
            RAISE EXCEPTION 'Instrument % is not active; new datasets cannot be added for this instrument; contact a DMS administrator if the instrument status should be changed', _instrumentName;
        End If;

        ---------------------------------------------------
        -- Lookup the default dataset type ID (could be null)
        ---------------------------------------------------

        SELECT default_dataset_type
        INTO _defaultDatasetTypeID
        FROM t_instrument_group
        WHERE instrument_group = _instrumentGroup::citext;

        ---------------------------------------------------
        -- Resolve dataset type ID
        ---------------------------------------------------

        _datasetTypeID := public.get_dataset_type_id(_msType);

        If _datasetTypeID = 0 Then
            -- Could not resolve _msType to a dataset type
            -- If _mode is 'add', we will auto-update _msType to the default

            If _addingDataset And Coalesce(_defaultDatasetTypeID, 0) > 0 Then
                -- Use the default dataset type
                _datasetTypeID := _defaultDatasetTypeID;

                _msTypeOld := _msType;

                -- Update _msType
                SELECT Dataset_Type
                INTO _msType
                FROM t_dataset_type_name
                WHERE dataset_type_ID = _datasetTypeID;
            Else
                RAISE EXCEPTION 'Invalid dataset type: %', _msType;
            End If;
        End If;

        ---------------------------------------------------
        -- Verify that dataset type is valid for given instrument group
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Call Validate_Instrument_Group_and_Dataset_Type with type = %s and group = %s', _msType, _instrumentGroup);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
        End If;

        CALL public.validate_instrument_group_and_dataset_type (
                        _datasetType     => _msType,
                        _instrumentGroup => _instrumentGroup,   -- Input/Output
                        _datasetTypeID   => _datasetTypeID,     -- Output
                        _message         => _msg,               -- Output
                        _returnCode      => _returnCode);       -- Output

        If _returnCode <> '' And _addingDataset And Coalesce(_defaultDatasetTypeID, 0) > 0 Then

            If _logDebugMessages Then
                _debugMsg := 'Dataset type is not valid for this instrument group, however, _mode is ''add'', so auto-update _msType';
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            -- Dataset type is not valid for this instrument group
            -- However, _mode is 'add', so we will auto-update _msType

            If _msType::citext In ('HMS-MSn', 'HMS-HMSn') And Exists (
                SELECT IGADST.Dataset_Type
                FROM t_instrument_group ING
                     INNER JOIN t_instrument_name InstName
                       ON ING.instrument_group = InstName.instrument_group
                     INNER JOIN t_instrument_group_allowed_ds_type IGADST
                       ON ING.instrument_group = IGADST.instrument_group
                WHERE InstName.instrument = _instrumentName AND
                      IGADST.dataset_type::citext = 'IMS-HMS-HMSn' ) Then

                -- This is an IMS MS/MS dataset
                _msType := 'IMS-HMS-HMSn';
                _datasetTypeID := public.get_dataset_type_id(_msType);

            Else
                -- Not an IMS dataset; change _datasetTypeID to zero so that the default dataset type is used
                _datasetTypeID := 0;
            End If;

            If _datasetTypeID = 0 Then
                _datasetTypeID := _defaultDatasetTypeID;

                _msTypeOld := _msType;

                -- Update _msType
                SELECT Dataset_Type
                INTO _msType
                FROM t_dataset_type_name
                WHERE dataset_type_id = _datasetTypeID;

                If _msTypeOld::citext = 'GC-MS' And _msType::citext = 'EI-HMS' Then
                    -- This happens for most datasets from instrument GCQE01; do not update the comment
                    _returnCode := '';
                End If;
            End If;

            -- Validate the new dataset type name (in case the default dataset type is invalid for this instrument group, which would indicate invalid data in table t_instrument_group)

            CALL public.validate_instrument_group_and_dataset_type (
                            _datasetType     => _msType,
                            _instrumentGroup => _instrumentGroup,   -- Input/Output
                            _datasetTypeID   => _datasetTypeID,     -- Output
                            _message         => _msg,               -- Output
                            _returnCode      => _returnCode);       -- Output

            If _returnCode <> '' Then
                _comment := public.append_to_text(_comment, 'Error: Default dataset type defined in t_instrument_group is invalid', _delimiter => ' - ');
            End If;
        End If;

        If _returnCode <> '' Then
            -- _msg should already contain the details of the error
            If Coalesce(_msg, '') = '' Then
                _msg := format('Validate_Instrument_Group_and_Dataset_Type returned non-zero result code: %s', _returnCode);
            End If;

            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Check for instrument changing when dataset not in new state
        ---------------------------------------------------

        If _mode::citext In ('update', 'check_update') and _instrumentID <> _curDSInstID and _curDSStateID <> 1 Then
            RAISE EXCEPTION 'Cannot change instrument if dataset not in "new" state';
        End If;

        ---------------------------------------------------
        -- Resolve user ID for operator username
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Query get_user_id with _operatorUsername = %s', _operatorUsername);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
        End If;

        _userID := public.get_user_id(_operatorUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _operatorUsername contains simply the username

            SELECT username
            INTO _operatorUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _operatorUsername
            -- Try to auto-resolve the name

            If _logDebugMessages Then
                _debugMsg := format('Call auto_resolve_name_to_username with _operatorUsername = %s', _operatorUsername);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            CALL public.auto_resolve_name_to_username (
                    _operatorUsername,
                    _matchCount       => _matchCount,   -- Output
                    _matchingUsername => _newUsername,  -- Output
                    _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _operatorUsername
                _operatorUsername := _newUsername;
            Else
                If _matchCount = 0 Then
                    RAISE EXCEPTION 'Invalid operator username: "%" does not exist', _operatorUsername;
                Else
                    RAISE EXCEPTION 'Invalid operator username: "%" matches more than one user', _operatorUsername;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Perform additional steps if a requested run ID was provided
        ---------------------------------------------------

        If _requestID <> 0 And _addingDataset Then
            ---------------------------------------------------
            -- Verify acceptable combination of EUS fields
            ---------------------------------------------------

            If _eusProposalID <> '' Or _eusUsageType <> '' Or _eusUsersList <> '' Then
                If (_eusUsageType::citext = '(lookup)' And _eusProposalID::citext = '(lookup)' And _eusUsersList::citext = '(lookup)') Or
                   (_eusUsageType::citext = '(ignore)') Then
                    _warning := '';
                Else
                    _warning := format('Warning: ignoring proposal ID, usage type, and user list since request %s was specified', _requestID);
                End If;

                -- When a request is specified, force _eusProposalID, _eusUsageType, and _eusUsersList to be blank
                -- Previously, we would raise an error here
                _eusProposalID := '';
                _eusUsageType := '';
                _eusUsersList := '';

                If _logDebugMessages Then
                    CALL post_log_entry ('Debug', _warning, 'Add_Update_Dataset');
                End If;
            End If;

            ---------------------------------------------------
            -- If the dataset starts with 'blank' but _requestID is non-zero, this is likely incorrect
            -- Auto-update things if this is the case
            ---------------------------------------------------

            If _datasetName::citext Like 'Blank%' Then
                -- See if the experiment matches for this request; if it doesn't, change _requestID to 0
                _experimentCheck := '';

                SELECT E.experiment
                INTO _experimentCheck
                FROM t_experiments E INNER JOIN
                     t_requested_run RR
                       ON E.exp_id = RR.exp_id
                WHERE RR.request_id = _requestID;

                If _experimentCheck <> _experimentName Then
                    _requestID := 0;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- If the dataset starts with 'Blank' and _requestID is zero, perform some additional checks
        ---------------------------------------------------

        If _requestID = 0 And _addingDataset Then
            -- If the EUS information is not defined, auto-define the EUS usage type as 'MAINTENANCE'
            If (_datasetName::citext SIMILAR TO 'Blank%' Or
                _datasetName::citext SIMILAR TO '%[_]Tune[_]%' Or
                _datasetName::citext SIMILAR TO '%TuneMix%'
               ) And
               _eusProposalID = '' And
               _eusUsageType = ''
            Then
                _eusUsageType := 'MAINTENANCE';
            End If;
        End If;

        ---------------------------------------------------
        -- Possibly look for an active requested run that we can auto-associate with this dataset
        ---------------------------------------------------

        If _requestID = 0 And _addingDataset Then

            If _logDebugMessages Then
                _debugMsg := format('Call Find_Active_Requested_Run_for_Dataset with _datasetName = %s', _datasetName);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            CALL public.find_active_requested_run_for_dataset (
                            _datasetName,
                            _experimentID,
                            _requestID         => _requestID,           -- Output
                            _requestInstGroup  => _requestInstGroup,    -- Output
                            _requestMatchCount => _requestMatchCount,   -- Output
                            _showDebugMessages => false);

            If _requestID > 0 Then
                -- Match found; check for an instrument group mismatch
                If _requestInstGroup::citext <> _instrumentGroup::citext Then
                    _warning := public.append_to_text(_warning,
                        format('Instrument group for requested run (%s) does not match instrument group for %s (%s)',
                               _requestInstGroup, _instrumentName, _instrumentGroup));
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Update the dataset comment if it starts with the requested run's comment
        ---------------------------------------------------

        If _requestID <> 0 And _addingDataset Then
            _reqRunComment := '';

            SELECT comment
            INTO _reqRunComment
            FROM t_requested_run
            WHERE request_id = _requestID;

            -- Assure that _reqRunComment doesn't have &quot; or &#34; or &amp;
            _reqRunComment := public.replace_character_codes(_reqRunComment);

            If Trim(Coalesce(_reqRunComment)) <> '' And (_comment = _reqRunComment Or _comment ILike _reqRunComment || '%') Then
                If char_length(_comment) = char_length(_reqRunComment) Then
                    _comment := '';
                Else
                    _comment := LTrim(Substring(_comment, char_length(_reqRunComment) + 1, char_length(_comment)));
                End If;
            End If;
        End If;

        -- Validation checks are complete; now enable _logErrors
        _logErrors := true;

        ---------------------------------------------------
        -- Action for dataset create task mode
        ---------------------------------------------------

        If _mode = 'add_dataset_create_task' Or _mode = 'add_trigger' Then

            If _requestID <> 0 Then
                ---------------------------------------------------
                -- Validate that experiments match
                -- (check code taken from consume_scheduled_run procedure)
                ---------------------------------------------------

                -- Get experiment ID from dataset; this was already done above

                -- Get experiment ID from scheduled run

                SELECT exp_id
                INTO _reqExperimentID
                FROM t_requested_run
                WHERE request_id = _requestID;

                -- Validate that experiments match

                If _experimentID <> _reqExperimentID Then
                    _message := format('Experiment for dataset (%s) does not match with the requested run''s experiment (Request %s)', _experimentName, _requestID);
                    RAISE EXCEPTION '%', _message;
                End If;
            End If;

            ---------------------------------------------------
            -- Resolve ID for LC Cart and update requested run table
            ---------------------------------------------------

            SELECT cart_id
            INTO _cartID
            FROM t_lc_cart
            WHERE cart_name = _lcCartName::citext;

            If Not FOUND Then
                RAISE EXCEPTION 'Unknown LC Cart name: %', _lcCartName;
            End If;

            If _requestID = 0 Then

                -- RequestID not specified
                -- Try to determine EUS information using Experiment name
                -- (Check code taken from Add_Update_Requested_Run procedure)

                ---------------------------------------------------
                -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
                -- This will update the data in _eusUsageType, _eusProposalID, or _eusUsersList if it is '(lookup)'
                ---------------------------------------------------

                CALL public.lookup_eus_from_experiment_sample_prep (
                                    _experimentName,
                                    _eusUsageType  => _eusUsageType,    -- Input/output
                                    _eusProposalID => _eusProposalID,   -- Input/output
                                    _eusUsersList  => _eusUsersList,    -- Input/output
                                    _message       => _msg,             -- Output
                                    _returnCode    => _returnCode);     -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION '%', _msg;
                End If;

                If Coalesce(_msg, '') <> '' Then
                    _message := public.append_to_text(_message, _msg);
                End If;

                ---------------------------------------------------
                -- Validate EUS type, proposal, and user list
                ---------------------------------------------------

                CALL public.validate_eus_usage (
                                _eusUsageType      => _eusUsageType,       -- Input/Output
                                _eusProposalID     => _eusProposalID,      -- Input/Output
                                _eusUsersList      => _eusUsersList,       -- Input/Output
                                _eusUsageTypeID    => _eusUsageTypeID,     -- Output
                                _autoPopulateUserListIfBlank => false,
                                _samplePrepRequest => false,
                                _experimentID      => _experimentID,
                                _campaignID        => 0,
                                _addingItem        => _addingDataset,
                                _infoOnly          => false,
                                _message           => _msg,                -- Output
                                _returnCode        => _returnCode          -- Output
                            );

                If _returnCode <> '' Then
                    _logErrors := false;
                    RAISE EXCEPTION '%', _msg;
                End If;

                If Coalesce(_msg, '') <> '' Then
                    _message := public.append_to_text(_message, _msg);
                End If;

            Else

                ---------------------------------------------------
                -- Verify that request ID is correct
                ---------------------------------------------------

                If Not Exists (SELECT request_id FROM t_requested_run WHERE request_id = _requestID) Then
                    RAISE EXCEPTION 'Request request_id not found';
                End If;

            End If;

            If _callingUser = '' Then
                _dsCreatorUsername := SESSION_USER;
            Else
                _dsCreatorUsername := _callingUser;
            End If;

            _runStart := '';
            _runFinish := '';

            If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                _warning := _message;
            End If;

            If _logDebugMessages Then
                _debugMsg := format('Create trigger for dataset %s, instrument %s, request %s', _datasetName, _instrumentName, _requestID);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            CALL public.add_new_dataset_to_creation_queue (
                            _datasetName,           -- Dataset name
                            _experimentName,        -- Experiment name
                            _instrumentName,        -- Instrument name
                            _secSep,                -- Separation type
                            _lcCartName,            -- LC cart
                            _lcCartConfig,          -- LC cart config
                            _lcColumnName,          -- LC column
                            _wellplateName,         -- Wellplate
                            _wellNumber,            -- Well number
                            _msType,                -- Datset type
                            _operatorUsername,      -- Operator username
                            _dsCreatorUsername,     -- Dataset creator username
                            _comment,               -- Comment
                            _rating,                -- Interest rating
                            _requestID,             -- Requested run ID
                            _workPackage,           -- Work package
                            _eusUsageType,          -- EUS usage type
                            _eusProposalID,         -- EUS proposal id
                            _eusUsersList,          -- EUS users list
                            _captureSubfolder,      -- Capture subfolder
                            _message => _message,               -- Output
                            _returnCode => _returnCode);        -- Output

            If _returnCode <> '' Then
                -- add_new_dataset_to_creation_queue should have already logged critical errors to t_log_entries
                -- No need for this procedure to log the message again
                _logErrors := false;
                RAISE EXCEPTION 'Error adding the new dataset to the creation queue: %', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            ---------------------------------------------------
            -- Lookup storage path ID
            ---------------------------------------------------

            _refDate := CURRENT_TIMESTAMP;

            If _logDebugMessages Then
                _debugMsg := format('Call Get_Instrument_Storage_Path_For_New_Datasets with _instrumentID = %s', _instrumentID);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            _storagePathID := public.get_instrument_storage_path_for_new_datasets(
                                        _instrumentID,
                                        _refDate,
                                        _autoSwitchActiveStorage => true,
                                        _infoOnly                => false);

            If _storagePathID = 0 Then
                _storagePathID := 2; -- index of 'none' in t_storage_path
                RAISE EXCEPTION 'Valid storage path could not be found';
            End If;

            If _logDebugMessages Then
                _debugMsg := format('Add dataset %s, instrument ID %s, storage path ID %s', _datasetName, _instrumentID, _storagePathID);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            BEGIN

                If Coalesce(_aggregationJobDataset, false) Then
                    _newDSStateID := 3;
                Else
                    _newDSStateID := 1;
                End If;

                If _logDebugMessages Then
                    RAISE INFO '%', 'Insert into t_dataset';
                End If;

                -- Insert values into a new row

                INSERT INTO t_dataset (
                    dataset,
                    operator_username,
                    comment,
                    created,
                    instrument_id,
                    dataset_type_ID,
                    well,
                    separation_type,
                    dataset_state_id,
                    folder_name,
                    storage_path_ID,
                    exp_id,
                    dataset_rating_id,
                    lc_column_ID,
                    wellplate,
                    internal_standard_ID,
                    capture_subfolder,
                    cart_config_id
                ) VALUES (
                    _datasetName,
                    _operatorUsername,
                    _comment,
                    _refDate,
                    _instrumentID,
                    _datasetTypeID,
                    _wellNumber,
                    _secSep,
                    _newDSStateID,
                    _folderName,
                    _storagePathID,
                    _experimentID,
                    _ratingID,
                    _columnID,
                    _wellplateName,
                    _intStdID,
                    _captureSubfolder,
                    _cartConfigID
                )
                RETURNING dataset_id
                INTO _datasetID;

                If Not FOUND Then
                    RAISE EXCEPTION 'Insert operation failed for dataset %', _datasetName;
                End If;

                -- As a precaution, query t_dataset using Dataset name to make sure we have the correct Dataset_ID

                SELECT dataset_id
                INTO _datasetIDConfirm
                FROM t_dataset
                WHERE dataset = _datasetName;

                If _datasetID <> Coalesce(_datasetIDConfirm, _datasetID) Then
                    _debugMsg := format('Warning: Inconsistent identity values when adding dataset %s: Found ID %s but the INSERT INTO query reported %s',
                                        _datasetName, _datasetIDConfirm, _datasetID);

                    CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Dataset');

                    _datasetID := _datasetIDConfirm;
                End If;

                -- If _callingUser is defined, Call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If _callingUser <> '' Then
                    If _logDebugMessages Then
                        RAISE INFO '%', 'Call public.alter_event_log_entry_user';
                    End If;

                    _targetType := 4;
                    CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _newDSStateID, _callingUser, _message => _alterEnteredByMessage);

                    _targetType := 8;
                    CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _ratingID,     _callingUser, _message => _alterEnteredByMessage);
                End If;

                ---------------------------------------------------
                -- If scheduled run is not specified, create one
                ---------------------------------------------------

                If _requestID = 0 Then

                    If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                        _warning := _message;
                    End If;

                    If _workPackage::citext In ('', 'none', 'na', '(lookup)') Then
                        If _logDebugMessages Then
                            RAISE INFO '%', 'Query Get_WP_for_EUS_Proposal';
                        End If;

                        SELECT work_package
                        INTO _workPackage
                        FROM public.get_wp_for_eus_proposal(_eusProposalID);
                    End If;

                    _requestName := format('AutoReq_%s', _datasetName);

                    If _logDebugMessages Then
                        RAISE INFO '%', 'Call Add_Update_Requested_Run';
                    End If;

                    -- Make a new requested run for the new dataset

                    CALL public.add_update_requested_run (
                                            _requestName => _requestName,
                                            _experimentName => _experimentName,
                                            _requesterUsername => _operatorUsername,
                                            _instrumentGroup => _instrumentGroup,
                                            _workPackage => _workPackage,
                                            _msType => _msType,
                                            _instrumentSettings => 'na',
                                            _wellplateName => NULL,
                                            _wellNumber => NULL,
                                            _internalStandard => 'na',
                                            _comment => 'Automatically created by Dataset entry',
                                            _batch => 0,
                                            _block => 0,
                                            _runOrder => 0,
                                            _eusProposalID => _eusProposalID,
                                            _eusUsageType => _eusUsageType,
                                            _eusUsersList => _eusUsersList,
                                            _mode => 'add-auto',
                                            _secSep => _secSep,
                                            _mrmAttachment => '',
                                            _status => 'Completed',
                                            _skipTransactionRollback => true,
                                            _autoPopulateUserListIfBlank => true,        -- Auto populate _eusUsersList if blank since this is an Auto-Request
                                            _callingUser => _callingUser,
                                            _vialingConc => null,
                                            _vialingVol => null,
                                            _stagingLocation => null,
                                            _requestIDForUpdate => null,
                                            _logDebugMessages => _logDebugMessages,
                                            _request => _requestID,                                 -- Output
                                            _resolvedInstrumentInfo => _resolvedInstrumentInfo,     -- Output
                                            _message => _message,                                   -- Output
                                            _returnCode => _returnCode);                            -- Output

                    If _returnCode <> '' Then
                        If _eusProposalID = '' And _eusUsageType = '' and _eusUsersList = '' Then
                            _msg := format('Create AutoReq run request failed: dataset %s; EUS Proposal ID, Usage Type, and Users list cannot all be blank -> %s',
                                            _msType, _message);
                        Else
                            _msg := format('Create AutoReq run request failed: dataset %s with Proposal ID "%s", Usage Type "%s", Users List "%s" and Work Package "%s" -> %s',
                                            _datasetName, _eusProposalID, _eusUsageType, _eusUsersList, _workPackage, _message);
                        End If;

                        _logErrors := false;

                        RAISE EXCEPTION '%', _msg;
                    End If;
                End If;

                ---------------------------------------------------
                -- If a cart name is specified, update it for the requested run
                ---------------------------------------------------

                If _requestID > 0 And Not _lcCartName::citext In ('', 'no update') Then

                    If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                        _warning := _message;
                    End If;

                    If _logDebugMessages Then
                        RAISE INFO '%', 'Call update_cart_parameters with _mode="CartName"';
                    End If;

                    CALL public.update_cart_parameters (
                                        'CartName',
                                        _requestID,
                                        _newValue   => _lcCartName,
                                        _message    => _message,        -- Output
                                        _returnCode => _returnCode);    -- Output

                    If _returnCode <> '' Then
                        RAISE EXCEPTION 'Update LC cart name failed: dataset % -> %',_datasetName, _message;
                    End If;
                End If;

                ---------------------------------------------------
                -- If _cartConfigID is a positive number, update it for the requested run
                ---------------------------------------------------

                If _requestID > 0 And _cartConfigID > 0 Then

                    If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                        _warning := _message;
                    End If;

                    If _logDebugMessages Then
                        RAISE INFO '%', 'Call update_cart_parameters with _mode="CartConfigID"';
                    End If;

                    CALL public.update_cart_parameters (
                                        'CartConfigID',
                                        _requestID,
                                        _newValue   => _cartConfigID::text,
                                        _message    => _message,        -- Output
                                        _returnCode => _returnCode);    -- Output

                    If _returnCode <> '' Then
                        RAISE EXCEPTION 'Update cart config ID failed: dataset % -> %',_datasetName, _message;
                    End If;
                End If;

                ---------------------------------------------------
                -- Consume the scheduled run
                ---------------------------------------------------

                _datasetID := 0;

                SELECT dataset_id
                INTO _datasetID
                FROM t_dataset
                WHERE dataset = _datasetName;

                If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                    _warning := _message;
                End If;

                If _logDebugMessages Then
                    RAISE INFO 'Call consume_scheduled_run';
                End If;

                CALL public.consume_scheduled_run (
                            _datasetID,
                            _requestID,
                            _message          => _message,          -- Output
                            _callingUser      => _callingUser,
                            _logDebugMessages => _logDebugMessages,
                            _returnCode       => _returnCode);      -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Consume operation failed: dataset % -> %', _datasetName, _message;
                End If;

            END;

            If _logDebugMessages Then
                _debugMsg := format('Call update_cached_dataset_instruments with _datasetId = %s', _datasetId);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            -- Update t_cached_dataset_instruments
            CALL public.update_cached_dataset_instruments (
                                _processingMode => 0,
                                _datasetId      => _datasetID,
                                _infoOnly       => false,
                                _message        => _message,        -- Output
                                _returnCode     => _returnCode);    -- Output

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            If _logDebugMessages Then
                _debugMsg := format('Update dataset %s (Dataset ID %s)', _datasetName, _datasetID);
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Update_Dataset');
            End If;

            UPDATE t_dataset
            SET operator_username    = _operatorUsername,
                comment              = _comment,
                dataset_type_ID      = _datasetTypeID,
                well                 = _wellNumber,
                separation_type      = _secSep,
                folder_name          = _folderName,
                exp_id               = _experimentID,
                dataset_rating_id    = _ratingID,
                lc_column_ID         = _columnID,
                wellplate            = _wellplateName,
                internal_standard_ID = _intStdID,
                capture_subfolder    = _captureSubfolder,
                cart_config_id       = _cartConfigID
            WHERE dataset_id = _datasetID;

            -- If _callingUser is defined, Call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If _callingUser <> '' And _ratingID <> Coalesce(_curDSRatingID, -1000) Then
                _targetType := 8;
                CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _ratingID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Lookup the Requested Run info for this dataset

            SELECT RR.request_id,
                   RR.request_name,
                   RR.instrument_setting,
                   RR.work_package,
                   RR.wellplate,
                   RR.well,
                   RR.comment,
                   RR.request_internal_standard,
                   RR.mrm_attachment,
                   RR.state_name
            INTO _requestID,
                 _requestName,
                 _reqRunInstSettings,
                 _workPackageFromRequest,
                 _wellplateNameFromRequest,
                 _wellNumberFromRequest,
                 _reqRunComment,
                 _reqRunInternalStandard,
                 _mrmAttachmentID,
                 _reqRunStatus
            FROM t_dataset DS
                 INNER JOIN t_requested_run RR
                   ON DS.dataset_id = RR.dataset_id
            WHERE DS.dataset_id = _datasetID;

            If Not FOUND Then
                _requestID := 0;
            Else
                If Coalesce(_workPackageFromRequest, '') <> '' Then
                    _workPackage := _workPackageFromRequest;
                End If;

                If Coalesce(_wellplateName, '') = '' And Coalesce(_wellplateNameFromRequest, '') <> '' Then
                    _wellplateName := _wellplateNameFromRequest;
                End If;

                If Coalesce(_wellNumber, '') = '' And Coalesce(_wellNumberFromRequest, '') <> '' Then
                    _wellNumber := _wellNumberFromRequest;
                End If;
            End If;

            ---------------------------------------------------
            -- If a cart name is specified, update it for the requested run
            ---------------------------------------------------

            If Not _lcCartName::citext In ('', 'no update') Then

                If Coalesce(_requestID, 0) = 0 Then
                    _warningAddon := 'Dataset is not associated with a requested run; cannot update the LC Cart Name';
                    _warning := public.append_to_text(_warning, _warningAddon);
                Else

                    CALL public.update_cart_parameters (
                                        'CartName',
                                        _requestID,
                                        _lcCartName,
                                        _message    => _warningAddon,   -- Output
                                        _returnCode => _returnCode);    -- Output

                    If _returnCode <> '' Then
                        _warningAddon := format('Update LC cart name failed: %s', _warningAddon);
                        _warning := public.append_to_text(_warning, _warningAddon);
                        _returnCode := '';
                    End If;
                End If;
            End If;

            ---------------------------------------------------
            -- If _cartConfigID is a positive number, update it for the requested run
            ---------------------------------------------------

            If _requestID > 0 And _cartConfigID > 0 Then

                CALL public.update_cart_parameters (
                                    'CartConfigID',
                                    _requestID,
                                    _newValue   => _cartConfigID::text,
                                    _message    => _warningAddon,   -- Output
                                    _returnCode => _returnCode);    -- Output

                If _returnCode <> '' Then
                    _warningAddon := format('Update cart config ID failed: %s', _warningAddon);
                    _warning := public.append_to_text(_warning, _warningAddon);
                    _returnCode := '';
                End If;
            End If;

            If _requestID > 0 And _eusUsageType <> '' Then

                -- Lookup Batch ID, Block, and Run Order

                SELECT batch_id,
                       block,
                       run_order
                INTO _batchID, _block, _runOrder
                FROM t_requested_run
                WHERE request_id = _requestID;

                _batchID  := Coalesce(_batchID, 0);
                _block    := Coalesce(_block, 0);
                _runOrder := Coalesce(_runOrder, 0);

                CALL public.add_update_requested_run (
                                    _requestName                 => _requestName,
                                    _experimentName              => _experimentName,
                                    _requesterUsername           => _operatorUsername,
                                    _instrumentGroup             => _instrumentGroup,
                                    _workPackage                 => _workPackage,
                                    _msType                      => _msType,
                                    _instrumentSettings          => _reqRunInstSettings,
                                    _wellplateName               => _wellplateName,
                                    _wellNumber                  => _wellNumber,
                                    _internalStandard            => _reqRunInternalStandard,
                                    _comment                     => _reqRunComment,
                                    _batch                       => _batchID,
                                    _block                       => _block,
                                    _runOrder                    => _runOrder,
                                    _eusProposalID               => _eusProposalID,
                                    _eusUsageType                => _eusUsageType,
                                    _eusUsersList                => _eusUsersList,
                                    _mode                        => 'update',
                                    _secSep                      => _secSep,
                                    _mrmAttachment               => _mrmAttachmentID::text,
                                    _status                      => _reqRunStatus,
                                    _skipTransactionRollback     => true,
                                    _autoPopulateUserListIfBlank => true,   -- Auto populate _eusUsersList if blank since this is an Auto-Request
                                    _callingUser                 => _callingUser,
                                    _vialingConc                 => null,
                                    _vialingVol                  => null,
                                    _stagingLocation             => null,
                                    _requestIDForUpdate          => null,
                                    _logDebugMessages            => _logDebugMessages,
                                    _request                     => _requestID,                 -- Output
                                    _resolvedInstrumentInfo      => _resolvedInstrumentInfo,    -- Output
                                    _message                     => _message,                   -- Output
                                    _returnCode                  => _returnCode);               -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Requested run update error using Proposal ID "%", Usage Type "%", Users List "%" and Work Package "%" ->%',
                                    _eusProposalID, _eusUsageType, _eusUsersList, _workPackage, _message;
                End If;
            End If;

            ---------------------------------------------------
            -- If rating changed from -5, -6, or -7 to 5, check if any jobs exist for this dataset
            -- If no jobs are found, Call schedule_predefined_analysis_jobs for this dataset
            -- Skip jobs with dataset_unreviewed = 1 when looking for existing jobs (these jobs were created before the dataset was dispositioned)
            ---------------------------------------------------

            If _ratingID >= 2 And Coalesce(_curDSRatingID, -1000) In (-5, -6, -7) Then
                If Not Exists (SELECT dataset_id FROM t_analysis_job WHERE dataset_id = _datasetID AND dataset_unreviewed = 0) Then
                    CALL public.schedule_predefined_analysis_jobs (
                                    _datasetName,
                                    _callingUser => _callingUser,
                                    _message     => _message,       -- Output
                                    _returnCode  => _returnCode);   -- Output

                    -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field
                    -- in t_event_log for any newly created jobs for this dataset

                    If _callingUser <> '' Then
                        _jobStateID := 1;

                        CREATE TEMP TABLE Tmp_ID_Update_List (
                            TargetID int NOT NULL
                        );

                        INSERT INTO Tmp_ID_Update_List (TargetID)
                        SELECT job
                        FROM t_analysis_job
                        WHERE dataset_id = _datasetID;

                        _targetType := 5;
                        CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _jobStateID, _callingUser, _message => _alterEnteredByMessage);

                        DROP TABLE Tmp_ID_Update_List;
                    End If;

                End If;
            End If;

            -- Update t_cached_dataset_instruments
            CALL public.update_cached_dataset_instruments (
                            _processingMode => 0,
                            _datasetId      => _datasetID,
                            _infoOnly       => false,
                            _message        => _message,        -- Output
                            _returnCode     => _returnCode);    -- Output

        End If;

        -- Update _message if _warning is not empty
        If Coalesce(_warning, '') <> '' Then

            If _warning Like 'Warning:' Then
                _warningWithPrefix := _warning;
            Else
                _warningWithPrefix := format('Warning: %s', _warning);
            End If;

            If Coalesce(_message, '') = '' Then
                _message := _warningWithPrefix;
            ElsIf _message = _warning Then
                _message := _warningWithPrefix;
            Else
                _message := format('%s; %s', _warningWithPrefix, _message);
            End If;
        End If;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Dataset %s', _exceptionMessage, _datasetName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_ID_Update_List;
END
$$;


ALTER PROCEDURE public.add_update_dataset(IN _datasetname text, IN _experimentname text, IN _operatorusername text, IN _instrumentname text, IN _mstype text, IN _lccolumnname text, IN _wellplatename text, IN _wellnumber text, IN _secsep text, IN _internalstandards text, IN _comment text, IN _rating text, IN _lccartname text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _requestid integer, IN _workpackage text, IN _mode text, IN _callinguser text, IN _aggregationjobdataset boolean, IN _capturesubfolder text, IN _lccartconfig text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_dataset(IN _datasetname text, IN _experimentname text, IN _operatorusername text, IN _instrumentname text, IN _mstype text, IN _lccolumnname text, IN _wellplatename text, IN _wellnumber text, IN _secsep text, IN _internalstandards text, IN _comment text, IN _rating text, IN _lccartname text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _requestid integer, IN _workpackage text, IN _mode text, IN _callinguser text, IN _aggregationjobdataset boolean, IN _capturesubfolder text, IN _lccartconfig text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_dataset(IN _datasetname text, IN _experimentname text, IN _operatorusername text, IN _instrumentname text, IN _mstype text, IN _lccolumnname text, IN _wellplatename text, IN _wellnumber text, IN _secsep text, IN _internalstandards text, IN _comment text, IN _rating text, IN _lccartname text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _requestid integer, IN _workpackage text, IN _mode text, IN _callinguser text, IN _aggregationjobdataset boolean, IN _capturesubfolder text, IN _lccartconfig text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text) IS 'AddUpdateDataset';


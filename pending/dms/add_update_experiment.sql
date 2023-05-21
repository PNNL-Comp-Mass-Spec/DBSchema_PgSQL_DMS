--
CREATE OR REPLACE PROCEDURE public.add_update_experiment
(
    INOUT _experimentId int,
    _experimentName text,
    _campaignName text,
    _researcherUsername text,
    _organismName text,
    _reason text = 'na',
    _comment text = '',
    _sampleConcentration text = 'na',
    _enzymeName text = 'Trypsin',
    _labNotebookRef text = 'na',
    _labelling text = 'none',
    _biomaterialList text = '',
    _referenceCompoundList text = '',
    _samplePrepRequest int = 0,
    _internalStandard text,
    _postdigestIntStd text,
    _wellplateName text,
    _wellNumber text,
    _alkylation text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _container text = 'na',
    _barcode text = '',
    _tissue text = '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new experiment to DB
**
**      Note that the Experiment Detail Report web page
**      uses DoMaterialItemOperation to retire an experiment
**
**  Arguments:
**    _experimentId            Input/output; When copying an experiment, this will have the new experiment's ID; this is required if renaming an existing experiment
**    _experimentName          Experiment name
**    _referenceCompoundList   Semicolon separated list of reference compound IDs; supports integers, or names of the form 3311:ANFTSQETQGAGK
**    _mode                    'add, 'update', 'check_add', 'check_update'
**
**  Auth:   grk
**  Date:   01/8/2002 - initial release
**          08/25/2004 jds - updated proc to add T_Enzyme table value
**          06/10/2005 grk - added handling for sample prep request
**          10/28/2005 grk - added handling for internal standard
**          11/11/2005 grk - added handling for postdigest internal standard
**          11/21/2005 grk - fixed update error for postdigest internal standard
**          01/12/2007 grk - added verification mode
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**          04/30/2007 grk - added better name validation (Ticket #450)
**          02/13/2008 mem - Now checking for _badCh = 'space' (Ticket #602)
**          03/13/2008 grk - added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter _callingUser
**          03/25/2008 mem - Now calling alter_event_log_entry_user if _callingUser is not blank (Ticket #644)
**          07/16/2009 grk - added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          12/01/2009 grk - modified to skip checking of existing well occupancy if updating existing experiment
**          04/22/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _researcherPRN contains a person's real name rather than their username
**          05/18/2010 mem - Now validating that _internalStandard and _postdigestIntStd are active internal standards when creating a new experiment (_mode is 'add' or 'check_add')
**          11/15/2011 grk - added alkylation field
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in _comment
**          03/26/2012 mem - Now validating _container
**                         - Updated to validate additional terms when _mode = 'check_add'
**          11/15/2012 mem - Now updating _biomaterialList to replace commas with semicolons
**          04/03/2013 mem - Now requiring that the experiment name be at least 6 characters in length
**          05/09/2014 mem - Expanded _campaignName from varchar(50) to varchar(64)
**          09/09/2014 mem - Added _barcode
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          07/31/2015 mem - Now updating Last_Used when key fields are updated
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Update error messages to use user-friendly entity names (e.g. campaign name instead of campaignNum)
**          09/14/2016 mem - Validate inputs
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          11/23/2016 mem - Include the experiment name when calling PostLogEntry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          01/24/2017 mem - Fix validation of _labelling to raise an error when the label name is unknown
**          01/27/2017 mem - Change _internalStandard and _postdigestIntStd to 'none' if empty
**          03/17/2017 mem - Only call MakeTableFromListDelim if _biomaterialList contains a semicolon
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/18/2017 mem - Add parameter _tissue (tissue name, e.g. hypodermis)
**          09/01/2017 mem - Allow _tissue to be a BTO ID (e.g. BTO:0000131)
**          11/29/2017 mem - Call udfParseDelimitedList instead of MakeTableFromListDelim
**                           Rename #CC to Tmp_ExpToCCMap
**                           No longer pass _biomaterialList to AddExperimentCellCulture since it uses Tmp_ExpToCCMap
**                           Remove references to the Cell_Culture_List field in T_Experiments (procedure AddExperimentCellCulture calls UpdateCachedExperimentInfo)
**                           Add argument _referenceCompoundList
**          01/04/2018 mem - Entries in _referenceCompoundList are now assumed to be in the form Compound_ID:Compound_Name, though we also support only Compound_ID or only Compound_Name
**          07/30/2018 mem - Expand _reason and _comment to varchar(500)
**          11/27/2018 mem - Check for _referenceCompoundList having '100:(none)'
**                           Remove items from Tmp_ExpToRefCompoundMap that map to the reference compound named (none)
**          11/30/2018 mem - Add output parameter _experimentID
**          03/27/2019 mem - Update _experimentId using _existingExperimentID
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/25/2021 mem - Use ReplaceCharacterCodes to replace character codes with punctuation marks
**                         - Use RemoveCrLf to replace linefeeds with semicolons
**          07/06/2021 mem - Expand _organismName and _labNotebookRef to varchar(128)
**          09/30/2021 mem - Allow renaming an experiment if it does not have an associated requested run or dataset
**                         - Move argument _experimentID, making it the first argument
**                         - Rename the Experiment, Campaign, and Wellplate name arguments
**          11/26/2022 mem - Rename parameter to _biomaterialList
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _invalidBiomaterialList text := null;
    _invalidRefCompoundList text;
    _existingExperimentID int := 0;
    _existingExperimentName text := '';
    _existingRequestedRun text := '';
    _existingDataset text := '';
    _curContainerID int := 0;
    _badCh text;
    _tissueIdentifier text;
    _tissueName text;
    _campaignID int;
    _userID int;
    _matchCount int;
    _newUsername text;
    _organismID int := 0;
    _totalCount int;
    _wellIndex int;
    _enzymeID int := 0;
    _labelID int := 0;
    _internalStandardID int := 0;
    _internalStandardState char := 'I';
    _postdigestIntStdID int := 0;
    _contID int := 0;
    _curContainerName text := '';
    _expIDConfirm int := 0;
    _debugMsg text;
    _stateID int := 1;
    _logMessage text;

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

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        _experimentID := Coalesce(_experimentID, 0);
        _experimentName := Trim(Coalesce(_experimentName, ''));
        _campaignName := Trim(Coalesce(_campaignName, ''));
        _researcherUsername := Trim(Coalesce(_researcherUsername, ''));
        _organismName := Trim(Coalesce(_organismName, ''));
        _reason := Trim(Coalesce(_reason, ''));
        _comment := Trim(Coalesce(_comment, ''));
        _enzymeName := Trim(Coalesce(_enzymeName, ''));
        _labelling := Trim(Coalesce(_labelling, ''));
        _biomaterialList := Trim(Coalesce(_biomaterialList, ''));
        _referenceCompoundList := Trim(Coalesce(_referenceCompoundList, ''));
        _internalStandard := Trim(Coalesce(_internalStandard, ''));
        _postdigestIntStd := Trim(Coalesce(_postdigestIntStd, ''));
        _alkylation := Trim(Coalesce(_alkylation, ''));

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If char_length(_experimentName) < 1 Then
            RAISE EXCEPTION 'Experiment name must be defined';
        End If;
        --
        If char_length(_campaignName) < 1 Then
            RAISE EXCEPTION 'Campaign name must be defined';
        End If;
        --
        If char_length(_researcherUsername) < 1 Then
            RAISE EXCEPTION 'Researcher Username must be defined';
        End If;
        --
        If char_length(_organismName) < 1 Then
            RAISE EXCEPTION 'Organism name must be defined';
        End If;
        --
        If char_length(_reason) < 1 Then
            RAISE EXCEPTION 'Reason cannot be blank';
        End If;
        --
        If char_length(_labelling) < 1 Then
            RAISE EXCEPTION 'Labelling cannot be blank';
        End If;

        If Not _alkylation::citext IN ('Y', 'N') Then
            RAISE EXCEPTION 'Alkylation must be Y or N';
        End If;

        -- Assure that _comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
        _comment := public.replace_character_codes(_comment);

        -- Replace instances of CRLF (or LF) with semicolons
        _comment := public.remove_cr_lf(_comment);

        -- Auto change empty internal standards to 'none' since now rarely used
        If _internalStandard = '' Then
            _internalStandard := 'none';
        End If;

        If _postdigestIntStd= '' Then
            _postdigestIntStd := 'none';
        End If;

        ---------------------------------------------------
        -- Validate experiment name
        ---------------------------------------------------

        _badCh := public.validate_chars(_experimentName, '');

        If _badCh <> '' Then
            If _badCh = 'space' Then
                RAISE EXCEPTION 'Experiment name may not contain spaces';
            Else
                RAISE EXCEPTION 'Experiment name may not contain the character(s) "%"', _badCh;
            End If;
        End If;

        If char_length(_experimentName) < 6 Then
            _msg := ('Experiment name must be at least 6 characters in length; currently %s characters', char_length(_experimentName));
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve _tissue to BTO identifier
        ---------------------------------------------------

        CALL get_tissue_id (
                _tissueNameOrID => _tissue,
                _tissueIdentifier => _tissueIdentifier output,
                _tissueName => _tissueName output,
                _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'Could not resolve tissue name or id: "%"', _tissue;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode::citext In ('update', 'check_update') And _experimentID > 0 Then
            Select exp_id,
                   experiment,
                   container_id
            INTO _existingExperimentID, _existingExperimentName, _curContainerID
            FROM t_experiments
            WHERE exp_id = _experimentID;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: Experiment ID % is not in database', _experimentID;
            End If;

            If _existingExperimentName <> _experimentName Then
                -- Allow renaming if the experiment is not associated with a dataset or requested run, and if the new name is unique

                If Exists (Select * From t_experiments Where experiment = _experimentName) Then
                    SELECT exp_id
                    INTO _existingExperimentID
                    FROM t_experiments
                    WHERE experiment = _experimentName
                    --
                    RAISE EXCEPTION 'Cannot rename: Experiment "%" already exists, with ID %', _experimentName, _existingExperimentID;
                End If;

                If Exists (Select * From t_dataset Where exp_id = _experimentID) Then
                    SELECT dataset
                    INTO _existingDataset
                    FROM t_dataset
                    WHERE exp_id = _experimentID
                    --
                    RAISE EXCEPTION 'Cannot rename: Experiment ID % is associated with dataset "%"', _experimentID, _existingDataset;
                End If;

                If Exists (Select * From t_requested_run Where exp_id = _experimentID) Then
                    SELECT request_name
                    INTO _existingRequestedRun
                    FROM t_requested_run
                    WHERE exp_id = _experimentID
                    --
                    RAISE EXCEPTION 'Cannot rename: Experiment ID % is associated with requested run "%"', _experimentID, _existingRequestedRun;
                End If;
            End If;
        Else
            -- Either _mode is 'add' or 'check_add' or _experimentID is null or 0
            -- Look for the experiment by name

            SELECT exp_id,
                   container_id
            INTO _existingExperimentID, _curContainerID
            FROM t_experiments
            WHERE experiment = _experimentName;

            If _mode::citext In ('update', 'check_update') And Not FOUND Then
                RAISE EXCEPTION 'Cannot update: Experiment "%" is not in database', _experimentName;
            End If;

            -- Assure that _experimentId is up-to-date
            _experimentId := _existingExperimentID;
        End If;

        -- Cannot create an entry that already exists
        --
        If _existingExperimentID <> 0 and (_mode::citext In ('add', 'check_add')) Then
            RAISE EXCEPTION 'Cannot add: Experiment "%" already in database; cannot add', _experimentName;
        End If;

        ---------------------------------------------------
        -- Resolve campaign ID
        ---------------------------------------------------

        _campaignID := get_campaign_id (_campaignName);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for campaign "%"', _campaignName;
        End If;

        ---------------------------------------------------
        -- Resolve researcher username
        ---------------------------------------------------

        _userID := public.get_user_id (_researcherUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _researcherUsername contains simply the username
            --
            SELECT username
            INTO _researcherUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _researcherUsername
            -- Try to auto-resolve the name

            CALL auto_resolve_name_to_username (_researcherUsername, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match found; update _researcherUsername
                _researcherUsername := _newUsername;
            Else
                RAISE EXCEPTION 'Could not find entry in database for researcher username "%"', _researcherUsername;
            End If;

        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := get_organism_id(_organismName);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for organism name "%"', _organismName;
        End If;

        ---------------------------------------------------
        -- Set up and validate wellplate values
        ---------------------------------------------------
        --
        If _mode::citext In ('add', 'check_add') THEN
            _totalCount := 1;
        Else
            _totalCount := 0;
        End If;
        --
        CALL validate_wellplate_loading (
                                _wellplateName => _wellplateName,   -- Output
                                _wellNumber => _wellNumber,         -- Output
                                _totalCount => _totalCount,
                                _wellIndex => _wellIndex,           -- Output
                                _message => _message,               -- Output
                                _returnCode => _returnCode);        -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'ValidateWellplateLoading: %', _msg;
        End If;

        -- Make sure we do not put two experiments in the same place
        --
        If exists (SELECT * FROM t_experiments WHERE wellplate = _wellplateName AND well = _wellNumber) AND _mode::citext In ('add', 'check_add') Then
            RAISE EXCEPTION 'There is another experiment assigned to the same wellplate and well';
        End If;
        --
        If exists (SELECT * FROM t_experiments WHERE wellplate = _wellplateName AND well = _wellNumber AND experiment <> _experimentName) AND _mode::citext In ('update', 'check_update') Then
            RAISE EXCEPTION 'There is another experiment assigned to the same wellplate and well';
        End If;

        ---------------------------------------------------
        -- Resolve enzyme ID
        ---------------------------------------------------

        SELECT enzyme_id
        INTO _enzymeID
        FROM t_enzymes
        WHERE enzyme_name::citext = _enzymeName::citext;

        If Not FOUND Then
            If _enzymeName = 'na' Then
                RAISE EXCEPTION 'The enzyme cannot be "%"; use No_Enzyme if enzymatic digestion was not used', _enzymeName;
            Else
                RAISE EXCEPTION 'Could not find entry in database for enzyme "%"', _enzymeName;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve labelling ID
        ---------------------------------------------------
        --
        SELECT label_id
        INTO _labelID
        FROM t_sample_labelling
        WHERE label::citext = _labelling::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Could not find entry in database for labelling "%"; use "none" if unlabeled', _labelling;
        End If;

        ---------------------------------------------------
        -- Resolve predigestion internal standard ID
        -- If creating a new experiment, make sure the internal standard is active
        ---------------------------------------------------

        --
        SELECT internal_standard_id, active
        INTO _internalStandardID, _internalStandardState
        FROM t_internal_standards
        WHERE name::citext = _internalStandard::citext;
        --
        If Not FOUND Then
            RAISE EXCEPTION 'Could not find entry in database for predigestion internal standard "%"', _internalStandard;
        End If;

        If (_mode::citext In ('add', 'check_add')) And _internalStandardState <> 'A' Then
            RAISE EXCEPTION 'Predigestion internal standard "%" is not active; this standard cannot be used when creating a new experiment', _internalStandard;
        End If;

        ---------------------------------------------------
        -- Resolve postdigestion internal standard ID
        ---------------------------------------------------
        --
        _internalStandardState := 'I';
        --
        SELECT internal_standard_id active
        INTO _postdigestIntStdID, _internalStandardState
        FROM t_internal_standards
        WHERE name::citext = _postdigestIntStd::citext;
        --
        If Not FOUND Then
            RAISE EXCEPTION 'Could not find entry in database for postdigestion internal standard "%"', _postdigestIntStd;
        End If;

        If (_mode::citext In ('add', 'check_add')) And _internalStandardState <> 'A' Then
            RAISE EXCEPTION 'Postdigestion internal standard "%" is not active; this standard cannot be used when creating a new experiment', _postdigestIntStd;
        End If;

        ---------------------------------------------------
        -- Resolve container name to ID
        -- Auto-switch name from 'none' to 'na'
        ---------------------------------------------------

        If _container::citext = 'none'::citext Then
            _container := 'na';
        End If;

        SELECT container_id
        INTO _contID
        FROM t_material_containers
        WHERE container::citext = _container::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid container name "%"', _container;
        End If;

        ---------------------------------------------------
        -- Resolve current container id to name
        -- (skip if adding experiment)
        ---------------------------------------------------
        --
        If Not _mode::citext In ('add', 'check_add') Then
            SELECT container
            INTO _curContainerName
            FROM t_material_containers
            WHERE container_id = _curContainerID;

        ---------------------------------------------------
        -- Create temporary tables to hold biomaterial and reference compounds associated with the parent experiment
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Experiment_to_Biomaterial_Map (
            Biomaterial_Name text not null,
            Biomaterial_ID int null
        )

        CREATE TEMP TABLE Tmp_ExpToRefCompoundMap (
            Compound_IDName text not null,
            Colon_Pos int null,
            Compound_ID int null
        )

        ---------------------------------------------------
        -- Resolve biomaterial
        -- Auto-switch from 'none' or 'na' or '(none)' to ''
        ---------------------------------------------------

        If _biomaterialList::citext IN ('none', 'na', '(none)') Then
            _biomaterialList := '';
        End If;

        -- Replace commas with semicolons
        If _biomaterialList Like '%,%' Then
            _biomaterialList := Replace(_biomaterialList, ',', ';');
        End If;

        -- Get biomaterial names from list argument into table
        --
        If _biomaterialList Like '%;%' Then
            INSERT INTO Tmp_Experiment_to_Biomaterial_Map (Biomaterial_Name)
            SELECT Value
            FROM public.parse_delimited_list(_biomaterialList, ';')
        ElsIf _biomaterialList <> ''
            INSERT INTO Tmp_Experiment_to_Biomaterial_Map (Biomaterial_Name)
            VALUES (_biomaterialList)
        End If;

        -- Verify that biomaterial items exist
        --
        UPDATE Tmp_Experiment_to_Biomaterial_Map Src
        SET Biomaterial_ID = Src.Biomaterial_ID
        FROM T_Biomaterial Src
        WHERE Src.Biomaterial_Name = Target.Biomaterial_Name

        SELECT string_agg(Biomaterial_Name, ', ' ORDER BY Biomaterial_Name)
        INTO _invalidBiomaterialList
        FROM Tmp_Experiment_to_Biomaterial_Map
        WHERE Biomaterial_ID IS NULL

        If Coalesce(_invalidBiomaterialList, '') <> '' Then
            RAISE EXCEPTION 'Invalid biomaterial name(s): %', _invalidBiomaterialList;
        End If;

        ---------------------------------------------------
        -- Resolve reference compounds
        -- Auto-switch from 'none' or 'na' or '(none)' to ''
        ---------------------------------------------------

        If _referenceCompoundList::citext IN ('none', 'na', '(none)', '100:(none)') Then
            _referenceCompoundList := '';
        End If;

        -- Replace commas with semicolons
        If _referenceCompoundList Like '%,%' Then
            _referenceCompoundList := Replace(_referenceCompoundList, ',', ';');
        End If;

        -- Get names of reference compounds from list argument into table
        --
        If _referenceCompoundList Like '%;%' Then
            INSERT INTO Tmp_ExpToRefCompoundMap (Compound_IDName, Colon_Pos)
            SELECT Value, Position(':' In Value)
            FROM public.parse_delimited_list(_referenceCompoundList, ';')
        ElsIf _referenceCompoundList <> ''
            INSERT INTO Tmp_ExpToRefCompoundMap (Compound_IDName, Colon_Pos)
            VALUES (_referenceCompoundList, Position(':' In _referenceCompoundList))
        End If;

        -- Update entries in Tmp_ExpToRefCompoundMap to remove extra text that may be present
        -- For example, switch from 3311:ANFTSQETQGAGK to 3311
        UPDATE Tmp_ExpToRefCompoundMap
        SET Compound_IDName = Substring(Compound_IDName, 1, Colon_Pos - 1)
        WHERE Not Colon_Pos Is Null And Colon_Pos > 0

        -- Populate the Compound_ID column using any integers in Compound_IDName
        UPDATE Tmp_ExpToRefCompoundMap
        SET Compound_ID = public.try_cast(Compound_IDName, null::int)

        -- If any entries still have a null Compound_ID value, try matching via reference compound name
        -- We have numerous reference compounds with identical names, so matches found this way will be ambiguous
        --
        UPDATE Tmp_ExpToRefCompoundMap Src
        SET Compound_ID = Src.Compound_ID
        FROM t_reference_compound Src
        WHERE Src.compound_name = Target.Compound_IDName AND
              Target.compound_id IS Null;

        -- Delete any entries to where the name is '(none)'
        DELETE Tmp_ExpToRefCompoundMap
        FROM t_reference_compound Src
        WHERE Src.compound_id = Target.compound_id And
              Src.compound_name = '(none)';

        ---------------------------------------------------
        -- Look for invalid entries in Tmp_ExpToRefCompoundMap
        ---------------------------------------------------
        --

        -- First look for entries without a Compound_ID
        --
        _invalidRefCompoundList := null;

        SELECT string_agg(Compound_IDName, ', ' ORDER BY Compound_IDName)
        INTO _invalidRefCompoundList
        FROM Tmp_ExpToRefCompoundMap
        WHERE Compound_ID IS NULL;

        If char_length(Coalesce(_invalidRefCompoundList, '')) > 0 Then
            RAISE EXCEPTION 'Invalid reference compound name(s): %', _invalidRefCompoundList;
        End If;

        -- Next look for entries with an invalid Compound_ID
        --
        _invalidRefCompoundList := null;

        SELECT string_agg(Compound_IDName, ', ' ORDER BY Compound_IDName)
        INTO _invalidRefCompoundList
        FROM Tmp_ExpToRefCompoundMap Src
             LEFT OUTER JOIN t_reference_compound RC
               ON Src.compound_id = RC.compound_id
        WHERE NOT Src.compound_id IS NULL AND
              RC.compound_id IS NULL;

        If char_length(Coalesce(_invalidRefCompoundList, '')) > 0 Then
            RAISE EXCEPTION 'Invalid reference compound ID(s): %', _invalidRefCompoundList;
        End If;

        ---------------------------------------------------
        -- Add/update the experiment
        ---------------------------------------------------

        _logErrors := true;

        If _mode = 'add' Then
            ---------------------------------------------------
            -- Action for add mode
            ---------------------------------------------------

            INSERT INTO t_experiments (
                    experiment,
                    researcher_username,
                    organism_id,
                    reason,
                    comment,
                    created,
                    sample_concentration,
                    enzyme_id,
                    labelling,
                    lab_notebook_ref,
                    campaign_id,
                    sample_prep_request_id,
                    internal_standard_id,
                    post_digest_internal_std_id,
                    container_id,
                    wellplate,
                    well,
                    alkylation,
                    barcode,
                    tissue_id,
                    last_used
            ) VALUES (
                _experimentName,
                _researcherUsername,
                _organismID,
                _reason,
                _comment,
                CURRENT_TIMESTAMP,
                _sampleConcentration,
                _enzymeID,
                _labelling,
                _labNotebookRef,
                _campaignID,
                _samplePrepRequest,
                _internalStandardID,
                _postdigestIntStdID,
                _contID,
                _wellplateName,
                _wellNumber,
                _alkylation,
                _barcode,
                _tissueIdentifier,
                CURRENT_TIMESTAMP::Date
            )
            RETURNING exp_id
            INTO _experimentID;

            -- As a precaution, query t_experiments using Experiment name to make sure we have the correct Exp_ID

            SELECT exp_id
            INTO _expIDConfirm
            FROM t_experiments
            WHERE experiment = _experimentName

            If _experimentID <> Coalesce(_expIDConfirm, _experimentID) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding experiment %s: Found ID %s but INSERT query reported %s',
                                    _experimentName, _expIDConfirm, _experimentID);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Experiment');

                _experimentID := _expIDConfirm;
            End If;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                CALL alter_event_log_entry_user (3, _experimentID, _stateID, _callingUser);
            End If;

            -- Add the experiment to biomaterial mapping
            -- The procedure uses table Tmp_Experiment_to_Biomaterial_Map
            --
            CALL add_experiment_biomaterial (
                                    _experimentID,
                                    _updateCachedInfo => false,
                                    _message => _msg,               -- Output
                                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not add experiment biomaterial to database for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Add the experiment to reference compound mapping
            -- The procedure uses table Tmp_ExpToRefCompoundMap
            --
            CALL add_experiment_reference_compound (
                                    _experimentID,
                                    _updateCachedInfo => true,
                                    _message => _msg,               -- Output
                                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not add experiment reference compounds to database for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Material movement logging
            --
            If _curContainerID <> _contID Then
                CALL post_material_log_entry (
                    'Experiment Move',
                    _experimentName,
                    'na',
                    _container,
                    _callingUser,
                    'Experiment added');
            End If;

        End If; -- add mode

        If _mode = 'update' Then
            ---------------------------------------------------
            -- Action for update mode
            ---------------------------------------------------

            UPDATE t_experiments Set
                experiment = _experimentName,
                researcher_username = _researcherUsername,
                organism_id = _organismID,
                reason = _reason,
                comment = _comment,
                sample_concentration = _sampleConcentration,
                enzyme_id = _enzymeID,
                labelling = _labelling,
                lab_notebook_ref = _labNotebookRef,
                campaign_id = _campaignID,
                sample_prep_request_id = _samplePrepRequest,
                internal_standard_id = _internalStandardID,
                post_digest_internal_std_id = _postdigestIntStdID,
                container_id = _contID,
                wellplate = _wellplateName,
                well = _wellNumber,
                alkylation = _alkylation,
                barcode = _barcode,
                tissue_id = _tissueIdentifier,
                last_used = Case When organism_id <> _organismID OR
                                      reason <> _reason OR
                                      comment <> _comment OR
                                      enzyme_id <> _enzymeID OR
                                      labelling <> _labelling OR
                                      campaign_id <> _campaignID OR
                                      sample_prep_request_id <> _samplePrepRequest OR
                                      alkylation <> _alkylation
                                 Then CURRENT_TIMESTAMP::Date
                                 Else Last_Used
                            End If;
            WHERE Exp_ID = _experimentId;

            -- Update the experiment to biomaterial mapping
            -- The procedure uses table Tmp_Experiment_to_Biomaterial_Map
            --
            CALL add_experiment_biomaterial (
                                    _experimentID,
                                    _updateCachedInfo => false,
                                    _message => _msg,               -- Output
                                    _returnCode => _returnCode);    -- Output

            --
            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not update experiment biomaterial mapping for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Update the experiment to reference compound mapping
            -- The procedure uses table Tmp_ExpToRefCompoundMap
            --
            CALL add_experiment_reference_compound (
                                    _experimentID,
                                    _updateCachedInfo => true,
                                    _message => _msg,               -- Output
                                    _returnCode => _returnCode);    -- Output
            --
            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not update experiment reference compound mapping for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Material movement logging
            --
            If _curContainerID <> _contID Then
                CALL post_material_log_entry
                    'Experiment Move',
                    _experimentName,
                    _curContainerName,
                    _container,
                    _callingUser,
                    'Experiment updated'
            End If;

            If char_length(_existingExperimentName) > 0 And _existingExperimentName <> _experimentName Then
                _message := format('Renamed experiment from "%s" to "%s"', _existingExperimentName, _experimentName);
            End If;

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Experiment %s', _exceptionMessage, _experimentName);

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

    DROP TABLE IF EXISTS Tmp_Experiment_to_Biomaterial_Map;
    DROP TABLE IF EXISTS Tmp_ExpToRefCompoundMap;
END
$$;

COMMENT ON PROCEDURE public.add_update_experiment IS 'AddUpdateExperiment';

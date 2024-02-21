--
-- Name: add_update_experiment(integer, text, text, text, text, text, text, text, text, text, text, text, text, integer, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_experiment(INOUT _experimentid integer, IN _experimentname text, IN _campaignname text, IN _researcherusername text, IN _organismname text, IN _reason text DEFAULT 'na'::text, IN _comment text DEFAULT ''::text, IN _sampleconcentration text DEFAULT 'na'::text, IN _enzymename text DEFAULT 'Trypsin'::text, IN _labnotebookref text DEFAULT 'na'::text, IN _labelling text DEFAULT 'none'::text, IN _biomateriallist text DEFAULT ''::text, IN _referencecompoundlist text DEFAULT ''::text, IN _samplepreprequest integer DEFAULT 0, IN _internalstandard text DEFAULT ''::text, IN _postdigestintstd text DEFAULT ''::text, IN _wellplatename text DEFAULT ''::text, IN _wellnumber text DEFAULT ''::text, IN _alkylation text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, IN _container text DEFAULT 'na'::text, IN _barcode text DEFAULT ''::text, IN _tissue text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new experiment to the database
**
**      Note that the Experiment Detail Report web page uses do_material_item_operation to retire an experiment
**
**  Arguments:
**    _experimentId             Input/output: experiment ID; when copying an experiment, this will have the new experiment's ID; this is required if renaming an existing experiment
**    _experimentName           Experiment name
**    _campaignName             Campaign name
**    _researcherUsername       Researcher username
**    _organismName             Organism name
**    _reason                   Experiment description
**    _comment                  Additional comments
**    _sampleConcentration      Sample concentration, e.g. '0.1 ug/ul' or 'na'
**    _enzymeName               Enzyme name, e.g. 'Trypsin', 'LysC, or 'No_Enzyme'
**    _labNotebookRef           Lab notebook description or Sharepoint URL
**    _labelling                Isotopic label name, e.g. 'TMT10' or 'TMT18'; use 'none' if no label or 'Unknown' if undefined
**    _biomaterialList          Semicolon-separated or comma-separated list of biomaterial names; empty string if not applicable
**    _referenceCompoundList    Semicolon-separated or comma-separated list of reference compound IDs; supports integers, or names of the form 3311:ANFTSQETQGAGK
**    _samplePrepRequest        Sample prep request ID; 0 if no request
**    _internalStandard         Internal standard name, e.g. 'MP_10_02'; last used in 2013
**    _postdigestIntStd         Post-digestion internal standard name, e.g. 'ADHYeast_031411'; last used in 2014
**    _wellplateName            Wellplate name
**    _wellNumber               Well position (aka well number)
**    _alkylation               Alkylation: 'Y' or 'N'
**    _mode                     Mode: 'add, 'update', 'check_add', 'check_update'
**    _container                Container name, e.g. 'MC-3375'
**    _barcode                  Barcode, e.g. '90154017002'; last used in 2019
**    _tissue                   Tissue name, e.g. 'blood plasma', 'cell culture', 'plant, 'soil', etc.
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Auth:   grk
**  Date:   01/08/2002 grk - Initial version
**          08/25/2004 jds - Updated proc to add T_Enzyme table value
**          06/10/2005 grk - Added handling for sample prep request
**          10/28/2005 grk - Added handling for internal standard
**          11/11/2005 grk - Added handling for postdigest internal standard
**          11/21/2005 grk - Fixed update error for postdigest internal standard
**          01/12/2007 grk - Added verification mode
**          01/13/2007 grk - Switched to organism ID instead of organism name (Ticket #360)
**          04/30/2007 grk - Added better name validation (Ticket #450)
**          02/13/2008 mem - Now checking for _badCh = 'space' (Ticket #602)
**          03/13/2008 grk - Added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter _callingUser
**          03/25/2008 mem - Now calling alter_event_log_entry_user if _callingUser is not blank (Ticket #644)
**          07/16/2009 grk - Added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          12/01/2009 grk - Modified to skip checking of existing well occupancy if updating existing experiment
**          04/22/2010 grk - Use try-catch for error handling
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _researcherPRN contains a person's real name rather than their username
**          05/18/2010 mem - Now validating that _internalStandard and _postdigestIntStd are active internal standards when creating a new experiment (_mode is 'add' or 'check_add')
**          11/15/2011 grk - Added alkylation field
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
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the experiment name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          01/24/2017 mem - Fix validation of _labelling to raise an error when the label name is unknown
**          01/27/2017 mem - Change _internalStandard and _postdigestIntStd to 'none' if empty
**          03/17/2017 mem - Only call Make_Table_From_List_Delim if _biomaterialList contains a semicolon
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/18/2017 mem - Add parameter _tissue (tissue name, e.g. hypodermis)
**          09/01/2017 mem - Allow _tissue to be a BTO ID (e.g. BTO:0000131)
**          11/29/2017 mem - Call Parse_Delimited_List instead of Make_Table_From_List_Delim
**                         - Rename #CC to Tmp_ExpToCCMap
**                         - No longer pass _biomaterialList to Add_Experiment_Cell_Culture since it uses Tmp_ExpToCCMap
**                         - Remove references to the Cell_Culture_List field in T_Experiments (procedure Add_Experiment_Cell_Culture calls Update_Cached_Experiment_Info)
**                         - Add argument _referenceCompoundList
**          01/04/2018 mem - Entries in _referenceCompoundList are now assumed to be in the form Compound_ID:Compound_Name, though we also support only Compound_ID or only Compound_Name
**          07/30/2018 mem - Expand _reason and _comment to varchar(500)
**          11/27/2018 mem - Check for _referenceCompoundList having '100:(none)'
**                         - Remove items from Tmp_ExpToRefCompoundMap that map to the reference compound named (none)
**          11/30/2018 mem - Add output parameter _experimentID
**          03/27/2019 mem - Update _experimentId using _existingExperimentID
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/25/2021 mem - Use Replace_Character_Codes to replace character codes with punctuation marks
**                         - Use Remove_Cr_Lf to replace linefeeds with semicolons
**          07/06/2021 mem - Expand _organismName and _labNotebookRef to varchar(128)
**          09/30/2021 mem - Allow renaming an experiment if it does not have an associated requested run or dataset
**                         - Move argument _experimentID, making it the first argument
**                         - Rename the Experiment, Campaign, and Wellplate name arguments
**          11/26/2022 mem - Rename parameter to _biomaterialList
**          09/07/2023 mem - Update warning messages
**          09/26/2023 mem - Update cached experiment names in t_data_package_experiments
**          12/05/2023 mem - Ported to PostgreSQL
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/08/2024 mem - Remove procedure name from error message
**          01/11/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _dropTempTables boolean := false;
    _invalidBiomaterialList text := null;
    _invalidRefCompoundList text;
    _existingExperimentID int := 0;
    _existingExperimentName citext := '';
    _existingRequestedRun citext := '';
    _existingDataset citext := '';
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
    _labelName text;
    _internalStandardID int := 0;
    _internalStandardState citext := 'I';
    _postdigestIntStdID int := 0;
    _contID int := 0;
    _curContainerName citext := '';
    _expIDConfirm int := 0;
    _debugMsg text;
    _stateID int := 1;
    _msg text;
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

        _experimentID          := Coalesce(_experimentID, 0);
        _experimentName        := Trim(Coalesce(_experimentName, ''));
        _campaignName          := Trim(Coalesce(_campaignName, ''));
        _researcherUsername    := Trim(Coalesce(_researcherUsername, ''));
        _organismName          := Trim(Coalesce(_organismName, ''));
        _reason                := Trim(Coalesce(_reason, ''));
        _comment               := Trim(Coalesce(_comment, ''));
        _enzymeName            := Trim(Coalesce(_enzymeName, ''));
        _labelling             := Trim(Coalesce(_labelling, ''));
        _biomaterialList       := Trim(Coalesce(_biomaterialList, ''));
        _referenceCompoundList := Trim(Coalesce(_referenceCompoundList, ''));
        _samplePrepRequest     := Coalesce(_samplePrepRequest, 0);
        _internalStandard      := Trim(Coalesce(_internalStandard, ''));
        _postdigestIntStd      := Trim(Coalesce(_postdigestIntStd, ''));
        _alkylation            := Trim(Upper(Coalesce(_alkylation, '')));
        _mode                  := Trim(Lower(Coalesce(_mode, '')));
        _barcode               := Trim(Coalesce(_barcode, ''));

        If _experimentName = '' Then
            RAISE EXCEPTION 'Experiment name must be specified';
        End If;

        If _campaignName = '' Then
            RAISE EXCEPTION 'Campaign name must be specified';
        End If;

        If _researcherUsername = '' Then
            RAISE EXCEPTION 'Researcher Username must be specified';
        End If;

        If _organismName = '' Then
            RAISE EXCEPTION 'Organism name must be specified';
        End If;

        If _reason = '' Then
            RAISE EXCEPTION 'Reason must be specified';
        End If;

        If _labelling = '' Then
            RAISE EXCEPTION 'Labelling must be specified';
        End If;

        If Not _alkylation::citext In ('Y', 'N') Then
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
            If _badCh = '[space]' Then
                RAISE EXCEPTION 'Experiment name may not contain spaces';
            Else
                RAISE EXCEPTION 'Experiment name may not contain the character(s) "%"', _badCh;
            End If;
        End If;

        If char_length(_experimentName) < 6 Then
            RAISE EXCEPTION 'Experiment name must be at least 6 characters in length; currently % characters', char_length(_experimentName);
        End If;

        ---------------------------------------------------
        -- Resolve _tissue to BTO identifier
        ---------------------------------------------------

        CALL public.get_tissue_id (
                _tissueNameOrID => _tissue,
                _tissueIdentifier => _tissueIdentifier,    -- Output
                _tissueName => _tissueName,                -- Output (unused here)
                _message    => _message,                   -- Output
                _returnCode => _returnCode);               -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'Could not resolve tissue name or id: "%"', _tissue;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode In ('update', 'check_update') And _experimentID > 0 Then

            SELECT exp_id,
                   experiment,
                   container_id
            INTO _existingExperimentID, _existingExperimentName, _curContainerID
            FROM t_experiments
            WHERE exp_id = _experimentID;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: experiment ID % does not exist', _experimentID;
            End If;

            If _existingExperimentName <> _experimentName::citext Then
                -- Allow renaming if the experiment is not associated with a dataset or requested run, and if the new name is unique

                If Exists (SELECT Exp_ID FROM T_Experiments WHERE experiment = _experimentName::citext) Then
                    SELECT exp_id
                    INTO _existingExperimentID
                    FROM t_experiments
                    WHERE experiment = _experimentName::citext;

                    RAISE EXCEPTION 'Cannot rename: experiment "%" already exists, with ID %', _experimentName, _existingExperimentID;
                End If;

                If Exists (SELECT Exp_ID FROM T_Dataset WHERE exp_id = _experimentID) Then
                    SELECT dataset
                    INTO _existingDataset
                    FROM t_dataset
                    WHERE exp_id = _experimentID;

                    RAISE EXCEPTION 'Cannot rename: experiment ID % is associated with dataset "%"', _experimentID, _existingDataset;
                End If;

                If Exists (SELECT Exp_ID FROM t_requested_run WHERE exp_id = _experimentID) Then
                    SELECT request_name
                    INTO _existingRequestedRun
                    FROM t_requested_run
                    WHERE exp_id = _experimentID;

                    RAISE EXCEPTION 'Cannot rename: experiment ID % is associated with requested run "%"', _experimentID, _existingRequestedRun;
                End If;
            End If;
        Else
            -- Either _mode is 'add' or 'check_add' or _experimentID is null or 0
            -- Look for the experiment by name

            SELECT exp_id,
                   container_id
            INTO _existingExperimentID, _curContainerID
            FROM t_experiments
            WHERE experiment = _experimentName::citext;

            If _mode In ('update', 'check_update') And Not FOUND Then
                RAISE EXCEPTION 'Cannot update: experiment "%" does not exist', _experimentName;
            End If;

            -- Assure that _experimentId is up-to-date
            _experimentId := _existingExperimentID;
        End If;

        -- Cannot create an entry that already exists

        If _existingExperimentID <> 0 and (_mode In ('add', 'check_add')) Then
            RAISE EXCEPTION 'Cannot add: experiment "%" already exists', _experimentName;
        End If;

        ---------------------------------------------------
        -- Resolve campaign ID
        ---------------------------------------------------

        _campaignID := public.get_campaign_id(_campaignName);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Invalid campaign name: "%" does not exist', _campaignName;
        End If;

        ---------------------------------------------------
        -- Resolve researcher username
        ---------------------------------------------------

        _userID := public.get_user_id(_researcherUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _researcherUsername contains simply the username
            SELECT username
            INTO _researcherUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _researcherUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                            _researcherUsername,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _researcherUsername
                _researcherUsername := _newUsername;
            Else
                If _matchCount = 0 Then
                    RAISE EXCEPTION 'Invalid researcher username: "%" does not exist', _researcherUsername;
                Else
                    RAISE EXCEPTION 'Invalid researcher username: "%" matches more than one user', _researcherUsername;
                End If;
            End If;

        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := public.get_organism_id(_organismName);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Invalid organism name: "%" does not exist', _organismName;
        End If;

        ---------------------------------------------------
        -- Set up and validate wellplate values
        ---------------------------------------------------

        If _mode In ('add', 'check_add') THEN
            _totalCount := 1;
        Else
            _totalCount := 0;
        End If;

        CALL public.validate_wellplate_loading (
                        _wellplateName => _wellplateName,   -- Input/Output
                        _wellPosition  => _wellNumber,      -- Input/Output
                        _totalCount    => _totalCount,
                        _wellIndex     => _wellIndex,       -- Output
                        _message       => _msg,             -- Output
                        _returnCode    => _returnCode);     -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Make sure we do not put two experiments in the same place

        If Exists (SELECT exp_id FROM t_experiments WHERE wellplate = _wellplateName::citext AND well = _wellNumber::citext) AND _mode IN ('add', 'check_add') Then
            RAISE EXCEPTION 'There is another experiment assigned to the same wellplate and well';
        End If;

        If Exists (SELECT exp_id FROM t_experiments WHERE wellplate = _wellplateName::citext AND well = _wellNumber::citext AND experiment <> _experimentName::citext) AND _mode IN ('update', 'check_update') Then
            RAISE EXCEPTION 'There is another experiment assigned to the same wellplate and well';
        End If;

        ---------------------------------------------------
        -- Resolve enzyme ID
        ---------------------------------------------------

        SELECT enzyme_id
        INTO _enzymeID
        FROM t_enzymes
        WHERE enzyme_name = _enzymeName::citext;

        If Not FOUND Then
            If _enzymeName::citext = 'na' Then
                RAISE EXCEPTION 'The enzyme cannot be "%"; use No_Enzyme if enzymatic digestion was not used', _enzymeName;
            Else
                RAISE EXCEPTION 'Invalid enzyme: "%" does not exist', _enzymeName;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve labelling ID
        ---------------------------------------------------

        SELECT label_id, label
        INTO _labelID, _labelName
        FROM t_sample_labelling
        WHERE label = _labelling::citext;

        If Not FOUND Then
            RAISE EXCEPTION '"%" is not a valid label name; use "none" if unlabeled', _labelling;
        Else
            _labelling := _labelName;
        End If;

        ---------------------------------------------------
        -- Validate the sample prep request ID
        ---------------------------------------------------

        If _samplePrepRequest > 0 And Not Exists (SELECT prep_request_id FROM t_sample_prep_request WHERE prep_request_id = _samplePrepRequest) Then
            RAISE EXCEPTION 'Invalid sample prep request ID: % does not exist', _samplePrepRequest;
        End If;

        ---------------------------------------------------
        -- Resolve predigestion internal standard ID
        -- If creating a new experiment, make sure the internal standard is active
        ---------------------------------------------------

        SELECT internal_standard_id, active
        INTO _internalStandardID, _internalStandardState
        FROM t_internal_standards
        WHERE name = _internalStandard::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid predigestion internal standard: "%" does not exist', _internalStandard;
        End If;

        If (_mode In ('add', 'check_add')) And _internalStandardState <> 'A' Then
            RAISE EXCEPTION 'Predigestion internal standard "%" is not active; this standard cannot be used when creating a new experiment', _internalStandard;
        End If;

        ---------------------------------------------------
        -- Resolve postdigestion internal standard ID
        ---------------------------------------------------

        SELECT internal_standard_id active
        INTO _postdigestIntStdID, _internalStandardState
        FROM t_internal_standards
        WHERE name = _postdigestIntStd::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid postdigestion internal standard: "%" does not exist', _postdigestIntStd;
        End If;

        If _mode In ('add', 'check_add') And _internalStandardState <> 'A' Then
            RAISE EXCEPTION 'Postdigestion internal standard "%" is not active; this standard cannot be used when creating a new experiment', _postdigestIntStd;
        End If;

        ---------------------------------------------------
        -- Resolve container name to ID
        -- Auto-switch name from 'none' to 'na'
        ---------------------------------------------------

        If _container::citext = 'none' Then
            _container := 'na';
        End If;

        SELECT container_id
        INTO _contID
        FROM t_material_containers
        WHERE container = _container::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid container name "%"', _container;
        End If;

        ---------------------------------------------------
        -- Resolve current container id to name
        -- (skip if adding experiment)
        ---------------------------------------------------

        If Not _mode In ('add', 'check_add') Then
            SELECT container
            INTO _curContainerName
            FROM t_material_containers
            WHERE container_id = _curContainerID;
        End If;

        ---------------------------------------------------
        -- Create temporary tables to hold biomaterial and reference compounds associated with the parent experiment
        ---------------------------------------------------

        -- This table is used by procedure add_experiment_biomaterial.sql
        CREATE TEMP TABLE Tmp_Experiment_to_Biomaterial_Map (
            Biomaterial_Name citext not null,
            Biomaterial_ID int null
        );

        -- This table is used by procedure add_experiment_reference_compound
        CREATE TEMP TABLE Tmp_ExpToRefCompoundMap (
            Compound_IDName citext not null,          -- This holds compound ID as text; if it is originally of the form '3311:ANFTSQETQGAGK', it will be changed to '3311'
            Colon_Pos int null,
            Compound_ID int null
        );

        _dropTempTables := true;

        ---------------------------------------------------
        -- Resolve biomaterial
        -- Auto-switch from 'none' or 'na' or '(none)' to ''
        ---------------------------------------------------

        If _biomaterialList::citext In ('none', 'na', '(none)') Then
            _biomaterialList := '';
        End If;

        -- Replace commas with semicolons
        If _biomaterialList Like '%,%' Then
            _biomaterialList := Replace(_biomaterialList, ',', ';');
        End If;

        -- Get biomaterial names from list argument into table

        INSERT INTO Tmp_Experiment_to_Biomaterial_Map (Biomaterial_Name)
        SELECT Value
        FROM public.parse_delimited_list(_biomaterialList, ';');

        -- Verify that biomaterial items exist

        UPDATE tmp_experiment_to_biomaterial_map Target
        SET biomaterial_id = Src.biomaterial_id
        FROM t_biomaterial Src
        WHERE Src.biomaterial_name = Target.biomaterial_name;

        SELECT string_agg(biomaterial_name, ', ' ORDER BY biomaterial_name)
        INTO _invalidBiomaterialList
        FROM tmp_experiment_to_biomaterial_map
        WHERE biomaterial_id IS NULL;

        If Coalesce(_invalidBiomaterialList, '') <> '' Then
            RAISE EXCEPTION 'Invalid biomaterial name(s): %', _invalidBiomaterialList;
        End If;

        ---------------------------------------------------
        -- Resolve reference compounds
        -- Auto-switch from 'none' or 'na' or '(none)' to ''
        ---------------------------------------------------

        If _referenceCompoundList::citext In ('none', 'na', '(none)', '100:(none)') Then
            _referenceCompoundList := '';
        End If;

        -- Replace commas with semicolons
        If _referenceCompoundList Like '%,%' Then
            _referenceCompoundList := Replace(_referenceCompoundList, ',', ';');
        End If;

        -- Get names of reference compounds from list argument into table

        INSERT INTO Tmp_ExpToRefCompoundMap (Compound_IDName, Colon_Pos)
        SELECT Value, Position(':' In Value)
        FROM public.parse_delimited_list(_referenceCompoundList, ';');

        -- Update entries in Tmp_ExpToRefCompoundMap to remove extra text that may be present
        -- For example, switch from 3311:ANFTSQETQGAGK to 3311
        UPDATE Tmp_ExpToRefCompoundMap
        SET Compound_IDName = Substring(Compound_IDName, 1, Colon_Pos - 1)
        WHERE NOT Colon_Pos IS NULL AND Colon_Pos > 0;

        -- Populate the Compound_ID column using any integers in Compound_IDName
        UPDATE Tmp_ExpToRefCompoundMap
        SET Compound_ID = public.try_cast(Compound_IDName, null::int);

        -- If any entries still have a null Compound_ID value, try matching via reference compound name
        -- We have numerous reference compounds with identical names, so matches found this way will be ambiguous

        UPDATE Tmp_ExpToRefCompoundMap Target
        SET Compound_ID = Src.Compound_ID
        FROM t_reference_compound Src
        WHERE Src.compound_name = Target.Compound_IDName AND
              Target.compound_id IS Null;

        -- Delete any entries where the name is '(none)'

        DELETE FROM Tmp_ExpToRefCompoundMap
        WHERE Compound_IDName = '(none)';

        -- This is an alternative method for deleting entries,
        -- joining on compound_id and examining compound_name in t_reference_compound
        DELETE FROM Tmp_ExpToRefCompoundMap
        WHERE EXISTS (SELECT Src.compound_id
                      FROM t_reference_compound Src
                      WHERE Src.compound_id = Tmp_ExpToRefCompoundMap.compound_id AND
                            Src.compound_name = '(none)');

        ---------------------------------------------------
        -- Look for invalid entries in Tmp_ExpToRefCompoundMap
        ---------------------------------------------------

        -- First look for entries without a Compound_ID

        _invalidRefCompoundList := null;

        SELECT string_agg(Compound_IDName, ', ' ORDER BY Compound_IDName)
        INTO _invalidRefCompoundList
        FROM Tmp_ExpToRefCompoundMap
        WHERE Compound_ID IS NULL;

        If char_length(Coalesce(_invalidRefCompoundList, '')) > 0 Then
            RAISE EXCEPTION 'Invalid reference compound name(s): %', _invalidRefCompoundList;
        End If;

        -- Next look for entries with an invalid Compound_ID

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
            WHERE experiment = _experimentName::citext;

            If _experimentID <> Coalesce(_expIDConfirm, _experimentID) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding experiment %s: found ID %s but INSERT query reported %s',
                                    _experimentName, _expIDConfirm, _experimentID);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Experiment');

                _experimentID := _expIDConfirm;
            End If;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                _targetType := 3;
                CALL public.alter_event_log_entry_user ('public', _targetType, _experimentID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Add the experiment to biomaterial mapping
            -- The procedure uses table Tmp_Experiment_to_Biomaterial_Map

            CALL public.add_experiment_biomaterial (
                            _experimentID,
                            _updateCachedInfo => false,
                            _message          => _msg,          -- Output
                            _returnCode       => _returnCode);  -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not add experiment biomaterial to database for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Add the experiment to reference compound mapping
            -- The procedure uses table Tmp_ExpToRefCompoundMap

            CALL public.add_experiment_reference_compound (
                            _experimentID,
                            _updateCachedInfo => true,
                            _message          => _msg,          -- Output
                            _returnCode       => _returnCode);  -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not add experiment reference compounds to database for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Material movement logging

            If _curContainerID <> _contID Then
                CALL public.post_material_log_entry (
                                _type         => 'Experiment Move',
                                _item         => _experimentName,
                                _initialState => 'na',                  -- Initial State: Old container name ('na')
                                _finalState   => _container,            -- Final State:   New container name
                                _callingUser  => _callingUser,
                                _comment      => 'Experiment added');
            End If;

        End If;

        If _mode = 'update' Then
            ---------------------------------------------------
            -- Action for update mode
            ---------------------------------------------------

            UPDATE t_experiments
            SET experiment                  = _experimentName,
                researcher_username         = _researcherUsername,
                organism_id                 = _organismID,
                reason                      = _reason,
                comment                     = _comment,
                sample_concentration        = _sampleConcentration,
                enzyme_id                   = _enzymeID,
                labelling                   = _labelling,
                lab_notebook_ref            = _labNotebookRef,
                campaign_id                 = _campaignID,
                sample_prep_request_id      = _samplePrepRequest,
                internal_standard_id        = _internalStandardID,
                post_digest_internal_std_id = _postdigestIntStdID,
                container_id                = _contID,
                wellplate                   = _wellplateName,
                well                        = _wellNumber,
                alkylation                  = _alkylation,
                barcode                     = _barcode,
                tissue_id                   = _tissueIdentifier,
                last_used                   = CASE WHEN organism_id <> _organismID OR
                                                        reason <> _reason OR
                                                        comment <> _comment OR
                                                        enzyme_id <> _enzymeID OR
                                                        labelling <> _labelling OR
                                                        campaign_id <> _campaignID OR
                                                        sample_prep_request_id <> _samplePrepRequest OR
                                                        alkylation <> _alkylation
                                                   THEN CURRENT_TIMESTAMP::Date
                                                   ELSE Last_Used
                                              END
            WHERE Exp_ID = _experimentId;

            -- Update the experiment to biomaterial mapping
            -- The procedure uses table Tmp_Experiment_to_Biomaterial_Map

            CALL public.add_experiment_biomaterial (
                            _experimentID,
                            _updateCachedInfo => false,         -- This is false here because we call add_experiment_reference_compound below, using _updateCachedInfo => true
                            _message          => _msg,          -- Output
                            _returnCode       => _returnCode);  -- Output


            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not update experiment biomaterial mapping for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Update the experiment to reference compound mapping
            -- The procedure uses table Tmp_ExpToRefCompoundMap

            CALL public.add_experiment_reference_compound (
                            _experimentID,
                            _updateCachedInfo => true,
                            _message          => _msg,          -- Output
                            _returnCode       => _returnCode);  -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not update experiment reference compound mapping for experiment "%" :%', _experimentName, _msg;
            End If;

            -- Material movement logging

            If _curContainerID <> _contID Then
                CALL public.post_material_log_entry (
                                _type         => 'Experiment Move',
                                _item         => _experimentName,
                                _initialState => _curContainerName,     -- Initial State: Old container name
                                _finalState   => _container,            -- Final State:   New container name
                                _callingUser  => _callingUser,
                                _comment      => 'Experiment updated');
            End If;

            If Trim(Coalesce(_existingExperimentName, '')) <> '' And _existingExperimentName <> _experimentName::citext Then
                _message := format('Renamed experiment from "%s" to "%s"', _existingExperimentName, _experimentName);

                --------------------------------------------
                -- Update cached experiment names in t_data_package_experiments
                --------------------------------------------

                UPDATE dpkg.t_data_package_experiments
                SET experiment = _experimentName
                WHERE experiment_id = _experimentID AND
                      Coalesce(experiment, '') <> _experimentName;
            End If;

        End If;

        If _dropTempTables Then
            DROP TABLE Tmp_Experiment_to_Biomaterial_Map;
            DROP TABLE Tmp_ExpToRefCompoundMap;
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

    If _dropTempTables Then
        DROP TABLE IF EXISTS Tmp_Experiment_to_Biomaterial_Map;
        DROP TABLE IF EXISTS Tmp_ExpToRefCompoundMap;
    End If;
END
$$;


ALTER PROCEDURE public.add_update_experiment(INOUT _experimentid integer, IN _experimentname text, IN _campaignname text, IN _researcherusername text, IN _organismname text, IN _reason text, IN _comment text, IN _sampleconcentration text, IN _enzymename text, IN _labnotebookref text, IN _labelling text, IN _biomateriallist text, IN _referencecompoundlist text, IN _samplepreprequest integer, IN _internalstandard text, IN _postdigestintstd text, IN _wellplatename text, IN _wellnumber text, IN _alkylation text, IN _mode text, IN _container text, IN _barcode text, IN _tissue text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_experiment(INOUT _experimentid integer, IN _experimentname text, IN _campaignname text, IN _researcherusername text, IN _organismname text, IN _reason text, IN _comment text, IN _sampleconcentration text, IN _enzymename text, IN _labnotebookref text, IN _labelling text, IN _biomateriallist text, IN _referencecompoundlist text, IN _samplepreprequest integer, IN _internalstandard text, IN _postdigestintstd text, IN _wellplatename text, IN _wellnumber text, IN _alkylation text, IN _mode text, IN _container text, IN _barcode text, IN _tissue text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_experiment(INOUT _experimentid integer, IN _experimentname text, IN _campaignname text, IN _researcherusername text, IN _organismname text, IN _reason text, IN _comment text, IN _sampleconcentration text, IN _enzymename text, IN _labnotebookref text, IN _labelling text, IN _biomateriallist text, IN _referencecompoundlist text, IN _samplepreprequest integer, IN _internalstandard text, IN _postdigestintstd text, IN _wellplatename text, IN _wellnumber text, IN _alkylation text, IN _mode text, IN _container text, IN _barcode text, IN _tissue text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateExperiment';


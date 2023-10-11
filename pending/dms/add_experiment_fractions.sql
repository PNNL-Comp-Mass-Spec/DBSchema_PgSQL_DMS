--
CREATE OR REPLACE PROCEDURE public.add_experiment_fractions
(
    _parentExperiment text,
    _groupType text = 'Fraction',
    _suffix text = '',
    _nameSearch  text = '',
    _nameReplace text = '',
    _groupName text,
    _description text,
    _totalCount int,
    _addUnderscore text = 'Yes',
    INOUT _groupID int,
    _requestOverride text = 'parent',
    _internalStandard text = 'parent',
    _postdigestIntStd text = 'parent',
    _researcher text = 'parent',
    INOUT _wellplateName text,
    INOUT _wellNumber text,
    _container text = 'na',
    _prepLCRunID int,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a group of new experiments in DMS, linking back to the parent experiment
**
**  Arguments:
**    _parentExperiment   Parent experiment for group (must already exist)
**    _groupType          Must be 'Fraction'
**    _suffix             Text to append to the parent experiment name, prior to adding the fraction number
**    _nameSearch         Text to find in the parent experiment name, to be replaced by _nameReplace
**    _nameReplace        Replacement text
**    _groupName          User-defined name for this experiment group (aka fraction group); previously _tab
**    _description        Purpose of group
**    _totalCount         Number of new experiments to automatically create
**    _addUnderscore      When Yes (or 1 or ''), add an underscore before the fraction number; when _suffix is defined, it is helpful to set this to 'No'
**    _groupID            ID of newly created experiment group
**    _requestOverride    ID of sample prep request for fractions (if different than parent experiment)
**    _container          na, 'parent', '-20', or actual container ID
**    _mode               'add' or 'preview'; when previewing, will show the names of the new fractions
**
**  Auth:   grk
**  Date:   05/28/2005
**          05/29/2005 grk - Added mods to better work with entry page
**          05/31/2005 grk - Added mods for separate group members table
**          06/10/2005 grk - Added handling for sample prep request
**          10/04/2005 grk - Added call to Add_Experiment_Cell_Culture
**          10/04/2005 grk - Added override for request ID
**          10/28/2005 grk - Added handling for internal standard
**          11/11/2005 grk - Added handling for postdigest internal standard
**          12/20/2005 grk - Added handling for separate user
**          02/06/2006 grk - Increased maximum count
**          01/13/2007 grk - Switched to organism ID instead of organism name (Ticket #360)
**          09/27/2007 mem - Moved the copying of AuxInfo to occur after the new experiments have been created and to use CopyAuxInfoMultiID (Ticket #538)
**          10/22/2008 grk - Added container field (Ticket http://prismtrac.pnl.gov/trac/ticket/697)
**          07/16/2009 grk - Added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          07/31/2009 grk - Added prep LC run field (http://prismtrac.pnl.gov/trac/ticket/743)
**          09/13/2011 grk - Added researcher to experiment group
**          10/03/2011 grk - Added try-catch error handling
**          11/10/2011 grk - Added Tab field
**          11/15/2011 grk - Added handling for experiment alkylation field
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/22/2017 mem - Copy TissueID
**          08/25/2017 mem - Use TissueID from the Sample Prep Request if _requestOverride is not 'parent' and if the prep request has a tissue defined
**          09/06/2017 mem - Fix data type for _tissueID
**          11/29/2017 mem - No longer pass _cellCultureList to Add_Experiment_Cell_Culture since it now uses temp table Tmp_Experiment_to_Biomaterial_Map
**                         - Remove references to the Cell_Culture_List field in T_Experiments (procedure Add_Experiment_Cell_Culture calls Update_Cached_Experiment_Info)
**                         - Call Add_Experiment_Reference_Compound
**          01/04/2018 mem - Update fields in Tmp_ExpToRefCompoundMap, switching from Compound_Name to Compound_IDName
**          12/03/2018 mem - Add parameter _suffix
**                         - Add support for _mode = 'preview'
**          12/04/2018 mem - Insert plex member info into T_Experiment_Plex_Members if defined for the parent experiment
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          01/24/2019 mem - Add parameters _nameSearch, _nameReplace, and _addUnderscore
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/15/2021 mem - If the parent experiment has a TissueID defined, use it, even if the Sample Prep Request is not 'parent' (for _requestOverride)
**                         - No longer copy the parent experiment concentration to the fractions
**          06/01/2021 mem - Raise an error if _mode is invalid
**          04/12/2022 mem - Do not log data validation errors to T_Log_Entries
**          11/18/2022 mem - Rename parameter to _groupName
**          11/25/2022 mem - Rename parameter to _wellplate
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _fractionCount int := 0;
    _maxCount int := 200;
    _fractionNumberText text;
    _fullFractionCount int;
    _newExpID int;
    _startingIndex int := 1      -- Initial index for automatic naming of new experiments;
    _step int := 1               -- Step interval in index;
    _fractionsCreated int := 0;

    _parentExperimentInfo record;
    _experimentIDList text := '';
    _materialIDList text := '';
    _fractionNamePreviewList text := '';
    _wellPlateMode text;
    _logErrors boolean := false;
    _dropTempTables boolean := false;
    _wellIndex int;
    _note text := 'Created by experiment fraction entry (' + @parentExperiment + ')';
    _prepRequestTissueID text := Null;
    _tmpID int := Null;
    _userID int;
    _newUsername text;
    _matchCount int;
    _newComment text;
    _newExpName text;
    _expId int;
    _wn text;
    _nameFractionLinker text;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If Coalesce(_totalCount, 0) <= 0 Then
            _message := 'Number of child experments cannot be 0';
            RAISE EXCEPTION '%', _message;
        End If;

        -- Don't allow too many child experiments to be created
        --
        If _totalCount > _maxCount Then
            _message := format('Cannot create more than %s child experments', _maxCount);
            RAISE EXCEPTION '%', _message;
        End If;

        -- Make sure that we don't overflow our alloted space for digits
        --
        If _startingIndex + (_totalCount * _step) > 999 Then
            _message := 'Automatic numbering parameters will require too many digits';
            RAISE EXCEPTION '%', _message;
        End If;

        _groupType := Trim(Coalesce(_groupType, ''));

        If char_length(_groupType) = 0 Then
            _groupType := 'Fraction';
        ElsIf _groupType <> 'Fraction' Then
            _message := 'The only supported _groupType is "Fraction"';
            RAISE EXCEPTION '%', _message;
        End If;

        _suffix           := Trim(Coalesce(_suffix, ''));
        _nameSearch       := Trim(Coalesce(_nameSearch, ''));
        _nameReplace      := Trim(Coalesce(_nameReplace, ''));
        _addUnderscore    := Trim(Coalesce(_addUnderscore, 'Yes'));

        _requestOverride  := Trim(Coalesce(_requestOverride,  'parent'));
        _internalStandard := Trim(Coalesce(_internalStandard, 'parent'));
        _postdigestIntStd := Trim(Coalesce(_postdigestIntStd, 'parent'));
        _researcher       := Trim(Coalesce(_researcher,       'parent'));

        _mode             := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode::citext In ('add', 'preview') Then
            RAISE EXCEPTION 'Invalid mode: should be "add" or "preview", not "%"', _mode;
        End If;

        -- Create temporary tables to hold biomaterial and reference compounds associated with the parent experiment
        --
        CREATE TEMP TABLE Tmp_Experiment_to_Biomaterial_Map (
            Biomaterial_Name text not null,
            Biomaterial_ID int null
        );

        CREATE TEMP TABLE Tmp_ExpToRefCompoundMap (
            Compound_IDName text not null,
            Colon_Pos int null,
            Compound_ID int null
        );

        _dropTempTables := true;

        ---------------------------------------------------
        -- Get information for parent experiment
        ---------------------------------------------------

        SELECT exp_id AS ParentExperimentID,
               experiment AS BaseFractionName,
               researcher_username AS ResearcherUsername,
               organism_id AS OrganismID,
               reason AS Reason,
               comment AS Comment,
               created AS Created,
               lab_notebook_ref AS LabNotebook,
               campaign_id AS CampaignID,
               labelling AS Labelling,
               enzyme_id AS EnzymeID,
               sample_prep_request_id AS SamplePrepRequest,
               internal_standard_id AS InternalStandardID,
               post_digest_internal_std_id AS PostdigestIntStdID,
               container_id AS ParentContainerID,
               alkylation AS Alkylation,
               tissue_id AS TissueID
        INTO _parentExperimentInfo
        FROM t_experiments
        WHERE experiment = _parentExperiment;

        If Not FOUND Then
            _message := format('Could not find parent experiment named %s', _parentExperiment);
            RAISE EXCEPTION '%', _message;
        End If;

        -- Make sure _parentExperiment is capitalized properly
        _parentExperiment := _baseFractionName;

        -- Search/replace, if defined
        If char_length(_nameSearch) > 0 Then
            _baseFractionName := Replace(_baseFractionName, _nameSearch, _nameReplace);
        End If;

        -- Append the suffix, if defined
        If char_length(_suffix) > 0 Then
            If Substring(_suffix, 1, 1) In ('_', '-') Then
                _baseFractionName := format('%s%s', _baseFractionName, _suffix);
            Else
                _baseFractionName := format('%s_%s', _baseFractionName, _suffix);
            End If;
        End If;

        ---------------------------------------------------
        -- Cache the biomaterial mapping
        ---------------------------------------------------

        INSERT INTO Tmp_Experiment_to_Biomaterial_Map( Biomaterial_Name,
                                                       Biomaterial_ID )
        SELECT CC.Biomaterial_Name,
               CC.Biomaterial_ID
        FROM t_experiment_biomaterial ECC
             INNER JOIN t_biomaterial CC
               ON ECC.Biomaterial_ID = CC.Biomaterial_ID
        WHERE ECC.Exp_ID = _parentExperimentID;

        ---------------------------------------------------
        -- Cache the reference compound mapping
        ---------------------------------------------------

        INSERT INTO Tmp_ExpToRefCompoundMap( Compound_IDName,
                                             compound_id )
        SELECT RC.compound_id::text,
               RC.compound_id
        FROM t_experiment_reference_compounds ERC
             INNER JOIN t_reference_compound RC
               ON ERC.compound_id = RC.compound_id
        WHERE ERC.exp_id = _parentExperimentID;

        ---------------------------------------------------
        -- Set up and validate wellplate values
        ---------------------------------------------------

        CALL public.validate_wellplate_loading (
                        _wellplateName => _wellplateName,   -- Output
                        _wellNumber    => _wellNumber,      -- Output
                        _totalCount    => _totalCount,
                        _wellIndex     => _wellIndex,       -- Output
                        _message       => _message,         -- Output
                        _returnCode    => _returnCode);     -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Assure that wellplate is in wellplate table (if set)
        ---------------------------------------------------

        If Not _wellplateName Is Null Then
            If _wellplateName::citext = 'new' Then
                _wellplateName := '(generate name)';
                _wellPlateMode := 'add';
            Else
                _wellPlateMode := 'assure';
            End If;

            CALL public.add_update_wellplate (
                            _wellplateName => _wellplateName,   -- Output
                            _note          => _note,
                            _wellPlateMode => _wellPlateMode,
                            _message       => _message,         -- Output
                            _returnCode    => _returnCode,      -- Output
                            _callingUser   => _callingUser)

            If _returnCode <> '' Then
                DROP TABLE Tmp_Experiment_to_Biomaterial_Map;
                DROP TABLE Tmp_ExpToRefCompoundMap;

                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Possibly override prep request ID
        ---------------------------------------------------

        If _requestOverride <> 'parent' Then

            -- Try to cast as an integer, but store null if not an integer
            _samplePrepRequest := public.try_cast(_requestOverride, null::int);

            If _samplePrepRequest Is Null Then
                _logErrors := false;
                _message := format('Prep request ID is not an integer: %s', _requestOverride);
                RAISE EXCEPTION '%', _message;
            End If;

            SELECT tissue_id
            INTO _prepRequestTissueID
            FROM t_sample_prep_request
            WHERE prep_request_id = _samplePrepRequest

            If Not FOUND Then
                _logErrors := false;
                _message := format('Could not find sample prep request: %s', _requestOverride);
                RAISE EXCEPTION '%', _message;
            End If;

            If Coalesce(_tissueID, '') = '' And Coalesce(_prepRequestTissueID, '') <> '' Then
                _tissueID := _prepRequestTissueID;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve predigest internal standard ID
        ---------------------------------------------------

        If _internalStandard <> 'parent' Then
            --
            SELECT internal_standard_id
            INTO _tmpID
            FROM t_internal_standards
            WHERE (name = _internalStandard)

            If Not FOUND Then
                _logErrors := false;
                _message := format('Could not find entry in database for internal standard "%s"', _internalStandard);
                RAISE EXCEPTION '%', _message;
            End If;
            _internalStandardID := _tmpID;
        End If;

        ---------------------------------------------------
        -- Resolve postdigestion internal standard ID
        ---------------------------------------------------

        If _postdigestIntStd <> 'parent' Then

            SELECT internal_standard_id
            INTO _tmpID
            FROM t_internal_standards
            WHERE (name = _postdigestIntStd)

            If Not FOUND Then
                _logErrors := false;
                _message := format('Could not find entry in database for postdigestion internal standard "%s"', _tmpID);
                RAISE EXCEPTION '%', _message;
            End If;
            _postdigestIntStdID := _tmpID;
        End If;

        ---------------------------------------------------
        -- Resolve researcher
        ---------------------------------------------------

        If _researcher <> 'parent' Then
            _userID := public.get_user_id(_researcher);

            If _userID > 0 Then
                -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
                -- Assure that _researcher contains simply the username
                --
                SELECT username
                INTO _researcher
                FROM t_users
                WHERE user_id = _userID;
            Else
                -- Could not find entry in database for _researcher
                -- Try to auto-resolve the name

                CALL public.auto_resolve_name_to_username (
                                _researcher,
                                _matchCount       => _matchCount,   -- Output
                                _matchingUsername => _newUsername,  -- Output
                                _matchingUserID   => _userID);      -- Output

                If _matchCount = 1 Then
                    -- Single match found; update _researcher
                    _researcher := _newUsername
                Else
                    _logErrors := false;
                    _message := format('Could not find entry in database for researcher username "%s"', _researcher);
                    RAISE EXCEPTION '%', _message;
                End If;
            End If;

            _researcherUsername := _researcher;
        End If;

        _logErrors := true;

        If _mode Like '%preview%' Then
            _groupID := 0;
        Else
            ---------------------------------------------------
            -- Make Experiment group entry
            ---------------------------------------------------

            INSERT INTO t_experiment_groups (
                group_type,
                parent_exp_id,
                description,
                prep_lc_run_id,
                created,
                researcher,
                group_name
            ) VALUES (
                _groupType,
                _parentExperimentID,
                _description,
                _prepLCRunID,
                CURRENT_TIMESTAMP,
                _researcherUsername,
                _groupName
            )
            RETURNING group_id
            INTO _groupID;

            ---------------------------------------------------
            -- Add parent experiment to reference group
            ---------------------------------------------------

            INSERT INTO t_experiment_group_members( group_id,
                                                    exp_id )
            VALUES (_groupID, _parentExperimentID);

        End If;

        ---------------------------------------------------
        -- Insert Fractionated experiment entries
        ---------------------------------------------------

        _wn := _wellNumber;

        If _addUnderscore::citext In ('No', 'N', '0') Then
            _nameFractionLinker := '';
        Else
            _nameFractionLinker := '_';
        End If;

        WHILE _fractionCount < _totalCount
        LOOP
            -- Build name for new experiment fraction
            --
            _fullFractionCount := _startingIndex + _fractionCount;

            If  _fullFractionCount < 10 Then
                _fractionNumberText := format('0%s', _fullFractionCount);
            Else
                _fractionNumberText := format('%s',  _fullFractionCount);
            End If;

            _fractionCount := _fractionCount + _step;
            _newComment := format('(Fraction %s of %s)', _fullfractioncount, _totalcount);
            _newExpName := format('%s%s%s', _baseFractionName, _nameFractionLinker, _fractionNumberText);
            _fractionsCreated := _fractionsCreated + 1;

            -- Verify that experiment name is not duplicated in table
            --
            _expId := public.get_experiment_id(_newExpName);

            If _expId <> 0 Then
                _message := format('Failed to add new fraction experiment since existing experiment already exists named: %s', _newExpName);
                _returnCode := 'U5102';
                RAISE EXCEPTION '%', _message;
            End If;

            If _fractionsCreated < 4 Then
                If char_length(_fractionNamePreviewList) = 0 Then
                    _fractionNamePreviewList := _newExpName;
                Else
                    _fractionNamePreviewList := format('%s, %s', _fractionNamePreviewList, _newExpName);
                End If;
            ElsIf _fractionCount = _totalCount Then
                _fractionNamePreviewList := format('%s, ... %s', _fractionNamePreviewList, _newExpName);
            End If;

            If _mode = 'add' Then

                -- Insert new experiment into table

                INSERT INTO t_experiments (
                    experiment,
                    researcher_username,
                    organism_id,
                    reason,
                    comment,
                    created,
                    sample_concentration,
                    lab_notebook_ref,
                    campaign_id,
                    labelling,
                    enzyme_id,
                    sample_prep_request_id,
                    internal_standard_id,
                    post_digest_internal_std_id,
                    wellplate,
                    well,
                    alkylation,
                    tissue_id
                ) VALUES (
                    _newExpName,
                    _researcherUsername,
                    _organismID,
                    _reason,
                    _newComment,
                    CURRENT_TIMESTAMP,
                    '? ug/uL',
                    _labNotebook,
                    _campaignID,
                    _labelling,
                    _enzymeID,
                    _samplePrepRequest,
                    _internalStandardID,
                    _postdigestIntStdID,
                    _wellplateName,
                    _wn,
                    _alkylation,
                    _tissueID
                )
                RETURNING exp_id
                INTO _newExpID;

                -- Add the experiment to biomaterial mapping
                -- The procedure uses table Tmp_Experiment_to_Biomaterial_Map

                CALL public.add_experiment_biomaterial (
                                _newExpID,
                                _updateCachedInfo => false,
                                _message          => _message,      -- Output
                                _returnCode       => _returnCode);  -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Could not add experiment biomaterial to database for experiment: "%", %', _newExpName, _message);
                End If;

                -- Add the experiment to reference compound mapping
                -- The procedure uses table Tmp_ExpToRefCompoundMap
                --
                CALL public.add_experiment_reference_compound (
                                _newExpID,
                                _updateCachedInfo => true,
                                _message          => _message,      -- Output
                                _returnCode       => _returnCode);  -- Output
                --
                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Could not add experiment reference compounds to database for experiment: "%", %', _newExpName, _message
                End If;

                ---------------------------------------------------
                -- Add fractionated experiment reference to experiment group
                ---------------------------------------------------

                INSERT INTO t_experiment_group_members( group_id,
                                                        exp_id )
                VALUES (_groupID, _newExpID);

                ---------------------------------------------------
                -- Append Experiment ID to _experimentIDList and _materialIDList
                ---------------------------------------------------

                If char_length(_experimentIDList) > 0 Then
                    _experimentIDList := format('%s,%s', _experimentIDList, _newExpID);
                Else
                    _experimentIDList := format('%s', _newExpID);
                End If;

                If char_length(_materialIDList) > 0 Then
                    _materialIDList := format('%s,E:%s', _materialIDList, _newExpID);
                Else
                    _materialIDList := format('E:%s', _newExpID);
                End If;

                ---------------------------------------------------
                -- Copy experiment plex info, if defined
                ---------------------------------------------------

                If Exists (SELECT plex_exp_id FROM t_experiment_plex_members WHERE plex_exp_id = _parentExperimentID) Then

                    INSERT INTO t_experiment_plex_members( plex_exp_id,
                                                           channel,
                                                           exp_id,
                                                           channel_type_id,
                                                           comment )
                    SELECT _newExpID AS Plex_Exp_ID,
                           channel,
                           exp_id,
                           channel_type_id,
                           comment
                    FROM t_experiment_plex_members
                    WHERE plex_exp_id = _parentExperimentID;

                    If char_length(_callingUser) > 0 Then
                        -- Call public.alter_entered_by_user to alter the entered_by field in t_experiment_plex_members_history
                        --
                        CALL public.alter_entered_by_user ('public', 't_experiment_plex_members_history', 'plex_exp_id', _newExpID, _callingUser, _message => _alterEnteredByMessage);
                    End If;

                End If;
            End If;

            If _mode = 'add' Then
                ---------------------------------------------------
                -- Update the member_count field in t_experiment_groups
                -- Note that the count includes the parent experiment
                ---------------------------------------------------

                CALL public.update_experiment_group_member_count (_groupID => _groupID);
            End If;

            ---------------------------------------------------
            -- Increment well number
            ---------------------------------------------------

            If Not _wn Is Null Then
                _wellIndex := _wellIndex + 1;
                _wn := public.get_well_position(_wellIndex);
            End If;

        END LOOP;

        If _mode Like '%Preview%' Then
            _message := format('Preview of new fraction names: %s', _fractionNamePreviewList);
        Else

            ---------------------------------------------------
            -- Resolve parent container name
            ---------------------------------------------------

            If _container = 'parent' Then
                SELECT container
                INTO _container
                FROM t_material_containers
                WHERE container_id = _parentContainerID;
            End If;

            ---------------------------------------------------
            -- Move new fraction experiments to container
            ---------------------------------------------------

            CALL public.update_material_items (
                            _mode        => 'move_material',
                            _itemList    => _materialIDList,
                            _itemType    => 'mixed_material',
                            _newValue    => _container,
                            _comment     => '',
                            _message     => _message,       -- Output
                            _returnCode  => _returnCode,    -- Output
                            _callingUser => _callingUser);

                      If _returnCode <> '' Then
                RAISE EXCEPTION '%', _message;
            End If;

            ---------------------------------------------------
            -- Now copy the aux info from the parent experiment
            -- into the fractionated experiments
            ---------------------------------------------------

            CALL public.copy_aux_info_multi_id (
                            _targetName         => 'Experiment',
                            _targetEntityIDList => _experimentIDList,
                            _categoryName       => '',
                            _subCategoryName    => '',
                            _sourceEntityID     => _parentExperimentID,
                            _mode               => 'copyAll',
                            _message            => _message,        -- Output
                            _returnCode         => _returnCode)     -- Output

            If _returnCode <> '' Then
                _message := format('Error copying Aux Info from parent Experiment to fractionated experiments, code %s', _returnCode);
                RAISE EXCEPTION '%', _message;
            End If;

            If _message = '' Then
                _message := format('New fraction names: %s', _fractionNamePreviewList);
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
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

COMMENT ON PROCEDURE public.add_experiment_fractions IS 'AddExperimentFractions';

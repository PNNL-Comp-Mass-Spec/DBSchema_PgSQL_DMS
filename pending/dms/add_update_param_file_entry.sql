--
CREATE OR REPLACE PROCEDURE public.add_update_param_file_entry
(
    _paramFileID int,
    _entrySeqOrder int,
    _entryType text,
    _entrySpecifier text,
    _entryValue text,
    _mode text = 'add',
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing parameter file entry
**
**      This only applies to SEQUEST parameter files, and SEQUEST was retired in 2019
**
**  Arguments:
**    _paramFileID      Name of new parameter file description
**    _entrySeqOrder    Entry sequence order
**    _entryType        Entry type; for modifications, will be 'DynamicModification', 'StaticModification', 'IsotopicModification', or 'TermDynamicModification'; for other parameters, will be the name entered into t_param_entries, either 'BasicParam' or 'AdvancedParam'
**    _entrySpecifier   Entry specifier; For modifications, this is the residues affected for dynamic, static, or isotopic mods; for other entries, will be the name entered into t_param_entries, column Entry_Specifier, e.g. 'FragmentMassType' or 'PeptideMassTolerance'
**    _entryValue       Entry value
**    _mode             Mode: 'add' or 'update'
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   kja
**  Date:   07/22/2004
**          08/10/2004 kja - Added in code to update mapping table as well
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will populate field Entered_By with this name
**          01/20/2010 mem - Added support for dynamic peptide terminus mods (TermDynamicModification)
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _existingCount int := 0;
    _localSymbolID int;
    _typeSymbol text;
    _affectedResidue text;
    _affectedResidueID int;
    _massCorrectionID int;
    _counter int;
    _paramEntryID int := 0;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _paramFileID    := Coalesce(_paramFileID, 0);
    _entrySeqOrder  := Coalesce(_entrySeqOrder, 0);
    _entryType      := Trim(Coalesce(_entryType, ''));
    _entrySpecifier := Trim(Coalesce(_entrySpecifier, ''));
    _entryValue     := Trim(Coalesce(_entryValue, ''));
    _infoOnly       := Coalesce(_infoOnly, false);
    _mode           := Trim(Lower(Coalesce(_mode, '')));

    If _paramFileID = 0 Then
        _returnCode := 'U5201';
        RAISE EXCEPTION 'ParamFileID cannot be 0';
    End If;

    If _entrySeqOrder = 0 Then
        _returnCode := 'U5202';
        RAISE EXCEPTION 'EntrySeqOrder cannot be 0';
    End If;

    If _entryType = '' Then
        _returnCode := 'U5203';
        RAISE EXCEPTION 'EntryType must be specified';
    End If;

    If _entrySpecifier = '' Then
        _returnCode := 'U5204';
        RAISE EXCEPTION 'EntrySpecifier must be specified';

    End If;

    If _entryValue = '' Then
        _returnCode := 'U5205';
        RAISE EXCEPTION 'EntryValue must be specified';
    End If;

    ---------------------------------------------------
    -- Detour if Mass mod
    ---------------------------------------------------

    If (_entryType::citext In ('DynamicModification', 'StaticModification', 'IsotopicModification', 'TermDynamicModification')) Then

        If _infoOnly Then
            RAISE INFO '_entryType = %', _entryType;
        End If;

        If (_entryType = 'StaticModification') Then
            _localSymbolID := 0;
            _typeSymbol := 'S';
            _affectedResidue := _entrySpecifier;
        End If;

        If (_entryType = 'IsotopicModification') Then
            _localSymbolID := 0;
            _typeSymbol := 'I';
            _affectedResidueID := 1;
        End If;

        If (_entryType = 'DynamicModification') Then
            _localSymbolID := public.get_next_local_symbol_id(_paramFileID);
            _typeSymbol := 'D';
        End If;

        If _entryType = 'TermDynamicModification' Then
            _localSymbolID := 0;

            If _entrySpecifier = '<' Then
                _localSymbolID := 9;
            End If;

            If _entrySpecifier = '>' Then
                _localSymbolID := 8;
            End If;

            _typeSymbol := 'D';

            If _localSymbolID = 0 Then
                _message := format('EntrySpecifier of "%s" is invalid for ModType "TermDynamicModification"; must be < or >', _entrySpecifier);
                RAISE WARNING '%', _message;

                _returnCode := 'U5201';
                RETURN;
            End If;

        End If;

        _counter := 0;

        _massCorrectionID := GetMassCorrectionID(_entryValue);

        If _infoOnly Then
            RAISE INFO 'Mod "%" corresponds to _massCorrectionID %', _entryValue, _massCorrectionID;
        End If;

        WHILE _counter < char_length(_entryspecifier)
        LOOP

            _counter := _counter + 1;

            If (_entryType = 'StaticModification') And _counter < 2 Then

                If char_length(_entrySpecifier) > 1 Then
                    -- The mod is a terminal mod

                    If _entrySpecifier = 'N_Term_Protein' Then
                        _affectedResidue := '[';
                        _typeSymbol := 'P';
                    End If;

                    If _entrySpecifier = 'C_Term_Protein' Then
                        _affectedResidue := ']';
                        _typeSymbol := 'P';
                    End If;

                    If _entrySpecifier = 'N_Term_Peptide' Then
                        _affectedResidue := '<';
                        _typeSymbol := 'T';
                    End If;

                    If _entrySpecifier = 'C_Term_Peptide' Then
                        _affectedResidue := '>';
                        _typeSymbol := 'T';
                    End If;
                End If;

                SELECT residue_id
                INTO _affectedResidueID
                FROM t_residues
                WHERE residue_symbol = _affectedResidue;

            Else
                -- Jump out of the while if this is a static modification or a 'TermDynamicModification'
                If (_entryType = 'StaticModification' Or _entryType = 'TermDynamicModification') And _counter > 1 Then
                    break;
                End If;
            End If;

            If _entryType = 'DynamicModification' or _entryType = 'TermDynamicModification' Then
                _affectedResidue := Substring(_entrySpecifier, _counter, 1);

                SELECT residue_id
                INTO _affectedResidueID
                FROM t_residues
                WHERE residue_symbol = _affectedResidue;
            End If;

            If _infoOnly Then
                SELECT  _entryType AS EntryType,
                        _affectedResidue AS AffectedReseidue,
                        _affectedResidueID AS AffectedResidueID,
                        _localSymbolID AS LocalSymbolID,
                        _massCorrectionID AS MassCorrectionID,
                        _paramFileID AS ParamFileID,
                        _typeSymbol AS TypeSymbol;
            Else
                INSERT INTO t_param_file_mass_mods (
                    residue_id,
                    local_symbol_id,
                    mass_correction_id,
                    param_file_id,
                    mod_type_symbol
                ) VALUES (
                    _affectedResidueID,
                    _localSymbolID,
                    _massCorrectionID,
                    _paramFileID,
                    _typeSymbol
                )

            End If;

        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Entry is not a modification related entry
    -- Is it already in database?
    ---------------------------------------------------

    SELECT param_entry_id
    INTO _paramEntryID
    FROM t_param_entries
    WHERE param_file_id = _paramFileID AND
          entry_type = _entryType::citext AND
          entry_specifier = _entrySpecifier::citext AND
          entry_sequence_order = _entrySeqOrder;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    If _mode = 'add' And _existingCount > 0 Then
        -- Auto-switch the mode
        _mode := 'update';
    End If;

    -- Cannot update a non-existent entry

    If _mode = 'update' And _existingCount = 0 Then
        _message := 'Cannot update: param entry matching the specified parameters not found in table t_param_entries';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then
        If _infoOnly Then
            RAISE INFO 'Mode: %, SeqOrder: %, Type: %, Specifier: %, Value: %, ParamFileID: %',
                       _mode, _entrySeqOrder, _entryType, _entrySpecifier, _entryValue, _paramFileID;
        Else
            INSERT INTO t_param_entries (
                entry_sequence_order,
                entry_type,
                entry_specifier,
                entry_value,
                param_file_id
            ) VALUES (
                _entrySeqOrder,
                _entryType,
                _entrySpecifier,
                _entryValue,
                _paramFileID
            )
            RETURNING param_entry_id
            INTO _paramEntryID;

            -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                CALL public.alter_entered_by_user ('public', 't_param_entries', 'param_entry_id', _paramEntryID, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then
        If _infoOnly Then
            RAISE INFO 'Mode: %, SeqOrder: %, Type: %, Specifier: %, Value: %, ParamFileID: %, ParamEntryID: %',
                       _mode, _entrySeqOrder, _entryType, _entrySpecifier, _entryValue, _paramFileID, _paramEntryID;
        Else

            UPDATE t_param_entries
            SET entry_specifier = _entrySpecifier,
                entry_value = _entryValue
            WHERE param_entry_id = _paramEntryID;

            -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                CALL public.alter_entered_by_user ('public', 't_param_entries', 'param_entry_id', _paramEntryID, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_param_file_entry IS 'AddUpdateParamFileEntry';

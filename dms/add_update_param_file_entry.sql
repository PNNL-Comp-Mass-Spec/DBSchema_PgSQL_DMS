--
-- Name: add_update_param_file_entry(integer, integer, text, text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_param_file_entry(IN _paramfileid integer, IN _entryseqorder integer, IN _entrytype text, IN _entryspecifier text, IN _entryvalue text, IN _mode text DEFAULT 'add'::text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
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
**    _entrySpecifier   Entry specifier; for modifications, this is the residues affected for dynamic, static, or isotopic mods; for other entries, will be the name entered into t_param_entries, column Entry_Specifier, e.g. 'FragmentMassType' or 'PeptideMassTolerance'
**    _entryValue       Entry value; for modifications, this is the modification mass; for other entries, this is the value associated with the given specifier
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
**          01/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _existingCount int := 0;
    _localSymbolID int := 0;
    _typeSymbol text;
    _affectedResidue citext;
    _affectedResidueID int;
    _massCorrectionID int;
    _modMass float8;
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
    _callingUser    := Trim(Coalesce(_callingUser, ''));
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

    If _entryType::citext In ('DynamicModification', 'StaticModification', 'IsotopicModification', 'TermDynamicModification') Then

        If _entryType::citext = 'StaticModification' Then
            _localSymbolID := 0;
            _typeSymbol := 'S';
            _affectedResidue := _entrySpecifier;
        End If;

        If _entryType::citext = 'IsotopicModification' Then
            _localSymbolID := 0;
            _typeSymbol := 'I';
            _affectedResidueID := 1;
        End If;

        If _entryType::citext = 'DynamicModification' Then
            _localSymbolID := public.get_next_local_symbol_id(_paramFileID);
            _typeSymbol := 'D';
        End If;

        If _entryType::citext = 'TermDynamicModification' Then
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

                _returnCode := 'U5206';
                RETURN;
            End If;

        End If;

        _modMass := public.try_cast(_entryValue, null::float8);

        _massCorrectionID := get_mass_correction_id(_modMass);

        If _infoOnly Then
            RAISE INFO 'Mod "%" corresponds to _massCorrectionID %', _entryValue, _massCorrectionID;
        End If;

        FOR _counter IN 1 .. char_length(_entrySpecifier)
        LOOP

            If _entryType::citext = 'StaticModification' And _counter < 2 Then

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

                If Not FOUND Then
                    _returnCode := 'U5207';
                    RAISE EXCEPTION 'Invalid affected residue: %', _affectedResidue;
                End If;
            Else
                -- Jump out of the loop if on the second iteration and this is a static modification or a 'TermDynamicModification'
                If _entryType::citext In ('StaticModification', 'TermDynamicModification') And _counter > 1 Then
                    -- Break out of the for loop
                    EXIT;
                End If;
            End If;

            If _entryType::citext In ('DynamicModification', 'TermDynamicModification') Then
                _affectedResidue := Substring(_entrySpecifier, _counter, 1);

                SELECT residue_id
                INTO _affectedResidueID
                FROM t_residues
                WHERE residue_symbol = _affectedResidue;

                If Not FOUND Then
                    _returnCode := 'U5208';
                    RAISE EXCEPTION 'Invalid affected residue: %', _affectedResidue;
                End If;
            End If;

            If _infoOnly Then
                RAISE INFO '';
                RAISE INFO 'Entry type:          %', _entryType;
                RAISE INFO 'Affected residue:    %', _affectedResidue;
                RAISE INFO 'Affected residue ID: %', _affectedResidueID;
                RAISE INFO 'Local symbol ID:     %', _localSymbolID;
                RAISE INFO 'Mass correction ID:  %', _massCorrectionID;
                RAISE INFO 'Parameter file ID:   %', _paramFileID;
                RAISE INFO 'Type symbol:         %', _typeSymbol;
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
                );

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

        _returnCode := 'U5207';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then
        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Mode:        %', _mode;
            RAISE INFO 'SeqOrder:    %', _entrySeqOrder;
            RAISE INFO 'Type:        %', _entryType;
            RAISE INFO 'Specifier:   %', _entrySpecifier;
            RAISE INFO 'Value:       %', _entryValue;
            RAISE INFO 'ParamFileID: %', _paramFileID;
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
            If _callingUser <> '' Then
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
                entry_value     = _entryValue
            WHERE param_entry_id = _paramEntryID;

            -- If _callingUser is defined, update entered_by in t_analysis_job_processor_group
            If _callingUser <> '' Then
                CALL public.alter_entered_by_user ('public', 't_param_entries', 'param_entry_id', _paramEntryID, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_param_file_entry(IN _paramfileid integer, IN _entryseqorder integer, IN _entrytype text, IN _entryspecifier text, IN _entryvalue text, IN _mode text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_param_file_entry(IN _paramfileid integer, IN _entryseqorder integer, IN _entrytype text, IN _entryspecifier text, IN _entryvalue text, IN _mode text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_param_file_entry(IN _paramfileid integer, IN _entryseqorder integer, IN _entrytype text, IN _entryspecifier text, IN _entryvalue text, IN _mode text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateParamFileEntry';


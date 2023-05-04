--
CREATE OR REPLACE PROCEDURE public.duplicate_param_file_mass_mods
(
    _sourceParamFileID int,
    _destParamFileID int,
    _updateParamEntries boolean = true,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies the mass modification definitions from
**      an existing parameter file to a new parameter file
**
**      Requires that the new parameter file exists in
**      T_Param_Files, but does not yet have any entries
**      in T_Param_File_Mass_Mods
**
**      If _updateParamEntries is true, will also populate T_Param_Entries
**
**  Arguments:
**    _updateParamEntries   When true, updates T_Param_Entries in addition to T_Param_File_Mass_Mods
**
**  Auth:   mem
**  Date:   05/04/2009
**          07/01/2009 mem - Added parameter _destParamFileID
**          07/22/2009 mem - Now returning the suggested query for tweaking the newly entered mass mods
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _s text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _updateParamEntries := Coalesce(_updateParamEntries, true);
    _infoOnly := Coalesce(_infoOnly, false);

    If _sourceParamFileID Is Null Or _destParamFileID Is Null Then
        _message := 'Both the source and target parameter file ID must be defined; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    _s := '';
    _s := _s || ' SELECT PFMM.*, R.residue_symbol,';
    _s := _s ||        ' MCF.mass_correction_tag, MCF.monoisotopic_mass,';
    _s := _s ||        ' SLS.local_symbol, R.description AS Residue_Desc';
    _s := _s || ' FROM t_param_file_mass_mods PFMM';
    _s := _s ||      ' INNER JOIN t_residues R';
    _s := _s ||        ' ON PFMM.residue_id = R.residue_id';
    _s := _s ||      ' INNER JOIN t_mass_correction_factors MCF';
    _s := _s ||        ' ON PFMM.mass_correction_id = MCF.mass_correction_id';
    _s := _s ||      ' INNER JOIN t_seq_local_symbols_list SLS';
    _s := _s ||        ' ON PFMM.local_symbol_id = SLS.local_symbol_id';
    _s := _s ||      ' WHERE (PFMM.param_file_id = ' || _destParamFileID::text || ')';
    _s := _s || ' ORDER BY PFMM.param_file_id, PFMM.local_symbol_id, R.residue_symbol';

    RAISE INFO '%', _s;

    -----------------------------------------
    -- Make sure the parameter file IDs are valid
    -----------------------------------------

    If Not Exists (SELECT * FROM t_param_files WHERE param_file_id = _sourceParamFileID) Then
        _message := 'Source Param File ID (' || _sourceParamFileID::text || ') not found in t_param_files; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM t_param_files WHERE param_file_id = _destParamFileID) Then
        _message := 'Destination Param File ID (' || _destParamFileID::text || ') not found in t_param_files; unable to continue';
        _returnCode := 'U5202';
        RETURN;
    End If;

    -----------------------------------------
    -- Make sure the destination parameter file does not yet have any mass mods defined
    -----------------------------------------

    If Exists (SELECT * FROM t_param_file_mass_mods WHERE param_file_id = _destParamFileID) Then
        _message := 'Destination Param File ID (' || _destParamFileID::text || ') already has entries in t_param_file_mass_mods; unable to continue';
        _returnCode := 'U5203';
        RETURN;
    End If;

    If _updateParamEntries Then
        If Exists (SELECT * FROM t_param_entries WHERE param_file_id = _destParamFileID) Then
            _message := 'Destination Param File ID (' || _destParamFileID::text || ') already has entries in t_param_entries; unable to continue';
            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    If _infoOnly Then
        -- ToDo: display this using Raise Info

        SELECT PFMM.*, R.residue_symbol, MCF.mass_correction_tag,
            MCF.monoisotopic_mass, SLS.local_symbol,
            R.description AS Residue_Desc,
            _destParamFileID AS Destination_Param_File_ID
        FROM t_param_file_mass_mods PFMM INNER JOIN
            t_residues R ON
            PFMM.residue_id = R.residue_id INNER JOIN
            t_mass_correction_factors MCF ON
            PFMM.mass_correction_id = MCF.mass_correction_id INNER JOIN
            t_seq_local_symbols_list SLS ON
            PFMM.local_symbol_id = SLS.local_symbol_id
        WHERE (PFMM.param_file_id = _sourceParamFileID)
        ORDER BY PFMM.param_file_id, PFMM.local_symbol_id, R.residue_symbol

        If _updateParamEntries Then
            SELECT PE.*, _destParamFileID AS Destination_Param_File_ID
            FROM t_param_entries PE
            WHERE (param_file_id = _sourceParamFileID)
            ORDER BY PE.entry_sequence_order
        End If;
    Else
        -- Copy the mass mod definitions
        INSERT INTO t_param_file_mass_mods( param_file_id,
                                            residue_id,
                                            local_symbol_id,
                                            mod_type_symbol,
                                            mass_correction_id )
        SELECT _destParamFileID AS Param_File_ID,
            residue_id,
            local_symbol_id,
            mod_type_symbol,
            mass_correction_id
        FROM t_param_file_mass_mods PFMM
        WHERE (param_file_id = _sourceParamFileID)
        ORDER BY param_file_id, mod_type_symbol, local_symbol_id;

        If Not FOUND Then
            _message := 'Warning: Param File ID ' || _sourceParamFileID::text || ' does not have any entries in t_param_file_mass_mods';
        End If;

        If _updateParamEntries Then
            INSERT INTO t_param_entries( entry_sequence_order,
                                         entry_type,
                                         entry_specifier,
                                         entry_value,
                                         param_file_id )
            SELECT entry_sequence_order,
                   entry_type,
                   entry_specifier,
                   entry_value,
                   _destParamFileID AS Param_File_ID
            FROM t_param_entries
            WHERE (param_file_id = _sourceParamFileID)
            ORDER BY entry_sequence_order
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;

        SELECT *
        FROM V_Param_File_Mass_Mods
        WHERE Param_File_ID = _destParamFileID

    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.duplicate_param_file_mass_mods IS 'DuplicateParamFileMassMods';

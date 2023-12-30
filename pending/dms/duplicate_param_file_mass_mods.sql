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
**      Copy the mass modification definitions from an existing parameter file to a new parameter file
**
**      Requires that the new parameter file exists in t_param_files,
**      but does not yet have any entries in t_param_file_mass_mods
**
**  Arguments:
**    _sourceParamFileID    Source parameter file ID
**    _destParamFileID      Destination parameter file ID
**    _updateParamEntries   When true, updates t_param_entries in addition to t_param_file_mass_mods
**                          However, table t_param_entries is only used by SEQUEST parameter files, and SEQUEST was retired in 2019, so this argument is obsolete
**    _infoOnly             When true, preview the modification definitions that would be copied
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   05/04/2009 mem - Initial version
**          07/01/2009 mem - Added parameter _destParamFileID
**          07/22/2009 mem - Now returning the suggested query for tweaking the newly entered mass mods
**          11/30/2018 mem - Renamed the Monoisotopic_Mass and Average_Mass columns
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sql text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _formatSpecifierPE text;
    _infoHeadPE text;
    _infoHeadSeparatorPE text;

BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _updateParamEntries := Coalesce(_updateParamEntries, true);
    _infoOnly := Coalesce(_infoOnly, false);

    If _sourceParamFileID Is Null Or _destParamFileID Is Null Then
        _message := 'Both the source and target parameter file ID must be specified; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    _sql := 'SELECT PFMM.*, R.residue_symbol, '
                   'MCF.mass_correction_tag, MCF.monoisotopic_mass, '
                   'SLS.local_symbol, R.description AS Residue_Desc'
            'FROM t_param_file_mass_mods PFMM '
                 'INNER JOIN t_residues R '
                   'ON PFMM.residue_id = R.residue_id '
                 'INNER JOIN t_mass_correction_factors MCF '
                   'ON PFMM.mass_correction_id = MCF.mass_correction_id '
                 'INNER JOIN t_seq_local_symbols_list SLS '
                   'ON PFMM.local_symbol_id = SLS.local_symbol_id ' ||
     format('WHERE (PFMM.param_file_id = %s) ', _destParamFileID) ||
            'ORDER BY PFMM.param_file_id, PFMM.local_symbol_id, R.residue_symbol';

    RAISE INFO '%', _sql;

    -----------------------------------------
    -- Make sure the parameter file IDs are valid
    -----------------------------------------

    If Not Exists (SELECT param_file_id FROM t_param_files WHERE param_file_id = _sourceParamFileID) Then
        _message := format('Source Param File ID (%s) not found in t_param_files; unable to continue', _sourceParamFileID);
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not Exists (SELECT param_file_id FROM t_param_files WHERE param_file_id = _destParamFileID) Then
        _message := format('Destination Param File ID (%s) not found in t_param_files; unable to continue', _destParamFileID);
        _returnCode := 'U5202';
        RETURN;
    End If;

    -----------------------------------------
    -- Make sure the destination parameter file does not yet have any mass mods defined
    -----------------------------------------

    If Exists (SELECT param_file_id FROM t_param_file_mass_mods WHERE param_file_id = _destParamFileID) Then
        _message := format('Destination Param File ID (%s) already has entries in t_param_file_mass_mods; unable to continue', _destParamFileID);
        _returnCode := 'U5203';
        RETURN;
    End If;

    If _updateParamEntries Then
        If Exists (SELECT param_file_id FROM t_param_entries WHERE param_file_id = _destParamFileID) Then
            _message := format('Destination Param File ID (%s) already has entries in t_param_entries; unable to continue', _destParamFileID);
            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    -----------------------------------------
    -- Construct the format specifier used to either
    -- preview the source parameter file mass mods,
    -- or show the data after adding rows to t_param_file_mass_mods
    -----------------------------------------

    _formatSpecifier := '%-12s %-10s %-15s %-18s %-14s %-15s %-15s %-7s %-19s %-17s %-12s %-12s %-12s';

    _infoHead := format(_formatSpecifier,
                        'Mod_Entry_ID',
                        'Residue_ID',
                        'Local_Symbol_ID',
                        'Mass_Correction_ID',
                        'Source_File_ID',
                        'Mod_Type_Symbol',
                        'Maxquant_Mod_ID',
                        'Residue',
                        'Mass_Correction_Tag',
                        'Monoisotopic_Mass',
                        'Local_Symbol',
                        'Residue_Desc',
                        'Dest_File_ID'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '------------',
                                 '----------',
                                 '---------------',
                                 '------------------',
                                 '--------------',
                                 '---------------',
                                 '---------------',
                                 '-------',
                                 '-------------------',
                                 '-----------------',
                                 '------------',
                                 '------------',
                                 '------------'
                                );

    If _infoOnly Then

        RAISE INFO '';

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT PFMM.mod_entry_id,
                   PFMM.residue_id,
                   PFMM.local_symbol_id,
                   PFMM.mass_correction_id,
                   PFMM.param_file_id AS source_file_id,
                   PFMM.mod_type_symbol,
                   PFMM.maxquant_mod_id,
                   R.residue_symbol AS residue,
                   MCF.mass_correction_tag,
                   MCF.monoisotopic_mass,
                   SLS.local_symbol,
                   R.description AS residue_desc,
                   _destParamFileID AS dest_file_id
            FROM t_param_file_mass_mods PFMM
                 INNER JOIN t_residues R
                   ON PFMM.residue_id = R.residue_id
                 INNER JOIN t_mass_correction_factors MCF
                   ON PFMM.mass_correction_id = MCF.mass_correction_id
                 INNER JOIN t_seq_local_symbols_list SLS
                   ON PFMM.local_symbol_id = SLS.local_symbol_id
            WHERE PFMM.param_file_id = _sourceParamFileID
            ORDER BY PFMM.param_file_id, PFMM.local_symbol_id, R.residue_symbol
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.mod_entry_id,
                                _previewData.residue_id,
                                _previewData.local_symbol_id,
                                _previewData.mass_correction_id,
                                _previewData.source_file_id
                                _previewData.mod_type_symbol,
                                _previewData.maxquant_mod_id,
                                _previewData.residue,
                                _previewData.mass_correction_tag,
                                _previewData.monoisotopic_mass,
                                _previewData.local_symbol,
                                _previewData.residue_desc,
                                _previewData.dest_file_id
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        If _updateParamEntries And Exists (SELECT param_file_id FROM t_param_entries WHERE param_file_id = _sourceParamFileID)

            RAISE INFO '';

            _formatSpecifierPE := '%-14s %-20s %-15s %-35s %-15s %-25s';

            _infoHeadPE := format(_formatSpecifierPE,
                                  'Param_Entry_ID',
                                  'Entry_Sequence_Order',
                                  'Entry_Type',
                                  'Entry_Specifier',
                                  'Entry_Value',
                                  'Destination_Param_File_ID'
                                 );

            _infoHeadSeparatorPE := format(_formatSpecifierPE,
                                         '--------------',
                                         '--------------------',
                                         '---------------',
                                         '-----------------------------------',
                                         '---------------',
                                         '-------------------------'
                                          );

            RAISE INFO '%', _infoHeadPE;
            RAISE INFO '%', _infoHeadSeparatorPE;

            FOR _previewData IN
                SELECT PE.Param_Entry_ID,
                       PE.Entry_Sequence_Order,
                       PE.Entry_Type,
                       PE.Entry_Specifier,
                       PE.Entry_Value,
                       _destParamFileID AS Destination_Param_File_ID
                FROM t_param_entries PE
                WHERE param_file_id = _sourceParamFileID
                ORDER BY PE.entry_sequence_order

            LOOP
                _infoData := format(_formatSpecifierPE,
                                    _previewData.Param_Entry_ID,
                                    _previewData.Entry_Sequence_Order,
                                    _previewData.Entry_Type,
                                    _previewData.Entry_Specifier,
                                    _previewData.Entry_Value,
                                    _previewData.Destination_Param_File_ID
                        );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        RETURN;
    End If;

    -----------------------------------------
    -- Copy the mass mod definitions
    -----------------------------------------

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
        _message := format('Warning: Param File ID %s does not have any entries in t_param_file_mass_mods', _sourceParamFileID);
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

    End If;

    -----------------------------------------
    -- Show the newly added rows
    -----------------------------------------

    RAISE INFO '';
    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT PFMM.mod_entry_id,
               PFMM.residue_id,
               PFMM.local_symbol_id,
               PFMM.mass_correction_id,
               _sourceParamFileID AS source_file_id,
               PFMM.mod_type_symbol,
               PFMM.maxquant_mod_id,
               R.residue_symbol AS residue,
               MCF.mass_correction_tag,
               MCF.monoisotopic_mass,
               SLS.local_symbol,
               R.description AS residue_desc,
               PFMM.param_file_id AS dest_file_id
        FROM t_param_file_mass_mods PFMM
             INNER JOIN t_residues R
               ON PFMM.residue_id = R.residue_id
             INNER JOIN t_mass_correction_factors MCF
               ON PFMM.mass_correction_id = MCF.mass_correction_id
             INNER JOIN t_seq_local_symbols_list SLS
               ON PFMM.local_symbol_id = SLS.local_symbol_id
        WHERE PFMM.param_file_id = _destParamFileID
        ORDER BY PFMM.param_file_id, PFMM.local_symbol_id, R.residue_symbol
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.mod_entry_id,
                            _previewData.residue_id,
                            _previewData.local_symbol_id,
                            _previewData.mass_correction_id,
                            _previewData.source_file_id
                            _previewData.mod_type_symbol,
                            _previewData.maxquant_mod_id,
                            _previewData.residue,
                            _previewData.mass_correction_tag,
                            _previewData.monoisotopic_mass,
                            _previewData.local_symbol,
                            _previewData.residue_desc,
                            _previewData.dest_file_id
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.duplicate_param_file_mass_mods IS 'DuplicateParamFileMassMods';

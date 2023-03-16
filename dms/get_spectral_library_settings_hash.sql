--
-- Name: get_spectral_library_settings_hash(integer, text, text, real, real, integer, text, integer, integer, integer, real, real, integer, integer, integer, text, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_spectral_library_settings_hash(_library_id integer, _protein_collection_list text DEFAULT ''::text, _organism_db_file text DEFAULT ''::text, _fragment_ion_mz_min real DEFAULT 0, _fragment_ion_mz_max real DEFAULT 0, _trim_n_terminal_met integer DEFAULT 0, _cleavage_specificity text DEFAULT ''::text, _missed_cleavages integer DEFAULT 0, _peptide_length_min integer DEFAULT 0, _peptide_length_max integer DEFAULT 0, _precursor_mz_min real DEFAULT 0, _precursor_mz_max real DEFAULT 0, _precursor_charge_min integer DEFAULT 0, _precursor_charge_max integer DEFAULT 0, _static_cys_carbamidomethyl integer DEFAULT 0, _static_mods text DEFAULT ''::text, _dynamic_mods text DEFAULT ''::text, _max_dynamic_mods integer DEFAULT 0, _showdebug boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    Computes a SHA-1 hash value using the settings used to create an in-silico digest based spectral library
**
**    If the Spectral library ID is non-zero, reads settings from T_Spectral_Library
**    Otherwise, uses the values provided to the other parameters
**
**  Returns:
**    Computed hash, or an empty string if an error
**
**  Auth:   mem
**  Date:   03/15/2023 mem - Initial Release
**
*****************************************************/
DECLARE
    _settings text;
    _hash text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _library_id := Coalesce(_library_id, 0);
    _showDebug := Coalesce(_showDebug, false);

    If _library_id > 0 Then
        SELECT Protein_Collection_List, Organism_DB_File,
               Fragment_Ion_Mz_Min, Fragment_Ion_Mz_Max,
               Trim_N_Terminal_Met, Cleavage_Specificity, Missed_Cleavages,
               Peptide_Length_Min, Peptide_Length_Max,
               Precursor_Mz_Min, Precursor_Mz_Max,
               Precursor_Charge_Min, Precursor_Charge_Max,
               Static_Cys_Carbamidomethyl,
               Static_Mods, Dynamic_Mods,
               Max_Dynamic_Mods
        INTO _Protein_Collection_List, _Organism_DB_File,
             _Fragment_Ion_Mz_Min, _Fragment_Ion_Mz_Max,
             _Trim_N_Terminal_Met, _Cleavage_Specificity, _Missed_Cleavages,
             _Peptide_Length_Min, _Peptide_Length_Max,
             _Precursor_Mz_Min, _Precursor_Mz_Max,
             _Precursor_Charge_Min, _Precursor_Charge_Max,
             _Static_Cys_Carbamidomethyl,
             _Static_Mods, _Dynamic_Mods,
             _Max_Dynamic_Mods
        FROM T_Spectral_Library
        WHERE Library_ID = _library_id;

        If Not FOUND Then
            RAISE WARNING 'Spectral library ID not found in T_Spectral_Library: %', _library_id;
            Return '';
        End If;
    Else
        _Protein_Collection_List := Coalesce(_Protein_Collection_List, '');
        _Organism_DB_File := Coalesce(_Organism_DB_File, '');
        _Fragment_Ion_Mz_Min := Coalesce(_Fragment_Ion_Mz_Min, 0);
        _Fragment_Ion_Mz_Max := Coalesce(_Fragment_Ion_Mz_Max, 0);
        _Trim_N_Terminal_Met := Coalesce(_Trim_N_Terminal_Met, 0);
        _Cleavage_Specificity := Coalesce(_Cleavage_Specificity, '');
        _Missed_Cleavages := Coalesce(_Missed_Cleavages, 0);
        _Peptide_Length_Min := Coalesce(_Peptide_Length_Min, 0);
        _Peptide_Length_Max := Coalesce(_Peptide_Length_Max, 0);
        _Precursor_Mz_Min := Coalesce(_Precursor_Mz_Min, 0);
        _Precursor_Mz_Max := Coalesce(_Precursor_Mz_Max, 0);
        _Precursor_Charge_Min := Coalesce(_Precursor_Charge_Min, 0);
        _Precursor_Charge_Max := Coalesce(_Precursor_Charge_Max, 0);
        _Static_Cys_Carbamidomethyl := Coalesce(_Static_Cys_Carbamidomethyl, 0);
        _Static_Mods := Coalesce(_Static_Mods, '');
        _Dynamic_Mods := Coalesce(_Dynamic_Mods, '');
        _Max_Dynamic_Mods := Coalesce(_Max_Dynamic_Mods, 0);
    End If;

    -- Remove any spaces in the static and dynamic mods
    _Static_Mods = Replace(_Static_Mods, ' ', '');
    _Dynamic_Mods = Replace(_Dynamic_Mods, ' ', '');

    ---------------------------------------------------
    -- Store the options in _settings
    ---------------------------------------------------

    _settings = _Protein_Collection_List || '_' ||
                _Organism_DB_File || '_' ||
                Cast(_Fragment_Ion_Mz_Min As text) || '_' ||
                Cast(_Fragment_Ion_Mz_Max As text) || '_' ||
                Cast(_Trim_N_Terminal_Met As text) || '_' ||
                Cast(_Cleavage_Specificity As text) || '_' ||
                Cast(_Missed_Cleavages As text) || '_' ||
                Cast(_Peptide_Length_Min As text) || '_' ||
                Cast(_Peptide_Length_Max As text) || '_' ||
                Cast(_Precursor_Mz_Min As text) || '_' ||
                Cast(_Precursor_Mz_Max As text) || '_' ||
                Cast(_Precursor_Charge_Min As text) || '_' ||
                Cast(_Precursor_Charge_Max As text) || '_' ||
                Cast(_Static_Cys_Carbamidomethyl As text) || '_' ||
                _Static_Mods || '_' ||
                _Dynamic_Mods || '_' ||
                Cast(_max_dynamic_mods As text) || '_';

    If _showDebug Then
        RAISE INFO '%', _settings;
    End If;

    ---------------------------------------------------
    -- Convert _settings to a SHA-1 hash (upper case hex string)
    ---------------------------------------------------

    _hash := sw.get_sha1_hash(_settings);

    RETURN _hash;
END
$$;


ALTER FUNCTION public.get_spectral_library_settings_hash(_library_id integer, _protein_collection_list text, _organism_db_file text, _fragment_ion_mz_min real, _fragment_ion_mz_max real, _trim_n_terminal_met integer, _cleavage_specificity text, _missed_cleavages integer, _peptide_length_min integer, _peptide_length_max integer, _precursor_mz_min real, _precursor_mz_max real, _precursor_charge_min integer, _precursor_charge_max integer, _static_cys_carbamidomethyl integer, _static_mods text, _dynamic_mods text, _max_dynamic_mods integer, _showdebug boolean) OWNER TO d3l243;


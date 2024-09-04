--
-- Name: get_spectral_library_settings_hash(integer, text, text, real, real, boolean, text, integer, integer, integer, real, real, integer, integer, boolean, text, text, integer, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_spectral_library_settings_hash(_libraryid integer, _proteincollectionlist text DEFAULT ''::text, _organismdbfile text DEFAULT ''::text, _fragmentionmzmin real DEFAULT 0, _fragmentionmzmax real DEFAULT 0, _trimnterminalmet boolean DEFAULT false, _cleavagespecificity text DEFAULT ''::text, _missedcleavages integer DEFAULT 0, _peptidelengthmin integer DEFAULT 0, _peptidelengthmax integer DEFAULT 0, _precursormzmin real DEFAULT 0, _precursormzmax real DEFAULT 0, _precursorchargemin integer DEFAULT 0, _precursorchargemax integer DEFAULT 0, _staticcyscarbamidomethyl boolean DEFAULT false, _staticmods text DEFAULT ''::text, _dynamicmods text DEFAULT ''::text, _maxdynamicmods integer DEFAULT 0, _programversion text DEFAULT ''::text, _showdebug boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Compute a SHA-1 hash value using the settings used to create an in-silico digest based spectral library
**
**      If the Spectral library ID is non-zero, reads settings from t_spectral_library
**      Otherwise, uses the values provided to the other parameters
**
**  Arguments:
**    _libraryID    Spectral library ID; when zero, read settings from t_spectral_library and ignore the other parameters
**    _proteinCollectionList        Comma-separated list of protein collection names, or 'na' if using a legacy FASTA file
**    _organismDbFile               Legacy FASTA file name, or 'na' if using protein collections
**    _fragmentIonMzMin             DIA-NN setting for minimum fragment ion m/z
**    _fragmentIonMzMax             DIA-NN setting for maximum fragment ion m/z
**    _trimNTerminalMet             DIA-NN setting for whether the N-terminal methionine can be removed
**    _cleavageSpecificity          DIA-NN cleavage specificity, e.g. K*,R*
**    _missedCleavages              DIA-NN setting for maximum number of allowed missed cleavages
**    _peptideLengthMin             DIA-NN setting for minimum peptide length
**    _peptideLengthMax             DIA-NN setting for maximum peptide length
**    _precursorMzMin               DIA-NN setting for minimum precursor ion m/z
**    _precursorMzMax               DIA-NN setting for maximum precursor ion m/z
**    _precursorChargeMin           DIA-NN setting for minimum precursor charge
**    _precursorChargeMax           DIA-NN setting for maximum precursor charge
**    _staticCysCarbamidomethyl     DIA-NN setting for whether static Cys carbamidomethyl (+57.021) is enabled
**    _staticMods                   Semicolon-separated list of static (fixed) mods that DIA-NN will consider
**    _dynamicMods                  Semicolon-separated list of dynamic (variable) mods that DIA-NN will consider
**    _maxDynamicMods               DIA-NN setting for maximum number of dynamic mods (per peptide)
**    _programVersion               DIA-NN executable name and major.minor version, e.g. 'DIA-NN_1.9'
**
**  Returns:
**    Computed hash, or an empty string if an error
**
**  Auth:   mem
**  Date:   03/15/2023 mem - Initial Release
**          03/18/2023 mem - Rename arguments
**          03/20/2023 mem - Change _trimNTerminalMet and _staticCysCarbamidomethyl to boolean
**          03/28/2023 mem - Change columns Trim_N_Terminal_Met and Static_Cys_Carbamidomethyl to boolean in T_Spectral_Library
**          04/16/2023 mem - Auto-update _proteinCollectionList and _organismDbFile to 'na' if an empty string
**          04/17/2023 mem - Use 'na' for _organismDBFile if _proteinCollectionList is not 'na' or an empty string
**          05/22/2023 mem - Capitalize reserved word
**          05/30/2023 mem - Use format() for string concatenation
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/11/2023 mem - Remove unnecessary _trimWhitespace argument when calling validate_na_parameter
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          09/03/2024 mem - Add argument _programVersion
**
*****************************************************/
DECLARE
    _settings text;
    _hash text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _libraryId := Coalesce(_libraryId, 0);
    _showDebug := Coalesce(_showDebug, false);

    If _libraryId > 0 Then
        SELECT Protein_Collection_List, Organism_DB_File,
               Fragment_Ion_Mz_Min, Fragment_Ion_Mz_Max,
               Trim_N_Terminal_Met, Cleavage_Specificity, Missed_Cleavages,
               Peptide_Length_Min, Peptide_Length_Max,
               Precursor_Mz_Min, Precursor_Mz_Max,
               Precursor_Charge_Min, Precursor_Charge_Max,
               Static_Cys_Carbamidomethyl,
               Static_Mods, Dynamic_Mods,
               Max_Dynamic_Mods, Program_Version
        INTO _proteinCollectionList, _organismDBFile,
             _fragmentIonMzMin, _fragmentIonMzMax,
             _trimNTerminalMet, _cleavageSpecificity, _missedCleavages,
             _peptideLengthMin, _peptideLengthMax,
             _precursorMzMin, _precursorMzMax,
             _precursorChargeMin, _precursorChargeMax,
             _staticCysCarbamidomethyl,
             _staticMods, _dynamicMods,
             _maxDynamicMods, _programVersion
        FROM T_Spectral_Library
        WHERE Library_ID = _libraryId;

        If Not FOUND Then
            RAISE WARNING 'Spectral library ID not found in T_Spectral_Library: %', _libraryId;
            RETURN '';
        End If;
    Else
        _proteinCollectionList    := Trim(Coalesce(_proteinCollectionList, ''));
        _organismDBFile           := Trim(Coalesce(_organismDBFile, ''));
        _fragmentIonMzMin         := Coalesce(_fragmentIonMzMin, 0);
        _fragmentIonMzMax         := Coalesce(_fragmentIonMzMax, 0);
        _trimNTerminalMet         := Coalesce(_trimNTerminalMet, false);
        _cleavageSpecificity      := Trim(Coalesce(_cleavageSpecificity, ''));
        _missedCleavages          := Coalesce(_missedCleavages, 0);
        _peptideLengthMin         := Coalesce(_peptideLengthMin, 0);
        _peptideLengthMax         := Coalesce(_peptideLengthMax, 0);
        _precursorMzMin           := Coalesce(_precursorMzMin, 0);
        _precursorMzMax           := Coalesce(_precursorMzMax, 0);
        _precursorChargeMin       := Coalesce(_precursorChargeMin, 0);
        _precursorChargeMax       := Coalesce(_precursorChargeMax, 0);
        _staticCysCarbamidomethyl := Coalesce(_staticCysCarbamidomethyl, false);
        _staticMods               := Trim(Coalesce(_staticMods, ''));
        _dynamicMods              := Trim(Coalesce(_dynamicMods, ''));
        _maxDynamicMods           := Coalesce(_maxDynamicMods, 0);
        _programVersion           := Trim(Coalesce(_programVersion, ''));

        If _proteinCollectionList = '' Then
            _proteinCollectionList := 'na';
        End If;

        If _organismDbFile = '' Then
            _organismDbFile := 'na';
        End If;
    End If;

    -- Remove any spaces in the static and dynamic mods
    _staticMods  := Replace(_staticMods, ' ', '');
    _dynamicMods := Replace(_dynamicMods, ' ', '');

    ---------------------------------------------------
    -- Store the options in _settings
    ---------------------------------------------------

    If public.validate_na_parameter(_proteinCollectionList) <> 'na' Then
        _settings := format('%s_na', _proteinCollectionList);
    Else
        _settings := 'na';

        If public.validate_na_parameter(_organismDBFile) <> 'na' Then
            _settings := format('%s_%s', _settings, _organismDBFile);
        Else
            _settings := format('%s_na', _settings);
        End If;

    End If;

    _settings := format('%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s_%s',
                        _settings,
                        _fragmentIonMzMin,
                        _fragmentIonMzMax,
                        CASE WHEN _trimNTerminalMet THEN 'true' ELSE 'false' END,
                        _cleavageSpecificity,
                        _missedCleavages,
                        _peptideLengthMin,
                        _peptideLengthMax,
                        _precursorMzMin,
                        _precursorMzMax,
                        _precursorChargeMin,
                        _precursorChargeMax,
                        CASE WHEN _staticCysCarbamidomethyl THEN 'true' ELSE 'false' END,
                        _staticMods,
                        _dynamicMods,
                        _maxDynamicMods,
                        _programVersion
                       );

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


ALTER FUNCTION public.get_spectral_library_settings_hash(_libraryid integer, _proteincollectionlist text, _organismdbfile text, _fragmentionmzmin real, _fragmentionmzmax real, _trimnterminalmet boolean, _cleavagespecificity text, _missedcleavages integer, _peptidelengthmin integer, _peptidelengthmax integer, _precursormzmin real, _precursormzmax real, _precursorchargemin integer, _precursorchargemax integer, _staticcyscarbamidomethyl boolean, _staticmods text, _dynamicmods text, _maxdynamicmods integer, _programversion text, _showdebug boolean) OWNER TO d3l243;


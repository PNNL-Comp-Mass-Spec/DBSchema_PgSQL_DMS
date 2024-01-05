--
-- Name: get_spectral_library_id(boolean, integer, text, text, real, real, boolean, text, integer, integer, integer, real, real, integer, integer, boolean, text, text, integer, boolean, integer, integer, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_spectral_library_id(IN _allowaddnew boolean, IN _dmssourcejob integer DEFAULT 0, IN _proteincollectionlist text DEFAULT ''::text, IN _organismdbfile text DEFAULT ''::text, IN _fragmentionmzmin real DEFAULT 0, IN _fragmentionmzmax real DEFAULT 0, IN _trimnterminalmet boolean DEFAULT false, IN _cleavagespecificity text DEFAULT ''::text, IN _missedcleavages integer DEFAULT 0, IN _peptidelengthmin integer DEFAULT 0, IN _peptidelengthmax integer DEFAULT 0, IN _precursormzmin real DEFAULT 0, IN _precursormzmax real DEFAULT 0, IN _precursorchargemin integer DEFAULT 0, IN _precursorchargemax integer DEFAULT 0, IN _staticcyscarbamidomethyl boolean DEFAULT false, IN _staticmods text DEFAULT ''::text, IN _dynamicmods text DEFAULT ''::text, IN _maxdynamicmods integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _libraryid integer DEFAULT 0, INOUT _librarystateid integer DEFAULT 0, INOUT _libraryname text DEFAULT ''::text, INOUT _storagepath text DEFAULT ''::text, INOUT _sourcejobshouldmakelibrary boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for an existing entry in T_Spectral_Library that matches the specified settings
**      If found, returns the spectral library ID and state
**      If not found, and if _allowAddNew = true, adds a new row to T_Spectral_Library
**
**  Arguments:
**    _allowAddNew                  True if the calling process can create the spectral library if it is missing or has state = 1; false if only checking whether an existing library matches the settings
**    _dmsSourceJob                 DMS job number to use when the library does not exist, but _allowAddNew is true
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
**    _infoOnly                     True to look for the spectral library and update _message, but not update T_Spectral_Library if the library is missing (or in state 1)
**    _libraryId                    Output: spectral library ID if found an existing library, or assigned ID if a new row was added to T_Spectral_Library
**    _libraryStateId               Output: library state ID
**    _libraryName                  Output: library name
**    _storagePath                  Output: storage path (server share)
**    _sourceJobShouldMakeLibrary   Output: true if the calling process should create the spectral library
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   03/17/2023 mem - Initial Release
**          03/18/2023 mem - Rename parameters
**                         - Add output parameter _sourceJobShouldMakeLibrary
**                         - Append organism name to the storage path
**                         - Assign the source job to the spectral library if it has state 1 and _allowAddNew is enabled
**          03/19/2023 mem - Truncate protein collection lists to 110 characters
**                         - Remove the extension from legacy FASTA file names
**          03/20/2023 mem - Ported to PostgreSQL
**          03/28/2023 mem - Change columns Trim_N_Terminal_Met and Static_Cys_Carbamidomethyl to boolean in T_Spectral_Library
**          03/29/2023 mem - If the library state is 2 and _dmsSourceJob matches the Source_Job in T_Spectral_Library, assume the job failed and was re-started, and thus set _sourceJobShouldMakeLibrary to true
**          04/16/2023 mem - Auto-update _proteinCollectionList and _organismDbFile to 'na' if an empty string
**          05/03/2023 mem - Fix typo in format string
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/30/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          06/19/2023 mem - Set _organismDbFile to 'na' when _proteinCollectionList is defined; otherwise, set _proteinCollectionList to 'na' when _organismDbFile is defined
**                         - Set _returnCode to 'U5225' if an existing spectral library is not found, and _allowAddNew is false
**          09/07/2023 mem - Align assignment statements
**                         - Update warning messages
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
**          09/11/2023 mem - Adjust capitalization of keywords
**          12/11/2023 mem - Remove unnecessary _trimWhitespace argument when calling validate_na_parameter
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _defaultLibraryName text = '';      -- Default library name, without the suffix '.predicted.speclib'
    _libraryNameHash text = '';
    _hash text = '';
    _defaultStoragePath text = '';
    _commaPosition int;
    _periodLocation int;
    _proteinCollection text = '';
    _organism text = '';
    _libraryTypeId int;
    _libraryCreated timestamp;
    _existingSourceJob int;
    _existingHash text = '';
    _actualSourceJob int;
    _logMessage text;
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

        _allowAddNew              := Coalesce(_allowAddNew, false);
        _dmsSourceJob             := Coalesce(_dmsSourceJob, 0);

        _proteinCollectionList    := Trim(Coalesce(_proteinCollectionList, ''));
        _organismDbFile           := Trim(Coalesce(_organismDbFile, ''));
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
        _infoOnly                 := Coalesce(_infoOnly, false);

        _libraryId := 0;
        _libraryStateId := 0;
        _libraryName := '';
        _storagePath := '';
        _sourceJobShouldMakeLibrary := false;

        If _proteinCollectionList = '' Then
            _proteinCollectionList := 'na';
        End If;

        If _organismDbFile = '' Then
            _organismDbFile := 'na';
        End If;

        ---------------------------------------------------
        -- Assure that the protein collection list is in the standard format
        ---------------------------------------------------

        If Trim(Coalesce(_proteinCollectionList)) <> '' And public.validate_na_parameter(_proteinCollectionList) <> 'na' Then
            _proteinCollectionList = pc.standardize_protein_collection_list (_proteinCollectionList);
        End If;

        ---------------------------------------------------
        -- Remove any spaces in the static and dynamic mods
        ---------------------------------------------------

        _staticMods  := Replace(_staticMods, ' ', '');
        _dynamicMods := Replace(_dynamicMods, ' ', '');

        ---------------------------------------------------
        -- Create the default name for the spectral library, using either the protein collection list or the organism DB file name
        -- If the default name is over 110 characters long, truncate to the first 110 characters and append the SHA-1 hash of the full name.
        ---------------------------------------------------

        If public.validate_na_parameter(_proteinCollectionList) <> 'na' Then

            -- Always set _organismDbFile to 'na' when a protein collection list is defined
            _organismDbFile := 'na';

            _defaultLibraryName := _proteinCollectionList;

            -- Lookup the organism associated with the first protein collection in the list
            _commaPosition := Position(',' In _proteinCollectionList);

            If _commaPosition > 0 Then
                _proteinCollection := Left(_proteinCollectionList, _commaPosition - 1);
            Else
                _proteinCollection := _proteinCollectionList;
            End If;

            SELECT Organism_Name
            INTO _organism
            FROM pc.V_Protein_Collections_by_Organism
            WHERE collection_name = _proteinCollection
            ORDER BY Organism_Name
            LIMIT 1;

            If Not FOUND Then
                _logMessage := format('Protein collection not found in V_Protein_Collections_by_Organism; cannot determine the organism for %s', _proteinCollection);
                CALL post_log_entry ('Warning', _logMessage, 'Get_Spectral_Library_ID');

                _organism := 'Undefined';
            End If;

        ElsIf public.validate_na_parameter(_organismDbFile) <> 'na' Then

            -- Always set _proteinCollectionList to 'na' when an organism DB file is defined
            _proteinCollectionList := 'na';

            _defaultLibraryName := _organismDbFile;

            -- Remove the extension (which should be .fasta)
            If _defaultLibraryName Like '%.fasta' Then
                _defaultLibraryName := Left(_defaultLibraryName, char_length(_defaultLibraryName) - char_length('.fasta'));
            ElsIf _defaultLibraryName Like '%.faa' Then
                _defaultLibraryName := Left(_defaultLibraryName, char_length(_defaultLibraryName) - char_length('.faa'));
            Else
                -- Find the position of the last period
                _periodLocation := Position('.' In Reverse(_defaultLibraryName));

                If _periodLocation > 0 Then
                    _periodLocation := char_length(_defaultLibraryName) - _periodLocation;

                    _defaultLibraryName := Left(_defaultLibraryName, _periodLocation);
                End If;
            End If;

            -- Lookup the organism for _organismDbFile

            SELECT Org.OG_name
            INTO _organism
            FROM T_Organism_DB_File OrgFile
                 INNER JOIN T_Organisms Org
                   ON OrgFile.Organism_ID = Org.Organism_ID
            WHERE OrgFile.FileName = _organismDbFile;

            If Not FOUND Then
                _logMessage := format('Legacy FASTA file not found in T_Organism_DB_File; cannot determine the organism for %s', _organismDbFile);
                CALL post_log_entry ('Warning', _logMessage, 'Get_Spectral_Library_ID');

                _organism := 'Undefined';
            End If;
        Else
            -- Cannot create a new spectral library since both the protein collection list and organism DB file are blank or "na"'
            _defaultLibraryName := '';
        End If;

        If _defaultLibraryName <> '' Then
            -- Replace commas with underscores
            _defaultLibraryName := Replace(_defaultLibraryName, ',', '_');

            If char_length(_defaultLibraryName) > 110 Then
                ---------------------------------------------------
                -- Convert _defaultLibraryName to a SHA-1 hash (upper case hex string)
                ---------------------------------------------------

                _libraryNameHash := sw.get_sha1_hash(_defaultLibraryName);

                -- Truncate the library name to 110 characters, then append an underscore and the first 8 characters of the hash

                _defaultLibraryName := Substring(_defaultLibraryName, 1, 110);

                If Right(_defaultLibraryName, 1) <> '_' Then
                    _defaultLibraryName := format('%s_', _defaultLibraryName);
                End If;

                 _defaultLibraryName := format('%s%s', _defaultLibraryName, Substring(_libraryNameHash, 1, 8));
            End If;
        End If;

        ---------------------------------------------------
        -- Determine the path where the spectrum library is stored
        ---------------------------------------------------

        SELECT Server
        INTO _defaultStoragePath
        FROM T_Misc_Paths
        WHERE path_function = 'Spectral_Library_Files';

        If Not FOUND Then
            _message := 'Function "Spectral_Library_Files" not found in table T_Misc_Paths';
            CALL post_log_entry ('Error', _message, 'Get_Spectral_Library_ID');

            _returnCode := 'U5201';
            RETURN;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            'Preparing to look for an existing spectral library file',
                            _logError => true, _displayError => true);

        _returnCode := 'U5202';
        RETURN;
    END;

    BEGIN
        ---------------------------------------------------
        -- Look for an existing spectral library file
        ---------------------------------------------------

        SELECT Library_ID,
               Library_Name,
               Library_State_ID,
               Library_Type_ID,
               Created,
               Source_Job,
               Storage_Path,
               Settings_Hash
        INTO  _libraryId,
              _libraryName,
              _libraryStateId,
              _libraryTypeId,
              _libraryCreated,
              _existingSourceJob,
              _storagePath,
              _existingHash
        FROM T_Spectral_Library
        WHERE Protein_Collection_List    = _proteinCollectionList And
              Organism_DB_File           = _organismDbFile And
              Fragment_Ion_Mz_Min        = _fragmentIonMzMin And
              Fragment_Ion_Mz_Max        = _fragmentIonMzMax And
              Trim_N_Terminal_Met        = _trimNTerminalMet And
              Cleavage_Specificity       = _cleavageSpecificity And
              Missed_Cleavages           = _missedCleavages And
              Peptide_Length_Min         = _peptideLengthMin And
              Peptide_Length_Max         = _peptideLengthMax And
              Precursor_Mz_Min           = _precursorMzMin And
              Precursor_Mz_Max           = _precursorMzMax And
              Precursor_Charge_Min       = _precursorChargeMin And
              Precursor_Charge_Max       = _precursorChargeMax And
              Static_Cys_Carbamidomethyl = _staticCysCarbamidomethyl And
              Static_Mods                = _staticMods And
              Dynamic_Mods               = _dynamicMods And
              Max_Dynamic_Mods           = _maxDynamicMods;

        If FOUND Then
            -- Match Found

            If _libraryStateID = 1 Then
                If _allowAddNew And _dmsSourceJob > 0 Then
                    If _infoOnly Then
                        _message := format('Found existing spectral library ID %s with state 1; would associate source job %s with the creation of spectra library %s',
                                            _libraryId, _dmsSourceJob, _libraryName);
                        RETURN;
                    End If;

                    UPDATE T_Spectral_Library
                    SET Library_State_ID = 2,
                        Source_Job = _dmsSourceJob
                    WHERE Library_ID = _libraryID AND
                          Library_State_ID = 1;

                    SELECT Source_Job,
                           Library_State_ID
                    INTO _actualSourceJob, _libraryStateID
                    FROM T_Spectral_Library
                    WHERE Library_ID = _libraryID;

                    If _actualSourceJob = _dmsSourceJob Then
                        _message := format('Found existing spectral library ID %s with state 1; associated source job %s with the creation of spectra library %s',
                                            _libraryId, _dmsSourceJob, _libraryName);

                        _sourceJobShouldMakeLibrary := true;
                    Else
                        _message := format('Found existing spectral library ID %s with state 1; tried to associate with source job %s but library is actually associated with job %s: %s',
                                            _libraryId, _dmsSourceJob, _actualSourceJob, _libraryName);
                    End If;

                    RETURN;
                Else
                    _message := format('Found existing spectral library ID %s with state 1', _libraryId);

                    If _allowAddNew And _dmsSourceJob <= 0 Then
                        _message := format('%s; although _allowAddNew is enabled, _dmsSourceJob is 0, so not updating the state', _message);
                    End If;

                    _message := format('%s; spectral library is not yet ready to use: %s', _message, _libraryName);
                    RETURN;
                End If;
            Else
                If _libraryStateID = 2 And _dmsSourceJob > 0 And _existingSourceJob = _dmsSourceJob Then
                    _message := format('Found existing spectral library ID %s with state 2, already associated with job %s: %s',
                                    _libraryId, _dmsSourceJob, _libraryName);

                    _sourceJobShouldMakeLibrary := true;
                Else
                    _message := format('Found existing spectral library ID %s with state %s: %s',
                                        _libraryId, _libraryStateID, _libraryName);
                End If;

                RETURN;
            End If;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            'Looking for an existing spectral library file',
                            _logError => true, _displayError => true);

        _returnCode := 'U5203';
        RETURN;
    END;

    BEGIN
        ---------------------------------------------------
        -- Match not found
        ---------------------------------------------------

        _libraryId := 0;
        _libraryStateId := 0;
        _storagePath := _defaultStoragePath;

        If _defaultLibraryName = '' Then
            _message := 'Cannot create a new spectral library since both the protein collection list and organism DB file are empty strings or "na"';
            RAISE INFO '%', _message;
            _returnCode := 'U5204';

            RETURN;
        End If;

        -- Append the organism name to _storagePath
        If char_length(Trim(Coalesce(_organism, ''))) = 0 Then
            _organism := 'Undefined';
        End If;

        _storagePath := public.combine_paths(_storagePath, _organism);

        ---------------------------------------------------
        -- Compute a SHA-1 hash of the settings
        ---------------------------------------------------

        _hash := public.get_spectral_library_settings_hash (
                    _libraryId                => 0,
                    _proteinCollectionList    => _proteinCollectionList,
                    _organismDbFile           => _organismDbFile,
                    _fragmentIonMzMin         => _fragmentIonMzMin,
                    _fragmentIonMzMax         => _fragmentIonMzMax,
                    _trimNTerminalMet         => _trimNTerminalMet,
                    _cleavageSpecificity      => _cleavageSpecificity,
                    _missedCleavages          => _missedCleavages,
                    _peptideLengthMin         => _peptideLengthMin,
                    _peptideLengthMax         => _peptideLengthMax,
                    _precursorMzMin           => _precursorMzMin,
                    _precursorMzMax           => _precursorMzMax,
                    _precursorChargeMin       => _precursorChargeMin,
                    _precursorChargeMax       => _precursorChargeMax,
                    _staticCysCarbamidomethyl => _staticCysCarbamidomethyl,
                    _staticMods               => _staticMods,
                    _dynamicMods              => _dynamicMods,
                    _maxDynamicMods           => _maxDynamicMods,
                    _showDebug                => false);


        ---------------------------------------------------
        -- Construct the library name by appending the first 8 characters of the settings hash, plus the filename suffix to the default library name
        ---------------------------------------------------

        _libraryName := format('%s_%s.predicted.speclib', _defaultLibraryName, Substring(_hash, 1, 8));

        If Not _allowAddNew Then
            _message := format('Spectral library not found, and _allowAddNew is false; not creating %s', _libraryName);
            RAISE INFO '%', _message;

            -- The analysis manager looks for return code 'U5225' in class AnalysisResourcesDiaNN
            _returnCode := 'U5225';

            RETURN;
        End If;

        If _infoOnly Then
            _message := format('Would create a new spectral library named %s', _libraryName);
            RAISE INFO '%', _message;
            RETURN;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            'Preparing to add a new spectral library file',
                            _logError => true, _displayError => true);

        _returnCode := 'U5205';
        RETURN;
    END;


    BEGIN
        ---------------------------------------------------
        -- Add a new spectral library, setting the state to 2 = In Progress
        ---------------------------------------------------

        _libraryStateId := 2;

        INSERT INTO T_Spectral_Library (
            Library_Name, Library_State_ID, Library_Type_ID,
            Created, Source_Job, Comment,
            Storage_Path, Protein_Collection_List, Organism_DB_File,
            Fragment_Ion_Mz_Min, Fragment_Ion_Mz_Max, Trim_N_Terminal_Met,
            Cleavage_Specificity, Missed_Cleavages,
            Peptide_Length_Min, Peptide_Length_Max,
            Precursor_Mz_Min, Precursor_Mz_Max,
            Precursor_Charge_Min, Precursor_Charge_Max,
            Static_Cys_Carbamidomethyl, Static_Mods, Dynamic_Mods,
            Max_Dynamic_Mods, Settings_Hash
            )
        Values (
                _libraryName,
                _libraryStateId,
                1,              -- In-silico digest of a FASTA file via a DIA-NN analysis job
                CURRENT_TIMESTAMP,
                _dmsSourceJob,
                '',     -- Comment
                _storagePath,
                _proteinCollectionList,
                _organismDbFile,
                _fragmentIonMzMin,
                _fragmentIonMzMax,
                _trimNTerminalMet,
                _cleavageSpecificity,
                _missedCleavages,
                _peptideLengthMin,
                _peptideLengthMax,
                _precursorMzMin,
                _precursorMzMax,
                _precursorChargeMin,
                _precursorChargeMax,
                _staticCysCarbamidomethyl,
                _staticMods,
                _dynamicMods,
                _maxDynamicMods,
                _hash
                )
        RETURNING library_id
        INTO _libraryId;

        _sourceJobShouldMakeLibrary := true;

        _message := format('Created spectral library ID %s: %s', _libraryId, _libraryName);
        RAISE INFO '%', _message;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            'Adding a new spectral library file',
                            _logError => true, _displayError => true);

        _returnCode := 'U5206';
        RETURN;
    END;
END
$$;


ALTER PROCEDURE public.get_spectral_library_id(IN _allowaddnew boolean, IN _dmssourcejob integer, IN _proteincollectionlist text, IN _organismdbfile text, IN _fragmentionmzmin real, IN _fragmentionmzmax real, IN _trimnterminalmet boolean, IN _cleavagespecificity text, IN _missedcleavages integer, IN _peptidelengthmin integer, IN _peptidelengthmax integer, IN _precursormzmin real, IN _precursormzmax real, IN _precursorchargemin integer, IN _precursorchargemax integer, IN _staticcyscarbamidomethyl boolean, IN _staticmods text, IN _dynamicmods text, IN _maxdynamicmods integer, IN _infoonly boolean, INOUT _libraryid integer, INOUT _librarystateid integer, INOUT _libraryname text, INOUT _storagepath text, INOUT _sourcejobshouldmakelibrary boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


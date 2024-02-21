--
-- Name: store_param_file_mass_mods(integer, text, boolean, boolean, boolean, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_param_file_mass_mods(IN _paramfileid integer, IN _mods text, IN _infoonly boolean DEFAULT false, IN _showresiduetable boolean DEFAULT false, IN _replaceexisting boolean DEFAULT false, IN _validateunimod boolean DEFAULT true, IN _paramfiletype text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Store (or validate) the dynamic and static mods to associate with a given parameter file
**
**  Format for MS-GF+, MSPathFinder, and mzRefinery:
**     The mod names listed in the 5th comma-separated column must be UniMod names
**     and must match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex           # 4-plex iTraq
**     StaticMod=144.102063,  K,  fix, any,       iTRAQ4plex           # 4-plex iTraq
**     StaticMod=C2H3N1O1,    C,  fix, any,       Carbamidomethyl      # Fixed Carbamidomethyl C (alkylation)
**
**     DynamicMod=HO3P, STY, opt, any,            Phospho              # Phosphorylation STY
**
**  Format for DIA-NN:
**     The format is Mod Name, Mass, Residues
**     The Mod Name in the first column should be in the form UniMod:35
**     If the mod does not have a UniMod ID, any name can be used, but _validateUnimod must then be set to 0 when calling this procedure
**     The residue list can include 'n' for the peptide N-terminus or '*n' for the protein N-terminus
**
**     StaticMod=UniMod:737,   229.162933, n         # TMT6plex
**     StaticMod=UniMod:737,   229.162933, K         # TMT6plex
**     StaticMod=UniMod:2016,  304.207153, n         # TMT16plex (TMTpro)
**     StaticMod=UniMod:2016,  304.207153, K         # TMT16plex
**
**     DynamicMod=UniMod:35,   15.994915,  M         # Oxidized methionine
**     DynamicMod=UniMod:21,   79.966331,  STY       # Phosphorylated STY
**     DynamicMod=UniMod:1,    42.010565,  *n        # Acetylation protein N-term
**     DynamicMod=UniMod:34,   14.015650,  n         # N-terminal methylation
**     DynamicMod=UniMod:121,  114.042927, K         # Lysine ubiquitinylation (K-GG)
**
**     Note that Static +57.021 on cysteine (carbamidomethylation) should be enabled using
**     StaticCysCarbamidomethyl=True (which corresponds to command line argument --unimod4)
**
**  Format for TopPIC:
**     The format is UniMod Name, Mass, Residues, Position, UnimodID
**     The UnimodName in the first column should match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=Carbamidomethylation,57.021464,C,any,4
**     StaticMod=TMT6plex,229.1629,*,N-term,737
**     StaticMod=TMT6plex,229.1629,K,any,737
**
**     DynamicMod=Phospho,79.966331,STY,any,21
**     DynamicMod=Oxidation,15.994915,CMW,any,35
**     DynamicMod=Methyl,14.015650,*,N-term,34
**
**  Format for MSFragger:
**     variable_mod_01 = 15.994900 M 3        # Oxidized methionine
**     variable_mod_02 = 42.010600 [^ 1       # Acetylation protein N-term
**     variable_mod_06 = 304.207146 n^ 1      # 16-plex TMT
**     add_C_cysteine = 57.021464
**     add_K_lysine = 304.207146              # 16-plex TMT
**
**  Format for MaxQuant when the run type is "Standard":
**     <fixedModifications>
**        <string>Carbamidomethyl (C)</string>
**     </fixedModifications>
**     <variableModifications>
**        <string>Oxidation (M)</string>
**        <string>Acetyl (Protein N-term)</string>
**     </variableModifications>
**
**  Format for MaxQuant when the run type is "Reporter ion MS2":
**     <fixedModifications>
**        <string>Carbamidomethyl (C)</string>
**     </fixedModifications>
**     <variableModifications>
**        <string>Oxidation (M)</string>
**        <string>Acetyl (Protein N-term)</string>
**     </variableModifications>
**     <isobaricLabels>
**        <IsobaricLabelInfo>
**           <internalLabel>TMT6plex-Lys126</internalLabel>
**           <terminalLabel>TMT6plex-Nter126</terminalLabel>
**        </IsobaricLabelInfo>
**     </isobaricLabels>
**
**  To validate mods without storing them, set _paramFileID to 0 or a negative number
**
**  Arguments:
**    _paramFileID          If 0 or a negative number, will validate the mods without updating any tables
**    _mods                 Dynamic and static modifications as defined in the parameter file for the analysis tool
**    _infoOnly             True to preview adding the modifications
**    _showResidueTable     When _infoOnly is true, if this is true will show Tmp_Residues for each modification
**    _replaceExisting      When true, replace existing mass mods; if false, report an error if mass mods are already defined
**    _validateUnimod       When true, require that the mod names are known Unimod names
**    _paramFileType        MSGFPlus, DiaNN, TopPIC, MSFragger, or MaxQuant; if empty, will lookup using _paramFileID; if no match (or if _paramFileID is null or 0) assumes MSGFPlus
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   05/16/2013 mem - Initial version
**          06/04/2013 mem - Now replacing tab characters with spaces
**          09/16/2013 mem - Now allowing mod Heme_615 to be stored (even though it is from PNNL and not UniMod)
**          09/03/2014 mem - Now treating static N-term or C-term mods that specify a target residue (instead of *) as Dynamic mods (a requirement for PHRP)
**          10/02/2014 mem - Add exception for Dyn2DZ
**          05/26/2015 mem - Add _validateUnimod
**          12/01/2015 mem - Now showing column Residue_Desc
**          03/14/2016 mem - Look for an entry in column Mass_Correction_Tag of T_Mass_Correction_Factors if no match is found in Original_Source_Name and _validateUnimod = false
**          08/31/2016 mem - Fix logic parsing N- or C-terminal static mods that use * for the affected residue
**                         - Store static N- or C-terminal mods as type 'T' instead of 'S'
**          11/30/2016 mem - Check for a residue specification of any instead of *
**          12/12/2016 mem - Check for tabs in the comma-separated mod definition rows
**          12/13/2016 mem - Silently skip rows StaticMod=None and DynamicMod=None
**          10/02/2017 mem - If _paramFileID is 0 or negative, validate mods only.  Returns 0 if valid, error code if not valid
**          08/17/2018 mem - Add support for TopPIC mods
**                           Add parameter _paramFileType
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to Parse_Delimited_List_Ordered
**          04/23/2019 mem - Add support for MSFragger mod defs
**          03/05/2021 mem - Add support for MaxQuant mod defs
**          05/13/2021 mem - Fix handling of static MaxQuant mods that are N-terminal or C-terminal
**          05/18/2021 mem - Add support for reporter ions in MaxQuant mod defs
**          06/15/2021 mem - Remove UNION statements to avoid sorting
**                         - Collapse isobaric mods into a single entry
**          09/07/2021 mem - Add support for dynamic N-terminal TMT mods in MSFragger (notated with n^)
**          02/23/2023 mem - Ported to PostgreSQL
**                         - Add support for DIA-NN
**          02/28/2023 mem - Use renamed parameter file type, 'MSGFPlus'
**          03/27/2023 mem - Remove dash from DiaNN tool name
**                         - Cast _paramFileType to citext
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Use Similar To when using square brackets to match text
**          05/23/2023 mem - Use format() for string concatenation
**          05/25/2023 mem - Simplify calls to RAISE INFO
**          05/30/2023 mem - Use format() for string concatenation
**          06/07/2023 mem - Add ORDER BY to string_agg()
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          07/27/2023 mem - Use "Not Found" to determine if a parameter file does not exist
**                         - Remove unused variables
**                         - Move Drop Tables commands to outside the for loop; you cannot drop a table being used by a for loop
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list_ordered for a comma-separated list
**          10/12/2023 mem - Add missing call to format()
**          12/02/2023 mem - Rename variable
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**                         - Remove unreachable code that previously showed the contents of temp table Tmp_ModDef
**          01/08/2024 mem - Use the default value for _maxRows when calling parse_delimited_list_ordered()
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _msgAddon text;
    _paramFileName text;
    _validateOnly boolean := false;
    _paramFileTypeID int := 0;
    _paramFileTypeNew citext := '';
    _delimiter text := '';
    _xml XML;
    _charPos int;
    _rowCount int;
    _row citext;
    _rowKey citext;
    _rowValue citext;
    _rowParsed boolean;
    _field citext;
    _affectedResidues citext;
    _modType citext;
    _modTypeSymbol citext;
    _massCorrectionID int;
    _modTypeSymbolToStore citext;
    _modName citext;
    _modMass real;
    _modMassToFind real;
    _location citext;
    _isobaricModIonNumber int;
    _lookupUniModID boolean;
    _staticCysCarbamidomethyl boolean;
    _uniModIDText text;
    _uniModID int;
    _maxQuantModID int;
    _localSymbolID int := 0;
    _localSymbolIDToStore int;
    _terminalMod boolean;
    _residueSymbol citext;
    _modInfo record;
    _paramFileInfo record;
    _residueInfo record;
    _formatString text;
    _exitProcedure boolean;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _infoOnly        := Coalesce(_infoOnly, false);
    _replaceExisting := Coalesce(_replaceExisting, false);
    _validateUnimod  := Coalesce(_validateUnimod, true);

    _paramFileType   := Trim(Coalesce(_paramFileType, ''));

    If _paramFileID Is Null Then
        _message := 'The parameter file ID must be specified; unable to continue';
        _returnCode := 'U5301';
        RETURN;
    End If;

    If Coalesce(_mods, '') = '' Then
        _message := 'The mods to parse cannot be empty; unable to continue';
        _returnCode := 'U5302';
        RETURN;
    End If;

    If _paramFileID <= 0 Then
        _validateOnly := true;
        If _paramFileType = '' Then
            _paramFileType := 'MSGFPlus';
        End If;
    Else
        -----------------------------------------
        -- Make sure the parameter file ID is valid
        -----------------------------------------

        SELECT param_file_name, param_file_type_id
        INTO _paramFileName, _paramFileTypeID
        FROM t_param_files
        WHERE param_file_id = _paramFileID;

        If Not FOUND Then
            _message := format('Param File ID (%s) not found in t_param_files; unable to continue', _paramFileID);
            _returnCode := 'U5303';
            RETURN;
        End If;

        If Not _replaceExisting And Exists (SELECT param_file_id FROM t_param_file_mass_mods WHERE param_file_id = _paramFileID) Then
            _message := format('Param File ID (%s) has existing mods in t_param_file_mass_mods but _replaceExisting = false; unable to continue', _paramFileID);
            _returnCode := 'U5304';
            RETURN;
        End If;

        If _paramFileTypeID > 0 Then

            SELECT param_file_type
            INTO _paramFileTypeNew
            FROM t_param_file_types
            WHERE param_file_type_id = _paramFileTypeID;

            If Coalesce(_paramFileTypeNew, '') <> '' Then
                _paramFileType := _paramFileTypeNew;
            End If;
        End If;
    End If;

    If Not _paramFileType::citext In ('MSGFPlus', 'DiaNN', 'TopPIC', 'MSFragger', 'MaxQuant') Then
        _paramFileType := 'MSGFPlus';
    End If;

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_MaxQuant_Mods (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        ModType text NOT NULL,
        ModName text NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_MaxQuant_Mods ON Tmp_MaxQuant_Mods (EntryID);

    CREATE TEMP TABLE Tmp_Mods (
        EntryID int NOT NULL,
        Value text null
    );

    CREATE UNIQUE INDEX IX_Tmp_Mods ON Tmp_Mods (EntryID);

    CREATE TEMP TABLE Tmp_ModDef (
        EntryID int NOT NULL,
        Value text null
    );

    CREATE UNIQUE INDEX IX_Tmp_ModDef ON Tmp_ModDef (EntryID);

    CREATE TEMP TABLE Tmp_Residues (
        Residue_Symbol char NOT NULL,
        Residue_ID int NULL,
        Residue_Desc text NULL,
        Terminal_AnyAA boolean NULL     -- Set to true if the mod matches any residue at a peptide or protein N- or C-terminus;
                                        -- false if it matches specific residues at terminii
    );

    CREATE UNIQUE INDEX IX_Tmp_Residues ON Tmp_Residues (Residue_Symbol);

    CREATE TEMP TABLE Tmp_ModsToStore (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Mod_Name text,
        Mass_Correction_ID int NOT NULL,
        Mod_Type_Symbol text NULL,
        Residue_Symbol text NULL,
        Residue_ID int NULL,
        Local_Symbol_ID int NULL,
        Residue_Desc text Null,
        Monoisotopic_Mass real NULL,
        MaxQuant_Mod_ID int Null,
        Isobaric_Mod_Ion_Number Int Null
    );

    CREATE UNIQUE INDEX IX_Tmp_ModsToStore ON Tmp_ModsToStore (Entry_ID);

    -----------------------------------------
    -- Split _mods on carriage returns (or line feeds)
    -- Store the data in Tmp_Mods
    -----------------------------------------

    If _paramFileType::citext = 'MaxQuant' Then
        -- Parse the text as XML

        ---------------------------------------------------
        -- Convert _mods to rooted XML
        ---------------------------------------------------

        _xml := public.try_cast('<root>' || _mods || '</root>', null::xml);

        If _xml Is Null Then
            _message := 'Modification list is not valid XML';
            _returnCode := 'U5305';

            DROP TABLE Tmp_Mods;
            DROP TABLE Tmp_ModDef;
            DROP TABLE Tmp_Residues;
            DROP TABLE Tmp_ModsToStore;
            DROP TABLE Tmp_MaxQuant_Mods;

            RETURN;
        End If;

        -- Look for defined modifications
        -- Do not use a UNION statement here, since sort order would be lost

        INSERT INTO Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'fixed' AS ModType,
               unnest(xpath('//root/fixedModifications/string/text()', _xml))::text;

        INSERT INTO Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'fixed' AS ModType,
               unnest(xpath('//root/MaxQuantParams/parameterGroups/parameterGroup/fixedModifications/string/text()', _xml))::text;

        INSERT INTO Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'variable' AS ModType,
               unnest(xpath('//root/variableModifications/string/text()', _xml));

        INSERT INTO Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'variable' AS ModType,
               unnest(xpath('//root/MaxQuantParams/parameterGroups/parameterGroup/variableModifications/string/text()', _xml))::text;

        If Position('IsobaricLabelInfo' In _mods) > 0 Then
            -- Reporter ions are defined (e.g. TMT or iTRAQ)
            -- Treat these as fixed mods
            INSERT INTO Tmp_MaxQuant_Mods (ModType, ModName)
            SELECT 'fixed' AS ModType,
                   unnest(xpath('//root/isobaricLabels/IsobaricLabelInfo/internalLabel/text()', _xml))::text
            UNION
            SELECT 'fixed' AS ModType,
                   unnest(xpath('//root/isobaricLabels/IsobaricLabelInfo/terminalLabel/text()', _xml))::text;
        End If;

        If Not Exists (SELECT * FROM Tmp_MaxQuant_Mods) Then
            _message := 'Did not find any XML nodes matching <fixedModifications> <string></string> </fixedModifications> or <variableModifications> <string></string> </variableModifications>';
            _returnCode := 'U5306';

            DROP TABLE Tmp_Mods;
            DROP TABLE Tmp_ModDef;
            DROP TABLE Tmp_Residues;
            DROP TABLE Tmp_ModsToStore;
            DROP TABLE Tmp_MaxQuant_Mods;

            RETURN;
        End If;

        -- Populate the Tmp_Mods table with entries of the form:
        --   fixed=Carbamidomethyl (C)
        --   variable=Oxidation (M)

        INSERT INTO Tmp_Mods (EntryID, Value)
        SELECT EntryID, format('%s=%s', ModType, ModName)
        FROM Tmp_MaxQuant_Mods
        ORDER BY EntryID;
    Else
        If Position(chr(10) In _mods) > 0 Then
            _delimiter := chr(10);
        Else
            _delimiter := chr(13);
        End If;

        INSERT INTO Tmp_Mods (EntryID, Value)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_mods, _delimiter);

        If Not Exists (SELECT * FROM Tmp_Mods) Then
            _message := 'Nothing returned when splitting the Mods on CR or LF';
            _returnCode := 'U5307';

            DROP TABLE Tmp_Mods;
            DROP TABLE Tmp_ModDef;
            DROP TABLE Tmp_Residues;
            DROP TABLE Tmp_ModsToStore;
            DROP TABLE Tmp_MaxQuant_Mods;

            RETURN;
        End If;
    End If;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Data in Tmp_Mods';

        FOR _modInfo IN
            SELECT EntryID, Value
            FROM Tmp_Mods
            ORDER BY EntryID
        LOOP
            RAISE INFO '%: %', _modInfo.EntryID, _modInfo.Value;
        END LOOP;

        RAISE INFO '';
    End If;

    -----------------------------------------
    -- Parse the modification definitions
    -----------------------------------------

    _exitProcedure := false;

    FOR _row IN
        SELECT Value
        FROM Tmp_Mods
        ORDER BY EntryID
    LOOP

        -- _row should now be empty, or contain something like the following:

        -- For MS-GF+
        -- StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex         # 4-plex iTraq
        --   or
        -- DynamicMod=HO3P, STY, opt, any,            Phospho            # Phosphorylation STY

        -- For DIA-NN
        -- StaticMod=UniMod:737,   229.1629,   n         # TMT6plex
        --   or
        -- DynamicMod=UniMod:35,   15.994915,  M         # Oxidized methionine

        -- For TopPIC:
        -- StaticMod=Carbamidomethylation,57.021464,C,any,4
        --   or
        -- DynamicMod=Phospho,79.966331,STY,any,21

        -- For MSFragger:
        -- variable_mod_01 = 15.9949 M
        --   or
        -- add_C_cysteine = 57.021464             # added to C - avg. 103.1429, mono. 103.00918

        -- For MaxQuant:
        -- variable=Oxidation (M)
        --   or
        -- fixed=Carbamidomethyl (C)

        -- Remove any text after the comment character, #
        _charPos := Position('#' In _row);

        If _charPos > 0 Then
            _row := Substring(_row, 1, _charPos - 1);
        End If;

        -- Remove unwanted whitespace characters
        _row := Replace (_row, chr(10), '');
        _row := Replace (_row, chr(13), '');
        _row := Replace (_row, chr(9), ' ');
        _row := Trim(Coalesce(_row, ''));

        If _row = '' Then
            CONTINUE;
        End If;

        If _infoOnly Then
            RAISE INFO '%', _row;
        End If;

        DELETE FROM Tmp_ModDef;
        _rowParsed := false;

        If _paramFileType::citext = 'MSFragger' Then
            _rowParsed := true;

            If _row SIMILAR TO 'variable[_]mod%' Then
                _charPos := Position('=' In _row);

                If _charPos > 0 Then
                    _rowValue := Trim(Substring(_row, _charPos + 1, char_length(_row)));

                    INSERT INTO Tmp_ModDef (EntryID, Value)
                    SELECT Entry_ID, Value
                    FROM public.parse_delimited_list_ordered(_rowValue, ' ');

                    UPDATE Tmp_ModDef
                    SET Value = format('DynamicMod=%s', Value)
                    WHERE EntryID = 1;
                End If;
            End If;

            If _row SIMILAR TO 'add[_]%' Then
                _charPos := Position('=' In _row);

                If _charPos > 0 Then
                    _rowKey   := Trim(Substring(_row, 1, _charPos - 1));
                    _rowValue := Trim(Substring(_row, _charPos + 1, char_length(_row)));

                    INSERT INTO Tmp_ModDef (EntryID, Value)
                    SELECT Entry_ID, Value
                    FROM public.parse_delimited_list_ordered(_rowValue, ' ');

                    UPDATE Tmp_ModDef
                    SET Value = format('StaticMod=%s', Value)
                    WHERE EntryID = 1;

                    -- _rowKey is Similar To add_C_cysteine or add_Cterm_peptide
                    -- Remove "add_"
                    _rowKey := Substring(_rowKey, 5, 100);

                    -- Add the affected mod symbol as the second column
                    If _rowKey SIMILAR TO 'Nterm[_]peptide%' Then
                        _residueSymbol := '<';
                    ElsIf _rowKey SIMILAR TO 'Cterm[_]peptide%' Then
                        _residueSymbol := '>';
                    ElsIf _rowKey SIMILAR TO 'Nterm[_]protein%' Then
                        _residueSymbol := '[';
                    ElsIf _rowKey SIMILAR TO 'Cterm[_]protein%' Then
                        _residueSymbol := ']';
                    Else
                        -- _rowKey is Similar To C_cysteine
                        _residueSymbol := Substring(_rowKey, 1, 1);
                    End If;

                    If Exists (SELECT EntryID FROM Tmp_ModDef WHERE EntryID = 2) Then
                        UPDATE Tmp_ModDef
                        SET Value = _residueSymbol
                        WHERE EntryID = 2;
                    Else
                        INSERT INTO Tmp_ModDef (EntryID, Value)
                        VALUES (2, _residueSymbol);
                    End If;
                End If;
            End If;

        End If;

        If _paramFileType::citext = 'MaxQuant' Then
            _rowParsed := true;

            If _row Like 'variable=%' Then
                _charPos  := Position('=' In _row);
                _rowValue := Trim(Substring(_row, _charPos + 1, char_length(_row)));

                INSERT INTO Tmp_ModDef (EntryID, Value)
                VALUES (1, format('DynamicMod=%s', _rowValue));
            End If;

            If _row Like 'fixed=%' Then
                _charPos  := Position('=' In _row);
                _rowValue := Trim(Substring(_row, _charPos + 1, char_length(_row)));

                INSERT INTO Tmp_ModDef (EntryID, Value)
                VALUES (1, format('StaticMod=%s', _rowValue));
            End If;
        End If;

        If _paramFileType::citext = 'DiaNN' Then
            -- Check for setting StaticCysCarbamidomethyl=True
            If _row Like 'StaticCysCarbamidomethyl%=%True' Then
               _rowParsed := true;

                -- Store this as a StaticMod entry, using the keyword StaticCysCarbamidomethyl
                INSERT INTO Tmp_ModDef (EntryID, Value)
                VALUES (1, 'StaticMod=StaticCysCarbamidomethyl'),
                       (2, '57.021465'),
                       (3, 'C');
            End If;
        End If;

        If Not _rowParsed Then
            -- MS-GF+ style mod (also used by DIA-NN and TOPIC)
            INSERT INTO Tmp_ModDef (EntryID, Value)
            SELECT Entry_ID, Value
            FROM public.parse_delimited_list_ordered(_row);
        End If;

        If Not Exists (SELECT * FROM Tmp_ModDef) Then
            RAISE INFO '';
            RAISE INFO 'Skipping row since Tmp_ModDef is empty: %', _row;
            CONTINUE;
        End If;

        -----------------------------------------
        -- Look for an equals sign in the first entry of Tmp_ModDef
        -----------------------------------------

        _field := '';

        SELECT Trim(Value)
        INTO _field
        FROM Tmp_ModDef
        WHERE EntryID = 1;

        -- _field should now look something like the following:
        -- StaticMod=None
        -- DynamicMod=None
        -- DynamicMod=O1
        -- DynamicMod=15.9949
        -- DynamicMod=Oxidation (M)

        -- Look for an equals sign in _field

        _charPos := Position('=' In _field);

        If _charPos <= 1 Then
            RAISE INFO '';
            RAISE INFO 'Skipping row since first column does not contain an equals sign: %', _row;
            CONTINUE;
        End If;

        -----------------------------------------
        -- Determine the ModType
        -----------------------------------------

        _modType := Substring(_field, 1, _charPos - 1);

        If Not _modType In ('DynamicMod', 'StaticMod') Then
            RAISE INFO '';
            RAISE INFO 'Skipping row since setting is not a DynamicMod or StaticMod setting: %', _row;
            CONTINUE;
        End If;

        -- Now that the _modType is known, remove that text from the first field in Tmp_ModDef

        UPDATE Tmp_ModDef
        SET Value = Substring(Value, _charPos + 1, 2048)
        WHERE EntryID = 1;

        -- Assure that Tmp_ModDef has at least 5 rows for MS-GF+ or TopPIC
        -- For DIA-NN, require at least 3 rows
        -- For MSFragger, require at least 2 rows
        -- For MaxQuant, there will just be 1 row, which has the MaxQuant-tracked mod name

        SELECT COUNT(*)
        INTO _rowCount
        FROM Tmp_ModDef;

        If _paramFileType::citext In ('MSGFPlus', 'TopPIC') And _rowCount < 5 Then
            If Position(chr(9) In _row) > 0 Then
                If Position(',' In _row) > 0 Then
                    _message := format('Aborting since row has a mix of tabs and commas; should only be comma-separated: %s', _row);
                Else
                    _message := format('Aborting since row appears to be tab separated instead of comma-separated: %s', _row);
                End If;

                _returnCode := 'U5310';

                If Not _infoOnly Then
                    -- Break out of the for loop
                    _exitProcedure := true;
                    EXIT;
                End If;
            Else
                -- MS-GF+ uses 'StaticMod=None' and 'DynamicMod=None' to indicate no static or dynamic mods
                -- TopPIC uses 'StaticMod=None' and 'DynamicMod=Defaults' to indicate no static or dynamic mods
                If Not _field::citext in ('StaticMod=None', 'DynamicMod=None', 'DynamicMod=Defaults') Then
                    _message := format('Aborting since row has %s comma-separated columns (should have 5 columns): %s', _rowCount, _row);
                    _returnCode := 'U5311';

                    If Not _infoOnly Then
                        RAISE WARNING '%', _message;

                        -- Break out of the for loop
                        _exitProcedure := true;
                        EXIT;
                    End If;
                End If;
            End If;

            -- Row is not valid, so move on to the next row
            CONTINUE;
        End If;

        If _paramFileType::citext In ('DiaNN') And _rowCount < 3 Then
            RAISE INFO '';
            RAISE INFO 'Skipping row since not enough rows in Tmp_ModDef: %', _row;
            CONTINUE;
        End If;

        If _paramFileType::citext In ('MSFragger') And _rowCount < 2 Then
            RAISE INFO '';
            RAISE INFO 'Skipping row since not enough rows in Tmp_ModDef: %', _row;
            CONTINUE;
        End If;

        _field := '';

        If _paramFileType::citext In ('DiaNN', 'TopPIC', 'MSFragger', 'MaxQuant') Then
            -- Mod defs for these tools don't include 'opt' or 'fix, so we update _field based on _modType
            If _modType = 'DynamicMod' Then
                _field := 'opt';
            End If;

            If _modType = 'StaticMod' Then
                _field := 'fix';
            End If;
        Else
            -- MS-GF+
            SELECT Trim(Value)
            INTO _field
            FROM Tmp_ModDef
            WHERE EntryID = 3;
        End If;

        If _modType = 'DynamicMod' Then
            _modTypeSymbol := 'D';

            If _field <> 'opt' Then
                _message := format('DynamicMod entries must have "opt" in the 3rd column; aborting; see row: %s', _row);
                _returnCode := 'U5312';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

        End If;

        If _modType = 'StaticMod' Then
            _modTypeSymbol := 'S';

            If _field <> 'fix' Then
                _message := format('StaticMod entries must have "fix" in the 3rd column; aborting; see row: %s', _row);
                _returnCode := 'U5313';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;
        End If;

        _modName := '';
        _modMass := 0;
        _modMassToFind := 0;
        _massCorrectionID := 0;
        _location := '';
        _terminalMod := false;
        _affectedResidues := '';
        _maxQuantModID := NULL;
        _isobaricModIonNumber := 0;

        DELETE FROM Tmp_Residues;

        If _paramFileType::citext In ('MSGFPlus', 'DiaNN', 'TopPIC') Then

            -----------------------------------------
            -- Determine the modification name (preferably UniMod name, but could also be a mass correction tag name)
            -----------------------------------------

            If _paramFileType::citext In ('MSGFPlus', 'TopPIC') Then

                SELECT Trim(Value)
                INTO _modName
                FROM Tmp_ModDef
                WHERE _paramFileType::citext = 'MSGFPlus' AND EntryID = 5 OR
                      _paramFileType::citext = 'TopPIC' AND EntryID = 1;

                -- Auto change Glu->pyro-Glu to Dehydrated
                -- Both have empirical formula H(-2) O(-1) but DMS can only associate one Unimod name with each unique empirical formula and Dehydrated is associated with H(-2) O(-1)
                If _modName = 'Glu->pyro-Glu' Then
                    _modName := 'Dehydrated';
                End If;

            Else
                -- DIA-NN parameter file

                SELECT Trim(Value)
                INTO _field
                FROM Tmp_ModDef
                WHERE EntryID = 1;

                _lookupUniModID := true;
                _staticCysCarbamidomethyl := false;

                If Not _field SIMILAR TO 'UniMod:[0-9]%' Then
                    If _field = 'StaticCysCarbamidomethyl' Then
                        _field := 'UniMod:4';
                        _staticCysCarbamidomethyl := true;

                    ElsIf _validateUnimod Then

                        _message := format('Mod name "%s" is not in the expected form (e.g. UniMod:35); see row: %s', _field, _row);
                        _returnCode := 'U5314';

                        -- Break out of the for loop
                        _exitProcedure := true;
                        EXIT;
                    Else
                        _lookupUniModID = false;
                    End If;
                End If;

                If Not _lookupUniModID Then
                    _modName := _field;

                Else
                    _uniModIDText := Substring(_field, 8, 100);
                    _uniModID := public.try_cast(_uniModIDText, null::int);

                    If _uniModID Is Null Then
                        _message := format('UniMod ID "%s" is not an integer; see row: %s', _uniModIDText, _row);
                        _returnCode := 'U5315';

                        -- Break out of the for loop
                        _exitProcedure := true;
                        EXIT;
                    End If;

                    If _uniModID = 4 And Not _staticCysCarbamidomethyl Then
                        _message := format('Define static Cys Carbamidomethyl using "StaticCysCarbamidomethyl=True", not using "StaticMod=UniMod:4"; see row: %s', _row);
                        _returnCode := 'U5316';

                        -- Break out of the for loop
                        _exitProcedure := true;
                        EXIT;
                    End If;

                    SELECT Name
                    INTO _modName
                    FROM ont.t_unimod_mods
                    WHERE Unimod_ID = _uniModID;

                    If Not FOUND Then
                        _message := format('UniMod ID "%s" not found in T_Unimod_Mods; see row: %s', _field, _row);
                        _returnCode := 'U5317';

                        -- Break out of the for loop
                        _exitProcedure := true;
                        EXIT;
                    End If;
                End If;
            End If;

            -----------------------------------------
            -- Determine the Mass_Correction_ID based on the UniMod name
            -----------------------------------------

            SELECT mass_correction_id, monoisotopic_mass
            INTO _massCorrectionID, _modMass
            FROM t_mass_correction_factors
            WHERE original_source_name = _modName AND
                  (original_source = 'UniMod' OR _modName IN ('Heme_615','Dyn2DZ','DeoxyHex', 'Pentose') Or Not _validateUnimod);
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If (_matchCount = 0 Or _massCorrectionID = 0) And Not _validateUnimod Then
                -- No match, try matching the DMS name (Mass_Correction_Tag)

                SELECT mass_correction_id
                INTO _massCorrectionID
                FROM t_mass_correction_factors
                WHERE mass_correction_tag = _modName;
                --
                GET DIAGNOSTICS _matchCount = ROW_COUNT;
            End If;

            If _matchCount = 0 Or Coalesce(_massCorrectionID, 0) = 0 Then
                If _validateUnimod Then
                    _message := format('UniMod modification not found in t_mass_correction_factors.original_source_name for mod "%s"; see row: %s',
                                        _modName, _row);
                Else
                    _message := format('Modification name not found in t_mass_correction_factors.original_source_name or t_mass_correction_factors.mass_correction_tag for mod "%s"; see row: %s',
                                        _modName, _row);
                End If;

                _returnCode := 'U5318';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            -----------------------------------------
            -- Determine the affected residues
            -----------------------------------------

            SELECT Trim(Value)
            INTO _location
            FROM Tmp_ModDef
            WHERE _paramFileType::citext = 'MSGFPlus' AND EntryID = 4 OR
                  _paramFileType::citext = 'TopPIC' AND EntryID = 4;

            If _paramFileType::citext = 'MSGFPlus' And Not _location In ('any', 'N-term', 'C-term', 'Prot-N-term', 'Prot-C-term') Then
                _message := format('Invalid location "%s"; should be "any", "N-term", "C-term", "Prot-N-term", or "Prot-C-term"; see row: %s',
                                    _location, _row);

                _returnCode := 'U5319';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            If _paramFileType::citext = 'TopPIC' And Not _location In ('any', 'N-term', 'C-term') Then
                _message := format('Invalid location "%s"; should be "any", "N-term", or "C-term"; see row: %s',
                                    _location, _row);

                _returnCode := 'U5320';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            If _paramFileType::citext = 'DiaNN' Then
                SELECT Trim(Value)
                INTO _field
                FROM Tmp_ModDef
                WHERE _paramFileType::citext = 'DiaNN' AND EntryID = 3;

                If _field = '*n' Then
                    _location := 'Prot-N-term';   -- Protein N-terminus
                ElsIf ascii(_field) = 110 Then
                    _location := 'N-term';        -- Peptide N-terminus (lowercase 'n' is ASCII 110)
                Else
                    _location := 'any';
                End If;
            End If;

            If _location = 'Prot-N-term' Then
                _terminalMod := true;
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES ('[', true);
            End If;

            If _location = 'Prot-C-term' Then
                _terminalMod := true;
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES (']', true);
            End If;

            If _location = 'N-term' Then
                _terminalMod := true;
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES ('<', true);
            End If;

            If _location = 'C-term' Then
                _terminalMod := true;
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES ('>', true);
            End If;

            -- Parse out the affected residue (or residues)
            -- In MS-GF+ and TOPPIC, N- or C-terminal mods use * for any residue at a terminus

            SELECT Trim(Value)
            INTO _field
            FROM Tmp_ModDef
            WHERE EntryID = 2 AND _paramFileType::citext IN ('MSGFPlus') OR
                  EntryID = 3 AND _paramFileType::citext IN ('DiaNN', 'TopPIC');

            If _field = 'any' Then
                _message := format('Use * to match all residues, not the word "any"; see row: %s', _row);
                _returnCode := 'U5321';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            _affectedResidues := _field;
        End If; -- MS-GF+, DIA-NN, and TopPIC

        If _paramFileType::citext In ('MSFragger') Then
            -----------------------------------------
            -- Determine the Mass_Correction_ID based on the mod mass
            -----------------------------------------

            SELECT Trim(Value)
            INTO _field
            FROM Tmp_ModDef
            WHERE EntryID = 1;

            _modMassToFind := public.try_cast(_field, null::real);

            If _modMassToFind Is Null Then
                _message := format('Mod mass "%s" is not a number; see row: %s', _field, _row);
                _returnCode := 'U5322';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            If Abs(_modMassToFind) < 0.01 Then
                -- Likely an undefined static mod, e.g. add_T_threonine = 0.0000
                -- Skip it
                CONTINUE;
            End If;

            SELECT mass_correction_id, mass_correction_tag, monoisotopic_mass
            INTO _massCorrectionID, _modName, _modMass
            FROM t_mass_correction_factors
            WHERE Abs(monoisotopic_mass - _modMassToFind) < 0.25
            ORDER BY Abs(monoisotopic_mass - _modMassToFind)
            LIMIT 1;

            If Not FOUND Then
                _message := format('Matching modification not found for mass %s in t_mass_correction_factors; see row: %s', _modMassToFind, _row);

                _returnCode := 'U5323';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            SELECT Trim(Value)
            INTO _affectedResidues
            FROM Tmp_ModDef
            WHERE EntryID = 2;

            If _affectedResidues In ('<','>','[',']') Then
                -- N or C terminal static mod
                -- (specified with add_Cterm_peptide or similar,
                -- but we replaced that with a symbol earlier in this procedure)
                _terminalMod := true;

                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA)
                VALUES (_affectedResidues, true);

                _affectedResidues := '*';

            ElsIf _affectedResidues In ('[^', ']^', 'n^')  Then
                -- N or C terminal dynamic mod
                _terminalMod := true;

                -- Override 'n^' to instead use '[^'
                If _affectedResidues = 'n^' Then
                    _affectedResidues := '[^';
                End If;

                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA)
                VALUES (Substring(_affectedResidues, 1, 1), true);

                _affectedResidues := '*';

            End If;

        End If; -- MSFragger

        If _paramFileType::citext In ('MaxQuant') Then
            -----------------------------------------
            -- Determine the Mass_Correction_ID and affected residues based on the mod name
            -----------------------------------------

            SELECT Trim(Value)
            INTO _field
            FROM Tmp_ModDef
            WHERE EntryID = 1;

            SELECT mod_id,
                   mod_position,
                   mass_correction_id,
                   isobaric_mod_ion_number
            INTO _maxQuantModID, _location, _massCorrectionID, _isobaricModIonNumber
            FROM t_maxquant_mods
            WHERE mod_title = _field;

            If Not FOUND Then
                _message := format('MaxQuant modification not found in t_maxquant_mods: %s', _field);
                _returnCode := 'U5324';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            If Coalesce(_massCorrectionID, 0) = 0 Then
                _message := format('Mass Correction ID not defined for MaxQuant modification "%s"; either update table t_maxquant_mods or delete this mod from the XML', _field);
                _returnCode := 'U5325';

                -- Break out of the for loop
                _exitProcedure := true;
                EXIT;
            End If;

            SELECT mass_correction_id, mass_correction_tag, monoisotopic_mass
            INTO _massCorrectionID, _modName, _modMass
            FROM t_mass_correction_factors
            WHERE mass_correction_id = _massCorrectionID
            LIMIT 1;

            -- Lookup the affected residues

            SELECT string_agg(R.residue_symbol, '' ORDER BY R.residue_symbol)
            INTO _affectedResidues
            FROM t_maxquant_mod_residues M
                 INNER JOIN t_residues R
                   ON M.residue_id = R.residue_id
            WHERE mod_id = _maxQuantModID;

            If _location = 'proteinNterm' Then
                _terminalMod := true;
                _affectedResidues := '*';
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES ('[', true);
            End If;

            If _location = 'proteinCterm' Then
                _terminalMod := true;
                _affectedResidues := '*';
                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES (']', true);
            End If;

            If _location in ('anyNterm', 'notNterm') Then
                _terminalMod := true;
                If Coalesce(_affectedResidues, '') = '' Or Not _affectedResidues SIMILAR TO '[A-Z]' Then
                    _affectedResidues := '<';
                End If;

                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES (_affectedResidues,  true);
            End If;

            If _location in ('anyCterm', 'notCterm') Then
                _terminalMod := true;
                If Coalesce(_affectedResidues, '') = '' Or Not _affectedResidues SIMILAR TO '[A-Z]' Then
                    _affectedResidues := '>';
                End If;

                INSERT INTO Tmp_Residues (Residue_Symbol, Terminal_AnyAA) VALUES (_affectedResidues, true);
            End If;
        End If; -- MaxQuant

        -- Parse each character in _affectedResidues
        _charPos := 0;

        WHILE _charPos < char_length(_affectedResidues)
        LOOP
            _charPos := _charPos + 1;

            _residueSymbol := Substring(_affectedResidues, _charPos, 1);

            If _terminalMod Then
                If _paramFileType::citext = 'DiaNN' Then
                    -- This should be a peptide or protein N-terminal mod
                    -- Break out of the while loop
                    EXIT;

                ElsIf Not _residueSymbol In ('*', '<', '>', '[', ']') Then
                    -- Terminal mod that targets specific residues
                    -- Store this as a dynamic terminal mod
                    UPDATE Tmp_Residues
                    SET Terminal_AnyAA = false;

                    -- Break out of the while loop
                    EXIT;
                End If;
            Else
                -- Not matching an N or C-Terminus
                If _paramFileType::citext In ('MSFragger') Then
                    If ascii(_residueSymbol) In (110, 99) Then
                        -- Lowercase n or c indicates peptide N- or C-terminus
                        If _charPos = char_length(_affectedResidues) Then
                            _message := format('Lowercase n or c should be followed by a residue or *; see row: %s', _row);
                            _returnCode := 'U5326';

                            _exitProcedure := true;
                            EXIT;
                        End If;

                        _charPos := _charPos + 1;
                        _residueSymbol := Substring(_affectedResidues, _charPos, 1);
                    End If;
                End If;

                INSERT INTO Tmp_Residues (Residue_Symbol)
                VALUES (_residueSymbol);
            End If;

        END LOOP;

        If _exitProcedure Then
            -- Break out of the for loop
            EXIT;
        End If;

        -----------------------------------------
        -- Determine the residue IDs for the entries in Tmp_Residues
        -----------------------------------------

        UPDATE Tmp_Residues
        SET Residue_ID = R.Residue_ID,
            Residue_Desc = R.Description
        FROM t_residues R
        WHERE R.residue_symbol = Tmp_Residues.residue_symbol;

        If _infoOnly And _showResidueTable Then
            RAISE INFO '';
            RAISE INFO 'Residue Info';

            FOR _residueInfo IN
                SELECT Residue_Symbol AS Symbol,
                       Residue_ID AS ID,
                       Residue_Desc AS Description,
                       Terminal_AnyAA AS TerminalAnyAA
                FROM Tmp_Residues
            LOOP
                RAISE INFO '%:  %,  %  %',
                            _residueInfo.ID,
                            _residueInfo.Symbol,
                            _residueInfo.Description,
                            CASE WHEN Terminal_AnyAA
                               THEN '(match any residue)'
                               ELSE '(match specific residue)'
                            END;
            END LOOP;

            RAISE INFO '';
        End If;

        -- Look for symbols that did not resolve
        If Exists (SELECT Residue_Symbol FROM Tmp_Residues WHERE Residue_ID IS Null) Then
            _msgAddon := '';

            SELECT string_agg(Residue_Symbol, ', ' ORDER BY Residue_Symbol)
            INTO _msgAddon
            FROM Tmp_Residues
            WHERE Residue_ID IS NULL;

            _matchCount := array_length(string_to_array(_msgAddon, ','), 1);

            _message := format('Unrecognized residue %s "%s"; %s not found in t_residues; see row: %s',
                                public.check_plural(_msgAddon, 'symbol', 'symbols'),
                                _msgAddon,
                                public.check_plural(_msgAddon, 'symbol', 'symbols'),
                                _row);

            _returnCode := 'U5327';

            -- Break out of the for loop
            _exitProcedure := true;
            EXIT;
        End If;

        -----------------------------------------
        -- Check for N-terminal or C-terminal static mods that do not use *
        -----------------------------------------

        If _modTypeSymbol = 'S' And Exists (SELECT Residue_Symbol FROM Tmp_Residues WHERE Residue_Symbol IN ('<', '>') AND NOT Terminal_AnyAA) Then
            -- Auto-switch to tracking as a dynamic mod (required for PHRP)
            _modTypeSymbol := 'D';
        End If;

        -----------------------------------------
        -- Determine the Local_Symbol_ID to store for dynamic mods
        -----------------------------------------

        If _modTypeSymbol = 'D' Then
            If Exists (SELECT Mod_Name FROM Tmp_ModsToStore WHERE Mod_Name = _modName AND Mod_Type_Symbol = 'D') Then
                -- This DynamicMod entry uses the same mod name as a previous one; re-use it
                SELECT Local_Symbol_ID
                INTO _localSymbolIDToStore
                FROM Tmp_ModsToStore
                WHERE Mod_Name = _modName AND Mod_Type_Symbol = 'D'
                LIMIT 1;
            Else
                -- New dynamic mod
                _localSymbolID := _localSymbolID + 1;
                _localSymbolIDToStore := _localSymbolID;
            End If;

        Else
            -- Static mod; store 0
            _localSymbolIDToStore := 0;
        End If;

        If _isobaricModIonNumber > 0 Then
            -----------------------------------------
            -- Check whether this isobaric mod already exists in Tmp_ModsToStore
            -----------------------------------------

            SELECT CASE WHEN _modTypeSymbol = 'S' AND
                             Residue_Symbol IN ('<', '>') THEN 'T'
                        ELSE _modTypeSymbol
                   END,
                   Residue_Symbol
            INTO _modTypeSymbolToStore, _residueSymbol
            FROM Tmp_Residues;

            If Exists(
                    SELECT *
                    FROM Tmp_ModsToStore
                    WHERE Mod_Name = _modName AND
                          Mass_Correction_ID = _massCorrectionID AND
                          Mod_Type_Symbol = _modTypeSymbolToStore AND
                          Residue_Symbol = _residueSymbol AND
                          Abs(Monoisotopic_Mass - _modMass) < 0.0001 ) THEN

                -- Mod already stored; skip it
                RAISE INFO '';
                RAISE INFO 'Skipping row since the isobaric mod has already been stored: %', _row;
                CONTINUE;
            End If;
        End If;


        -----------------------------------------
        -- Append the mod defs to Tmp_ModsToStore
        -----------------------------------------

        INSERT INTO Tmp_ModsToStore (
                Mod_Name,
                Mass_Correction_ID,
                Mod_Type_Symbol,
                Residue_Symbol,
                Residue_ID,
                Local_Symbol_ID,
                Residue_Desc,
                Monoisotopic_Mass,
                MaxQuant_Mod_ID,
                Isobaric_Mod_Ion_Number
            )
        SELECT _modName AS Mod_Name,
               _massCorrectionID AS MassCorrectionID,
               CASE WHEN _modTypeSymbol = 'S' AND Residue_Symbol IN ('<', '>') THEN 'T' ELSE _modTypeSymbol END AS Mod_Type,
               Residue_Symbol,
               Residue_ID,
               _localSymbolIDToStore AS Local_Symbol_ID,
               Residue_Desc,
               _modMass,
               _maxQuantModID,
               Coalesce(_isobaricModIonNumber, 0)
        FROM Tmp_Residues;

    END LOOP;

    If _exitProcedure Then
        DROP TABLE Tmp_Mods;
        DROP TABLE Tmp_ModDef;
        DROP TABLE Tmp_Residues;
        DROP TABLE Tmp_ModsToStore;
        DROP TABLE Tmp_MaxQuant_Mods;
        RETURN;
    End If;

    If _infoOnly Then
        -- Preview the mod defs

        _formatString := '%-10s %-30s %-20s %-15s %-10s %-10s %-15s %-20s %-17s %-15s %-18s %-15s %-20s %-100s';

        RAISE INFO '';
        RAISE INFO '%',
            format(_formatString,
                   'Entry_ID',
                   'Mod_Name',
                   'Mass_Correction_ID',
                   'Mod_Type_Symbol',
                   'Residue',
                   'Residue_ID',
                   'Local_Symbol_ID',
                   'Residue_Desc',
                   'Monoisotopic_Mass',
                   'MaxQuant_Mod_ID',
                   'Isobaric_Mod_Ion_#',
                   'Param_File_ID',
                   'Isobaric Mod Comment',
                   'Param_File'
                  );

        RAISE INFO '%',
                   format(_formatString,
                                     '----------',
                                     '------------------------------',
                                     '--------------------',
                                     '---------------',
                                     '----------',
                                     '----------',
                                     '---------------',
                                     '--------------------',
                                     '-----------------',
                                     '---------------',
                                     '------------------',
                                     '---------------',
                                     '--------------------',
                                     '----------------------------------------------------------------------------------------------------'
                         );

        FOR _modInfo IN
            SELECT M.Entry_ID,
                   M.Mod_Name,
                   M.Mass_Correction_ID,
                   M.Mod_Type_Symbol,
                   M.Residue_Symbol,
                   M.Residue_ID,
                   M.Local_Symbol_ID,
                   M.Residue_Desc,
                   M.Monoisotopic_Mass,
                   M.MaxQuant_Mod_ID,
                   M.Isobaric_Mod_Ion_Number,
                   _paramFileID AS Param_File_ID,
                   _paramFileName AS Param_File,
                   CASE
                       WHEN LookupQ.Min_Isobaric_Mod_Ion_Number IS NULL THEN
                         'Duplicate isobaric mod that will be skipped'
                       ELSE ''
                   END AS Isobaric_Mod_Comment
            FROM Tmp_ModsToStore M
                 LEFT OUTER JOIN ( SELECT Residue_ID,
                                          Local_Symbol_ID,
                                          Mass_Correction_ID,
                                          Mod_Type_Symbol,
                                          MIN(Isobaric_Mod_Ion_Number) AS Min_Isobaric_Mod_Ion_Number
                                   FROM Tmp_ModsToStore
                                   GROUP BY Residue_ID, Local_Symbol_ID, Mass_Correction_ID, Mod_Type_Symbol) AS LookupQ
                   ON M.Residue_ID = LookupQ.Residue_ID AND
                      M.Local_Symbol_ID = LookupQ.Local_Symbol_ID AND
                      M.Mass_Correction_ID = LookupQ.Mass_Correction_ID AND
                      M.Mod_Type_Symbol = LookupQ.Mod_Type_Symbol AND
                      M.Isobaric_Mod_Ion_Number = LookupQ.Min_Isobaric_Mod_Ion_Number
            ORDER BY M.Entry_ID
        LOOP
            RAISE INFO '%',
                format(_formatString,
                        _modInfo.Entry_ID,
                        _modInfo.Mod_Name,
                        _modInfo.Mass_Correction_ID,
                        _modInfo.Mod_Type_Symbol,
                        _modInfo.Residue_Symbol,
                        _modInfo.Residue_ID,
                        _modInfo.Local_Symbol_ID,
                        _modInfo.Residue_Desc,
                        _modInfo.Monoisotopic_Mass,
                        _modInfo.MaxQuant_Mod_ID,
                        _modInfo.Isobaric_Mod_Ion_Number,
                        _modInfo.Param_File_ID,
                        _modInfo.Isobaric_Mod_Comment,
                        _modInfo.Param_File
                       );

        END LOOP;

    End If;

    If Not _infoOnly And Not _validateOnly Then
        -- Store the mod defs

        If Exists (SELECT param_file_id FROM t_param_file_mass_mods WHERE param_file_id = _paramFileID) Then
            DELETE FROM t_param_file_mass_mods
            WHERE param_file_id = _paramFileID;
        End If;

        INSERT INTO t_param_file_mass_mods (residue_id, local_symbol_id, mass_correction_id, Param_File_ID, Mod_Type_Symbol, MaxQuant_Mod_ID)
        SELECT residue_id, local_symbol_id, mass_correction_id, _paramFileID, Mod_Type_Symbol, MaxQuant_Mod_ID
        FROM Tmp_ModsToStore;

        RAISE INFO 'Mods stored in t_param_file_mass_mods for param file ID %', _paramFileID;

        FOR _paramFileInfo IN
            SELECT mod_entry_id,
                   mod_type_symbol,
                   residue_symbol,
                   mass_correction_tag,
                   monoisotopic_mass,
                   local_symbol
            FROM V_Param_File_Mass_Mods
            WHERE Param_File_ID = _paramFileID
            ORDER BY mod_entry_id
        LOOP
            RAISE INFO '%: mod type % on %, mod name % with mass % and symbol %',
                   _paramFileInfo.mod_entry_id,
                   _paramFileInfo.mod_type_symbol,
                   _paramFileInfo.residue_symbol,
                   _paramFileInfo.mass_correction_tag,
                   _paramFileInfo.monoisotopic_mass,
                   _paramFileInfo.local_symbol;
        END LOOP;
    End If;

    If _infoOnly Then
        If Trim(Coalesce(_message)) <> '' Then
            RAISE INFO '%', _message;
        End If;
    End If;

    If Not _infoOnly And _returnCode <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_Mods;
    DROP TABLE Tmp_ModDef;
    DROP TABLE Tmp_Residues;
    DROP TABLE Tmp_ModsToStore;
    DROP TABLE Tmp_MaxQuant_Mods;
END
$$;


ALTER PROCEDURE public.store_param_file_mass_mods(IN _paramfileid integer, IN _mods text, IN _infoonly boolean, IN _showresiduetable boolean, IN _replaceexisting boolean, IN _validateunimod boolean, IN _paramfiletype text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_param_file_mass_mods(IN _paramfileid integer, IN _mods text, IN _infoonly boolean, IN _showresiduetable boolean, IN _replaceexisting boolean, IN _validateunimod boolean, IN _paramfiletype text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_param_file_mass_mods(IN _paramfileid integer, IN _mods text, IN _infoonly boolean, IN _showresiduetable boolean, IN _replaceexisting boolean, IN _validateunimod boolean, IN _paramfiletype text, INOUT _message text, INOUT _returncode text) IS 'StoreParamFileMassMods';


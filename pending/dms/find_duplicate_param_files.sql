--
CREATE OR REPLACE FUNCTION public.find_duplicate_param_files
(
    _paramFileNameFilter text = '',
    _paramFileTypeList text = 'MSGFPlus',
    _ignoreParentMassType boolean = true,
    _considerInsignificantParameters boolean = false,
    _checkValidOnly boolean = true,
    _maxFilesToTest int = 0,
    _previewSql boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
RETURNS TABLE
(
    Entry_ID int,
    Param_File_Type text,
    Param_File_ID_Master int,
    Param_File_ID_Dup int,
    param_file_Name_A text,
    param_file_Name_B text,
    param_file_Description_A text,
    param_file_Description_B text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Compares the param file entries in T_Param_Entries and
**      T_Param_File_Mass_Mods to find parameter files that match
**
**  Arguments:
**    _paramFileNameFilter    One or more param file name specifiers, separated by commas (filters can contain % wildcards)
**    _paramFileTypeList      MSGFPlus, MaxQuant, MSFragger, XTandem, etc.
**    _ignoreParentMassType   When true, ignore 'ParentMassType' differences in T_Param_Entries
**
**  Auth:   mem
**  Date:   05/15/2008 mem - Initial version (Ticket:671)
**          07/11/2014 mem - Optimized execution speed by adding Tmp_MassModCounts
**                         - Updated default value for _paramFileTypeList
**          02/28/2023 mem - Use renamed parameter file type, 'MSGFPlus'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _sqlStart text;
    _sql text;
    _filesProcessed int;
    _paramFileInfo record;
    _updateCount int;
    _modCount int;
    _entryCount int;
    _entryInfo record;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _paramFileNameFilter := Trim(Coalesce(_paramFileNameFilter, ''));
    _paramFileTypeList := Trim(Coalesce(_paramFileTypeList, ''));
    _ignoreParentMassType := Coalesce(_ignoreParentMassType, true);
    _considerInsignificantParameters := Coalesce(_considerInsignificantParameters, false);
    _checkValidOnly := Coalesce(_checkValidOnly, true);
    _maxFilesToTest := Coalesce(_maxFilesToTest, 0);
    _previewSql := Coalesce(_previewSql, false);

    If _previewSql Then
        _maxFilesToTest := 1;
    End If;

    If char_length(_paramFileTypeList) = 0 Then
        _message := 'Error: _paramFileTypeList cannot be empty';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_ParamFileTypeFilter (
        Param_File_Type text,
        Valid boolean
    );

    CREATE TEMP TABLE Tmp_ParamFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Param_File_ID int,
        Param_File_Name text,
        Param_File_Type_ID int,
        Param_File_Type text
    );

    CREATE INDEX IX_Tmp_ParamFiles ON Tmp_ParamFiles (Entry_ID);

    CREATE TEMP TABLE Tmp_ParamEntries (
        Param_File_ID int,
        Entry_Type text,
        Entry_Specifier text,
        Entry_Value text,
        Compare boolean default true
    );

    CREATE INDEX IX_Tmp_ParamEntries_Param_File_ID ON Tmp_ParamEntries (Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Entry_Type_Entry_Specifier ON Tmp_ParamEntries (Entry_Type, Entry_Specifier, Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Compare ON Tmp_ParamEntries (Compare, Param_File_ID);

    CREATE TEMP TABLE Tmp_DefaultSequestParamEntries (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Entry_Type text,
        Entry_Specifier text,
        Entry_Value text,
        Compare boolean default true
    );

    CREATE INDEX IX_Tmp_DefaultSequestParamEntries_Entry_ID ON Tmp_DefaultSequestParamEntries (Entry_ID);
    CREATE UNIQUE INDEX IX_Tmp_DefaultSequestParamEntries_Entry_Type_Entry_Specifier ON Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier);

    CREATE TEMP TABLE Tmp_MassModDuplicates (
        Param_File_ID int
    );

    CREATE TEMP TABLE Tmp_ParamEntryDuplicates (
        Param_File_ID int
    );

    CREATE TEMP TABLE Tmp_SimilarParamFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Param_File_ID_Master int,
        Param_File_ID_Dup int
    );

    CREATE TEMP TABLE Tmp_MassModCounts (
        Param_File_ID int,
        ModCount int
    );

    CREATE INDEX IX_Tmp_MassModCounts_ModCount ON Tmp_MassModCounts (ModCount);
    CREATE UNIQUE INDEX IX_Tmp_MassModCounts_ModCountParamFileID ON Tmp_MassModCounts (ModCount, Param_File_ID);

    -----------------------------------------
    -- Populate Tmp_ParamFileTypeFilter
    -----------------------------------------

    INSERT INTO Tmp_ParamFileTypeFilter (Param_File_Type, Valid)
    SELECT DISTINCT Value, true
    FROM public.parse_delimited_list(_paramFileTypeList, ',');

    UPDATE Tmp_ParamFileTypeFilter
    SET Valid = false
    WHERE NOT EXISTS (SELECT PFT.param_file_type FROM t_param_file_types PFT WHERE Tmp_ParamFileTypeFilter.param_file_type = PFT.param_file_type);

    If FOUND Then
        SELECT string_agg(param_file_type, ', ' ORDER BY param_file_type)
        INTO _message
        FROM Tmp_ParamFileTypeFilter
        WHERE Not Valid;

        If Position(', ' In _message) > 0 Then
            _message := format('Warning: _paramFileTypeList has the following invalid parameter file types: %s', _message);
        Else
            _message := format('Warning: invalid parameter file type found in _paramFileTypeList: %s', _message);
        End If;

        RAISE WARNING '%', _message;

        _message := '';

        DELETE FROM Tmp_ParamFileTypeFilter
        WHERE Not Valid;
    End If;

    -----------------------------------------
    -- Populate Tmp_ParamFiles
    -----------------------------------------

    _sqlStart := 'INSERT INTO Tmp_ParamFiles (Param_File_ID, Param_File_Name, Param_File_Type_ID, Param_File_Type)';

    _sql := 'SELECT PF.param_file_id, '
                   'PF.param_file_name, '
                   'PF.param_file_type_id, '
                   'PFT.param_file_type '
            'FROM t_param_files PF INNER JOIN '
                 't_param_file_types PFT ON PF.param_file_type_id = PFT.param_file_type_id INNER JOIN '
                 'Tmp_ParamFileTypeFilter PFTF ON PFT.param_file_type = PFTF.param_file_type';

    If _checkValidOnly Then
        _sql := format('%s WHERE PF.Valid <> 0', _sql);
    Else
        _sql := format('%s WHERE true', _sql);
    End If;

    If char_length(_paramFileNameFilter) > 0 Then
        _sql := format('%s AND (%s)', _sql, public.create_like_clause_from_separated_string(_paramFileNameFilter, 'Param_File_Name', ','));
    End If;

    _sql := format('%s ORDER BY Param_File_Type, Param_File_ID', _sql);

    If _previewSql Then
        RAISE INFO '%', format('%s %s', _sqlStart, _sql);

        -- Populate Tmp_ParamFiles with up to five parameter files matching the filters
        EXECUTE (format('%s %s LIMIT 5', _sqlStart, _sql));

        FOR _paramFileInfo IN
            SELECT Param_File_Type AS ParamFileType,
                   Param_File_ID AS ParamFileID,
                   Param_File_Name AS ParamFileName
            FROM Tmp_ParamFiles
            ORDER BY Entry_ID
        LOOP
            RAISE INFO '%', format('%s param file ID %s: %s',
                                   _paramFileInfo.ParamFileType,
                                   _paramFileInfo.ParamFileID,
                                   _paramFileInfo.ParamFileName);
        END LOOP;

    Else
        EXECUTE (format('%s %s', _sqlStart, _sql));
    End If;

    -----------------------------------------
    -- Populate Tmp_MassModCounts
    -----------------------------------------

    INSERT INTO Tmp_MassModCounts( Param_File_ID,
                                   ModCount )
    SELECT P.Param_File_ID,
           SUM(CASE
                   WHEN Mod_Entry_ID IS NULL THEN 0
                   ELSE 1
               END) AS ModCount
    FROM Tmp_ParamFiles P
         LEFT OUTER JOIN t_param_file_mass_mods MM
           ON P.param_file_id = MM.param_file_id
    GROUP BY P.param_file_id

    If _paramFileTypeList ILIKE '%Sequest%' Then
    -- <a1>

        -----------------------------------------
        -- Populate Tmp_ParamEntries with t_param_entries
        -- After this, standardize the entries to allow for rapid comparison
        -----------------------------------------

        INSERT INTO Tmp_ParamEntries( param_file_id,
                                      entry_type,
                                      entry_specifier,
                                      entry_value,
                                      Compare )
        SELECT PE.param_file_id,
            PE.entry_type,
            PE.entry_specifier,
            PE.entry_value,
            true AS Compare
        FROM t_param_entries PE
        ORDER BY param_file_id, entry_type, entry_specifier;

        If _checkValidOnly Then
            DELETE Tmp_ParamEntries
            FROM  t_param_files PF
            WHERE Tmp_ParamEntries.param_file_id = PF.param_file_id AND PF.valid = 0;
        End If;

        -----------------------------------------
        -- Possibly add entries for 'sequest_N14_NE.params' to Tmp_ParamEntries
        -----------------------------------------

        _paramFileID := 1000;

        SELECT param_file_id
        INTO _paramFileID
        FROM t_param_files
        WHERE param_file_name = 'sequest_N14_NE.params';

        If Not Exists (SELECT * FROM Tmp_ParamEntries WHERE Param_File_ID = _paramFileID) Then
            INSERT INTO Tmp_ParamEntries ( Param_File_ID,
                                           Entry_Type,
                                           Entry_Specifier,
                                           Entry_Value,
                                           Compare )
            VALUES (_paramFileID, 'BasicParam', 'SelectedEnzymeIndex', 0, true);
        End If;

        -----------------------------------------
        -- Populate a temporary table with the default values to add to Tmp_ParamEntries
        -----------------------------------------

        INSERT INTO Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value)
        VALUES ('BasicParam', 'MaximumNumberMissedCleavages', '4'),
               ('BasicParam', 'ParentMassType', 'average'),
               ('BasicParam', 'SelectedEnzymeCleavagePosition', '0'),
               ('BasicParam', 'SelectedEnzymeIndex', '0'),

               ('AdvancedParam', 'FragmentIonTolerance', '1'),
               ('AdvancedParam', 'MaximumNumDifferentialPerPeptide', '3'),
               ('AdvancedParam', 'MaximumNumAAPerDynMod', '4'),
               ('AdvancedParam', 'PeptideMassTolerance', '3'),
               ('AdvancedParam', 'Use_a_Ions', '0'),
               ('AdvancedParam', 'Use_b_Ions', '1'),
               ('AdvancedParam', 'Use_y_Ions', '1'),
               ('AdvancedParam', 'PeptideMassUnits', '0'),

               ('AdvancedParam', 'a_Ion_Weighting', '0'),
               ('AdvancedParam', 'b_Ion_Weighting', '1'),
               ('AdvancedParam', 'c_Ion_Weighting', '0'),
               ('AdvancedParam', 'd_Ion_Weighting', '0'),
               ('AdvancedParam', 'v_Ion_Weighting', '0'),
               ('AdvancedParam', 'w_Ion_Weighting', '0'),
               ('AdvancedParam', 'x_Ion_Weighting', '0'),
               ('AdvancedParam', 'y_Ion_Weighting', '1'),
               ('AdvancedParam', 'z_Ion_Weighting', '0');

        -- Note: If _considerInsignificantParameters is false, the following options will not actually affect the results
        INSERT INTO Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier, Entry_Value, Compare)
        VALUES ('AdvancedParam', 'ShowFragmentIons', 'False', _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfDescriptionLines', '3', _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfOutputLines', '10', _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfResultsToProcess', '500', _considerInsignificantParameters);

        -----------------------------------------
        -- Add the default values to Tmp_ParamEntries, where missing
        -----------------------------------------

        FOR _entryInfo IN
            SELECT Entry_Type As Type,
                   Entry_Specifier As Specifier,
                   Entry_Value As Value,
                   Compare
            FROM Tmp_DefaultSequestParamEntries
            ORDER BY Entry_ID
        LOOP
            INSERT INTO Tmp_ParamEntries (Param_File_ID, Entry_Type, Entry_Specifier, Entry_Value, Compare)
            SELECT DISTINCT Param_File_ID, _entryInfo.Type, _entryInfo.Specifier, _entryInfo.Value, Coalesce(_entryInfo.Compare, true)
            FROM Tmp_ParamEntries
            WHERE NOT Param_File_ID IN ( SELECT Param_File_ID
                                         FROM Tmp_ParamEntries
                                         WHERE Entry_Type = entryInfo.Type AND
                                               Entry_Specifier = _entryInfo.Specifier );

        END LOOP;

        -----------------------------------------
        -- Make sure all 'FragmentIonTolerance' entries are non-zero (defaulting to 1 if 0)
        -----------------------------------------

        UPDATE Tmp_ParamEntries
        SET Entry_value = '1'
        WHERE Entry_Type = 'AdvancedParam' AND
              Entry_Specifier = 'FragmentIonTolerance' AND
              Entry_Value = '0';

        -----------------------------------------
        -- Change Compare to false for entries in Tmp_ParamEntries that correspond to
        -- Entry_Specifier values in Tmp_DefaultSequestParamEntries that have Compare = false
        -----------------------------------------

        UPDATE Tmp_ParamEntries
        SET Compare = false
        FROM ( SELECT DISTINCT Entry_Type, Entry_Specifier
               FROM Tmp_DefaultSequestParamEntries
               WHERE Compare = false) LookupQ
        WHERE Tmp_ParamEntries.Entry_Type = LookupQ.Entry_Type AND
              Tmp_ParamEntries.Entry_Specifier = LookupQ.Entry_Specifier AND
              Tmp_ParamEntries.Compare = true;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Note: Changed Compare to false for %s rows in Tmp_ParamEntries, since they correspond to entries in Tmp_DefaultSequestParamEntries that have Compare = false',
                             _updateCount);

            RAISE INFO '%', _message;
            _message := '';
        End If;

        -----------------------------------------
        -- If _ignoreParentMassType is true, mark these entries as Not-Compared
        -----------------------------------------

        If _ignoreParentMassType Then

            UPDATE Tmp_ParamEntries
            SET Compare = false
            WHERE Entry_Type = 'BasicParam' AND
                  Entry_Specifier = 'ParentMassType';

        End If;

        If _previewSql And Exists (SELECT * FROM Tmp_ParamEntries) Then

            -- ToDo: Use Raise Info to show the data in Tmp_ParamEntries

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

            _infoHead := format(_formatSpecifier,
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---',
                                         '---',
                                         '---',
                                         '---',
                                         '---'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Compare,
                       Entry_Type,
                       Entry_Specifier,
                       COUNT(param_file_id) AS Entry_Count,
                       MIN(Entry_Value) AS Entry_Value_Min,
                       MAX(Entry_Value) AS Entry_Value_Max
                FROM Tmp_ParamEntries
                WHERE Compare = true
                GROUP BY Compare, Entry_Type, Entry_Specifier
                UNION
                SELECT Compare,
                       Entry_Type,
                       Entry_Specifier,
                       COUNT(param_file_id) AS Entry_Count,
                       MIN(Entry_Value) AS Entry_Value_Min,
                       MAX(Entry_Value) AS Entry_Value_Max
                FROM Tmp_ParamEntries
                WHERE Compare = false
                GROUP BY Compare, Entry_Type, Entry_Specifier
                ORDER BY Compare Desc, Entry_Type, Entry_Specifier
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Compare,
                                    _previewData.Entry_Type,
                                    _previewData.Entry_Specifier,
                                    _previewData.Entry_Count,
                                    _previewData.Entry_Value_Min,
                                    _previewData.Entry_Value_Max
                        );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;
    End If; -- </a1>

    -----------------------------------------
    -- Step through the entries in Tmp_ParamFiles and look for
    -- duplicate and similar param files
    -----------------------------------------

    _filesProcessed := 0;

    FOR _paramFileInfo IN
        SELECT Param_File_ID AS ParamFileID,
               Param_File_Name AS ParamFileName,
               Param_File_Type_ID AS ParamFileTypeID,
               Param_File_Type AS ParamFileType
        FROM Tmp_ParamFiles
        ORDER BY Entry_ID
    LOOP

        TRUNCATE TABLE Tmp_MassModDuplicates;
        TRUNCATE TABLE Tmp_ParamEntryDuplicates;

        -----------------------------------------
        -- Look for duplicates in t_param_file_mass_mods
        -----------------------------------------

        -- First, lookup the mod count for this parameter file
        --
        SELECT ModCount
        INTO _modCount
        FROM Tmp_MassModCounts
        WHERE Param_File_ID = _paramFileInfo.ParamFileID;

        If Not FOUND Or _modCount = 0 Then

            -----------------------------------------
            -- Parameter file doesn't have any mass modifications
            -----------------------------------------

            INSERT INTO Tmp_MassModDuplicates (param_file_id)
            SELECT PF.param_file_id
            FROM t_param_files PF
                 INNER JOIN Tmp_MassModCounts PFMM
                   ON PF.param_file_id = PFMM.param_file_id
            WHERE PFMM.ModCount = 0 AND
                  PF.param_file_id <> _paramFileInfo.ParamFileID AND
                  PF.param_file_type_id = _paramFileInfo.ParamFileTypeID AND
                  Not _checkValidOnly OR PF.valid <> 0;

        Else

            -----------------------------------------
            -- Find parameter files that are of the same type and have the same set of modifications
            -- Note that we're ignoring Local_Symbol_ID
            -----------------------------------------

            INSERT INTO Tmp_MassModDuplicates (param_file_id)
            SELECT B.param_file_id
            FROM ( SELECT param_file_id,
                          residue_id,
                          mass_correction_id,
                          mod_type_symbol
                   FROM t_param_file_mass_mods
                   WHERE param_file_id = _paramFileInfo.ParamFileID
                 ) A
                INNER JOIN ( SELECT PFMM.param_file_id,
                                    PFMM.residue_id,
                                    PFMM.mass_correction_id,
                                    PFMM.mod_type_symbol
                            FROM t_param_file_mass_mods PFMM
                                 INNER JOIN t_param_files PF
                                    ON PFMM.param_file_id = PF.param_file_id
                            WHERE PFMM.param_file_id <> _paramFileInfo.ParamFileID AND
                                  PF.param_file_type_id = _paramFileInfo.ParamFileTypeID AND
                                  PFMM.param_file_id IN ( SELECT param_file_id
                                                          FROM Tmp_MassModCounts
                                                          WHERE ModCount = _modCount );
                        ) B
                ON A.residue_id = B.residue_id AND
                   A.mass_correction_id = B.mass_correction_id AND
                   A.mod_type_symbol = B.mod_type_symbol
            GROUP BY B.param_file_id
            HAVING COUNT(*) = _modCount;

        End If;

        -----------------------------------------
        -- Look for duplicates in t_param_entries
        -- At present, this is only applicable to Sequest parameter files
        -----------------------------------------

        If _paramFileInfo.ParamFileType::citext = 'Sequest' Then

            -----------------------------------------
            -- First, Count the number of entries in the table for this parameter file
            -- Skipping entries with Compare = false
            -----------------------------------------

            SELECT COUNT(*)
            INTO _entryCount
            FROM Tmp_ParamEntries
            WHERE Compare AND Param_File_ID = _paramFileInfo.ParamFileID;

            If _modCount = 0 Then

                -----------------------------------------
                -- Parameter file doesn't have any param entries (with compare = true)
                -- Find all other parameter files that don't have any param entries
                -----------------------------------------

                _sql :=  ' INSERT INTO Tmp_ParamEntryDuplicates (param_file_id)'
                         ' SELECT PF.param_file_id'
                         ' FROM t_param_files PF LEFT OUTER JOIN'
                              ' Tmp_ParamEntries PE ON '
                              ' PF.param_file_id = PE.param_file_id AND PE.Compare'
                         ' WHERE PE.param_file_id IS NULL AND '
                               ' PF.param_file_id <> $1 AND'
                               ' PF.param_file_type_id = $2';

                If _checkValidOnly Then
                    _sql := format('%s AND PF.Valid <> 0', _sql);
                End If;

                If _previewSql Then
                    RAISE INFO '%', _sql;
                Else
                    EXECUTE _sql
                    USING _paramFileInfo.ParamFileID, _paramFileInfo.ParamFileTypeID;
                End If;
            Else

                -----------------------------------------
                -- Find parameter files that are of the same type and have the same set of param entries
                -----------------------------------------

                INSERT INTO Tmp_ParamEntryDuplicates (param_file_id)
                SELECT B.param_file_id
                FROM (    SELECT param_file_id,
                                 Entry_Type,
                                 Entry_Specifier,
                                 Entry_Value
                        FROM Tmp_ParamEntries
                        WHERE Compare AND param_file_id = _paramFileInfo.ParamFileID
                    ) A
                    INNER JOIN ( SELECT PE.param_file_id,
                                        PE.Entry_Type,
                                        PE.Entry_Specifier,
                                        PE.Entry_Value
                                FROM Tmp_ParamEntries PE
                                    INNER JOIN t_param_files PF
                                        ON PE.param_file_id = PF.param_file_id
                                WHERE PE.Compare AND
                                      PE.param_file_id <> _paramFileInfo.ParamFileID AND
                                      PF.param_file_type_id = _paramFileInfo.ParamFileTypeID AND
                                      PE.param_file_id IN ( SELECT param_file_id
                                                            FROM Tmp_ParamEntries
                                                            WHERE Compare
                                                            GROUP BY param_file_id
                                                            HAVING COUNT(*) = _entryCount )
                            ) B
                    ON A.Entry_Type = B.Entry_Type AND
                       A.Entry_Specifier = B.Entry_Specifier AND
                       A.Entry_Value = B.Entry_Value
                GROUP BY B.param_file_id
                HAVING COUNT(*) = _entryCount;

            End If;

            -----------------------------------------
            -- Any Param_File_ID values that are in Tmp_ParamEntryDuplicates and Tmp_MassModDuplicates are duplicates
            -- Add their IDs to Tmp_SimilarParamFiles
            -----------------------------------------

            INSERT INTO Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
            SELECT _paramFileInfo.ParamFileID, PED.Param_File_ID
            FROM Tmp_ParamEntryDuplicates PED INNER JOIN
                 Tmp_MassModDuplicates MMD ON PED.Param_File_ID = MMD.Param_File_ID

        Else
            -----------------------------------------
            -- Any Param_File_ID values that are in Tmp_MassModDuplicates are duplicates
            -- Add their IDs to Tmp_SimilarParamFiles
            -----------------------------------------

            INSERT INTO Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
            SELECT _paramFileInfo.ParamFileID, MMD.Param_File_ID
            FROM Tmp_MassModDuplicates MMD
        End If;

        _filesProcessed := _filesProcessed + 1;

        If _maxFilesToTest <> 0 And _filesProcessed >= _maxFilesToTest Then
            -- Break out of the loop
            EXIT;
        End If;

    END LOOP;

    -----------------------------------------
    -- Return the results
    -----------------------------------------

    RETURN QUERY
    SELECT SPF.Entry_ID,
           PFInfo.Param_File_Type,
           SPF.Param_File_ID_Master,
           SPF.Param_File_ID_Dup,
           PFA.param_file_name As param_file_Name_A,
           PFB.param_file_Name As param_file_Name_B,
           PFA.param_file_Description As param_file_Description_A,
           PFB.param_file_Description As param_file_Description_B
    FROM Tmp_SimilarParamFiles SPF
         INNER JOIN t_param_files PFA
           ON SPF.Param_File_ID_Master = PFA.param_file_id
         INNER JOIN t_param_files PFB
           ON SPF.Param_File_ID_Dup = PFB.param_file_id
         INNER JOIN Tmp_ParamFiles PFInfo
           ON SPF.Param_File_ID_Master = PFInfo.param_file_id;

    If Exists (SELECT * FROM Tmp_ParamEntries) Then

        -- ToDo: Use RAISE INFO to show the data in Tmp_ParamEntries (only applies to SEQUEST parameter files)

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg',
                            'abcdefg'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---',
                                     '---',
                                     '---',
                                     '---',
                                     '---'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT 'Master' AS Param_File_Category,
                   Param_File_ID,
                   Entry_Type,
                   Entry_Specifier,
                   Entry_Value,
                   Compare
            FROM Tmp_ParamEntries PE
                 INNER JOIN Tmp_SimilarParamFiles SPF
                   ON SPF.Param_File_ID_Master = PE.Param_File_ID
            UNION
            SELECT 'Duplicate' AS Param_File_Category,
                   Param_File_ID,
                   Entry_Type,
                   Entry_Specifier,
                   Entry_Value,
                   Compare
            FROM Tmp_ParamEntries PE
                 INNER JOIN Tmp_SimilarParamFiles SPF
                   ON SPF.Param_File_ID_Dup = PE.Param_File_ID
            ORDER BY Param_File_Category Desc, Param_File_ID, Entry_Type

        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Param_File_Category,
                                _previewData.Param_File_ID,
                                _previewData.Entry_Type,
                                _previewData.Entry_Specifier,
                                _previewData.Entry_Value,
                                _previewData.Compare
                    );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_ParamFileTypeFilter;
    DROP TABLE Tmp_ParamFiles;
    DROP TABLE Tmp_ParamEntries;
    DROP TABLE Tmp_DefaultSequestParamEntries;
    DROP TABLE Tmp_MassModDuplicates;
    DROP TABLE Tmp_ParamEntryDuplicates;
    DROP TABLE Tmp_SimilarParamFiles;
    DROP TABLE Tmp_MassModCounts;
END
$$;

COMMENT ON FUNCTION public.find_duplicate_param_files IS 'FindDuplicateParamFiles';

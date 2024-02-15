--
-- Name: find_duplicate_param_files(text, text, boolean, boolean, boolean, integer, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.find_duplicate_param_files(_paramfilenamefilter text DEFAULT ''::text, _paramfiletypelist text DEFAULT 'MSGFPlus'::text, _ignoreparentmasstype boolean DEFAULT true, _considerinsignificantparameters boolean DEFAULT false, _checkvalidonly boolean DEFAULT true, _maxfilestotest integer DEFAULT 0, _previewsql boolean DEFAULT false, _showdebug boolean DEFAULT false) RETURNS TABLE(entry_id integer, param_file_type public.citext, param_file_id_master integer, param_file_id_dup integer, param_file_name_a public.citext, param_file_name_b public.citext, param_file_description_a public.citext, param_file_description_b public.citext)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Compare the param file entries in t_param_entries and t_param_file_mass_mods to find parameter files that have identical mass mods
**
**  Arguments:
**    _paramFileNameFilter              One or more parameter file name specifiers, separated by commas (names can contain % as a wildcard)
**    _paramFileTypeList                Parameter file type: 'MSGFPlus', 'MaxQuant', 'MSFragger', 'XTandem', etc.
**    _ignoreParentMassType             When true, ignore 'ParentMassType' differences in t_param_entries (only applies to SEQUEST parameter files, which were retired in 2019)
**    _considerInsignificantParameters  When true, also compare 'ShowFragmentIons', 'NumberOfDescriptionLines', 'NumberOfOutputLines', and 'NumberOfResultsToProcess' (only applies to SEQUEST parameter files, which were retired in 2019)
**    _checkValidOnly                   When true, ignore parameter files with Valid = 0
**    _maxFilesToTest                   Maximum number of parameter files to examine
**    _previewSql                       When true, preview SQL
**    _showDebug                        When true, show debug messages using RAISE INFO
**
**  Returns:
**      Table of duplicate parameter files
**
**  Auth:   mem
**  Date:   05/15/2008 mem - Initial version (Ticket:671)
**          07/11/2014 mem - Optimized execution speed by adding Tmp_MassModCounts
**                         - Updated default value for _paramFileTypeList
**          02/28/2023 mem - Use renamed parameter file type, 'MSGFPlus'
**          02/13/2024 mem - Ported to PostgreSQL
**          02/14/2024 mem - Add missing parentheses to where clause
**
*****************************************************/
DECLARE
    _sqlStart text;
    _sql text;
    _message text;
    _filesProcessed int;
    _paramFileInfo record;
    _paramFileID int;
    _matchCount int;
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

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _paramFileNameFilter             := Trim(Coalesce(_paramFileNameFilter, ''));
    _paramFileTypeList               := Trim(Coalesce(_paramFileTypeList, ''));
    _ignoreParentMassType            := Coalesce(_ignoreParentMassType, true);
    _considerInsignificantParameters := Coalesce(_considerInsignificantParameters, false);
    _checkValidOnly                  := Coalesce(_checkValidOnly, true);
    _maxFilesToTest                  := Coalesce(_maxFilesToTest, 0);
    _previewSql                      := Coalesce(_previewSql, false);
    _showDebug                       := Coalesce(_showDebug, false);

    If _previewSql Then
        _maxFilesToTest := 1;
    End If;

    If _paramFileTypeList = '' Then
        RAISE WARNING 'Error: parameter file type list must be defined using _paramFileTypeList';
        RETURN;
    End If;

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_ParamFileTypeFilter (
        Param_File_Type citext,
        Valid boolean
    );

    CREATE TEMP TABLE Tmp_ParamFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Param_File_ID int,
        Param_File_Name citext,
        Param_File_Type_ID int,
        Param_File_Type citext
    );

    CREATE INDEX IX_Tmp_ParamFiles ON Tmp_ParamFiles (Entry_ID);

    CREATE TEMP TABLE Tmp_ParamEntries (
        Param_File_ID int,
        Entry_Type citext,
        Entry_Specifier citext,
        Entry_Value citext,
        Compare boolean default true
    );

    CREATE INDEX IX_Tmp_ParamEntries_Param_File_ID ON Tmp_ParamEntries (Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Entry_Type_Entry_Specifier ON Tmp_ParamEntries (Entry_Type, Entry_Specifier, Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Compare ON Tmp_ParamEntries (Compare, Param_File_ID);

    CREATE TEMP TABLE Tmp_DefaultSequestParamEntries (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Entry_Type citext,
        Entry_Specifier citext,
        Entry_Value citext,
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
    FROM public.parse_delimited_list(_paramFileTypeList);

    UPDATE Tmp_ParamFileTypeFilter
    SET Valid = false
    WHERE NOT EXISTS (SELECT PFT.param_file_type FROM t_param_file_types PFT WHERE Tmp_ParamFileTypeFilter.param_file_type = PFT.param_file_type);

    If FOUND Then
        SELECT string_agg(PFTF.param_file_type, ', ' ORDER BY PFTF.param_file_type)
        INTO _message
        FROM Tmp_ParamFileTypeFilter PFTF
        WHERE Not PFTF.Valid;

        If Position(', ' In _message) > 0 Then
            _message := format('Warning: _paramFileTypeList has the following invalid parameter file types: %s', _message);
        Else
            _message := format('Warning: invalid parameter file type found in _paramFileTypeList: %s', _message);
        End If;

        RAISE WARNING '%', _message;

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

    If _paramFileNameFilter <> '' Then
        _sql := format('%s AND (%s)', _sql, public.create_like_clause_from_separated_string(_paramFileNameFilter, 'PF.Param_File_Name', ','));
    End If;

    _sql := format('%s ORDER BY PFT.Param_File_Type, PF.Param_File_ID', _sql);

    If _previewSql Then
        RAISE INFO '';
        RAISE INFO '%', _sqlStart;
        RAISE INFO '%', _sql;

        -- Populate Tmp_ParamFiles with up to five parameter files matching the filters
        EXECUTE (format('%s %s LIMIT 5', _sqlStart, _sql));

        RAISE INFO '';

        If Exists (SELECT Param_File_ID FROM Tmp_ParamFiles) Then
            RAISE INFO 'First five parameter files matching the filters:';

            FOR _paramFileInfo IN
                SELECT PF.Param_File_Type AS ParamFileType,
                       PF.Param_File_ID AS ParamFileID,
                       PF.Param_File_Name AS ParamFileName
                FROM Tmp_ParamFiles PF
                ORDER BY PF.Entry_ID
            LOOP
                RAISE INFO '%', format('%s param file ID %s: %s',
                                       _paramFileInfo.ParamFileType,
                                       _paramFileInfo.ParamFileID,
                                       _paramFileInfo.ParamFileName);
            END LOOP;
        Else
            RAISE INFO 'Did not find any parameter files that match the filters';
        End If;

    Else
        -- Populate Tmp_ParamFiles with the matching parameter files
        EXECUTE (format('%s %s', _sqlStart, _sql));
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO '';
            RAISE INFO 'Found % parameter files matching the filters', _matchCount;
        End If;
    End If;

    -----------------------------------------
    -- Populate Tmp_MassModCounts
    -----------------------------------------

    INSERT INTO Tmp_MassModCounts( Param_File_ID,
                                   ModCount )
    SELECT P.Param_File_ID,
           SUM(CASE WHEN Mod_Entry_ID IS NULL THEN 0
                    ELSE 1
               END) AS ModCount
    FROM Tmp_ParamFiles P
         LEFT OUTER JOIN t_param_file_mass_mods MM
           ON P.param_file_id = MM.param_file_id
    GROUP BY P.param_file_id;

    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _showDebug Then
        RAISE INFO 'Determined mass mod counts for % parameter files', _matchCount;
    End If;

    If _paramFileTypeList ILike '%SEQUEST%' Then

        -----------------------------------------
        -- Populate Tmp_ParamEntries
        -- After this, standardize the entries to allow for rapid comparison
        -----------------------------------------

        INSERT INTO Tmp_ParamEntries( Param_File_ID,
                                      Entry_Type,
                                      Entry_Specifier,
                                      Entry_Value,
                                      Compare )
        SELECT PE.param_file_id,
               Trim(PE.entry_type),
               Trim(PE.entry_specifier),
               Trim(PE.entry_value),
               true AS Compare
        FROM t_param_entries PE
        ORDER BY PE.param_file_id, PE.entry_type, PE.entry_specifier;

        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Added % rows to Tmp_ParamEntries', _matchCount;
        End If;

        If _checkValidOnly Then
            DELETE FROM Tmp_ParamEntries
            WHERE EXISTS (SELECT PF.param_file_id
                          FROM t_param_files PF
                          WHERE PF.param_file_id = Tmp_ParamEntries.param_file_id AND
                                PF.valid = 0);

            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _showDebug Then
                If _matchCount > 0 Then
                    RAISE INFO 'Deleted % rows from Tmp_ParamEntries with valid = 0', _matchCount;
                Else
                    RAISE INFO 'All rows in Tmp_ParamEntries have valid = 1';
                End If;
            End If;
        End If;

        -----------------------------------------
        -- Possibly add entries for 'sequest_N14_NE.params' to Tmp_ParamEntries
        -----------------------------------------

        SELECT PF.param_file_id
        INTO _paramFileID
        FROM t_param_files PF
        WHERE PF.param_file_name = 'sequest_N14_NE.params';

        If Not FOUND Then
            _paramFileID := 1000;
        End If;

        If Not Exists (SELECT PE.Param_File_ID FROM Tmp_ParamEntries PE WHERE PE.Param_File_ID = _paramFileID) Then
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
        VALUES ('AdvancedParam', 'ShowFragmentIons',         'False', _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfDescriptionLines', '3',     _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfOutputLines',      '10',    _considerInsignificantParameters),
               ('AdvancedParam', 'NumberOfResultsToProcess', '500',   _considerInsignificantParameters);

        -----------------------------------------
        -- Add the default values to Tmp_ParamEntries, where missing
        -----------------------------------------

        FOR _entryInfo IN
            SELECT PE.Entry_Type As Type,
                   PE.Entry_Specifier As Specifier,
                   PE.Entry_Value As Value,
                   PE.Compare
            FROM Tmp_DefaultSequestParamEntries PE
            ORDER BY PE.Entry_ID
        LOOP
            INSERT INTO Tmp_ParamEntries (Param_File_ID, Entry_Type, Entry_Specifier, Entry_Value, Compare)
            SELECT DISTINCT PE.Param_File_ID, Trim(_entryInfo.Type), Trim(_entryInfo.Specifier), Trim(_entryInfo.Value), Coalesce(_entryInfo.Compare, true)
            FROM Tmp_ParamEntries PE
            WHERE NOT PE.Param_File_ID IN ( SELECT Target.Param_File_ID
                                            FROM Tmp_ParamEntries Target
                                            WHERE Target.Entry_Type = _entryInfo.Type AND
                                                  Target.Entry_Specifier = _entryInfo.Specifier );

        END LOOP;

        -----------------------------------------
        -- Make sure all 'FragmentIonTolerance' entries are non-zero (defaulting to 1 if 0)
        -----------------------------------------

        UPDATE Tmp_ParamEntries PE
        SET Entry_value = '1'
        WHERE PE.Entry_Type = 'AdvancedParam' AND
              PE.Entry_Specifier = 'FragmentIonTolerance' AND
              PE.Entry_Value = '0';

        -----------------------------------------
        -- Change Compare to false for entries in Tmp_ParamEntries that correspond to
        -- Entry_Specifier values in Tmp_DefaultSequestParamEntries that have Compare = false
        -----------------------------------------

        UPDATE Tmp_ParamEntries PE
        SET Compare = false
        FROM ( SELECT DISTINCT SPE.Entry_Type, SPE.Entry_Specifier
               FROM Tmp_DefaultSequestParamEntries SPE
               WHERE SPE.Compare = false) LookupQ
        WHERE PE.Entry_Type = LookupQ.Entry_Type AND
              PE.Entry_Specifier = LookupQ.Entry_Specifier AND
              PE.Compare = true;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Note: Changed Compare to false for %s rows in Tmp_ParamEntries, since they correspond to entries in Tmp_DefaultSequestParamEntries that have Compare = false',
                             _updateCount);

            RAISE INFO '%', _message;
        End If;

        -----------------------------------------
        -- If _ignoreParentMassType is true, mark these entries as Not-Compared
        -----------------------------------------

        If _ignoreParentMassType Then

            UPDATE Tmp_ParamEntries PE
            SET Compare = false
            WHERE PE.Entry_Type = 'BasicParam' AND
                  PE.Entry_Specifier = 'ParentMassType';

        End If;

        If _previewSql And Exists (SELECT Param_File_ID FROM Tmp_ParamEntries) Then

            RAISE INFO '';

            _formatSpecifier := '%-7s %-15s %-35s %-11s %-15s %-15s';

            _infoHead := format(_formatSpecifier,
                                'Compare',
                                'Entry_Type',
                                'Entry_Specifier',
                                'Entry_Count',
                                'Entry_Value_Min',
                                'Entry_Value_Max'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-------',
                                         '---------------',
                                         '-----------------------------------',
                                         '-----------',
                                         '---------------',
                                         '---------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT PE.Compare,
                       PE.Entry_Type,
                       PE.Entry_Specifier,
                       COUNT(PE.Param_File_ID) AS Entry_Count,
                       MIN(PE.Entry_Value) AS Entry_Value_Min,
                       MAX(PE.Entry_Value) AS Entry_Value_Max
                FROM Tmp_ParamEntries PE
                WHERE PE.Compare = true
                GROUP BY PE.Compare, PE.Entry_Type, PE.Entry_Specifier
                UNION
                SELECT PE.Compare,
                       PE.Entry_Type,
                       PE.Entry_Specifier,
                       COUNT(PE.Param_File_ID) AS Entry_Count,
                       MIN(PE.Entry_Value) AS Entry_Value_Min,
                       MAX(PE.Entry_Value) AS Entry_Value_Max
                FROM Tmp_ParamEntries PE
                WHERE PE.Compare = false
                GROUP BY PE.Compare, PE.Entry_Type, PE.Entry_Specifier
                ORDER BY PE.Compare DESC, Entry_Type, PE.Entry_Specifier
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
    End If;

    -----------------------------------------
    -- Step through the entries in Tmp_ParamFiles
    -- and look for duplicate and similar param files
    -----------------------------------------

    _filesProcessed := 0;

    If _showDebug Then
        RAISE INFO '';
    End If;

    FOR _paramFileInfo IN
        SELECT PF.Param_File_ID      AS ParamFileID,
               PF.Param_File_Name    AS ParamFileName,
               PF.Param_File_Type_ID AS ParamFileTypeID,
               PF.Param_File_Type    AS ParamFileType
        FROM Tmp_ParamFiles PF
        ORDER BY PF.Entry_ID
    LOOP

        TRUNCATE TABLE Tmp_MassModDuplicates;
        TRUNCATE TABLE Tmp_ParamEntryDuplicates;

        If _showDebug And _paramFileInfo.ParamFileType::citext = 'SEQUEST' Then
            RAISE INFO '';
        End If;

        -----------------------------------------
        -- Look for duplicates in t_param_file_mass_mods
        -----------------------------------------

        -- First, lookup the mod count for this parameter file

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
                  (Not _checkValidOnly OR PF.valid <> 0);

            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _showDebug Then
                RAISE INFO 'Param file ID % does not have any mass modifications; there are % other parameter files that do not have mass mods (%)',
                           _paramFileInfo.ParamFileID, _matchCount, _paramFileInfo.ParamFileName;
            End If;
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
                                                           WHERE ModCount = _modCount )
                           ) B
                   ON A.residue_id = B.residue_id AND
                      A.mass_correction_id = B.mass_correction_id AND
                      A.mod_type_symbol = B.mod_type_symbol
            GROUP BY B.param_file_id
            HAVING COUNT(*) = _modCount;

            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _showDebug Then
                RAISE INFO 'Param file ID % has % mass %; found % other parameter files that have the same modifications and mod count (%)',
                           _paramFileInfo.ParamFileID,
                           _modCount,
                           public.check_plural(_modCount, 'modification', 'modifications'),
                           _matchCount,
                           _paramFileInfo.ParamFileName;
            End If;

        End If;

        -----------------------------------------
        -- Look for duplicates in t_param_entries
        -- This is only applicable to SEQUEST parameter files
        -----------------------------------------

        If _paramFileInfo.ParamFileType::citext = 'SEQUEST' Then

            -----------------------------------------
            -- First, Count the number of entries in the table for this parameter file
            -- Skipping entries with Compare = false
            -----------------------------------------

            SELECT COUNT(*)
            INTO _entryCount
            FROM Tmp_ParamEntries
            WHERE Compare AND Param_File_ID = _paramFileInfo.ParamFileID;

            If _entryCount = 0 Then

                -----------------------------------------
                -- Parameter file doesn't have any param entries (with compare = true)
                -- Find all other parameter files that don't have any param entries
                -----------------------------------------

                _sql := ' INSERT INTO Tmp_ParamEntryDuplicates (param_file_id)'
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
                FROM ( SELECT Param_File_ID,
                              Entry_Type,
                              Entry_Specifier,
                              Entry_Value
                       FROM Tmp_ParamEntries
                       WHERE Compare AND param_file_id = _paramFileInfo.ParamFileID
                    ) A
                    INNER JOIN ( SELECT PE.Param_File_ID,
                                        PE.Entry_Type,
                                        PE.Entry_Specifier,
                                        PE.Entry_Value
                                FROM Tmp_ParamEntries PE
                                    INNER JOIN t_param_files PF
                                        ON PE.param_file_id = PF.param_file_id
                                WHERE PE.Compare AND
                                      PE.param_file_id <> _paramFileInfo.ParamFileID AND
                                      PF.param_file_type_id = _paramFileInfo.ParamFileTypeID AND
                                      PE.param_file_id IN ( SELECT Param_File_ID
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

                GET DIAGNOSTICS _matchCount = ROW_COUNT;

                If _showDebug Then
                    If _matchCount > 0 Then
                        RAISE INFO 'Param file ID % has % param %; found % other parameter files that have the same param entries (%)',
                                   _paramFileInfo.ParamFileID,
                                   _entryCount,
                                   public.check_plural(_entryCount, 'entry', 'entries'),
                                   _matchCount,
                                   _paramFileInfo.ParamFileName;
                    Else
                        RAISE INFO 'Param file ID % has % param %; did not find any other parameter files that have the same param entries (%)',
                                   _paramFileInfo.ParamFileID,
                                   _entryCount,
                                   public.check_plural(_entryCount, 'entry', 'entries'),
                                   _paramFileInfo.ParamFileName;
                    End If;
                End If;
            End If;

            -----------------------------------------
            -- Any Param_File_ID values that are in Tmp_ParamEntryDuplicates and Tmp_MassModDuplicates are duplicates
            -- Add their IDs to Tmp_SimilarParamFiles, provided the existing combo does not yet already exist
            -----------------------------------------

            INSERT INTO Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
            SELECT _paramFileInfo.ParamFileID, PED.Param_File_ID
            FROM Tmp_ParamEntryDuplicates PED INNER JOIN
                 Tmp_MassModDuplicates MMD ON PED.Param_File_ID = MMD.Param_File_ID
            WHERE NOT EXISTS
                  ( SELECT 1
                    FROM Tmp_SimilarParamFiles SPF
                    WHERE SPF.Param_File_ID_Master = PED.Param_File_ID AND
                          SPF.Param_File_ID_Dup = _paramFileInfo.ParamFileID
                  );

            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _showDebug Then
                If _matchCount > 0 Then
                    RAISE INFO 'Found % other parameter % that have the same mass mods and param entries as parameter file %',
                               _matchCount,
                               public.check_plural(_matchCount, 'file', 'files'),
                               _paramFileInfo.ParamFileName;

                Else
                    RAISE INFO 'Did not find any other parameter files that have the same mass mods and param entries as parameter file %',
                               _paramFileInfo.ParamFileName;
                End If;
            End If;
        Else
            -----------------------------------------
            -- Any Param_File_ID values that are in Tmp_MassModDuplicates are duplicates
            -- Add their IDs to Tmp_SimilarParamFiles, provided the existing combo does not yet already exist
            -----------------------------------------

            INSERT INTO Tmp_SimilarParamFiles(Param_File_ID_Master, Param_File_ID_Dup)
            SELECT _paramFileInfo.ParamFileID, MMD.Param_File_ID
            FROM Tmp_MassModDuplicates MMD
            WHERE NOT EXISTS
                  ( SELECT 1
                    FROM Tmp_SimilarParamFiles SPF
                    WHERE SPF.Param_File_ID_Master = MMD.Param_File_ID AND
                          SPF.Param_File_ID_Dup = _paramFileInfo.ParamFileID
                  );

        End If;

        _filesProcessed := _filesProcessed + 1;

        If _maxFilesToTest > 0 And _filesProcessed >= _maxFilesToTest Then
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
           PFA.param_file_name AS param_file_Name_A,
           PFB.param_file_name AS param_file_Name_B,
           PFA.param_file_description AS param_file_Description_A,
           PFB.param_file_description AS param_file_Description_B
    FROM Tmp_SimilarParamFiles SPF
         INNER JOIN t_param_files PFA
           ON SPF.Param_File_ID_Master = PFA.param_file_id
         INNER JOIN t_param_files PFB
           ON SPF.Param_File_ID_Dup = PFB.param_file_id
         INNER JOIN Tmp_ParamFiles PFInfo
           ON SPF.Param_File_ID_Master = PFInfo.param_file_id;

    If Exists (SELECT Param_File_ID FROM Tmp_ParamEntries) Then

        -- Use RAISE INFO to show the data in Tmp_ParamEntries (only applies to SEQUEST parameter files)

        RAISE INFO '';

        _formatSpecifier := '%-19s %-13s %-15s %-35s %-11s %-15s %-15s';

        _infoHead := format(_formatSpecifier,
                            'Param_File_Category',
                            'Param_File_ID',
                            'Entry_Type',
                            'Entry_Specifier',
                            'Entry_Count',
                            'Entry_Value_Min',
                            'Entry_Value_Max'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------',
                                     '-------------',
                                     '---------------',
                                     '-----------------------------------',
                                     '-----------',
                                     '---------------',
                                     '---------------'
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
            ORDER BY Param_File_Category DESC, Param_File_ID, Entry_Type

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

    DROP TABLE Tmp_ParamFileTypeFilter;
    DROP TABLE Tmp_ParamFiles;
    DROP TABLE Tmp_ParamEntries;
    DROP TABLE Tmp_DefaultSequestParamEntries;
    DROP TABLE Tmp_MassModDuplicates;
    DROP TABLE Tmp_ParamEntryDuplicates;
    DROP TABLE Tmp_SimilarParamFiles;
    DROP TABLE Tmp_MassModCounts;
END
$_$;


ALTER FUNCTION public.find_duplicate_param_files(_paramfilenamefilter text, _paramfiletypelist text, _ignoreparentmasstype boolean, _considerinsignificantparameters boolean, _checkvalidonly boolean, _maxfilestotest integer, _previewsql boolean, _showdebug boolean) OWNER TO d3l243;


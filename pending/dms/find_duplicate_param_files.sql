--
CREATE OR REPLACE PROCEDURE public.find_duplicate_param_files
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
    _myRowCount int := 0;
    _sStart text;
    _s text;
    _filesProcessed int;
    _paramFileInfo record;
    _modCount int;
    _entryCount int;
    _entryInfo record;
BEGIN
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
    _message := '';
    _returnCode := '';

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
        Valid int
    )

    CREATE TEMP TABLE Tmp_ParamFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Param_File_ID int,
        Param_File_Name text,
        Param_File_Type_ID int,
        Param_File_Type text
    )
    CREATE INDEX IX_Tmp_ParamFiles ON Tmp_ParamFiles (Entry_ID)

    CREATE TEMP TABLE Tmp_ParamEntries (
        Param_File_ID int,
        Entry_Type text,
        Entry_Specifier text,
        Entry_Value text,
        Compare boolean Default true
    )

    CREATE INDEX IX_Tmp_ParamEntries_Param_File_ID ON Tmp_ParamEntries (Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Entry_Type_Entry_Specifier ON Tmp_ParamEntries (Entry_Type, Entry_Specifier, Param_File_ID);
    CREATE INDEX IX_Tmp_ParamEntries_Compare ON Tmp_ParamEntries (Compare, Param_File_ID);

    CREATE TEMP TABLE Tmp_DefaultSequestParamEntries (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Entry_Type text,
        Entry_Specifier text,
        Entry_Value text,
        Compare boolean Default true
    );

    CREATE INDEX IX_Tmp_DefaultSequestParamEntries_Entry_ID ON Tmp_DefaultSequestParamEntries (Entry_ID);
    CREATE UNIQUE INDEX IX_Tmp_DefaultSequestParamEntries_Entry_Type_Entry_Specifier ON Tmp_DefaultSequestParamEntries (Entry_Type, Entry_Specifier);

    CREATE TEMP TABLE Tmp_MassModDuplicates (
        Param_File_ID int
    )

    CREATE TEMP TABLE Tmp_ParamEntryDuplicates (
        Param_File_ID int
    )

    CREATE TEMP TABLE Tmp_SimilarParamFiles (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Param_File_ID_Master int,
        Param_File_ID_Dup int
    )

    CREATE TEMP TABLE Tmp_MassModCounts (
        Param_File_ID int,
        ModCount int
    )

    CREATE INDEX IX_Tmp_MassModCounts_ModCount ON Tmp_MassModCounts (ModCount);
    CREATE UNIQUE INDEX IX_Tmp_MassModCounts_ModCountParamFileID ON Tmp_MassModCounts (ModCount, Param_File_ID);

    -----------------------------------------
    -- Populate Tmp_ParamFileTypeFilter
    -----------------------------------------

    INSERT INTO Tmp_ParamFileTypeFilter (Param_File_Type, Valid)
    SELECT DISTINCT Item, 1
    FROM public.parse_delimited_list(_paramFileTypeList, ',')
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    UPDATE Tmp_ParamFileTypeFilter
    SET Valid = 0
    FROM Tmp_ParamFileTypeFilter PFTF

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_ParamFileTypeFilter
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_ParamFileTypeFilter.id;
    ********************************************************************************/

                           ToDo: Fix this query

        LEFT OUTER JOIN t_param_file_types PFT
        ON PFTF.param_file_type = PFT.param_file_type
    WHERE PFT.param_file_type IS NULL
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Warning: one or more items in _paramFileTypeList were not valid parameter file types';
        RAISE INFO '%', _message;

        SELECT _message, *
        FROM Tmp_ParamFileTypeFilter

        _message := '';

        DELETE FROM Tmp_ParamFileTypeFilter
        WHERE Valid = 0

    End If;

    -----------------------------------------
    -- Populate Tmp_ParamFiles
    -----------------------------------------

    _sStart := '';
    _s := '';

    _sStart := _sStart || ' INSERT INTO Tmp_ParamFiles (Param_File_ID, Param_File_Name, Param_File_Type_ID, Param_File_Type)';
    _sStart := _sStart || ' SELECT ';

    _s := _s || ' PF.param_file_id,';
    _s := _s ||        ' PF.param_file_name,';
    _s := _s ||        ' PF.param_file_type_id,';
    _s := _s ||        ' PFT.param_file_type';
    _s := _s || ' FROM t_param_files PF INNER JOIN ';
    _s := _s ||   ' t_param_file_types PFT ON PF.param_file_type_id = PFT.param_file_type_id INNER JOIN ';
    _s := _s ||      ' Tmp_ParamFileTypeFilter PFTF ON PFT.param_file_type = PFTF.param_file_type ';

    If _checkValidOnly Then
        _s := _s || ' WHERE (PF.Valid <> 0)';
    Else
        _s := _s || ' WHERE (PF.Valid = PF.Valid)';
    End If;

    If char_length(_paramFileNameFilter) > 0 Then
        _s := _s || ' AND (' || dbo.CreateLikeClauseFromSeparatedString(_paramFileNameFilter, 'Param_File_Name', ',') || ')';
    End If;

    _s := _s || ' ORDER BY Param_File_Type, Param_File_ID';

    If _previewSql Then
        RAISE INFO '% %', _sStart, _s;
    Else
        EXECUTE (_sStart || _s);
    End If;

    If _previewSql Then
        -- Populate Tmp_ParamFileTypeFilter with the first parameter file matching the filters
        _sStart := '';
        _sStart := _sStart || ' INSERT INTO Tmp_ParamFiles (Param_File_ID, Param_File_Name, Param_File_Type_ID, Param_File_Type)';
        _sStart := _sStart || ' SELECT ';

        EXECUTE (_sStart || _s || ' LIMIT 1');
    End If;

    If _previewSql Then
        -- ToDo: Update this to use RAISE INFO
        SELECT *;
        FROM Tmp_ParamFiles
        ORDER BY Entry_ID;
    End If;

    -----------------------------------------
    -- Populate Tmp_MassModCounts
    -----------------------------------------
    --
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

    If _paramFileTypeList LIKE '%Sequest%' Then
    -- <a1>

        -----------------------------------------
        -- Populate Tmp_ParamEntries with t_param_entries
        -- After this, standardize the entries to allow for rapid comparison
        -----------------------------------------
        --
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
        ORDER BY param_file_id, entry_type, entry_specifier
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _checkValidOnly Then
            DELETE Tmp_ParamEntries
            FROM  t_param_files PF
            WHERE Tmp_ParamEntries.param_file_id = PF.param_file_id AND PF.valid = 0;
        End If;

        -----------------------------------------
        -- Possibly add entries for 'sequest_N14_NE.params' to Tmp_ParamEntries
        -----------------------------------------
        --
        _paramFileID := 1000;

        SELECT param_file_id
        INTO _paramFileID
        FROM t_param_files
        WHERE (param_file_name = 'sequest_N14_NE.params')

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
            WHERE (NOT (Param_File_ID IN ( SELECT Param_File_ID
                                           FROM Tmp_ParamEntries
                                           WHERE (Entry_Type = _entryType) AND
                                                 (Entry_Specifier = _entrySpecifier) )));

        END LOOP;

        -----------------------------------------
        -- Make sure all 'FragmentIonTolerance' entries are non-zero (defaulting to 1 if 0)
        -----------------------------------------
        --
        UPDATE Tmp_ParamEntries
        SET Entry_value = '1'
        WHERE Entry_Type = 'AdvancedParam' AND
              Entry_Specifier = 'FragmentIonTolerance' AND
              Entry_Value = '0';
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -----------------------------------------
        -- Change Compare to false for entries in Tmp_ParamEntries that correspond to
        -- Entry_Specifier values in Tmp_DefaultSequestParamEntries that have Compare = 0
        -----------------------------------------
        --
        UPDATE Tmp_ParamEntries
        SET Compare = false
        FROM ( SELECT DISTINCT Entry_Type, Entry_Specifier
               FROM Tmp_DefaultSequestParamEntries
               WHERE Compare = false) LookupQ
        WHERE PE.Entry_Type = LookupQ.Entry_Type AND
              PE.Entry_Specifier = LookupQ.Entry_Specifier AND
              Compare = true;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _message := 'Note: Updated ' || _myRowCount::text || ' rows in Tmp_ParamEntries to have Compare = false, since they correspond to entries in Tmp_DefaultSequestParamEntries that have Compare = false';
            RAISE INFO '%', _message;
            _message := '';
        End If;

        -----------------------------------------
        -- If _ignoreParentMassType is true, mark these entries as Not-Compared
        -----------------------------------------
        --
        If _ignoreParentMassType Then

            UPDATE Tmp_ParamEntries
            SET Compare = false
            WHERE Entry_Type = 'BasicParam' AND
                  Entry_Specifier = 'ParentMassType';

        End If;

        If _previewSql Then

            -- ToDo: Use Raise Info to show this information

            -----------------------------------------
            -- Display stats on the data in Tmp_ParamEntries
            -----------------------------------------
            --
            SELECT Compare,
                   Entry_Type,
                   Entry_Specifier,
                   COUNT(*) AS Entry_Count,
                   MIN(Entry_Value) AS Entry_Value_Min,
                   MAX(Entry_Value) AS Entry_Value_Max
            FROM Tmp_ParamEntries
            WHERE Compare = true
            GROUP BY Compare, Entry_Type, Entry_Specifier;

            SELECT Compare,
                   Entry_Type,
                   Entry_Specifier,
                   COUNT(*) AS Entry_Count,
                   MIN(Entry_Value) AS Entry_Value_Min,
                   MAX(Entry_Value) AS Entry_Value_Max
            FROM Tmp_ParamEntries
            WHERE Compare = false
            GROUP BY Compare, Entry_Type, Entry_Specifier;

        End If;
    End If; -- </a1>

    -----------------------------------------
    -- Step through the entries in Tmp_ParamFiles and look for
    -- duplicate and similar param files
    -----------------------------------------
    --
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
        --
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
            --
            INSERT INTO Tmp_MassModDuplicates (param_file_id)
            SELECT PF.param_file_id
            FROM t_param_files PF
                 INNER JOIN Tmp_MassModCounts PFMM
                   ON PF.param_file_id = PFMM.param_file_id
            WHERE (PFMM.ModCount = 0) AND
                  (PF.param_file_id <> _paramFileInfo.ParamFileID) AND
                  (PF.param_file_type_id = _paramFileInfo.ParamFileTypeID) AND
                  (Not _checkValidOnly OR PF.valid <> 0);

        Else

            -----------------------------------------
            -- Find parameter files that are of the same type and have the same set of modifications
            -- Note that we're ignoring Local_Symbol_ID
            -----------------------------------------
            --
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
                                  PFMM.param_file_id IN (  SELECT param_file_id
                                                            FROM Tmp_MassModCounts
                                                            Where ModCount = _modCount );
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
        --
        If _paramFileInfo.ParamFileType::citext = 'Sequest' Then

            -----------------------------------------
            -- First, Count the number of entries in the table for this parameter file
            -- Skipping entries with Compare = false
            -----------------------------------------
            --
            SELECT COUNT(*)
            INTO _entryCount
            FROM Tmp_ParamEntries
            WHERE Compare AND Param_File_ID = _paramFileInfo.ParamFileID;

            If _modCount = 0 Then
            -- <d1>

                -----------------------------------------
                -- Parameter file doesn't have any param entries (with compare = true)
                -- Find all other parameter files that don't have any param entries
                -----------------------------------------
                --
                _s := '';
                _s := _s || ' INSERT INTO Tmp_ParamEntryDuplicates (param_file_id)';
                _s := _s || ' SELECT PF.param_file_id';
                _s := _s || ' FROM t_param_files PF LEFT OUTER JOIN';
                _s := _s ||      ' Tmp_ParamEntries PE ON ';
                _s := _s ||      ' PF.param_file_id = PE.param_file_id AND PE.Compare';
                _s := _s || ' WHERE (PE.param_file_id IS NULL) AND ';
                _s := _s ||       ' (PF.param_file_id <> $1) AND';
                _s := _s ||       ' (PF.param_file_type_id = $2)';

                If _checkValidOnly Then
                    _s := _s || ' AND (PF.Valid <> 0)';
                End If;

                If _previewSql Then
                    RAISE INFO '%', _s;
                Else
                    EXECUTE _s
                    USING _paramFileInfo.ParamFileID, _paramFileInfo.ParamFileTypeID
                End If;
            Else
            -- <d2>

                -----------------------------------------
                -- Find parameter files that are of the same type and have the same set of param entries
                -----------------------------------------
                --
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
                                WHERE (PE.Compare) AND
                                      (PE.param_file_id <> _paramFileInfo.ParamFileID) AND
                                      (PF.param_file_type_id = _paramFileInfo.ParamFileTypeID) AND
                                      (PE.param_file_id IN ( SELECT param_file_id
                                                             FROM Tmp_ParamEntries
                                                             WHERE Compare
                                                             GROUP BY param_file_id
                                                             HAVING (COUNT(*) = _entryCount) ))
                            ) B
                    ON A.Entry_Type = B.Entry_Type AND
                       A.Entry_Specifier = B.Entry_Specifier AND
                       A.Entry_Value = B.Entry_Value
                GROUP BY B.param_file_id
                HAVING (COUNT(*) = _entryCount)

            End If; -- </d2>

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
    -- Display the results
    -----------------------------------------

    -- ToDo: Convert this procedure to a function
    --       Likely use RAISE INFO for this query and RETURN QUERY for the UNION query

   SELECT SPF.Entry_ID,
           PFInfo.Param_File_Type,
           SPF.Param_File_ID_Master,
           SPF.Param_File_ID_Dup,
           PFA.param_file_name AS Name_A,
           PFB.param_file_name AS Name_B,
           PFA.param_file_description AS Desc_A,
           PFB.param_file_description AS Desc_B
    FROM Tmp_SimilarParamFiles SPF
         INNER JOIN t_param_files PFA
           ON SPF.Param_File_ID_Master = PFA.param_file_id
         INNER JOIN t_param_files PFB
           ON SPF.Param_File_ID_Dup = PFB.param_file_id
         INNER JOIN Tmp_ParamFiles PFInfo
           ON SPF.Param_File_ID_Master = PFInfo.param_file_id;

    RETURN QUERY
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
           ON SPF.Param_File_ID_Dup = PE.Param_File_ID;

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

COMMENT ON PROCEDURE public.find_duplicate_param_files IS 'FindDuplicateParamFiles';
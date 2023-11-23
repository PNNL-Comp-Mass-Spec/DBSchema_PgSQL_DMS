--
CREATE OR REPLACE PROCEDURE public.duplicate_filter_set_criteria
(
    _sourceFilterSetID int,
    _destFilterSetID int,
    _addMissingFilterCriteria boolean = true,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies the filter set critera
**
**      Requires that the new filter set exist in T_Filter_Sets
**      However, do not make any entries in T_Filter_Set_Criteria_Groups or T_Filter_Set_Criteria
**
**      The following query is useful for editing filter sets:
**
**         SELECT FS.Filter_Set_ID, FS.Filter_Set_Name,
**             FS.Filter_Set_Description, FSC.Filter_Criteria_Group_ID,
**             FSC.Filter_Set_Criteria_ID, FSC.Criterion_ID,
**             FSCN.Criterion_Name, FSC.Criterion_Comparison,
**             FSC.Criterion_Value
**         FROM t_Filter_Sets FS INNER JOIN
**             t_Filter_Set_Criteria_Groups FSCG ON
**             FS.Filter_Set_ID = FSCG.Filter_Set_ID INNER JOIN
**             t_Filter_Set_Criteria FSC ON
**             FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID INNER
**             JOIN
**             t_Filter_Set_Criteria_Names FSCN ON
**             FSC.Criterion_ID = FSCN.Criterion_ID
**         WHERE FS.Filter_Set_ID = 184
**         ORDER BY FSCN.Criterion_Name, FSC.Filter_Criteria_Group_ID
**
**  Arguments:
**
**  Auth:   mem
**  Date:   10/02/2009
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _groupIDOld int;
    _groupCount int;
    _filterCriteriaGroupIDNext int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _addMissingFilterCriteria := Coalesce(_addMissingFilterCriteria, true);
    _infoOnly := Coalesce(_infoOnly, false);

    If _sourceFilterSetID Is Null Or _destFilterSetID Is Null Then
        _message := 'Both the source and target filter set ID must be specified; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that _destFilterSetID is defined in t_filter_sets
    -----------------------------------------

    If Not Exists (SELECT filter_set_id FROM t_filter_sets WHERE filter_set_id = _destFilterSetID ) Then
        _message := format('Filter Set ID %s was not found in t_filter_sets; make an entry in that table for this filter set before calling this procedure', _destFilterSetID);
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that no groups exist for _destFilterSetID
    -----------------------------------------

    If Exists (SELECT filter_set_id FROM t_filter_set_criteria_groups WHERE filter_set_id = _destFilterSetID ) Then
        _message := format('Existing groups were found for Filter Set ID %s; this is not allowed', _destFilterSetID);
        RETURN;
    End If;

    -- Populate a temporary table with the list of groups for _sourceFilterSetID
    CREATE TEMP TABLE Tmp_FilterSetGroups (
        UniqueRowID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Group_ID_Old int NULL
    );

    -----------------------------------------
    -- Populate Tmp_FilterSetGroups with the groups defined for _sourceFilterSetID
    -----------------------------------------

    INSERT INTO Tmp_FilterSetGroups (Group_ID_Old)
    SELECT filter_criteria_group_id
    FROM t_filter_set_criteria_groups
    WHERE filter_set_id = _sourceFilterSetID
    ORDER BY filter_criteria_group_id;

    If Not FOUND Then
        _message := format('No groups found for Filter Set ID %s', _sourceFilterSetID);
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-24s %-12s %-25s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Filter_Criteria_Group_ID',
                            'Criterion_ID',
                            'Criterion_Name',
                            'Criterion_Comparison',
                            'Criterion_Value'
                            );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------------------',
                                     '------------',
                                     '-------------------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT FSC.Filter_Criteria_Group_ID,
                   FSC.Criterion_ID,
                   FSCN.Criterion_Name,
                   FSC.Criterion_Comparison,
                   FSC.Criterion_Value
            FROM t_filter_set_criteria FSC
                 INNER JOIN Tmp_FilterSetGroups FSG
                   ON FSC.filter_criteria_group_id = FSG.Group_ID_Old
                 INNER JOIN t_filter_set_criteria_names FSCN
                   ON FSC.criterion_id = FSCN.criterion_id
            ORDER BY FSG.Group_ID_Old, criterion_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Filter_Criteria_Group_ID,
                                _previewData.Criterion_ID,
                                _previewData.Criterion_Name,
                                _previewData.Criterion_Comparison,
                                _previewData.Criterion_Value
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    -----------------------------------------
    -- For each group in Tmp_FilterSetGroups, make a new group in t_filter_set_criteria_groups
    -- and duplicate the entries in t_filter_set_criteria
    -----------------------------------------

    FOR _groupIDOld IN
        SELECT Group_ID_Old
        FROM Tmp_FilterSetGroups
        ORDER BY UniqueRowID
    LOOP
        -- Define the next filter_criteria_group_id to insert into t_filter_set_criteria_groups
        SELECT MAX(filter_criteria_group_id) + 1
        INTO _filterCriteriaGroupIDNext
        FROM t_filter_set_criteria_groups

        INSERT INTO t_filter_set_criteria_groups (filter_set_id, filter_criteria_group_id)
        VALUES (_destFilterSetID, _filterCriteriaGroupIDNext);

        -- Duplicate the criteria for group _groupIDOld (from Filter Set _sourceFilterSetID)
        --
        INSERT INTO t_filter_set_criteria( filter_criteria_group_id,
                                           criterion_id,
                                           criterion_comparison,
                                           Criterion_Value )
        SELECT _filterCriteriaGroupIDNext AS NewGroupID,
               Criterion_ID,
               Criterion_Comparison,
               Criterion_Value
        FROM t_filter_set_criteria
        WHERE filter_criteria_group_id = _groupIDOld
        ORDER BY criterion_id;

    END LOOP;

    If _addMissingFilterCriteria Then
        -----------------------------------------
        -- Call Add_Missing_Filter_Criteria to add any missing criteria
        -----------------------------------------

        CALL public.add_missing_filter_criteria (
                        _filterSetID  => _destFilterSetID,
                        _message      => _message,
                        _returnCode   => _returnCode);
    End If;

    _message := format('Duplicated criteria from Filter Set ID %s to Filter Set ID %s', _sourceFilterSetID, _destFilterSetID);

    If char_length(_message) > 0 Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_FilterSetGroups;
END
$$;

COMMENT ON PROCEDURE public.duplicate_filter_set_criteria IS 'DuplicateFilterSetCriteria';

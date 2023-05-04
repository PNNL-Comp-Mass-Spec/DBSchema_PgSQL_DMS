--
CREATE OR REPLACE PROCEDURE public.duplicate_filter_set_group
(
    _filterSetID int,
    _filterCriteriaGroupID int,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies a given group for a given filter set
**      This procedure will auto-create a new entry in T_Filter_Set_Criteria_Groups
**      For safety, requires that you provide both the filter set ID and the Group ID to copy
**
**  Auth:   mem
**  Date:   02/17/2009
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _filterCriteriaGroupIDNext int;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode := '';

    If _filterSetID Is Null Or _filterCriteriaGroupID Is Null Then
        _message := 'Both the filter set ID and the filter criteria group ID must be defined; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that _filterSetID is defined in t_filter_sets
    -----------------------------------------
    --
    If Not Exists (SELECT *    FROM t_filter_sets WHERE filter_set_id = _filterSetID) Then
        _message := 'Filter Set ID ' || _filterSetID::text || ' was not found in t_filter_sets; unable to continue';
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that _filterCriteriaGroupID is defined in t_filter_set_criteria_groups
    -----------------------------------------
    --
    If Not Exists (SELECT *    FROM t_filter_set_criteria_groups WHERE filter_criteria_group_id = _filterCriteriaGroupID) Then
        _message := 'Filter Criteria Group ID ' || _filterCriteriaGroupID::text || ' was not found in t_filter_set_criteria_groups; unable to continue';
        RETURN;
    End If;

    -----------------------------------------
    -- Make sure that _filterCriteriaGroupID is mapped to _filterSetID
    -----------------------------------------
    --
    If Not Exists (SELECT *    FROM t_filter_set_criteria_groups WHERE filter_criteria_group_id = _filterCriteriaGroupID AND filter_set_id = _filterSetID) Then
        _message := 'Filter Criteria Group ID ' || _filterCriteriaGroupID::text || ' is not mapped to Filter Set ID ' || _filterSetID::text || ' in t_filter_set_criteria_groups; unable to continue';
        RETURN;
    End If;

    -----------------------------------------
    -- Lookup the next available Filter Criteria Group ID
    -----------------------------------------
    --
    SELECT MAX(filter_criteria_group_id) + 1
    INTO _filterCriteriaGroupIDNext
    FROM t_filter_set_criteria_groups;

    If _infoOnly Then
        -- ToDo: Show this data using RAISE INFO
        SELECT _filterCriteriaGroupIDNext AS NewGroupID, Criterion_ID, Criterion_Comparison, Criterion_Value
        FROM t_filter_set_criteria
        WHERE filter_criteria_group_id = _filterCriteriaGroupID
        ORDER BY criterion_id
    Else

        -- Create a new entry in t_filter_set_criteria_groups

        INSERT INTO t_filter_set_criteria_groups (filter_set_id, filter_criteria_group_id)
        VALUES (_filterSetID, _filterCriteriaGroupIDNext);

        -- Duplicate the criteria for group _filterCriteriaGroupID (from Filter Set _filterSetID)
        --
        INSERT INTO t_filter_set_criteria
            (filter_criteria_group_id, criterion_id, criterion_comparison, Criterion_Value)
        SELECT _filterCriteriaGroupIDNext AS NewGroupID, Criterion_ID, Criterion_Comparison, Criterion_Value
        FROM t_filter_set_criteria
        WHERE filter_criteria_group_id = _filterCriteriaGroupID
        ORDER BY criterion_id
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    End If;

    _message := format('Duplicated Filter Criteria Group %s for Filter Set ID %s', _filterCriteriaGroupID, _filterSetID);

    RAISE INFO '%', _message;

END
$$;

COMMENT ON PROCEDURE public.duplicate_filter_set_group IS 'DuplicateFilterSetGroup';
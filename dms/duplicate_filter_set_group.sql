--
-- Name: duplicate_filter_set_group(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.duplicate_filter_set_group(IN _filtersetid integer, IN _filtercriteriagroupid integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy a given group for a given filter set
**
**      This procedure will auto-create a new entry in t_filter_set_criteria_groups
**      For safety, it requires the caller to specify both the source filter set ID and source group ID
**
**  Arguments:
**    _filterSetID              Filter set ID
**    _filterCriteriaGroupID    Source criteria group ID
**    _infoOnly                 When true, preview updates
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   02/17/2009 mem - Initial version
**          02/13/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
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

    _infoOnly := Coalesce(_infoOnly, false);

    If _filterSetID Is Null Or _filterCriteriaGroupID Is Null Then
        _message := 'Both the filter set ID and the filter criteria group ID must be specified; unable to continue';
        _returnCode := 'U5201';
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that _filterSetID is defined in t_filter_sets
    -----------------------------------------

    If Not Exists (SELECT filter_set_id FROM t_filter_sets WHERE filter_set_id = _filterSetID) Then
        _message := format('Filter Set ID %s not found in t_filter_sets; unable to continue', _filterSetID);
        RETURN;
    End If;

    -----------------------------------------
    -- Validate that _filterCriteriaGroupID is defined in t_filter_set_criteria_groups
    -----------------------------------------

    If Not Exists (SELECT filter_criteria_group_id FROM t_filter_set_criteria_groups WHERE filter_criteria_group_id = _filterCriteriaGroupID) Then
        _message := format('Filter Criteria Group ID %s not found in t_filter_set_criteria_groups; unable to continue', _filterCriteriaGroupID);
        RETURN;
    End If;

    -----------------------------------------
    -- Make sure that _filterCriteriaGroupID is mapped to _filterSetID
    -----------------------------------------

    If Not Exists (SELECT filter_criteria_group_id FROM t_filter_set_criteria_groups WHERE filter_criteria_group_id = _filterCriteriaGroupID AND filter_set_id = _filterSetID) Then
        _message := format('Filter Criteria Group ID %s is not mapped to Filter Set ID %s in t_filter_set_criteria_groups; unable to continue', _filterCriteriaGroupID, _filterSetID);
        RETURN;
    End If;

    -----------------------------------------
    -- Lookup the next available Filter Criteria Group ID
    -----------------------------------------

    SELECT MAX(filter_criteria_group_id) + 1
    INTO _filterCriteriaGroupIDNext
    FROM t_filter_set_criteria_groups;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-12s %-12s %-30s %-20s %-15s';

        _infoHead := format(_formatSpecifier,
                            'New_Group_ID',
                            'Criterion_ID',
                            'Criterion_Name',
                            'Criterion_Comparison',
                            'Criterion_Value'
                            );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '------------',
                                     '------------',
                                     '------------------------------',
                                     '--------------------',
                                     '---------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT _filterCriteriaGroupIDNext AS New_Group_ID,
                   FSC.Criterion_ID,
                   FSCN.Criterion_Name,
                   FSC.Criterion_Comparison,
                   FSC.Criterion_Value
            FROM t_filter_set_criteria FSC
                 INNER JOIN t_filter_set_criteria_names FSCN
                   ON FSC.criterion_id = FSCN.criterion_id
            WHERE FSC.filter_criteria_group_id = _filterCriteriaGroupID
            ORDER BY FSC.criterion_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.New_Group_ID,
                                _previewData.Criterion_ID,
                                _previewData.Criterion_Name,
                                _previewData.Criterion_Comparison,
                                _previewData.Criterion_Value
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _message := format('Would duplicate Filter Criteria Group %s for Filter Set ID %s', _filterCriteriaGroupID, _filterSetID);
    Else

        -- Create a new entry in t_filter_set_criteria_groups

        INSERT INTO t_filter_set_criteria_groups (filter_set_id, filter_criteria_group_id)
        VALUES (_filterSetID, _filterCriteriaGroupIDNext);

        -- Duplicate the criteria for group _filterCriteriaGroupID (from filter set _filterSetID)

        INSERT INTO t_filter_set_criteria (filter_criteria_group_id, criterion_id, criterion_comparison, Criterion_Value)
        SELECT _filterCriteriaGroupIDNext AS NewGroupID,
               Criterion_ID,
               Criterion_Comparison,
               Criterion_Value
        FROM t_filter_set_criteria
        WHERE filter_criteria_group_id = _filterCriteriaGroupID
        ORDER BY criterion_id;

        _message := format('Duplicated Filter Criteria Group %s for Filter Set ID %s, creating group %s',
                           _filterCriteriaGroupID, _filterSetID, _filterCriteriaGroupIDNext);
    End If;

    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE public.duplicate_filter_set_group(IN _filtersetid integer, IN _filtercriteriagroupid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE duplicate_filter_set_group(IN _filtersetid integer, IN _filtercriteriagroupid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.duplicate_filter_set_group(IN _filtersetid integer, IN _filtercriteriagroupid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DuplicateFilterSetGroup';


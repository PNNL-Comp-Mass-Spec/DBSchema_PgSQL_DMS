--
-- Name: add_missing_filter_criteria(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_missing_filter_criteria(IN _filtersetid integer, IN _processgroupswithnocurrentcriteriadefined boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine the given filter set and makes sure all of its groups contain all of the criteria
**
**  Arguments:
**    _filterSetID                                  Filter set ID
**    _processGroupsWithNoCurrentCriteriaDefined    When true, process groups without any current criteria
**    _message                                      Status message
**    _returnCode                                   Return code
**
**  Auth:   mem
**  Date:   02/01/2006
**          10/30/2008 mem - Added Inspect MQScore, Inspect TotalPRMScore, and Inspect FScore
**          07/21/2009 mem - Added Inspect PValue
**          07/27/2010 mem - Added MSGF_SpecProb
**          09/16/2011 mem - Added MSGFDB_SpecProb, MSGFDB_PValue, and MSGFDB_FDR
**          12/04/2012 mem - Added MSAlign_PValue and MSAlign_FDR
**          05/07/2013 mem - Added MSGFPlus_PepQValue
**                           Renamed MSGFDB_FDR to MSGFPlus_QValue
**          12/12/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int;
    _groupID int;
    _criterionID int;
    _groupsProcessed int;
    _criteriaAdded int;
    _criterionComparison text;
    _criterionValue float8;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _filterSetID                               := Coalesce(_filterSetID, 0);
    _processGroupsWithNoCurrentCriteriaDefined := Coalesce(_processGroupsWithNoCurrentCriteriaDefined, false);

    _groupsProcessed := 0;
    _criteriaAdded := 0;

    _groupID := -1000000;

    WHILE true
    LOOP
        -- Lookup the first _groupID for _filterSetID
        If _processGroupsWithNoCurrentCriteriaDefined Then
            SELECT Filter_Criteria_Group_ID
            INTO _groupID
            FROM t_filter_set_criteria_groups
            WHERE filter_set_id = _filterSetID AND
                  filter_criteria_group_id > _groupID
            GROUP BY filter_criteria_group_id
            ORDER BY filter_criteria_group_id
            LIMIT 1;
        Else
            SELECT FSCG.filter_criteria_group_id
            INTO _groupID
            FROM t_filter_set_criteria_groups FSCG
                 INNER JOIN t_filter_set_criteria FSC
                   ON FSCG.filter_criteria_group_id = FSC.filter_criteria_group_id
            WHERE FSCG.filter_set_id = _filterSetID AND
                  FSC.filter_criteria_group_id > _groupID
            GROUP BY FSCG.filter_criteria_group_id
            ORDER BY FSCG.filter_criteria_group_id
            LIMIT 1;
        End If;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        -- Make sure an entry is present for each criterion_id defined in t_filter_set_criteria_names

        FOR _criterionID IN
            SELECT criterion_id
            FROM t_filter_set_criteria_names
            ORDER BY criterion_id
        LOOP

            SELECT COUNT(FSC.filter_set_criteria_id)
            INTO _matchCount
            FROM t_filter_set_criteria FSC INNER JOIN
                 t_filter_set_criteria_groups FSCG ON
                 FSC.filter_criteria_group_id = FSCG.filter_criteria_group_id
            WHERE FSCG.filter_set_id = _filterSetID AND
                  FSC.filter_criteria_group_id = _groupID AND
                  FSC.criterion_id = _criterionID;

            If _matchCount > 0 Then
                CONTINUE;
            End If;

            -- Define the default comparison operator and criterion value
            _criterionComparison := '>=';
            _criterionValue := 0;

            -- Update the values for some of the criteria
            If _criterionID = 1 Then
                -- Spectrum Count
                _criterionComparison := '>=';
                _criterionValue := 1;
            End If;

            If _criterionID = 7 Then
                -- DelCn
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 14 Then
                -- XTandem Hyperscore
                _criterionComparison := '>=';
                _criterionValue := 1;
            End If;

            If _criterionID = 15 Then
                -- XTandem Log_EValue
                _criterionComparison := '<=';
                _criterionValue := 0;
            End If;

            If _criterionID = 16 Then
                -- Peptide_Prophet_Probability
                _criterionComparison := '>=';
                _criterionValue := -100;
            End If;

            If _criterionID = 17 Then
                -- RankScore
                _criterionComparison := '>=';
                _criterionValue := 0;
            End If;

            If _criterionID = 18 Then
                -- Inspect MQScore
                _criterionComparison := '>=';
                _criterionValue := -10000;
            End If;

            If _criterionID = 19 Then
                -- Inspect TotalPRMScore
                _criterionComparison := '>=';
                _criterionValue := -10000;
            End If;

            If _criterionID = 20 Then
                -- Inspect FScore
                _criterionComparison := '>=';
                _criterionValue := -10000;
            End If;

            If _criterionID = 21 Then
                -- Inspect PValue
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 22 Then
                -- MSGF_SpecProb
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 23 Then
                -- MSGFDB_SpecProb
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 24 Then
                -- MSGFDB_PValue
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 25 Then
                -- MSGFPlus_QValue (previously MSGFDB_FDR)
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 26 Then
                -- MSAlign_PValue
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 27 Then
                -- MSAlign_FDR
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            If _criterionID = 28 Then
                -- MSGFPlus_PepQValue
                _criterionComparison := '<=';
                _criterionValue := 1;
            End If;

            INSERT INTO t_filter_set_criteria( filter_criteria_group_id,
                                               criterion_id,
                                               criterion_comparison,
                                               Criterion_Value )
            VALUES(_groupID, _criterionID, _criterionComparison, _criterionValue);

            _criteriaAdded := _criteriaAdded + 1;
        END LOOP;

        _groupsProcessed := _groupsProcessed + 1;
    END LOOP;

    If _groupsProcessed = 0 Then
        _message := format('No groups found for Filter Set ID %s', _filterSetID);
    Else
        _message := format('Finished processing Filter Set ID %s; processed %s %s and added %s criteria',
                            _filterSetID, _groupsProcessed, public.check_plural(_groupsProcessed, 'group', 'groups'), _criteriaAdded);
    End If;

    RAISE INFO '%', _message;

END
$$;


ALTER PROCEDURE public.add_missing_filter_criteria(IN _filtersetid integer, IN _processgroupswithnocurrentcriteriadefined boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_missing_filter_criteria(IN _filtersetid integer, IN _processgroupswithnocurrentcriteriadefined boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_missing_filter_criteria(IN _filtersetid integer, IN _processgroupswithnocurrentcriteriadefined boolean, INOUT _message text, INOUT _returncode text) IS 'AddMissingFilterCriteria';


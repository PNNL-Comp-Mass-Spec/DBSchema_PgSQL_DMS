--
-- Name: update_eus_proposals_from_eus_imports(text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_eus_proposals_from_eus_imports(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update EUS proposals in t_eus_proposals
**
**  Arguments:
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   03/24/2011 mem - Initial version
**          03/25/2011 mem - Now automatically setting proposal state_id to 3=Inactive
**          05/02/2011 mem - Now changing proposal state_ID to 2=Active if the proposal is present in V_EUS_Import_Proposals but the proposal's state in T_EUS_Proposals is not 2=Active or 4=No Interest
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          01/27/2012 mem - Added support for state 5=Permanently Active
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/05/2016 mem - Update logic to allow for V_EUS_Import_Proposals to include inactive proposals
**          11/09/2018 mem - Mark proposals as Active if their start date is in the future
**          05/12/2021 mem - Use new NEXUS-based views
**          05/14/2021 mem - Handle null values for actual_start_date
**          05/24/2021 mem - Add new proposal types to T_EUS_Proposal_Type
**          05/24/2022 mem - Avoid inserting duplicate proposals into T_EUS_Proposals by filtering on id_rank
**          03/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _setInactiveCount int;
    _callingProcName text;
    _usageMessage text := '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- t_eus_proposals with V_NEXUS_Import_Proposals
        ---------------------------------------------------

        SELECT COUNT(proposal_id)
        INTO _countBeforeMerge
        FROM t_eus_proposals;

        MERGE INTO t_eus_proposals AS target
        USING ( SELECT project_id,
                       title,
                       proposal_type_display AS Proposal_Type,
                       actual_start_date AS Proposal_Start_Date,
                       actual_end_date AS Proposal_End_Date,
                       CASE WHEN actual_start_date > CURRENT_TIMESTAMP THEN 1     -- Proposal start date is later than today; mark it active anyway
                            WHEN CURRENT_TIMESTAMP BETWEEN Coalesce(actual_start_date, CURRENT_TIMESTAMP) AND actual_end_date + INTERVAL '1 day' THEN 1
                            ELSE 0
                       END AS Active
                FROM V_NEXUS_Import_Proposals
                WHERE id_rank = 1
              ) AS Source
        ON (target.proposal_id = source.project_id)
        WHEN MATCHED AND
             (target.title         <> source.title OR
              target.proposal_type <> source.proposal_type OR
              Coalesce(target.proposal_start_date, make_date(2000, 1, 1)) <> source.proposal_start_date OR
              Coalesce(target.proposal_end_date,   make_date(2000, 1, 1)) <> source.proposal_end_date OR
              source.active = 1 AND NOT target.state_id IN (2, 4) OR
              source.active = 0 AND     target.state_id IN (1, 2)) THEN
            UPDATE SET
                title               = source.title,
                proposal_type       = source.proposal_type,
                proposal_start_date = source.proposal_start_date,
                proposal_end_date   = source.proposal_end_date,
                state_id = CASE WHEN state_id IN (4, 5)
                                THEN target.State_ID
                                ELSE CASE WHEN active = 1 THEN 2 ELSE 3 END
                           END,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (proposal_id, title, state_id, import_date,
                    proposal_type, proposal_start_date, proposal_end_date, last_affected)
            VALUES (source.project_id, source.title, 2, CURRENT_TIMESTAMP,
                    source.proposal_type, source.proposal_start_date, source.proposal_end_date, CURRENT_TIMESTAMP);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(proposal_id)
        INTO _countAfterMerge
        FROM t_eus_proposals;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- For rows in t_eus_proposals where proposal_id is not in V_NEXUS_Import_Proposals, set the state to 3 if the state is In (1, 2)

        UPDATE t_eus_proposals target
        SET State_ID = 3        -- Auto-change state to Inactive
        WHERE target.State_ID IN (1, 2) AND
              NOT EXISTS (SELECT 1
                          FROM V_NEXUS_Import_Proposals source
                          WHERE target.Proposal_ID = source.project_id);

        GET DIAGNOSTICS _setInactiveCount = ROW_COUNT;

        If _mergeInsertCount > 0 Or _mergeUpdateCount > 0 Then
            _message := format('Updated t_eus_proposals: %s added, %s updated', _mergeInsertCount, _mergeUpdateCount);

            If _setInactiveCount > 0 Then
                _message := format('%s; %s set to inactive', _message, _setInactiveCount);
            End If;

            RAISE INFO '%', _message;
            CALL post_log_entry ('Normal', _message, 'Update_EUS_Proposals_From_EUS_Imports');
            _message := '';
        Else
            RAISE INFO 'Table t_eus_proposals is up-to-date';
        End If;

        ---------------------------------------------------
        -- Add new proposal types to t_eus_proposal_type
        ---------------------------------------------------

        INSERT INTO t_eus_proposal_type (proposal_type,
                                         proposal_type_name,
                                         abbreviation)
        SELECT DISTINCT EUP.proposal_type,
                        EUP.proposal_type,
                        Replace(EUP.proposal_type, ' ', '')
        FROM t_eus_proposals EUP
             LEFT OUTER JOIN t_eus_proposal_type EPT
               ON EUP.proposal_type = EPT.proposal_type
        WHERE NOT EUP.proposal_type IS NULL AND
              EPT.proposal_type_name IS NULL;
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        If _matchCount > 0 Then
            _message := format('Added %s new proposal %s to t_eus_proposal_type', _matchCount, public.check_plural(_matchCount, 'type', 'types'));

            RAISE INFO '%', _message;
            CALL post_log_entry ('Normal', _message, 'Update_EUS_Proposals_From_EUS_Imports');
            _message := '';
        Else
            RAISE INFO 'Table t_eus_proposal_type is up-to-date';
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
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    CALL post_usage_log_entry ('update_eus_proposals_from_eus_imports', _usageMessage);

END
$$;


ALTER PROCEDURE public.update_eus_proposals_from_eus_imports(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_eus_proposals_from_eus_imports(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_eus_proposals_from_eus_imports(INOUT _message text, INOUT _returncode text) IS 'UpdateEUSProposalsFromEUSImports';


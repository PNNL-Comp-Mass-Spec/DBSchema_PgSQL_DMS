--
CREATE OR REPLACE PROCEDURE public.update_eus_proposals_from_eus_imports
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates EUS proposals in T_EUS_Proposals
**
**  Auth:   mem
**  Date:   03/24/2011 mem - Initial version
**          03/25/2011 mem - Now automatically setting proposal state_id to 3=Inactive
**          05/02/2011 mem - Now changing proposal state_ID to 2=Active if the proposal is present in V_EUS_Import_Proposals but the proposal's state in T_EUS_Proposals is not 2=Active or 4=No Interest
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          01/27/2012 mem - Added support for state 5=Permanently Active
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/05/2016 mem - Update logic to allow for V_EUS_Import_Proposals to include inactive proposals
**          11/09/2018 mem - Mark proposals as Active if their start date is in the future
**          05/12/2021 mem - Use new NEXUS-based views
**          05/14/2021 mem - Handle null values for actual_start_date
**          05/24/2021 mem - Add new proposal types to T_EUS_Proposal_Type
**          05/24/2022 mem - Avoid inserting duplicate proposals into T_EUS_Proposals by filtering on id_rank
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
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

        SELECT COUNT(*)
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
        ON (target.Proposal_ID = source.project_id)
        WHEN MATCHED AND
             (target.Title <> source.Title OR
              target.Proposal_Type <> source.Proposal_Type OR
              Coalesce(target.Proposal_Start_Date, make_date(2000, 1, 1)) <> source.Proposal_Start_Date OR
              Coalesce(target.Proposal_End_Date, make_date(2000, 1, 1)) <> source.Proposal_End_Date OR
              source.Active = 1 And target.State_ID NOT IN (2, 4) OR
              source.Active = 0 And target.State_ID IN (1, 2)) THEN
            UPDATE SET
                Title = source.Title,
                Proposal_Type = source.Proposal_Type,
                Proposal_Start_Date = source.Proposal_Start_Date,
                Proposal_End_Date = source.Proposal_End_Date,
                State_ID = CASE WHEN State_ID IN (4, 5)
                                THEN target.State_ID
                                ELSE CASE WHEN Active = 1 THEN 2 ELSE 3 END
                           END,
                Last_Affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (Proposal_ID, Title, State_ID, Import_Date,
                    Proposal_Type, Proposal_Start_Date, Proposal_End_Date, Last_Affected)
            VALUES (source.project_id, source.Title, 2, CURRENT_TIMESTAMP,
                    source.Proposal_Type, source.Proposal_Start_Date, source.Proposal_End_Date, CURRENT_TIMESTAMP);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(*)
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
              NOT EXISTS (SELECT project_id
                          FROM V_NEXUS_Import_Proposals
                          WHERE target.Proposal_ID = source.project_id);

        GET DIAGNOSTICS _setInactiveCount = ROW_COUNT;

        If _mergeInsertCount > 0 OR _mergeUpdateCount > 0 Then
            _message := 'Updated t_eus_proposals: ' || _mergeInsertCount::text || ' added; ' || _mergeUpdateCount::text || ' updated';

            If _setInactiveCount > 0 Then
                _message := _message || '; ' || _setInactiveCount::text || ' set to inactive';
            End If;

            Call post_log_entry ('Normal', _message, 'Update_EUS_Proposals_From_EUS_Imports');
            _message := '';
        End If;

        ---------------------------------------------------
        -- Add new proposal types to t_eus_proposal_type
        ---------------------------------------------------

        INSERT INTO t_eus_proposal_type( proposal_type,
                                         proposal_type_name,
                                         abbreviation )
        SELECT DISTINCT EUP.proposal_type,
                        EUP.proposal_type,
                        Replace(EUP.proposal_type, ' ', '')
        FROM t_eus_proposals EUP
             LEFT OUTER JOIN t_eus_proposal_type EPT
               ON EUP.proposal_type = EPT.proposal_type
        WHERE NOT EUP.proposal_type IS NULL AND
              EPT.proposal_type_name IS NULL
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _message := format('Added %s new proposal %s to t_eus_proposal_type', _myRowCount, public.check_plural(_myRowCount, 'type', 'types'));

            Call post_log_entry ('Normal', _message, 'Update_EUS_Proposals_From_EUS_Imports');
            _message := '';
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

    Call post_usage_log_entry ('Update_EUS_Proposals_From_EUS_Imports', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_eus_proposals_from_eus_imports IS 'UpdateEUSProposalsFromEUSImports';

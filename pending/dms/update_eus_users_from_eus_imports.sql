--
CREATE OR REPLACE PROCEDURE public.update_eus_users_from_eus_imports
(
    _updateUsersOnInactiveProposals boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates associated EUS user associations for proposals that are currently active in DMS
**
**      Obtains data from nexus-prod-db.emsl.pnl.gov using the postgres_fdw foreign data wrapper
**
**  Arguments:
**    _updateUsersOnInactiveProposals   When true, update all proposals in t_eus_proposals, including inactive proposals; however, skips those with state 4 ('no interest')
**
**  Auth:   grk
**  Date:   03/01/2006 grk - Initial version
**          03/24/2011 mem - Updated to use V_EUS_Import_Proposal_Participants
**          03/25/2011 mem - Updated to remove entries from T_EUS_Proposal_Users if the row is no longer in V_EUS_Import_Proposal_Participants yet the proposal is still active
**          04/01/2011 mem - No longer removing entries from T_EUS_Proposal_Users; now changing to state 5 = 'No longer associated with proposal'
**                         - Added support for state 4 = 'Permanently associated with proposal'
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          03/19/2012 mem - Now populating T_EUS_Users.HID
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Use new NEXUS-based views
**                         - Add option to update EUS Users for Inactive proposals
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _setUnknownCount int;
    _callingProcName text;
    _currentLocation text := 'Start';
    _usageMessage text := '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _updateUsersOnInactiveProposals := Coalesce(_updateUsersOnInactiveProposals, false);

    BEGIN

        _currentLocation := 'Update t_eus_users';

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        SELECT COUNT(person_id)
        INTO _countBeforeMerge
        FROM t_eus_users;

        MERGE INTO t_eus_users AS target
        USING ( SELECT DISTINCT Source.user_id As Person_ID,
                                Source.name_fm,
                                CASE WHEN hanford_id IS NULL
                                     THEN NULL
                                     ELSE format('H%s', hanford_id)
                                     END AS HID,
                                CASE WHEN hanford_id IS NULL
                                     THEN 2        -- Offsite
                                     ELSE 1        -- Onsite
                                     END As Site_Status,
                                Source.first_name,
                                Source.last_name
                FROM V_NEXUS_Import_Proposal_Participants Source
                     INNER JOIN ( SELECT proposal_id
                                  FROM t_eus_proposals
                                  WHERE state_id IN (1,2) Or
                                        _updateUsersOnInactiveProposals AND state_id <> 4   -- State for is 'No Interest'
                                 ) DmsEUSProposals
                       ON Source.project_id = DmsEUSProposals.proposal_id
            ) AS Source
        ON (target.Person_ID = Source.Person_ID)
        WHEN MATCHED AND
             (target.NAME_FM     <> Source.name_fm OR
              target.HID         IS DISTINCT FROM Source.HID AND NOT Source.HID is null OR
              target.Site_Status <> Source.Site_Status OR
              target.First_Name  IS DISTINCT FROM Source.first_name AND NOT Source.first_name is null OR
              target.Last_Name   IS DISTINCT FROM Source.last_name  AND NOT Source.last_name is null) THEN
            UPDATE SET
                NAME_FM = Source.name_fm,
                HID = Coalesce(Source.HID, target.HID),
                Site_Status = Source.Site_Status,
                First_Name = Source.first_name,
                Last_Name = Source.last_name,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (Person_ID, NAME_FM, HID, Site_Status,
                    First_Name, Last_Name, last_affected)
            VALUES (Source.Person_ID, Source.name_fm, Source.HID, Source.Site_Status,
                    Source.first_name, Source.last_name, CURRENT_TIMESTAMP);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(person_id)
        INTO _countAfterMerge
        FROM t_eus_users;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- Note: don't delete data from t_eus_users
        _mergeDeleteCount := 0;

        If _mergeInsertCount > 0 Or _mergeUpdateCount > 0 Or _mergeDeleteCount > 0 Then
            _message := format('Updated t_eus_users: %s added; %s updated%s',
                                _mergeInsertCount,
                                _mergeUpdateCount,
                                CASE WHEN _mergeDeleteCount > 0
                                THEN format('; %s deleted', _mergeDeleteCount)
                                ELSE ''
                                END);

            CALL post_log_entry ('Normal', _message, 'Update_EUS_Users_From_EUS_Imports');
            _message := '';
        End If;

        _currentLocation := 'Update first_name and last_name in t_eus_users';

        Update t_eus_users
        Set first_name = Ltrim(Substring(name_fm, Position(',' In name_fm) + 1, 128))
        Where Coalesce(first_name, '') = '' And Position(',' In name_fm) > 1

        Update t_eus_users
        Set last_name = Substring(name_fm, 1, Position(',' In name_fm) - 1)
        Where Coalesce(last_name, '') = '' And Position(',' In name_fm) > 1

        _currentLocation := 'Update t_eus_proposal_users';

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        SELECT COUNT(person_id)
        INTO _countBeforeMerge
        FROM t_eus_proposal_users;

        MERGE INTO t_eus_proposal_users AS target
        USING ( SELECT DISTINCT Source.project_id AS Proposal_ID,
                                Source.user_id As Person_ID,
                                'Y' AS Of_DMS_Interest
                FROM V_NEXUS_Import_Proposal_Participants Source
                     INNER JOIN ( SELECT proposal_id
                                  FROM t_eus_proposals
                                  WHERE state_id IN (1,2)
                                ) DmsEUSProposals
                       ON Source.project_id = DmsEUSProposals.proposal_id
              ) AS Source
        ON (target.proposal_id = Source.proposal_id AND
            target.person_id = Source.person_id)
        WHEN MATCHED AND NOT Coalesce(target.state_id, 0) IN (1, 4) THEN
            UPDATE SET
                state_id = 1,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (proposal_id, person_id, of_dms_interest, State_ID, Last_Affected)
            VALUES (Source.proposal_id, Source.person_id, Source.of_dms_interest, 1, CURRENT_TIMESTAMP);

        GET DIAGNOSTICS _mergeCount = ROW_COUNT;

        SELECT COUNT(person_id)
        INTO _countAfterMerge
        FROM t_eus_proposal_users;

        _mergeInsertCount := _countAfterMerge - _countBeforeMerge;

        If _mergeCount > 0 Then
            _mergeUpdateCount := _mergeCount - _mergeInsertCount;
        Else
            _mergeUpdateCount := 0;
        End If;

        -- Set state_id to 3 (unknown association) for rows with state not in (2,4) that are also not in V_NEXUS_Import_Proposal_Participants
        --
        UPDATE t_eus_proposal_users target
        SET state_id = 3,       -- Unknown association; may need to delete
            last_affected = CURRENT_TIMESTAMP
        WHERE NOT Coalesce(target.state_id, 0) IN (2, 4) AND
              NOT EXISTS (SELECT source.Person_ID
                          FROM (SELECT DISTINCT Source.project_id AS Proposal_ID,
                                                Source.user_id As Person_ID
                                FROM V_NEXUS_Import_Proposal_Participants Source
                                     INNER JOIN ( SELECT proposal_id
                                                  FROM t_eus_proposals
                                                  WHERE state_id IN (1, 2)
                                                ) DmsEUSProposals
                                       ON Source.project_id = DmsEUSProposals.proposal_id
                          ) AS Source
                          WHERE target.proposal_id = Source.proposal_id AND
                                target.person_id = Source.person_id
                         );

        GET DIAGNOSTICS _setUnknownCount = ROW_COUNT;

        ---------------------------------------------------
        -- Update rows in t_eus_proposal_users where state_id is 3=Unknown
        -- but the associated proposal has state of 3=Inactive
        ---------------------------------------------------

        UPDATE t_eus_proposal_users
        SET state_id = 2
        FROM t_eus_proposals
        WHERE t_eus_proposal_users.proposal_id = t_eus_proposals.proposal_id AND
              t_eus_proposal_users.state_id = 3 AND
              t_eus_proposals.state_id IN (3, 4);

        ---------------------------------------------------
        -- Update rows in t_eus_proposal_users that still have state_id is 3=Unknown
        -- but the associated proposal has state 2=Active
        ---------------------------------------------------

        UPDATE t_eus_proposal_users
        SET state_id = 5
        FROM t_eus_proposals
        WHERE t_eus_proposal_users.proposal_id = t_eus_proposals.proposal_id AND
              t_eus_proposal_users.state_id = 3 AND
              t_eus_proposals.state_id = 2;

        If _mergeInsertCount > 0 Or _mergeUpdateCount > 0 Or _setUnknownCount > 0 Then
            _message := format('Updated t_eus_proposal_users: %s added; %s updated%s',
                                _mergeInsertCount,
                                _mergeUpdateCount,
                                CASE WHEN _setUnknownCount > 0
                                THEN format('; %s set to "unknown association"', _setUnknownCount)
                                ELSE ''
                                END);

            CALL post_log_entry ('Normal', _message, 'Update_EUS_Users_From_EUS_Imports');
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
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    CALL post_usage_log_entry ('update_eus_users_from_eus_imports', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_eus_users_from_eus_imports IS 'UpdateEUSUsersFromEUSImports';

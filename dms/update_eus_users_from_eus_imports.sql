--
-- Name: update_eus_users_from_eus_imports(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_eus_users_from_eus_imports(IN _updateusersoninactiveproposals boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update associated EUS user associations for proposals that are currently active in DMS
**
**      Obtains data from nexus-prod-db.emsl.pnl.gov using the postgres_fdw foreign data wrapper
**
**  Arguments:
**    _updateUsersOnInactiveProposals   When true, update all proposals in t_eus_proposals, including inactive proposals; however, skips those with state 4 ('no interest')
**    _message                          Status message
**    _returnCode                       Return code
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
**          03/01/2024 mem - Only change state_id to 3 in T_EUS_Proposal_Users if state_id is not 2, 3, 4, or 5 (previously not 2 or 4)
**                           This change was made to avoid state_id changing from 5 to 3, then from 3 back to 5 every time this procedure is called
**                         - Ported to PostgreSQL
**          07/07/2024 mem - Cache EUS proposals associated with each user
**
*****************************************************/
DECLARE
    _countBeforeMerge int;
    _countAfterMerge int;
    _mergeCount int;
    _mergeInsertCount int;
    _mergeUpdateCount int;
    _mergeDeleteCount int;
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
        RAISE INFO '%', _currentLocation;

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        SELECT COUNT(person_id)
        INTO _countBeforeMerge
        FROM t_eus_users;

        MERGE INTO t_eus_users AS target
        USING (SELECT DISTINCT Source.user_id AS person_id,
                               Source.name_fm,
                               CASE WHEN hanford_id IS NULL
                                    THEN NULL
                                    ELSE format('H%s', hanford_id)
                                    END AS hid,
                               CASE WHEN hanford_id IS NULL
                                    THEN 2        -- Offsite
                                    ELSE 1        -- Onsite
                                    END AS site_status_id,
                               Source.first_name,
                               Source.last_name
               FROM V_NEXUS_Import_Proposal_Participants Source
                    INNER JOIN (SELECT proposal_id
                                FROM t_eus_proposals
                                WHERE state_id IN (1, 2) OR
                                      _updateUsersOnInactiveProposals AND state_id <> 4   -- State for is 'No Interest'
                               ) DmsEUSProposals
                      ON Source.project_id = DmsEUSProposals.proposal_id
            ) AS Source
        ON (target.person_id = Source.person_id)
        WHEN MATCHED AND
             (target.name_fm        <> Source.name_fm OR
              target.hid            IS DISTINCT FROM Source.hid AND NOT Source.hid IS NULL OR
              target.site_status_id <> Source.site_status_id OR
              target.first_name     IS DISTINCT FROM Source.first_name AND NOT Source.first_name IS NULL OR
              target.last_name      IS DISTINCT FROM Source.last_name  AND NOT Source.last_name IS NULL) THEN
            UPDATE SET
                name_fm        = Source.name_fm,
                hid            = Coalesce(Source.hid, target.hid),
                site_status_id = Source.site_status_id,
                first_name     = Source.first_name,
                last_name      = Source.last_name,
                last_affected  = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (person_id, name_fm, hid, site_status_id,
                    first_name, last_name, last_affected)
            VALUES (Source.person_id, Source.name_fm, Source.hid, Source.site_status_id,
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

            RAISE INFO '%', _message;
            CALL post_log_entry ('Normal', _message, 'Update_EUS_Users_From_EUS_Imports');
            _message := '';
        End If;

        _currentLocation := 'Update first_name and last_name in t_eus_users';

        UPDATE t_eus_users
        SET first_name = LTrim(Substring(name_fm, Position(',' In name_fm) + 1, 128))
        WHERE Coalesce(first_name, '') = '' AND   Position(',' In name_fm) > 1;

        UPDATE t_eus_users
        SET last_name = Substring(name_fm, 1,  Position(',' In name_fm) - 1)
        WHERE Coalesce(last_name, '') = '' AND Position(',' In name_fm) > 1;

        _currentLocation := 'Update t_eus_proposal_users';
        RAISE INFO '%', _currentLocation;

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        SELECT COUNT(person_id)
        INTO _countBeforeMerge
        FROM t_eus_proposal_users;

        MERGE INTO t_eus_proposal_users AS target
        USING (SELECT DISTINCT Source.project_id AS proposal_id,
                               Source.user_id AS person_id,
                               'Y' AS of_dms_interest
               FROM V_NEXUS_Import_Proposal_Participants Source
                    INNER JOIN (SELECT proposal_id
                                FROM t_eus_proposals
                                WHERE state_id IN (1, 2)
                               ) DmsEUSProposals
                      ON Source.project_id = DmsEUSProposals.proposal_id
              ) AS Source
        ON (target.proposal_id = Source.proposal_id AND
            target.person_id = Source.person_id)
        WHEN MATCHED AND NOT Coalesce(target.state_id, 0) IN (1, 4) THEN
            UPDATE SET
                state_id      = 1,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (proposal_id, person_id, of_dms_interest, state_id, last_affected)
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

        -- Set state_id to 3 (unknown association) for rows with state not in (2, 3, 4, 5) that are also not in V_NEXUS_Import_Proposal_Participants

        UPDATE t_eus_proposal_users target
        SET state_id = 3,       -- Unknown association; may need to delete
            last_affected = CURRENT_TIMESTAMP
        WHERE NOT Coalesce(target.state_id, 0) IN (2, 3, 4, 5) AND
              NOT EXISTS (SELECT source.Person_ID
                          FROM (SELECT DISTINCT Source.project_id AS proposal_id,
                                                Source.user_id AS person_id
                                FROM V_NEXUS_Import_Proposal_Participants Source
                                     INNER JOIN (SELECT proposal_id
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

            RAISE INFO '%', _message;
            CALL post_log_entry ('Normal', _message, 'Update_EUS_Users_From_EUS_Imports');
            _message := '';
        Else
            RAISE INFO 'Table t_eus_proposal_users is up-to-date';
        End If;

        ---------------------------------------------------
        -- Update cached eus_proposals in t_eus_users
        ---------------------------------------------------

        _currentLocation := 'Update cached EUS proposals in t_eus_users';
        RAISE INFO '%', _currentLocation;

        CREATE TEMP TABLE Tmp_Proposals_By_User (
            Person_ID int,
            Proposals text
        );

        CREATE INDEX IX_Tmp_Proposals_By_User_Person_ID ON Tmp_Proposals_By_User (Person_ID);

        INSERT INTO Tmp_Proposals_By_User (Person_ID, Proposals)
        SELECT P.person_id, string_agg(P.Proposal_ID, ', ' ORDER BY P.Proposal_ID)
        FROM t_eus_proposal_users P
        WHERE P.state_id <> 5
        GROUP BY P.person_id;

        MERGE INTO t_eus_users AS t
        USING ( -- Option 1:
                -- SELECT U.person_id,
                --        public.get_eus_users_proposal_list(U.person_id) AS proposals
                -- FROM public.t_eus_users U

                -- Option 2:
                SELECT U.person_id,
                       P.Proposals
                FROM public.t_eus_users U
                     INNER JOIN Tmp_Proposals_By_User P
                       ON U.Person_ID = P.Person_ID
              ) AS s
        ON (t.person_id = s.person_id)
        WHEN MATCHED AND
             (t.eus_proposals IS DISTINCT FROM s.proposals) THEN
        UPDATE SET
            eus_proposals = s.proposals;

        -- Clear the eus_proposals field for users not in Tmp_Proposals_By_User
        UPDATE t_eus_users
        SET eus_proposals = ''
        WHERE person_id IN (SELECT U.person_id
                            FROM t_eus_users U
                                 LEFT OUTER JOIN Tmp_Proposals_By_User P
                                   ON P.person_id = U.person_id
                            WHERE P.person_id IS NULL) AND
              Coalesce(eus_proposals, '') <> '';

        DROP TABLE Tmp_Proposals_By_User;

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


ALTER PROCEDURE public.update_eus_users_from_eus_imports(IN _updateusersoninactiveproposals boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_eus_users_from_eus_imports(IN _updateusersoninactiveproposals boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_eus_users_from_eus_imports(IN _updateusersoninactiveproposals boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateEUSUsersFromEUSImports';


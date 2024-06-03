--
-- Name: add_update_eus_proposals(text, integer, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_eus_proposals(IN _euspropid text, IN _euspropstateid integer, IN _eusproptitle text, IN _euspropimpdate text, IN _eususerslist text, IN _eusproposaltype text, IN _autosupersedeproposalid text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing EUS proposal
**
**  Arguments:
**    _eusPropID                EUS Proposal ID (aka Project ID)
**    _eusPropStateID           EUS proposal state: 1=New, 2=Active, 3=Inactive, 4=No Interest
**    _eusPropTitle             EUS Proposal Title (aka Project Title)
**    _eusPropImpDate           Proposal Import Date
**    _eusUsersList             Comma-separated list of EUS Users IDs associated with this proposal
**    _eusProposalType          Proposal type; see table t_eus_proposal_type
**    _autoSupersedeProposalID  EUS Proposal ID to supersede this EUS proposal with if this proposal is closed
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   jds
**  Date:   08/15/2006
**          11/16/2006 grk - Fix problem with GetEUSPropID not able to return varchar (ticket #332)
**          04/01/2011 mem - Now updating State_ID in T_EUS_Proposal_Users
**          10/13/2015 mem - Added _eusProposalType
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/06/2019 mem - Add _autoSupersedeProposalID
**                         - Rename _eusPropState to _eusPropStateID and make it an int instead of varchar
**                         - Add Try/Catch error handling
**                         - Fix merge query bug
**          01/08/2024 mem - Update column last_affected
**                         - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingCount int := 0;
    _logErrors boolean := true;
    _tempEUSPropID text := '0';
    _proposalUserStateID int;
    _proposalImportdate timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _eusPropID               := Trim(Coalesce(_eusPropID, ''));
        _eusPropTitle            := Trim(Coalesce(_eusPropTitle, ''));
        _eusPropImpDate          := Trim(Coalesce(_eusPropImpDate, ''));
        _eusUsersList            := Trim(Coalesce(_eusUsersList, ''));
        _eusProposalType         := Trim(Coalesce(_eusProposalType, ''));
        _autoSupersedeProposalID := Trim(Coalesce(_autoSupersedeProposalID, ''));
        _mode                    := Trim(Lower(Coalesce(_mode, '')));

        If _eusPropID = '' Then
            _logErrors := false;
            RAISE EXCEPTION 'EUS proposal ID must be specified';
        End If;

        If _eusPropStateID Is Null Then
            _logErrors := false;
            RAISE EXCEPTION 'EUS proposal state cannot be null';
        End If;

        If Not Exists (SELECT state_name FROM t_eus_proposal_state_name WHERE state_id = _eusPropStateID) Then
            _logErrors := false;
            RAISE EXCEPTION 'Invalid EUS proposal state: %', _eusPropStateID;
        End If;

        If _eusPropTitle = '' Then
            _logErrors := false;
            RAISE EXCEPTION 'EUS proposal title must be specified';
        End If;

        If _eusPropImpDate = '' Then
            _eusPropImpDate := public.timestamp_text(CURRENT_TIMESTAMP);
        End If;

        _proposalImportdate := public.try_cast(_eusPropImpDate, null::timestamp);

        If _proposalImportdate Is Null Then
            _logErrors := false;
            RAISE EXCEPTION 'EUS proposal import date was not specified or is an invalid date';
        End If;

        If _eusPropStateID = 2 And _eusUsersList = '' Then
            _logErrors := false;
            RAISE EXCEPTION 'An "Active" EUS proposal must have at least 1 associated EUS User';
        End If;

        If _eusProposalType = '' Then
            _logErrors := false;
            RAISE EXCEPTION 'EUS proposal type must be specified';
        End If;

        If Not Exists (SELECT proposal_type FROM t_eus_proposal_type WHERE proposal_type = _eusProposalType::citext) Then
            _logErrors := false;
            RAISE EXCEPTION 'Invalid EUS proposal type: %', _eusProposalType;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT proposal_id
        INTO _tempEUSPropID
        FROM t_eus_proposals
        WHERE proposal_id = _eusPropID::citext;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        -- Cannot create an entry that already exists

        If _mode = 'add' And _existingCount > 0 Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot add: EUS proposal ID "%" already exists', _eusPropID;
        End If;

        -- Cannot update a non-existent entry

        If _mode = 'update' And _existingCount = 0 Then
            _logErrors := false;
            RAISE EXCEPTION 'Cannot update: EUS proposal ID "%" does not exist', _eusPropID;
        End If;

        If _autoSupersedeProposalID <> '' Then
            -- Verify that _autoSupersedeProposalID exists

            If Not Exists (SELECT proposal_id FROM t_eus_proposals WHERE proposal_id = _autoSupersedeProposalID::citext) Then
                _logErrors := false;
                RAISE EXCEPTION 'Cannot supersede proposal "%" with "%" since the new proposal does not exist', _eusPropID, _autoSupersedeProposalID;
            End If;

            If _autoSupersedeProposalID::citext = _eusPropID::citext Then
                _logErrors := false;
                RAISE EXCEPTION 'Cannot supersede proposal "%" with itself', _eusPropID;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_eus_proposals (
                proposal_id,
                title,
                state_id,
                import_date,
                proposal_type,
                proposal_id_auto_supersede
            ) VALUES (
                _eusPropID,
                _eusPropTitle,
                _eusPropStateID,
                _proposalImportdate,
                _eusProposalType,
                _autoSupersedeProposalID
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_eus_proposals
            SET title                      = _eusPropTitle,
                state_id                   = _eusPropStateID,
                import_date                = _proposalImportdate,
                proposal_type              = _eusProposalType,
                proposal_id_auto_supersede = _autoSupersedeProposalID,
                last_affected              = CURRENT_TIMESTAMP
            WHERE proposal_id = _eusPropID::citext;

        End If;

        ---------------------------------------------------
        -- Associate users in _eusUsersList with the proposal
        -- by updating information in table t_eus_proposal_users
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_EUS_Users (
            person_id int
        );

        INSERT INTO Tmp_EUS_Users (person_id)
        SELECT EUS_Person_ID
        FROM (SELECT value AS EUS_Person_ID
              FROM public.parse_delimited_integer_list ( _eusUsersList )
             ) SourceQ
             INNER JOIN t_eus_users
               ON SourceQ.EUS_Person_ID = t_eus_users.person_id;

        ---------------------------------------------------
        -- Add associations between proposal and users who are in list, but not in association table
        ---------------------------------------------------

        If _eusPropStateID In (1, 2) Then
            _proposalUserStateID := 1;
        Else
            _proposalUserStateID := 2;
        End If;

        MERGE INTO t_eus_proposal_users AS target
        USING (SELECT _eusPropID::citext AS Proposal_ID,
                      person_id,
                      'Y' AS Of_DMS_Interest
               FROM Tmp_EUS_Users
              ) AS Source
        ON (target.proposal_id = source.proposal_id AND
            target.person_id = source.person_id)
        WHEN MATCHED AND NOT Coalesce(target.state_id, 0) IN (_proposalUserStateID, 4) THEN
            UPDATE SET
                state_id = _proposalUserStateID,
                last_affected = CURRENT_TIMESTAMP
        WHEN NOT MATCHED THEN
            INSERT (proposal_id,
                    person_id,
                    of_dms_interest,
                    State_ID,
                    Last_Affected)
            VALUES (source.proposal_id,
                    source.person_id,
                    source.of_dms_interest,
                    _proposalUserStateID,
                    CURRENT_TIMESTAMP);

        -- Update rows in t_eus_proposal_users where proposal_id is _eusPropID but the user is not in Tmp_EUS_Users
        -- If state_id is not 4, set the user's state to 5 and update last_affected

        UPDATE t_eus_proposal_users target
        SET state_id = 5,
            last_affected = CURRENT_TIMESTAMP
        WHERE target.proposal_id = _eusPropID AND
              NOT Coalesce(target.state_id, 0) IN (4) AND
              NOT EXISTS (SELECT U.person_id
                          FROM Tmp_EUS_Users U
                          WHERE target.proposal_id = _eusPropID::citext AND
                                target.person_id = U.person_id);

        DROP TABLE Tmp_EUS_Users;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_EUS_Users;
END
$$;


ALTER PROCEDURE public.add_update_eus_proposals(IN _euspropid text, IN _euspropstateid integer, IN _eusproptitle text, IN _euspropimpdate text, IN _eususerslist text, IN _eusproposaltype text, IN _autosupersedeproposalid text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_eus_proposals(IN _euspropid text, IN _euspropstateid integer, IN _eusproptitle text, IN _euspropimpdate text, IN _eususerslist text, IN _eusproposaltype text, IN _autosupersedeproposalid text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_eus_proposals(IN _euspropid text, IN _euspropstateid integer, IN _eusproptitle text, IN _euspropimpdate text, IN _eususerslist text, IN _eusproposaltype text, IN _autosupersedeproposalid text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateEUSProposals';


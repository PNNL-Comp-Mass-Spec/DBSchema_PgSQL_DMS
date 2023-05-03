--
CREATE OR REPLACE PROCEDURE public.add_update_eus_proposals
(
    _eusPropID text,
    _eusPropStateID int,
    _eusPropTitle text,
    _eusPropImpDate text,
    _eusUsersList text,
    _eusProposalType text,
    _autoSupersedeProposalID text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing EUS Proposals in database
**
**  Arguments:
**    _eusPropID                EUS Proposal ID (aka Project ID)
**    _eusPropStateID           1=New, 2=Active, 3=Inactive, 4=No Interest
**    _eusPropTitle             EUS Proposal Title (aka Project Title)
**    _eusPropImpDate           Proposal Import Date
**    _eusUsersList             Comma separated list of EUS Users IDs associated with this proposal
**    _eusProposalType          Proposal type
**    _autoSupersedeProposalID  EUS Proposal ID to supersede this EUS proposal with if this proposal is closed
**    _mode                     add or update
**
**  Auth:   jds
**  Date:   08/15/2006
**          11/16/2006 grk - fix problem with GetEUSPropID not able to return varchar (ticket #332)
**          04/01/2011 mem - Now updating State_ID in T_EUS_Proposal_Users
**          10/13/2015 mem - Added _eusProposalType
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/06/2019 mem - Add _autoSupersedeProposalID
**                         - Rename _eusPropState to _eusPropStateID and make it an int instead of varchar
**                         - Add Try/Catch error handling
**                         - Fix merge query bug
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _msg text;
    _logErrors boolean := true;
    _tempEUSPropID text := '0';
    _proposalUserStateID int;

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

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        If char_length(_eusPropID) < 1 Then
            _logErrors := false;
            _msg := 'EUS Proposal ID was blank';
            RAISE EXCEPTION '%', _msg;
        End If;

        If _eusPropStateID Is Null Then
            _logErrors := false;
            _msg := 'EUS Proposal State cannot be null';
            RAISE EXCEPTION '%', _msg;
        End If;

        If char_length(_eusPropTitle) < 1 Then
            _logErrors := false;
            _msg := 'EUS Proposal Title was blank';
            RAISE EXCEPTION '%', _msg;
        End If;

        _eusPropImpDate := Coalesce(_eusPropImpDate, '');

        If char_length(_eusPropImpDate) < 1 Then
            _eusPropImpDate := public.timestamp_text(CURRENT_TIMESTAMP);
        End If;

        -- IsDate() equivalent
        If public.try_cast(_eusPropImpDate, null::timestamp) Is Null Then
            _logErrors := false;
            _msg := 'EUS Proposal Import Date was blank or an invalid date';
            RAISE EXCEPTION '%', _msg;
        End If;

        If _eusPropStateID = 2 and char_length(_eusUsersList) < 1 Then
            _logErrors := false;
            _msg := 'An "Active" EUS Proposal must have at least 1 associated EMSL User';
            RAISE EXCEPTION '%', _msg;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT proposal_id
        INTO _tempEUSPropID
        FROM t_eus_proposals
        WHERE proposal_id = _eusPropID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Cannot create an entry that already exists
        --
        If _mode = 'add' And _myRowCount > 0 Then
            _logErrors := false;
            _msg := format('Cannot add: EUS Proposal ID "%s" is already in the database', _eusPropID);
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Cannot update a non-existent entry
        --
        If _mode = 'update' And _myRowCount = 0 Then
            _logErrors := false;
            _msg := format('Cannot update: EUS Proposal ID "%s" is not in the database', _eusPropID);
            RAISE EXCEPTION '%', _msg;
        End If;

        If char_length(Coalesce(_autoSupersedeProposalID, '')) > 0 Then
            -- Verify that _autoSupersedeProposalID exists
            --
            If Not Exists (SELECT * FROM t_eus_proposals WHERE proposal_id = _autoSupersedeProposalID) Then
                _logErrors := false;
                _msg := format('Cannot supersede proposal "%s" with "%s" since the new proposal is not in the database',
                                _eusPropID, _autoSupersedeProposalID);
                RAISE EXCEPTION '%', _msg;
            End If;

            If Trim(_autoSupersedeProposalID) = Trim(_eusPropID)) Then
                _logErrors := false;
                _msg := format('Cannot supersede proposal "%s" with itself', _eusPropID);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        If _mode = 'add' Then

            INSERT INTO t_eus_proposals (
                proposal_id,
                'title',
                state_id,
                import_date,
                proposal_type,
                proposal_id_auto_supersede
            ) VALUES (
                _eusPropID,
                _eusPropTitle,
                _eusPropStateID,
                _eusPropImpDate,
                _eusProposalType,
                _autoSupersedeProposalID
            );

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            UPDATE t_eus_proposals
            SET
                'title' = _eusPropTitle,
                state_id = _eusPropStateID,
                import_date = _eusPropImpDate,
                proposal_type = _eusProposalType,
                proposal_id_auto_supersede = _autoSupersedeProposalID
            WHERE proposal_id = _eusPropID;

        End If; -- update mode

        ---------------------------------------------------
        -- Associate users in _eusUsersList with the proposal
        -- by updating information in table t_eus_proposal_users
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_EUS_Users (
            person_id int
        );

        INSERT INTO Tmp_EUS_Users (person_id)
        SELECT EUS_Person_ID
        FROM ( SELECT value AS EUS_Person_ID
               FROM public.parse_delimited_integer_list ( _eusUsersList )
             ) SourceQ
             INNER JOIN t_eus_users
               ON SourceQ.EUS_Person_ID = t_eus_users.person_id;

        ---------------------------------------------------
        -- Add associations between proposal and users
        -- who are in list, but not in association table
        ---------------------------------------------------
        --

        If _eusPropStateID IN (1, 2) Then
            _proposalUserStateID := 1;
        Else
            _proposalUserStateID := 2;
        End If;

        MERGE INTO t_eus_proposal_users AS target
        USING ( SELECT _eusPropID AS Proposal_ID,
                       person_id,
                       'Y' AS Of_DMS_Interest
                FROM Tmp_EUS_Users
              ) AS Source
        ON (target.proposal_id = source.proposal_id AND
            target.person_id = source.person_id)
        WHEN MATCHED AND Coalesce(target.state_id, 0) NOT IN (_proposalUserStateID, 4) THEN
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
        -- If state_id is not 4, set the user's state to 5 and update Last_Affected

        UPDATE t_eus_proposal_users target
        SET State_ID = 5,
            Last_Affected = CURRENT_TIMESTAMP
        WHERE target.proposal_id = _eusPropID AND
              Coalesce(target.state_id, 0) NOT IN (4) AND
              NOT EXISTS (SELECT U.person_id
                          FROM Tmp_EUS_Users U
                          WHERE target.proposal_id = U.proposal_id AND
                                target.person_id = U.person_id);
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

COMMENT ON PROCEDURE public.add_update_eus_proposals IS 'AddUpdateEUSProposals';

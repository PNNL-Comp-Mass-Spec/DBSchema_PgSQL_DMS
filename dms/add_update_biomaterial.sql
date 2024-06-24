--
-- Name: add_update_biomaterial(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_biomaterial(IN _biomaterialname text, IN _sourcename text, IN _contactusername text, IN _piusername text, IN _biomaterialtype text, IN _reason text, IN _comment text, IN _campaignname text, IN _mode text DEFAULT 'add'::text, IN _container text DEFAULT 'na'::text, IN _organismlist text DEFAULT NULL::text, IN _mutation text DEFAULT ''::text, IN _plasmid text DEFAULT ''::text, IN _cellline text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing biomaterial item
**
**  Arguments:
**    _biomaterialName      Name of biomaterial (or peptide sequence if tracking an MRM peptide)
**    _sourceName           Source that the material came from; can be a person (onsite or offsite) or a company
**    _contactUsername      Contact for the source; typically PNNL staff, but can be an offsite person
**    _piUsername           Project lead username
**    _biomaterialType      Biomaterial type, e.g. 'Eukaryote', 'Prokaryote', or 'Soil'; see column biomaterial_type in t_biomaterial_type_name
**    _reason               Biomaterial description
**    _comment              Biomaterial comment
**    _campaignName         Campaign name
**    _mode                 Mode: 'add', 'update', 'check_add', 'check_update'
**    _container            Container name; use '' or 'na' if no container
**    _organismList         List of one or more organisms to associate with this biomaterial; stored in t_biomaterial_organisms; if null, t_biomaterial_organisms is unchanged
**    _mutation             Mutation;  empty string if not applicable
**    _plasmid              Plasmid;   empty string if not applicable
**    _cellLine             Cell line; empty string if not applicable
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   grk
**  Date:   03/12/2002
**          01/12/2007 grk - Added verification mode
**          03/11/2008 grk - Added material tracking stuff (http://prismtrac.pnl.gov/trac/ticket/603); also added optional parameter _callingUser
**          03/25/2008 mem - Now calling alter_event_log_entry_user if _callingUser is not blank (Ticket #644)
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _ownerPRN and _piPRN contain a person's real name rather than their username
**          08/19/2010 grk - Use try-catch for error handling
**          11/15/2012 mem - Renamed parameter _ownerPRN to _contactPRN (aka _contactUsername); renamed column CC_Owner_PRN to CC_Contact_PRN (aka Contact_Username)
**                         - Added new fields to support peptide standards
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Fix spelling in error messages
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the cell culture name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/02/2016 mem - Add _organismList
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          01/06/2017 mem - When adding a new entry, only call Update_Organism_List_For_Biomaterial if _organismList is not null
**                         - When updating an existing entry, update _organismList to be '' if null (since the DMS website sends null when a form field is blank)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/27/2017 mem - Fix variable name bug
**          11/28/2017 mem - Deprecate old fields that are now tracked by Reference Compounds
**          08/31/2018 mem - Add _mutation, _plasmid, and _cellLine
**                         - Remove deprecated parameters that are now tracked in T_Reference_Compound
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          07/08/2022 mem - Rename procedure from Add_Update_Cell_Culture to Add_Update_Biomaterial and update argument names
**          12/30/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/11/2024 mem - Check for empty strings instead of using char_length()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _logErrors boolean := false;
    _biomaterialID int;
    _curContainerID int;
    _campaignID int;
    _typeID int;
    _containerID int;
    _curContainerName text;
    _userID int;
    _matchCount int;
    _newUsername text;
    _idConfirm int;
    _debugMsg text;
    _targetType int;
    _stateID int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _biomaterialName := Trim(Coalesce(_biomaterialName, ''));
        _sourceName      := Trim(Coalesce(_sourceName, ''));
        _contactUsername := Trim(Coalesce(_contactUsername, ''));
        _piUsername      := Trim(Coalesce(_piUsername, ''));
        _biomaterialType := Trim(Coalesce(_biomaterialType, ''));
        _reason          := Trim(Coalesce(_reason, ''));
        _campaignName    := Trim(Coalesce(_campaignName, ''));
        _container       := Trim(Coalesce(_container, ''));

        -- Note: leave _organismList as-is if it is null
        -- Procedure Update_Organism_List_For_Biomaterial will leave t_biomaterial_organisms unchanged if _organismList is null

        _mutation        := Trim(Coalesce(_mutation, ''));
        _plasmid         := Trim(Coalesce(_plasmid, ''));
        _cellLine        := Trim(Coalesce(_cellLine, ''));
        _callingUser     := Trim(Coalesce(_callingUser, ''));

        If _contactUsername = '' Then
            RAISE EXCEPTION 'Contact name must be specified';
        End If;

        If _piUsername = '' Then
            RAISE EXCEPTION 'Principle investigator username must be specified';
        End If;

        If _biomaterialName = '' Then
            RAISE EXCEPTION 'Biomaterial name must be specified';
        End If;

        If _sourceName = '' Then
            RAISE EXCEPTION 'Source name must be specified';
        End If;

        If _biomaterialType = '' Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Biomaterial type must be specified';
        End If;

        If _reason = '' Then
            RAISE EXCEPTION 'Reason must be specified';
        End If;

        If _campaignName = '' Then
            RAISE EXCEPTION 'Campaign name must be specified';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT Biomaterial_ID,
               Container_ID
        INTO _biomaterialID, _curContainerID
        FROM t_biomaterial
        WHERE Biomaterial_Name = _biomaterialName::citext;

        -- Cannot create an entry that already exists

        If FOUND And (_mode = 'add' or _mode = 'check_add') Then
            _msg := format('Cannot add: biomaterial "%s" already exists', _biomaterialName);
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Cannot update a non-existent entry

        If Not FOUND And (_mode = 'update' or _mode = 'check_update') Then
            _msg := format('Cannot update: biomaterial "%s" does not exist', _biomaterialName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve campaign name to ID
        ---------------------------------------------------

        _campaignID := public.get_campaign_id(_campaignName);

        If _campaignID = 0 Then
            _msg := format('Invalid campaign name: "%s"', _campaignName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve type name to ID
        ---------------------------------------------------

        SELECT biomaterial_type_id
        INTO _typeID
        FROM t_biomaterial_type_name
        WHERE biomaterial_type = _biomaterialType::citext;

        If Not FOUND Then
            _msg := format('Invalid biomaterial type: "%s"', _biomaterialType);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve container name to ID
        ---------------------------------------------------

        If _container = '' Then
            _container := 'na';
        End If;

        SELECT container_id
        INTO _containerID
        FROM t_material_containers
        WHERE container = _container::citext;

        If Not FOUND Then
            _msg := format('Invalid container name: "%s"', _container);
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Make sure the container name is properly capitalized
        SELECT container
        INTO _curContainerName
        FROM t_material_containers
        WHERE container_id = _curContainerID;

        ---------------------------------------------------
        -- Resolve Usernames to user IDs
        ---------------------------------------------------

        -- Verify that Owner Username is valid
        -- and get its id number

        _userID := public.get_user_id(_contactUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _contactUsername contains simply the username

            SELECT username
            INTO _contactUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _contactUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                            _contactUsername,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _contactUsername
                _contactUsername := _newUsername;
            End If;

        End If;

        -- Verify that principal investigator username is valid
        -- and get its id number

        _userID := public.get_user_id(_piUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _piUsername contains simply the username

            SELECT username
            INTO _piUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            ---------------------------------------------------
            -- _piUsername did not resolve to a user_id
            --
            -- In case a name was entered (instead of a username),
            -- try to auto-resolve using the name column in t_users
            ---------------------------------------------------

            CALL public.auto_resolve_name_to_username (
                            _piUsername,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match was found; update _piUsername
                _piUsername := _newUsername;
            Else
                If _matchCount = 0 Then
                    _msg := format('Invalid principal investigator username: "%s" does not exist', _piUsername);
                Else
                    _msg := format('Invalid principal investigator username: "%s" matches more than one user', _piUsername);
                End If;

                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_biomaterial (
                biomaterial_name,
                source_name,
                contact_username,
                pi_username,
                biomaterial_type_id,
                reason,
                comment,
                campaign_id,
                container_id,
                mutation,
                plasmid,
                cell_line,
                created
            ) VALUES (
                _biomaterialName,
                _sourceName,
                _contactUsername,
                _piUsername,
                _typeID,
                _reason,
                _comment,
                _campaignID,
                _containerID,
                _mutation,
                _plasmid,
                _cellLine,
                CURRENT_TIMESTAMP
            )
            RETURNING biomaterial_id
            INTO _biomaterialID;

            -- As a precaution, query T_Biomaterial using Biomaterial name to make sure we have the correct biomaterial ID

            SELECT biomaterial_id
            INTO _idConfirm
            FROM t_biomaterial
            WHERE biomaterial_name = _biomaterialName;

            If _biomaterialID <> Coalesce(_idConfirm, _biomaterialID) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding biomaterial %s: Found ID %s but the INSERT INTO query reported %s',
                                    _biomaterialName, _idConfirm, _biomaterialID);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Biomaterial');

                _biomaterialID := _idConfirm;
            End If;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If Trim(Coalesce(_callingUser)) <> '' Then
                _targetType := 2;
                _stateID := 1;
                CALL public.alter_event_log_entry_user ('public', _targetType, _biomaterialID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Material movement logging

            If _curContainerID <> _containerID Then
                CALL public.post_material_log_entry (
                                _type         => 'Biomaterial Move',
                                _item         => _biomaterialName,
                                _initialState => 'na',                  -- Initial State: Old container name (na)
                                _finalState   => _container,            -- Final State:   New container's name
                                _callingUser  => _callingUser,
                                _comment      => 'Biomaterial (Cell Culture) added');


            End If;

            If Coalesce(_organismList, '') <> '' Then
                -- Update the associated organism(s)
                CALL public.update_organism_list_for_biomaterial (
                                _biomaterialName,
                                _organismList,
                                _infoOnly   => false,
                                _message    => _message,       -- Output
                                _returnCode => _returnCode);   -- Output
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_biomaterial
            SET source_name         = _sourceName,
                contact_username    = _contactUsername,
                pi_username         = _piUsername,
                biomaterial_type_id = _typeID,
                reason              = _reason,
                comment             = _comment,
                campaign_id         = _campaignID,
                container_id        = _containerID,
                mutation            = _mutation,
                plasmid             = _plasmid,
                cell_line           = _cellLine
            WHERE biomaterial_name = _biomaterialName::citext;

            If Not FOUND Then
                _msg := format('Update operation failed: "%s"', _biomaterialName);
                RAISE EXCEPTION '%', _msg;
            End If;

            -- Material movement logging

            If _curContainerID <> _containerID Then
                CALL public.post_material_log_entry (
                                _type         => 'Biomaterial Move',
                                _item         => _biomaterialName,
                                _initialState => _curContainerName,     -- Initial State: Old container name
                                _finalState   => _container,            -- Final State:   New container name
                                _callingUser  => _callingUser,
                                _comment      => 'Biomaterial (Cell Culture) updated');
            End If;

            -- Update the associated organism(s)
            -- If _organismList is an empty string, any rows for the biomaterial will be removed from t_biomaterial_organisms and
            -- Cached_Organism_List will be cleared in t_biomaterial for _biomaterialName

            _organismList := Trim(Coalesce(_organismList, ''));

            CALL public.update_organism_list_for_biomaterial (
                            _biomaterialName,
                            _organismList,
                            _infoOnly   => false,
                            _message    => _message,       -- Output
                            _returnCode => _returnCode);   -- Output

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Biomaterial %s', _exceptionMessage, _biomaterialName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_biomaterial(IN _biomaterialname text, IN _sourcename text, IN _contactusername text, IN _piusername text, IN _biomaterialtype text, IN _reason text, IN _comment text, IN _campaignname text, IN _mode text, IN _container text, IN _organismlist text, IN _mutation text, IN _plasmid text, IN _cellline text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_biomaterial(IN _biomaterialname text, IN _sourcename text, IN _contactusername text, IN _piusername text, IN _biomaterialtype text, IN _reason text, IN _comment text, IN _campaignname text, IN _mode text, IN _container text, IN _organismlist text, IN _mutation text, IN _plasmid text, IN _cellline text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_biomaterial(IN _biomaterialname text, IN _sourcename text, IN _contactusername text, IN _piusername text, IN _biomaterialtype text, IN _reason text, IN _comment text, IN _campaignname text, IN _mode text, IN _container text, IN _organismlist text, IN _mutation text, IN _plasmid text, IN _cellline text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateBiomaterial';


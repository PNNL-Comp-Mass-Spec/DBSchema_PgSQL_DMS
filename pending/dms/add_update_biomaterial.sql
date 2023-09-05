--
CREATE OR REPLACE PROCEDURE public.add_update_biomaterial
(
    _biomaterialName text,
    _sourceName text,
    _contactUsername text,
    _piUsername text,
    _biomaterialType text,
    _reason text,
    _comment text,
    _campaignName text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _container text = 'na',
    _organismList text,
    _mutation text = '',
    _plasmid text = '',
    _cellLine text = '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing biomaterial items in database
**
**  Arguments:
**    _biomaterialName   Name of biomaterial (or peptide sequence if tracking an MRM peptide)
**    _sourceName        Source that the material came from; can be a person (onsite or offsite) or a company
**    _contactUsername   Contact for the Source; typically PNNL staff, but can be offsite person
**    _piUsername        Project lead
**    _mode              'add', 'update', 'check_add', 'check_update'
**    _organismList      List of one or more organisms to associate with this biomaterial; stored in T_Biomaterial_Organisms; if null, T_Biomaterial_Organisms is unchanged
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _logErrors boolean := false;
    _biomaterialID int := 0;
    _curContainerID int := 0;
    _campaignID int := 0;
    _typeID int := 0;
    _contID int := 0;
    _curContainerName text := '';
    _userID int;
    _matchCount int;
    _newUsername text;
    _idConfirm int := 0;
    _debugMsg text;
    _stateID int := 1;
    _logMessage text;
    _alterEnteredByMessage text;

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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _biomaterialName := Trim(Coalesce(_biomaterialName, ''));
        _sourceName := Trim(Coalesce(_sourceName, ''));
        _contactUsername := Trim(Coalesce(_contactUsername, ''));
        _piUsername := Trim(Coalesce(_piUsername, ''));
        _biomaterialType := Trim(Coalesce(_biomaterialType, ''));
        _reason := Trim(Coalesce(_reason, ''));
        _campaignName := Trim(Coalesce(_campaignName, ''));

        _container := Trim(Coalesce(_container, ''));

        -- Note: leave _organismList null
        -- Procedure Update_Organism_List_For_Biomaterial will leave t_biomaterial_organisms unchanged if _organismList is null

        _mutation := Trim(Coalesce(_mutation, ''));
        _plasmid := Trim(Coalesce(_plasmid, ''));
        _cellLine := Trim(Coalesce(_cellLine, ''));
        _callingUser := Coalesce(_callingUser, '');

        If char_length(_contactUsername) < 1 Then
            RAISE EXCEPTION 'Contact Name must be defined';
        End If;
        --
        If char_length(_piUsername) < 1 Then
            RAISE EXCEPTION 'Principle Investigator Username must be defined';
        End If;
        --
        If char_length(_biomaterialName) < 1 Then
            RAISE EXCEPTION 'Biomaterial Name must be defined';
        End If;
        --
        If char_length(_sourceName) < 1 Then
            RAISE EXCEPTION 'Source Name must be defined';
        End If;
        --
        If char_length(_biomaterialType) < 1 Then
            _returnCode := 'U5201';
            RAISE EXCEPTION 'Biomaterial Type must be defined';
        End If;
        --
        If char_length(_reason) < 1 Then
            RAISE EXCEPTION 'Reason must be defined';
        End If;
        --
        If char_length(_campaignName) < 1 Then
            RAISE EXCEPTION 'Campaign Name must be defined';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT Biomaterial_ID,
               Container_ID
        INTO _biomaterialID, _curContainerID
        FROM t_biomaterial
        WHERE Biomaterial_Name = _biomaterialName;

        -- Cannot create an entry that already exists
        --
        If FOUND And (_mode = 'add' or _mode = 'check_add') Then
            _msg := format('Cannot add: Biomaterial "%s" already in database ', _biomaterialName);
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Cannot update a non-existent entry
        --
        If Not FOUND And (_mode = 'update' or _mode = 'check_update') Then
            _msg := format('Cannot update: Biomaterial "%s" is not in database ', _biomaterialName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve campaign name to ID
        ---------------------------------------------------

        _campaignID := get_campaign_id (_campaignName);

        If _campaignID = 0 Then
            _msg := format('Could not resolve campaign name "%s" to ID"', _campaignName);
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve type name to ID
        ---------------------------------------------------

        --
        SELECT ID
        INTO _typeID
        FROM t_biomaterial_type_name
        WHERE Name = _biomaterialType;

        ---------------------------------------------------
        -- Resolve container name to ID
        ---------------------------------------------------

        --
        If _container = '' Then
            _container := 'na';
        End If;

        SELECT container_id
        INTO _contID
        FROM t_material_containers
        WHERE container = _container;

        ---------------------------------------------------
        -- Resolve current container id to name
        ---------------------------------------------------

        --
        SELECT container
        INTO _curContainerName
        FROM t_material_containers
        WHERE container_id = _curContainerID;

        ---------------------------------------------------
        -- Resolve Usernames to user IDs
        ---------------------------------------------------

        -- Verify that Owner Username  is valid
        -- and get its id number

        _userID := get_user_id (_contactUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _contactUsername contains simply the username
            --
            SELECT username
            INTO _contactUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for Username _contactUsername
            -- Try to auto-resolve the name

            CALL auto_resolve_name_to_username (
                    _contactUsername,
                    _matchCount => _matchCount,         -- Output
                    _matchingUsername => _newUsername,  -- Output
                    _matchingUserID => _userID);        -- Output

            If _matchCount = 1 Then
                -- Single match found; update _contactUsername
                _contactUsername := _newUsername;
            End If;

        End If;

        -- Verify that principal investigator username is valid
        -- and get its id number
        --
        _userID := public.get_user_id (_piUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _piUsername contains simply the username
            --
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

            CALL auto_resolve_name_to_username (
                    _piUsername,
                    _matchCount => _matchCount,         -- Output
                    _matchingUsername => _newUsername,  -- Output
                    _matchingUserID => _userID);        -- Output

            If _matchCount = 1 Then
                -- Single match was found; update _piUsername
                _piUsername := _newUsername;
            Else
                _msg := format('Could not find entry in database for principal investigator username "%s"', _piUsername);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
        -- <add>
            INSERT INTO t_biomaterial (
                biomaterial_name,
                source_name,
                contact_username,
                pi_username,
                biomaterial_type,
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
                _contID,
                _mutation,
                _plasmid,
                _cellLine,
                CURRENT_TIMESTAMP
            )
            RETURNING biomaterial_id
            INTO _biomaterialID;

            -- As a precaution, query T_Biomaterial using Biomaterial name to make sure we have the correct biomaterial ID

            SELECT Biomaterial_ID
            INTO _idConfirm
            FROM t_biomaterial
            WHERE Biomaterial_Name = _biomaterialName;

            If _biomaterialID <> Coalesce(_idConfirm, _biomaterialID) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding biomaterial %s: Found ID %s but the INSERT INTO query reported %s',
                                    _biomaterialName, _idConfirm, _biomaterialID);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Biomaterial');

                _biomaterialID := _idConfirm;
            End If;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                CALL public.alter_event_log_entry_user (2, _biomaterialID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Material movement logging
            --
            If _curContainerID <> _contID Then
                CALL post_material_log_entry
                     'Biomaterial Move',
                     _biomaterialName,
                     'na',
                     _container,
                     _callingUser,
                     'Biomaterial (Cell Culture) added'
            End If;

            If Coalesce(_organismList, '') <> '' Then
                -- Update the associated organism(s)
                CALL public.update_organism_list_for_biomaterial (_biomaterialName, _organismList, _infoOnly => false, _message => _message);
            End If;

        End If; -- </add>

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
        -- <update>
            --
            UPDATE t_biomaterial
            Set
                Source_Name      = _sourceName,
                Contact_Username = _contactUsername,
                PI_Username      = _piUsername,
                Type             = _typeID,
                Reason           = _reason,
                Comment          = _comment,
                Campaign_ID      = _campaignID,
                Container_ID     = _contID,
                Mutation         = _mutation,
                Plasmid          = _plasmid,
                Cell_Line        = _cellLine
            WHERE Biomaterial_Name = _biomaterialName

            If Not FOUND Then
                _msg := format('Update operation failed: "%s"', _biomaterialName);
                RAISE EXCEPTION '%', _msg;
            End If;

            -- Material movement logging
            --
            If _curContainerID <> _contID Then
                CALL post_material_log_entry
                     'Biomaterial Move',
                     _biomaterialName,
                     _curContainerName,
                     _container,
                     _callingUser,
                     'Biomaterial (Cell Culture) updated'
            End If;

            -- Update the associated organism(s)
            _organismList := Coalesce(_organismList, '');
            CALL public.update_organism_list_for_biomaterial (_biomaterialName, _organismList, _infoOnly => false, _message => _message);

        End If; -- </update>

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Biomaterial %s', _exceptionMessage, biomaterialName);

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

COMMENT ON PROCEDURE public.add_update_biomaterial IS 'AddUpdateBiomaterial';

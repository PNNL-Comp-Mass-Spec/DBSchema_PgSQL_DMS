--
-- Name: add_update_reference_compound(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_reference_compound(IN _compoundid integer, IN _compoundname text, IN _description text, IN _compoundtypename text, IN _genename text, IN _modifications text, IN _organismname text, IN _pubchemid text, IN _campaignname text, IN _containername text, IN _wellplatename text, IN _wellnumber text, IN _contactusername text, IN _supplier text, IN _productid text, IN _purchasedate text, IN _purity text, IN _purchasequantity text, IN _mass text, IN _active text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing reference compound
**
**  Arguments:
**    _compoundID           Reference compound ID in t_reference_compound
**    _compoundName         Reference compound name or peptide sequence
**    _description          Description
**    _compoundTypeName     Compound type name: 'Compound', 'Metabolite standards', or 'Protein/peptide standards'
**    _geneName             Gene or Protein name
**    _modifications        Semicolon-separated list of modifications, e.g. 'HeavyK@]' or 'Iodacet@9; Iodacet@10; Iodacet@22; HeavyK@]'
**    _organismName         Organism name
**    _pubChemID            Will be converted to an integer; empty strings are stored as null
**    _campaignName         Campaign name
**    _containerName        Material container name
**    _wellplateName        Wellplate name
**    _wellNumber           Well number
**    _contactUsername      Contact for the source; typically PNNL staff, but can be an offsite person
**    _supplier             Source that the material came from; can be a person (onsite or offsite) or a company
**    _productId            Product ID used by the supplier
**    _purchaseDate         Purchase date (as text)
**    _purity               Purity, e.g. 'Pure', 'Crude', or '90.19%'
**    _purchaseQuantity     Purchase quantity
**    _mass                 Compound mass (as text)
**    _active               Can be: 'Yes', 'No', 'Y', 'N', '1', or '0'; ignored when _mode is 'add'
**    _mode                 Mode: 'add', 'update', 'check_add', 'check_update'
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**
**  Auth:   mem
**  Date:   11/28/2017 mem - Initial version
**          12/19/2017 mem - Add parameters _compoundTypeName, _organismName, _wellplateName, _wellNumber, and _modifications
**          01/03/2018 mem - Add parameter _geneName and move parameter _modifications
**                         - No longer require that _compoundName be unique in T_Reference_Compound
**                         - Allow _description to be empty
**                         - Properly handle float-based dates (resulting from Excel copy / paste-value issues)
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          01/16/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _compoundIdAndName text;
    _pubChemIdValue int;
    _massValue float8;
    _purchaseDateValue timestamp;
    _activeValue int;
    _purchaseDateFloat float8;
    _compoundTypeID int := 0;
    _organismID int := 0;
    _curContainerID int := 0;
    _campaignID int := 0;
    _containerID int := 0;
    _curContainerName text := '';
    _userID int;
    _matchCount int;
    _newUsername text;
    _stateID int := 1;
    _targetType int;
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

        _compoundName     := Trim(Coalesce(_compoundName, ''));
        _description      := Trim(Coalesce(_description, ''));
        _compoundTypeName := Trim(Coalesce(_compoundTypeName, ''));
        _geneName         := Trim(Coalesce(_geneName, ''));
        _modifications    := Trim(Coalesce(_modifications, ''));
        _organismName     := Trim(Coalesce(_organismName, ''));
        _pubChemID        := Trim(Coalesce(_pubChemID, ''));
        _campaignName     := Trim(Coalesce(_campaignName, ''));
        _containerName    := Trim(Coalesce(_containerName, ''));
        _wellplateName    := Trim(Coalesce(_wellplateName, ''));
        _wellNumber       := Trim(Coalesce(_wellNumber, ''));
        _contactUsername  := Trim(Coalesce(_contactUsername, ''));
        _supplier         := Trim(Coalesce(_supplier, ''));
        _productId        := Trim(Coalesce(_productId, ''));
        _purchaseDate     := Trim(Coalesce(_purchaseDate, ''));
        _purity           := Trim(Coalesce(_purity, ''));
        _purchaseQuantity := Trim(Coalesce(_purchaseQuantity, ''));
        _mass             := Trim(Coalesce(_mass, ''));
        _active           := Trim(Coalesce(_active, 'Yes'));
        _callingUser      := Trim(Coalesce(_callingUser, ''));
        _mode             := Trim(Lower(Coalesce(_mode, '')));

        If _compoundID Is Null And Not _mode::citext In ('add', 'check_add') Then
            RAISE EXCEPTION 'Compound ID cannot be null';
        End If;

        If _compoundName = '' Then
            RAISE EXCEPTION 'Compound Name must be specified';
        End If;

        _compoundIdAndName := format('%s: %s', Coalesce(_compoundID, 0), Coalesce(_compoundName, '??'));

        If _compoundTypeName = '' Then
            RAISE EXCEPTION 'Compound type name must be specified';
        End If;

        If _organismName = '' Then
            _organismName := 'None';
        End If;

        If _campaignName = '' Then
            RAISE EXCEPTION 'Campaign Name must be specified';
        End If;

        If _contactUsername = '' Then
            RAISE EXCEPTION 'Contact Name must be specified';
        End If;

        If _supplier = '' Then
            RAISE EXCEPTION 'Supplier must be specified';
        End If;

        If _pubChemID = '' Then
            _pubChemIdValue := null;
        Else
            _pubChemIdValue := public.try_cast(_pubChemID, null::int);
            If _pubChemIdValue Is Null Then
                RAISE EXCEPTION 'Error, PubChemID is not an integer: %', _pubChemID;
            End If;
        End If;

        If _mass = '' Then
            _massValue := 0;
        Else
            _massValue := public.try_cast(_mass, null::float8);

            If _massValue Is Null Then
                RAISE EXCEPTION 'Error, non-numeric mass: %', _mass;
            End If;
        End If;

        If _mode = 'add' Then
            _activeValue := 1;
        ElsIf _active::citext In ('Y', 'Yes', '1') Then
            _activeValue := 1;
        ElsIf _active::citext In ('N', 'No', '0') Then
            _activeValue := 0;
        Else
            RAISE EXCEPTION 'Active should be Y or N';
        End If;

        If _purchaseDate = '' Then
            _purchaseDateValue := null;
        Else
            _purchaseDateValue := public.try_cast(_purchaseDate, null::timestamp);

            If _purchaseDateValue Is Null Then
                _purchaseDateFloat := public.try_cast(_purchaseDate, null::float8);

                If Not _purchaseDateFloat IS NULL Then
                    -- Integer or float based date (likely an Excel conversion artifact)
                    -- Convert to a timestamp (the base date is December 30, 1899 because Excel erroneously assumes that 1900 is a leap year, see https://learn.microsoft.com/en-us/office/troubleshoot/excel/wrongly-assumes-1900-is-leap-year)
                    _purchaseDateValue := DATE('1899-12-30') +
                                          INTERVAL '1 day' * FLOOR(_purchaseDateFloat) +
                                          INTERVAL '1 sec' * (_purchaseDateFloat - FLOOR(_purchaseDateFloat)) * 3600 * 24;
                Else
                    RAISE EXCEPTION 'Error, invalid purchase date: %', _purchaseDate;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve compound type name to ID
        ---------------------------------------------------

        SELECT compound_type_id
        INTO _compoundTypeID
        FROM t_reference_compound_type_name
        WHERE compound_type_name = _compoundTypeName::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid compound type name';
        End If;

        ---------------------------------------------------
        -- Resolve organism name to ID
        ---------------------------------------------------

        _organismID := public.get_organism_id(_organismName);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Invalid organism name: "%" does not exist', _organismName;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode In ('update', 'check_update') Then
            -- Confirm that the compound exists

            If _compoundID Is Null Then
                RAISE EXCEPTION 'Cannot update: reference compound ID cannot be null';
            ElsIf _compoundID <= 0 Then
                RAISE EXCEPTION 'Cannot update: reference compound ID must be a positive integer';
            End If;

            If Not Exists (SELECT compound_id FROM t_reference_compound WHERE compound_id = _compoundID) Then
                RAISE EXCEPTION 'Cannot update: reference compound ID % does not exist', _compoundID;
            End If;

            SELECT container_id
            INTO _curContainerID
            FROM t_reference_compound
            WHERE compound_id = _compoundID;

        End If;

        ---------------------------------------------------
        -- Resolve campaign name to ID
        ---------------------------------------------------

        _campaignID := public.get_campaign_id(_campaignName);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Could not resolve campaign name "%" to ID', _campaignName;
        End If;

        ---------------------------------------------------
        -- Resolve container name to ID
        ---------------------------------------------------

        If _containerName = '' Then
            _containerName := 'na';
        End If;

        SELECT container_id
        INTO _containerID
        FROM t_material_containers
        WHERE container = _containerName::citext;

        ---------------------------------------------------
        -- Resolve current container id to name
        ---------------------------------------------------

        SELECT container
        INTO _curContainerName
        FROM t_material_containers
        WHERE container_id = _curContainerID;

        ---------------------------------------------------
        -- Resolve usernames to user IDs
        ---------------------------------------------------

        -- Verify that Contact Username is valid and resolve its ID

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

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_reference_compound (
                compound_name,
                description,
                compound_type_id,
                gene_name,
                organism_id,
                pub_chem_cid,
                campaign_id,
                container_id,
                wellplate_name,
                well_number,
                contact_username,
                supplier,
                product_id,
                purchase_date,
                purity,
                purchase_quantity,
                mass,
                modifications,
                created,
                active
            ) VALUES (
                _compoundName,
                _description,
                _compoundTypeID,
                _geneName,
                _organismID,
                _pubChemIdValue,
                _campaignID,
                _containerID,
                _wellplateName,
                _wellNumber,
                _contactUsername,
                _supplier,
                _productId,
                _purchaseDateValue,
                _purity,
                _purchaseQuantity,
                _massValue,
                _modifications,
                CURRENT_TIMESTAMP,
                _activeValue
            )
            RETURNING compound_id
            INTO _compoundID;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If _callingUser <> '' Then
                _targetType := 13;
                CALL public.alter_event_log_entry_user ('public', _targetType, _compoundID, _stateID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Material movement logging

            If _curContainerID <> _containerID Then
                CALL public.post_material_log_entry (
                                _type         => 'Reference Compound Move',
                                _item         => _compoundIdAndName,
                                _initialState => 'na',                  -- Initial State: Old container ('na')
                                _finalState   => _containerName,        -- Final State    New container
                                _callingUser  => _callingUser,
                                _comment      => 'Reference Compound added');

            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_reference_compound
            SET compound_name     = _compoundName,
                description       = _description,
                compound_type_id  = _compoundTypeID,
                gene_name         = _geneName,
                organism_id       = _organismID,
                pub_chem_cid      = _pubChemIdValue,
                campaign_id       = _campaignID,
                container_id      = _containerID,
                wellplate_name    = _wellplateName,
                well_number       = _wellNumber,
                contact_username  = _contactUsername,
                supplier          = _supplier,
                product_id        = _productID,
                purchase_date     = _purchaseDateValue,
                purity            = _purity,
                purchase_quantity = _purchaseQuantity,
                mass              = _massValue,
                modifications     = _modifications,
                active            = _activeValue
            WHERE compound_id = _compoundID;

            If Not FOUND Then
                RAISE EXCEPTION 'Update operation failed, ID %', _compoundIdAndName;
            End If;

            -- Material movement logging

            If _curContainerID <> _containerID Then
                CALL public.post_material_log_entry (
                                _type         => 'Reference Compound Move',
                                _item         => _compoundIdAndName,
                                _initialState => _curContainerName,     -- Initial State: Old container
                                _finalState   => _containerName,        -- Final State    New container
                                _callingUser  => _callingUser,
                                _comment      => 'Reference Compound updated');
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; ID %s', _exceptionMessage, compoundIdAndName);

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


ALTER PROCEDURE public.add_update_reference_compound(IN _compoundid integer, IN _compoundname text, IN _description text, IN _compoundtypename text, IN _genename text, IN _modifications text, IN _organismname text, IN _pubchemid text, IN _campaignname text, IN _containername text, IN _wellplatename text, IN _wellnumber text, IN _contactusername text, IN _supplier text, IN _productid text, IN _purchasedate text, IN _purity text, IN _purchasequantity text, IN _mass text, IN _active text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_reference_compound(IN _compoundid integer, IN _compoundname text, IN _description text, IN _compoundtypename text, IN _genename text, IN _modifications text, IN _organismname text, IN _pubchemid text, IN _campaignname text, IN _containername text, IN _wellplatename text, IN _wellnumber text, IN _contactusername text, IN _supplier text, IN _productid text, IN _purchasedate text, IN _purity text, IN _purchasequantity text, IN _mass text, IN _active text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_reference_compound(IN _compoundid integer, IN _compoundname text, IN _description text, IN _compoundtypename text, IN _genename text, IN _modifications text, IN _organismname text, IN _pubchemid text, IN _campaignname text, IN _containername text, IN _wellplatename text, IN _wellnumber text, IN _contactusername text, IN _supplier text, IN _productid text, IN _purchasedate text, IN _purity text, IN _purchasequantity text, IN _mass text, IN _active text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateReferenceCompound';


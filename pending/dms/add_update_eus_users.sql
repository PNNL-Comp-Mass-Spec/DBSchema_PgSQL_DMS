--
CREATE OR REPLACE PROCEDURE public.add_update_eus_users
(
    _eusPersonID text,
    _eusNameFm text,
    _eusSiteStatus text,
    _hanfordID text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing EUS Users
**
**  Arguments:
**    _eusPersonID      EUS Proposal ID
**    _eusNameFm        EUS Proposal State
**    _eusSiteStatus    EUS Proposal Title
**    _hanfordID        Hanford ID
**    _mode             Mode: add' or 'update'
**    _message          Output message
**    _returnCode       Return code
**
**  Auth:   jds
**  Date:   09/01/2006
**          03/19/2012 mem - Added _hanfordID
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingCount int := 0;
    _msg text;
    _tempEUSPersonID int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If char_length(_eusPersonID) < 1 Then
        _returnCode := 'U5201';
        _message := 'EUS Person ID must be specified';
        RAISE EXCEPTION '%', _message;
    End If;

    If char_length(_eusNameFm) < 1 Then
        _returnCode := 'U5202';
        RAISE EXCEPTION 'EUS Person''s Name must be specified';
    End If;

    If char_length(_eusSiteStatus) < 1 Then
        _returnCode := 'U5203';
        RAISE EXCEPTION 'EUS Site Status must be specified';
    End If;

    If char_length(Coalesce(_hanfordID, '')) = 0 Then
        _hanfordID := Null;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT person_id
    INTO _tempEUSPersonID
    FROM t_eus_users
    WHERE person_id = _eusPersonID;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    -- Cannot create an entry that already exists
    --
    If _mode = 'add' And _existingCount > 0 Then
        _msg := format('Cannot add: EUS Person ID "%s" is already in the database ', _eusPersonID);
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    -- Cannot update a non-existent entry
    --
    If _mode = 'update' And _existingCount = 0 Then
        _msg := format('Cannot update: EUS Person ID "%s" is not in the database ', _eusPersonID);
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_eus_users (
            person_id,
            name_fm,
            site_status_id,
            hid,
            last_affected
        ) VALUES (
            _eusPersonID,
            _eusNameFm,
            _eusSiteStatus,
            _hanfordID,
            CURRENT_TIMESTAMP
        )

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE  t_eus_users
        SET
            name_fm = _eusNameFm,
            site_status_id =  _eusSiteStatus,
            hid = _hanfordID,
            last_affected = CURRENT_TIMESTAMP
        WHERE (person_id = _eusPersonID)

    End If; -- update mode

END
$$;

COMMENT ON PROCEDURE public.add_update_eus_users IS 'AddUpdateEUSUsers';

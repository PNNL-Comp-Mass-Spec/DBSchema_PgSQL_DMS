--
-- Name: add_update_eus_users(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_eus_users(IN _euspersonid text, IN _eusnamefm text, IN _eussitestatus text, IN _hanfordid text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or update an existing EUS user
**
**  Arguments:
**    _eusPersonID      EUS person ID (integer, as text)
**    _eusNameFm        Person's name, in the form "LastName, FirstName"
**    _eusSiteStatus    EUS site status ID: 0 for 'Undefined', 1 for 'ONSITE', 2 for 'REMOTE_OTHER' (see table t_eus_site_status)
**    _hanfordID        Hanford ID
**    _mode             Mode: add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   jds
**  Date:   09/01/2006
**          03/19/2012 mem - Added _hanfordID
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _eusPersonIdValue int;
    _eusSiteStatusValue smallint;
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

    _eusPersonID   := Trim(Coalesce(_eusPersonID, ''));
    _eusNameFm     := Trim(Coalesce(_eusNameFm, ''));
    _eusSiteStatus := Trim(Coalesce(_eusSiteStatus, ''));
    _hanfordID     := Trim(Coalesce(_hanfordID, ''));
    _mode          := Trim(Lower(Coalesce(_mode, '')));

    If _eusPersonID = '' Then
        _returnCode := 'U5201';
        _message := 'EUS Person ID must be specified';
        RAISE EXCEPTION '%', _message;
    End If;

    _eusPersonIdValue := public.try_cast(_eusPersonID, null::int);

    If _eusPersonIdValue Is Null Then
        _returnCode := 'U5202';
        _message := 'EUS person ID must be an integer';
        RAISE EXCEPTION '%', _message;
    End If;

    If _eusNameFm = '' Then
        _returnCode := 'U5203';
        RAISE EXCEPTION 'EUS person''s name must be specified';
    End If;

    If _eusSiteStatus = '' Then
        _returnCode := 'U5204';
        RAISE EXCEPTION 'EUS site status must be specified';
    End If;

    _eusSiteStatusValue := public.try_cast(_eusSiteStatus, null::smallint);

    If _eusSiteStatusValue Is Null Then
        _returnCode := 'U5202';
        _message := 'EUS site status must be an integer';
        RAISE EXCEPTION '%', _message;
    End If;

    If _hanfordID = '' Then
        _hanfordID := Null;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT person_id
    INTO _tempEUSPersonID
    FROM t_eus_users
    WHERE person_id = _eusPersonIdValue;
    --
    GET DIAGNOSTICS _existingCount = ROW_COUNT;

    -- Cannot create an entry that already exists

    If _mode = 'add' And _existingCount > 0 Then
        _msg := format('Cannot add: EUS Person ID "%s" already exists', _eusPersonID);
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    -- Cannot update a non-existent entry

    If _mode = 'update' And _existingCount = 0 Then
        _msg := format('Cannot update: EUS Person ID "%s" does not exist', _eusPersonID);
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5206';
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
            _eusPersonIdValue,
            _eusNameFm,
            _eusSiteStatusValue,
            _hanfordID,
            CURRENT_TIMESTAMP
        );

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_eus_users
        SET name_fm        = _eusNameFm,
            site_status_id =  _eusSiteStatusValue,
            hid            = _hanfordID,
            last_affected  = CURRENT_TIMESTAMP
        WHERE person_id = _eusPersonIdValue;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_eus_users(IN _euspersonid text, IN _eusnamefm text, IN _eussitestatus text, IN _hanfordid text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_eus_users(IN _euspersonid text, IN _eusnamefm text, IN _eussitestatus text, IN _hanfordid text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_eus_users(IN _euspersonid text, IN _eusnamefm text, IN _eussitestatus text, IN _hanfordid text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateEUSUsers';


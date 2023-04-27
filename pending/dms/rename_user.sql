--
CREATE OR REPLACE PROCEDURE public.rename_user
(
    _oldUserName text = '',
    _newUserName text = '',
    INOUT _message text = '',
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Renames a user in T_Users and other tracking tables
**
**  Auth:   10/31/2014 mem - Initial version
**  Date:   06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
BEGIN
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

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------
    --
    _oldUserName := Coalesce(_oldUserName, '');
    _newUserName := Coalesce(_newUserName, '');

    If _oldUserName = '' Then
        _message := '_oldUserName is empty; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _newUserName = '' Then
        _message := '_newUserName is empty; unable to continue';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _oldUserName = _newUserName Then
        _message := 'Usernames are identical; nothing to do';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    --------------------------------------------
    -- Examine t_users
    --------------------------------------------
    --
    If Not Exists (Select * From t_users Where username = _oldUserName) Then
        _message := 'User ' || _oldUserName || ' does not exist in t_users; nothing to do';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Exists (Select * From t_users Where username = _newUserName) Then
        _message := 'Cannot rename ' || _oldUserName || ' to ' || _newUserName || ' because the new username already exists in t_users';

        If Substring(_oldUserName, 1, char_length(_newUserName)) = _newUserName Then
            _message := _message || '. Will check for required renames in other tables';
            RAISE INFO '%', _message;
        Else
            _message := _message || '. The new username is too different than the old username; aborting';

            RAISE WARNING '%', _message;
            RETURN;
        End If;
    Else

        If _infoOnly Then
            RAISE INFO 'Preview of rename from % to %', _oldUserName, _newUserName;

            -- ToDo: Update this to use RAISEINFO

            SELECT *
            FROM t_users
            WHERE username IN (_oldUserName, _newUserName)
        Else
            RAISE INFO 'Renaming % to %', _oldUserName, _newUserName;

            UPDATE t_users
            SET username = _newUserName
            WHERE username = _oldUserName;
        End If;

    End If;

    If _infoOnly Then

        -- ToDo: Update these SELECT queries to use RAISE INFO

        SELECT *
        FROM t_dataset
        WHERE operator_username IN (_oldUserName, _newUserName);

        SELECT *
        FROM t_experiments
        WHERE researcher_username IN (_oldUserName, _newUserName);

        SELECT *
        FROM t_requested_run
        WHERE requester_username IN (_oldUserName, _newUserName);

        SELECT *
        FROM dpkg.T_Data_Package
        WHERE Owner IN (_oldUserName, _newUserName);

        SELECT *
        FROM dpkg.T_Data_Package
        WHERE Requester IN (_oldUserName, _newUserName);

    Else

        UPDATE t_dataset
        SET operator_username = _newUserName
        WHERE operator_username = _oldUserName;

        UPDATE t_experiments
        SET researcher_username = _newUserName
        WHERE researcher_username = _oldUserName;

        UPDATE t_requested_run
        SET requester_username = _newUserName
        WHERE requester_username = _oldUserName;

        UPDATE dpkg.T_Data_Package
        SET Owner = _newUserName
        WHERE Owner = _oldUserName;

        UPDATE dpkg.T_Data_Package
        SET Requester = _newUserName
        WHERE Requester = _oldUserName;

    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.rename_user IS 'RenameUser';

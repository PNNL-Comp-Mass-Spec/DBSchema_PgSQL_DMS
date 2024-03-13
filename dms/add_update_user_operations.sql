--
-- Name: add_update_user_operations(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_user_operations(IN _userid integer, IN _operationslist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the access permissions (user operations) defined for the given user
**
**  Arguments:
**    _userID           User ID
**    _operationsList   Comma-separated list of access permissions (aka operation names); see table t_user_operations
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/21/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _userID         := Coalesce(_userID, 0);
    _operationsList := Coalesce(_operationsList, '');

    If _userID <= 0 Then
        RAISE EXCEPTION 'User ID should be a positive integer';
    End If;

    ---------------------------------------------------
    -- Add/update operations defined for user
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UserOperations (
        User_Operation text
    );

    ---------------------------------------------------
    -- When populating Tmp_UserOperations, ignore any user operations that
    -- do not exist in t_user_operations
    ---------------------------------------------------

    INSERT INTO Tmp_UserOperations (User_Operation)
    SELECT value
    FROM public.parse_delimited_list(_operationsList)
    WHERE value::citext IN ( SELECT Operation FROM t_user_operations );

    ---------------------------------------------------
    -- Add missing associations between operations and user
    ---------------------------------------------------

    INSERT INTO t_user_operations_permissions (user_id, operation_id)
    SELECT _userID, UO.operation_id
    FROM Tmp_UserOperations NewOps
         INNER JOIN t_user_operations UO
           ON NewOps.User_Operation = UO.operation
         LEFT OUTER JOIN t_user_operations_permissions UOP
           ON UOP.user_id = _userID AND
              UO.operation_id = UOP.operation_id
    WHERE UOP.user_id IS NULL;

    ---------------------------------------------------
    -- Remove extra associations
    ---------------------------------------------------

    DELETE FROM t_user_operations_permissions UOP
    WHERE UOP.user_id = _userID AND
          NOT EXISTS ( SELECT UO.operation_id
                       FROM Tmp_UserOperations NewOps
                            INNER JOIN t_user_operations UO
                              ON NewOps.User_Operation = UO.operation
                       WHERE UOP.operation_id = UO.operation_id);

    DROP TABLE Tmp_UserOperations;
END
$$;


ALTER PROCEDURE public.add_update_user_operations(IN _userid integer, IN _operationslist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_user_operations(IN _userid integer, IN _operationslist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_user_operations(IN _userid integer, IN _operationslist text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateUserOperations';


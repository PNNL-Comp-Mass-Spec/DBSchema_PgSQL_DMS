--
CREATE OR REPLACE PROCEDURE public.add_update_user_operations
(
    _userID int,
    _operationsList text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the user operations defined for the given user
**
**  Arguments:
**    _operationsList   Comma separated separated list of operation names (see table T_User_Operations)
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
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

    ---------------------------------------------------
    -- Add/update operations defined for user
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UserOperations (
        User_Operation text
    )

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- When populating Tmp_UserOperations, ignore any user operations that
    -- do not exist in t_user_operations
    ---------------------------------------------------

    INSERT INTO Tmp_UserOperations( User_Operation )
    SELECT CAST(Item AS text) AS DMS_User_Operation
    FROM public.parse_delimited_list ( _operationsList )
    WHERE CAST(Item AS text) IN ( SELECT Operation
                                  FROM t_user_operations )

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Add missing associations between operations and user
    ---------------------------------------------------
    --
    INSERT INTO t_user_operations_permissions( user_id, operation_id )
    SELECT _userID, UO.operation_id
    FROM Tmp_UserOperations NewOps
         INNER JOIN t_user_operations UO
           ON NewOps.User_Operation = UO.operation
         LEFT OUTER JOIN t_user_operations_permissions UOP
           ON UOP.user_id = _userID AND
              UO.operation_id = UOP.operation_id
    WHERE UOP.user_id IS NULL

    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Remove extra associations
    ---------------------------------------------------
    --
    DELETE FROM t_user_operations_permissions
    WHERE UOP.user_id = _userID AND
          NOT EXISTS ( SELECT UO.operation_id
                       FROM Tmp_UserOperations NewOps
                            INNER JOIN t_user_operations UO
                              ON NewOps.User_Operation = UO.operation
                       WHERE t_user_operations_permissions.operation_id = UO.operation_id);

    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    DROP TABLE Tmp_UserOperations;
END
$$;

COMMENT ON PROCEDURE public.add_update_user_operations IS 'AddUpdateUserOperations';
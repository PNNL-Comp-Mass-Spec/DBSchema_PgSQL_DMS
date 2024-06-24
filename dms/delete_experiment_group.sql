--
-- Name: delete_experiment_group(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_experiment_group(IN _groupid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete the given experiment group (but not any associated experiments)
**
**  Arguments:
**    _groupID      Experiment group ID
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   07/13/2006
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/02/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _delim text := ',';
    _count int;
    _msg text;
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

    ---------------------------------------------------
    -- Does the experiment group exist?
    ---------------------------------------------------

    _groupID := Coalesce(_groupID, 0);

    If Not Exists (SELECT group_id FROM t_experiment_groups WHERE group_id = _groupID) Then
        _message := format('Could not find experiment group %s', _groupID);
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete the items
    ---------------------------------------------------

    DELETE FROM t_experiment_group_members
    WHERE group_id = _groupID;

    DELETE FROM t_experiment_groups
    WHERE group_id = _groupID;

    RAISE INFO '';
    RAISE INFO 'Deleted experiment group %', _groupID;
END
$$;


ALTER PROCEDURE public.delete_experiment_group(IN _groupid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_experiment_group(IN _groupid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_experiment_group(IN _groupid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteExperimentGroup';


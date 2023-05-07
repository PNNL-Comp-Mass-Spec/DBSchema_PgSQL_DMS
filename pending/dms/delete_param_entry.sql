--
CREATE OR REPLACE PROCEDURE public.delete_param_entry
(
    _paramFileID int,
    _entrySeqOrder int,
    _entryType text,
    _entrySpecifier text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given Sequest Param Entry from the T_Param_Entries
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _paramEntryID int;
    _result int;
    _transName text;
BEGIN
    _message := '';
    _returnCode:= '';

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
    -- Get ParamFileID
    ---------------------------------------------------

    _paramEntryID := get_param_entry_id(_paramFileID, _entryType, _entrySpecifier, _entrySeqOrder);

    ---------------------------------------------------
    -- Delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    DELETE FROM t_param_entries
    WHERE param_entry_id = _paramEntryID;

END
$$;

COMMENT ON PROCEDURE public.delete_param_entry IS 'DeleteParamEntry';

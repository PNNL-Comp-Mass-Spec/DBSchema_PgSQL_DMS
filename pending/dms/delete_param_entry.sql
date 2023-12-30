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
**      Delete a row from t_param_entries for a given parameter file ID and entry details
**
**      This only applies to SEQUEST parameter files, and is likely only used
**      by the SEQUEST Parameter File Editor, which is obsolete
**
**  Arguments:
**    _paramFileID      Parameter file ID
**    _entrySeqOrder    Entry sequence order
**    _entryType        Entry type
**    _entrySpecifier   Entry specifier name
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2024 mem - Ported to PostgreSQL
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
    -- Delete the matching row
    ---------------------------------------------------

    DELETE FROM t_param_entries
    WHERE param_file_id = _paramFileID AND
          entry_type = _entryType::citext AND
          entry_specifier = _entrySpecifier::citext AND
          entry_sequence_order = _entrySeqOrder;

END
$$;

COMMENT ON PROCEDURE public.delete_param_entry IS 'DeleteParamEntry';

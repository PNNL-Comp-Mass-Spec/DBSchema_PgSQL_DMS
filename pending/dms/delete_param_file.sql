--
CREATE OR REPLACE PROCEDURE public.delete_param_file
(
    _paramFileName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes given Sequest Param file from the T_Param_Files
**      and all referencing tables
**
**  Auth:   kja
**  Date:   07/22/2004 mem
**          02/12/2010 mem - Now updating _message when the parameter file is successfully deleted
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _paramFileID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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
    -- Get ParamFileID
    ---------------------------------------------------

    SELECT param_file_id
    INTO _paramFileID
    FROM t_param_files
    WHERE param_file_name = _paramFileName;

    If Not FOUND Then
        _message := format('Param file not found in t_param_files: %s', _paramFileName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    CALL delete_param_file_by_id (_paramFileID,
                                  _message => _message,     -- Output
                                  _returnCode => _returnCode);

    If _returnCode = '' Then
        _message := format('Deleted parameter file %s', _paramFileName);
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.delete_param_file IS 'DeleteParamFile';

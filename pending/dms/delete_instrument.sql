--
CREATE OR REPLACE PROCEDURE public.delete_instrument
(
    _instrumentName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Delete the specified instrument and associated storage path entries
**      Only allowed if no datasets exist for the instrument
**
**  Auth:   mem
**  Date:   02/12/2010
**          08/28/2010 mem - No longer deleting entries in the Instrument_Allowed_Dataset_Type table
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetCount int;
    _instrumentID int;
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
    -- Look up instrument ID for _instrumentName
    ---------------------------------------------------

    SELECT instrument_id
    INTO _instrumentID
    FROM t_instrument_name
    WHERE instrument = _instrumentName;

    If Not FOUND Then
        _message := format('instrument not found in t_instrument_name: %s', _instrumentName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure no datasets exist yet for this instrument
    ---------------------------------------------------

    SELECT COUNT(dataset_id)
    INTO _existingCount
    FROM t_dataset
    WHERE instrument_id = _instrumentID;

    If _datasetCount > 0 Then
        _message := format('Instrument %s has %s %s in t_dataset; deletion is not allowed', _instrumentName, _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets'));
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    -- Delete archive path entry
    DELETE FROM t_archive_path
    WHERE instrument_id = _instrumentID;

    -- Delete archive path entries
    DELETE FROM t_storage_path
    WHERE instrument = _instrumentName;

    -- Delete instrument
    DELETE FROM t_instrument_name
    WHERE instrument_id = _instrumentID;

    _message := format('Deleted instrument: %s', _instrumentName);
    RAISE INFO '%', _message;

END
$$;

COMMENT ON PROCEDURE public.delete_instrument IS 'DeleteInstrument';

--
CREATE OR REPLACE PROCEDURE public.update_instrument_group_allowed_dataset_type
(
    _instrumentGroup text,
    _datasetType text,
    _comment text,
    _mode text = 'add',
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds, updates, or deletes allowed datset type for given instrument group
**
**  Arguments:
**    _mode   'add' or 'update' or 'delete'
**
**  Auth:   grk
**  Date:   09/19/2009 grk - Initial release (Ticket #749, http://prismtrac.pnl.gov/trac/ticket/749)
**          02/12/2010 mem - Now making sure _datasetType is properly capitalized
**          08/28/2010 mem - Updated to work with instrument groups
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
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
    _msg text;
    _validMode boolean := false;
    _exists text;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Validate InstrumentGroup and DatasetType
        ---------------------------------------------------
        --
        If NOT EXISTS ( SELECT * FROM t_instrument_group WHERE instrument_group = _instrumentGroup ) Then
            RAISE EXCEPTION 'Instrument group "%" is not valid', _instrumentGroup;
        End If;

        If NOT EXISTS ( SELECT * FROM t_dataset_rating_name WHERE Dataset_Type = _datasetType ) Then
            RAISE EXCEPTION 'Dataset type "%" is not valid', _datasetType;
        End If;

        ---------------------------------------------------
        -- Make sure _datasetType is properly capitalized
        ---------------------------------------------------

        SELECT Dataset_Type INTO _datasetType
        FROM t_dataset_rating_name
        WHERE Dataset_Type = _datasetType

        ---------------------------------------------------
        -- Does an entry already exist?
        ---------------------------------------------------
        --
        SELECT instrument_group
        INTO _exists
        FROM t_instrument_group_allowed_ds_type
        WHERE instrument_group = _instrumentGroup AND
              dataset_type = _datasetType;

        ---------------------------------------------------
        -- Add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then
        --<add>
            If _exists <> '' Then
                _msg := 'Cannot add: Entry "' || _datasetType || '" already exists for group ' || _instrumentGroup;
                RAISE EXCEPTION '%', _msg;
            End If;

            INSERT INTO t_instrument_group_allowed_ds_type ( instrument_group,
                                                             dataset_type,
                                                             comment)
            VALUES(_instrumentGroup, _datasetType, _comment)

            _validMode := true;
        End If; --<add>

        ---------------------------------------------------
        -- Update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then
        --<update>
            If _exists = '' Then
                _msg := 'Cannot Update: Entry "' || _datasetType || '" does not exist for group ' || _instrumentGroup;
                RAISE EXCEPTION '%', _msg;
            End If;

            UPDATE t_instrument_group_allowed_ds_type
            SET comment = _comment
            WHERE (instrument_group = _instrumentGroup) AND
                  (dataset_type = _datasetType)

            _validMode := true;
        End If; --<update>

        ---------------------------------------------------
        -- Delete mode
        ---------------------------------------------------
        --
        If _mode = 'delete' Then
        --<delete>
            If _exists = '' Then
                _msg := 'Cannot Delete: Entry "' || _datasetType || '" does not exist for group ' || _instrumentGroup;
                RAISE EXCEPTION '%', _msg;
            End If;

            DELETE FROM t_instrument_group_allowed_ds_type
            WHERE (instrument_group = _instrumentGroup) AND
                  (dataset_type = _datasetType)

            _validMode := true;
        End If; --<delete>

        If Not _validMode Then
            ---------------------------------------------------
            -- Unrecognized mode
            ---------------------------------------------------

            _msg := 'Unrecognized Mode:' || _mode;
            RAISE EXCEPTION '%', _msg;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Instrument group: ' || _instrumentGroup;
    Call post_usage_log_entry ('UpdateInstrumentGroupAllowedDatasetType', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_instrument_group_allowed_dataset_type IS 'UpdateInstrumentGroupAllowedDatasetType';

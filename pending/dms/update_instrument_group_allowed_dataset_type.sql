--
CREATE OR REPLACE PROCEDURE public.update_instrument_group_allowed_dataset_type
(
    _instrumentGroup text,
    _datasetType text,
    _comment text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds, updates, or deletes allowed dataset type for given instrument group
**
**  Arguments:
**    _instrumentGroup  Instrument group name
**    _datasetType      Dataset type name
**    _comment          Comment
**    _mode             Mode: 'add' or 'update' or 'delete'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   09/19/2009 grk - Initial version (Ticket #749, http://prismtrac.pnl.gov/trac/ticket/749)
**          02/12/2010 mem - Now making sure _datasetType is properly capitalized
**          08/28/2010 mem - Updated to work with instrument groups
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
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

    _validMode boolean := false;
    _itemExists text;
    _usageMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Validate InstrumentGroup and DatasetType
        ---------------------------------------------------

        If Not Exists ( SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroup::citext ) Then
            RAISE EXCEPTION 'Instrument group "%" is not valid', _instrumentGroup;
        End If;

        If Not Exists ( SELECT dataset_type FROM t_dataset_type_name WHERE dataset_type = _datasetType::citext ) Then
            RAISE EXCEPTION 'Dataset type "%" is not valid', _datasetType;
        End If;

        ---------------------------------------------------
        -- Make sure _datasetType is properly capitalized
        ---------------------------------------------------

        SELECT Dataset_Type
        INTO _datasetType
        FROM t_dataset_type_name
        WHERE Dataset_Type = _datasetType::citext;

        ---------------------------------------------------
        -- Does an entry already exist?
        ---------------------------------------------------

        If Exists (SELECT instrument_group
                   FROM t_instrument_group_allowed_ds_type
                   WHERE instrument_group = _instrumentGroup::citext AND
                         dataset_type = _datasetType::citext)
        Then
            _itemExists := true;
        Else
            _itemExists := false;
        End If;

        ---------------------------------------------------
        -- Add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            If _itemExists Then
                RAISE EXCEPTION 'Cannot add: Entry "%" already exists for group %', _datasetType, _instrumentGroup;
            End If;

            INSERT INTO t_instrument_group_allowed_ds_type ( instrument_group,
                                                             dataset_type,
                                                             comment)
            VALUES(_instrumentGroup, _datasetType, _comment);

            _validMode := true;
        End If;

        ---------------------------------------------------
        -- Update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            If Not _itemExists Then
                RAISE EXCEPTION 'Cannot Update: Entry "%" does not exist for group %', _datasetType, _instrumentGroup;
            End If;

            UPDATE t_instrument_group_allowed_ds_type
            SET comment = _comment
            WHERE instrument_group = _instrumentGroup::citext AND
                  dataset_type = _datasetType::citext;

            _validMode := true;
        End If;

        ---------------------------------------------------
        -- Delete mode
        ---------------------------------------------------

        If _mode = 'delete' Then
            If Not _itemExists Then
                RAISE EXCEPTION 'Cannot Delete: Entry "%" does not exist for group %' _datasetType, _instrumentGroup;
            End If;

            DELETE FROM t_instrument_group_allowed_ds_type
            WHERE instrument_group = _instrumentGroup::citext AND
                  dataset_type = _datasetType::citext

            _validMode := true;
        End If;

        If Not _validMode Then
            ---------------------------------------------------
            -- Unrecognized mode
            ---------------------------------------------------

            RAISE EXCEPTION 'Unrecognized Mode: %', _mode;
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

    _usageMessage := format('Instrument group: %s', _instrumentGroup);
    CALL post_usage_log_entry ('update_instrument_group_allowed_dataset_type', _usageMessage);

END
$$;

COMMENT ON PROCEDURE public.update_instrument_group_allowed_dataset_type IS 'UpdateInstrumentGroupAllowedDatasetType';

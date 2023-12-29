--
CREATE OR REPLACE PROCEDURE public.add_update_instrument_group
(
    _instrumentGroup text,
    _usage text,
    _comment text,
    _active int,
    _samplePrepVisible int,
    _requestedRunVisible int,
    _allocationTag text,
    _defaultDatasetTypeName text,
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
**      Add new or edit an existing instrument group
**
**  Arguments:
**    _instrumentGroup          Instrument group name
**    _usage                    Instrument group usage, e.g. 'Metabolomics', 'MRM', or 'Research'
**    _comment                  Group comment
**    _active                   1 if active, 0 if inactive
**    _samplePrepVisible        1 if should be included in the sample prep instrument group pick list (samplePrepInstrumentGroupPickList), otherwise 0;     see https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/public/model_config/DMS_DB_Sql/dms_chooser.sql#L74
**    _requestedRunVisible      1 if should be included in the requested run instrument group pick list (requestedRunInstrumentGroupPickList), otherwise 0; see https://github.com/PNNL-Comp-Mass-Spec/DMS-Website/blob/master/public/model_config/DMS_DB_Sql/dms_chooser.sql#L75
**    _allocationTag            Allocation tag, e.g. 'GC', 'FT', 'ORB', or 'QQQ'
**    _defaultDatasetTypeName   Default dataset type name; empty string if no default
**    _mode                     Mode: 'add' or 'update'
**    _message                  Output message
**    _returnCode               Return code
**    _callingUser              Calling user username
**
**  Auth:   grk
**  Date:   08/28/2010 grk - Initial version
**          08/30/2010 mem - Added parameters _usage and _comment
**          09/02/2010 mem - Added parameter _defaultDatasetType
**          10/18/2012 mem - Added parameter _allocationTag
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/12/2017 mem - Added parameter _samplePrepVisible
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/18/2021 mem - Added parameter _requestedRunVisible
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _datasetTypeID int;

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

        _comment                := Trim(Coalesce(_comment, ''));
        _active                 := Coalesce(_active, 0);
        _samplePrepVisible      := Coalesce(_samplePrepVisible, 0);
        _requestedRunVisible    := Coalesce(_requestedRunVisible, 0);
        _defaultDatasetTypeName := Trim(Coalesce(_defaultDatasetTypeName, ''));
        _mode                   := Trim(Lower(Coalesce(_mode, '')));

        If _defaultDatasetTypeName <> '' Then
            _datasetTypeID := public.get_dataset_type_id(_defaultDatasetTypeName);
        Else
            _datasetTypeID := 0;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            If Not Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroup) Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_instrument_group( instrument_group,
                                            usage,
                                            comment,
                                            active,
                                            sample_prep_visible,
                                            requested_run_visible,
                                            allocation_tag,
                                            default_dataset_type )
            VALUES (_instrumentGroup, _usage, _comment,
                    _active, _samplePrepVisible, _requestedRunVisible,
                    _allocationTag,
                    CASE
                        WHEN _datasetTypeID > 0 THEN _datasetTypeID
                        ELSE NULL
                    END);

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_instrument_group
            SET usage = _usage,
                comment = _comment,
                active = _active,
                sample_prep_visible = _samplePrepVisible,
                requested_run_visible = _requestedRunVisible,
                allocation_tag = _allocationTag,
                default_dataset_type = CASE WHEN _datasetTypeID > 0 Then _datasetTypeID Else Null End
            WHERE instrument_group = _instrumentGrou;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('%s; Instrument group %s', _exceptionMessage, _instrumentGroup);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.add_update_instrument_group IS 'AddUpdateInstrumentGroup';

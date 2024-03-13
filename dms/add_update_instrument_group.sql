--
-- Name: add_update_instrument_group(text, text, text, integer, integer, integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument_group(IN _instrumentgroup text, IN _usage text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _requestedrunvisible integer, IN _allocationtag text, IN _defaultdatasettypename text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
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
**    _allocationTag            Allocation tag, e.g. 'GC', 'FT', 'ORB', or 'QQQ'; will store Null if this is an empty string
**    _defaultDatasetTypeName   Default dataset type name; empty string if no default
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user (unused by this procedure)
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
**          01/12/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _datasetTypeID int;
    _validatedName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _instrumentGroup        := Trim(Coalesce(_instrumentGroup, ''));
        _usage                  := Trim(Coalesce(_usage, ''));
        _comment                := Trim(Coalesce(_comment, ''));
        _active                 := Coalesce(_active, 0);
        _samplePrepVisible      := Coalesce(_samplePrepVisible, 0);
        _requestedRunVisible    := Coalesce(_requestedRunVisible, 0);
        _defaultDatasetTypeName := Trim(Coalesce(_defaultDatasetTypeName, ''));
        _mode                   := Trim(Lower(Coalesce(_mode, '')));

        If _instrumentGroup = '' Then
            RAISE EXCEPTION 'Instrument group name must be specified';
        End If;

        If _usage = '' Then
            RAISE EXCEPTION 'Usage type must be specified';
        End If;

        If _defaultDatasetTypeName <> '' Then
            _datasetTypeID := public.get_dataset_type_id(_defaultDatasetTypeName);
        Else
            _datasetTypeID := 0;
        End If;

        If Trim(Coalesce(_allocationTag, '')) = '' Then
            _allocationTag = null;
        Else
            -- Validate the allocation tag (and capitalize if necessary)
            SELECT allocation_tag
            INTO _validatedName
            FROM t_instrument_group_allocation_tag
            WHERE allocation_tag = _allocationTag::citext;

            If Not Found Then
                RAISE EXCEPTION 'Unrecognized allocation tag: %', _allocationTag;
            End If;

            _allocationTag := _validatedName;
        End If;

        ---------------------------------------------------
        -- Is entry already in database? (only applies to updates)
        ---------------------------------------------------

        If _mode = 'add' And Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroup::citext) Then
            RAISE EXCEPTION 'Cannot add: instrument group "%" already exists', _instrumentGroup;
        End If;

        If _mode = 'update' Then
            If Not Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroup::citext) Then
                RAISE EXCEPTION 'Cannot update: instrument group "%" does not exist', _instrumentGroup;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_instrument_group (
                instrument_group,
                usage,
                comment,
                active,
                sample_prep_visible,
                requested_run_visible,
                allocation_tag,
                default_dataset_type
            ) VALUES (
                _instrumentGroup,
                _usage,
                _comment,
                _active,
                _samplePrepVisible,
                _requestedRunVisible,
                _allocationTag,
                CASE WHEN _datasetTypeID > 0 THEN _datasetTypeID
                     ELSE NULL
                END
            );

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_instrument_group
            SET usage                 = _usage,
                comment               = _comment,
                active                = _active,
                sample_prep_visible   = _samplePrepVisible,
                requested_run_visible = _requestedRunVisible,
                allocation_tag        = _allocationTag,
                default_dataset_type  = CASE WHEN _datasetTypeID > 0 THEN _datasetTypeID
                                             ELSE Null
                                        END
            WHERE instrument_group = _instrumentGroup::citext;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _instrumentGroup Is Null Then
            _logMessage := _exceptionMessage;
        Else
            _logMessage := format('%s; Instrument group %s', _exceptionMessage, _instrumentGroup);
        End If;

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_instrument_group(IN _instrumentgroup text, IN _usage text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _requestedrunvisible integer, IN _allocationtag text, IN _defaultdatasettypename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument_group(IN _instrumentgroup text, IN _usage text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _requestedrunvisible integer, IN _allocationtag text, IN _defaultdatasettypename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument_group(IN _instrumentgroup text, IN _usage text, IN _comment text, IN _active integer, IN _sampleprepvisible integer, IN _requestedrunvisible integer, IN _allocationtag text, IN _defaultdatasettypename text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateInstrumentGroup';


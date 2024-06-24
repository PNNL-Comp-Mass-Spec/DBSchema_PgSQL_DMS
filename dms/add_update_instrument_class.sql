--
-- Name: add_update_instrument_class(text, integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_instrument_class(IN _instrumentclass text, IN _ispurgeable integer, IN _rawdatatype text, IN _params text, IN _comment text, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update an existing instrument class
**      (despite the procedure name, only updates are allowed)
**
**  Arguments:
**    _instrumentClass  Instrument class name
**    _isPurgeable      1 if datasets can be purged for this instrument class, 0 if purging is disabled
**    _rawDataType      Instrument data type; see table t_instrument_data_type_name
**    _params           XML parameters with DatasetQC options (see below)
**    _comment          Instrument class comment
**    _mode             The only valid mode is 'update', since 'add' is not allowed in this procedure; instead directly edit table t_instrument_class
**    _message          Status message
**    _returnCode       Return code
**
**  Example value for _params
**
**      <sections>
**        <section name="DatasetQC">
**          <item key="SaveTICAndBPIPlots" value="True" />
**          <item key="SaveLCMS2DPlots" value="True" />
**          <item key="ComputeOverallQualityScores" value="True" />
**          <item key="CreateDatasetInfoFile" value="True" />
**          <item key="LCMS2DPlotMZResolution" value="0.4" />
**          <item key="LCMS2DPlotMaxPointsToPlot" value="200000" />
**          <item key="LCMS2DPlotMinPointsPerSpectrum" value="2" />
**          <item key="LCMS2DPlotMinIntensity" value="0" />
**          <item key="LCMS2DOverviewPlotDivisor" value="10" />
**        </section>
**      </sections>
**
**  Auth:   jds
**  Date:   07/06/2006
**          07/25/2007 mem - Added parameter _allowedDatasetTypes
**          09/17/2009 mem - Removed parameter _allowedDatasetTypes (Ticket #748)
**          06/21/2010 mem - Added parameter _params
**          11/16/2010 mem - Added parameter _comment
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Add try/catch handling and disallow _mode = 'add'
**          02/01/2023 mem - Rename argument to _isPurgeable and switch from text to int
**                         - Remove argument _requiresPreparation
**          01/09/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _xmlParams xml;
    _logErrors boolean := false;

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _instrumentClass := Trim(Coalesce(_instrumentClass, ''));
        _rawDataType     := Trim(Coalesce(_rawDataType, ''));
        _params          := Trim(Coalesce(_params, ''));
        _comment         := Trim(Coalesce(_comment, ''));
        _mode            := Trim(Lower(Coalesce(_mode, '')));

        If _instrumentClass = '' Then
            RAISE EXCEPTION 'Instrument class name must be specified' USING ERRCODE = 'U5201';
        End If;

        If Not Exists (SELECT instrument_class FROM t_instrument_class WHERE instrument_class = _instrumentClass::citext) Then
            RAISE EXCEPTION 'Unrecognized instrument class: %', _instrumentClass USING ERRCODE = 'U5202';
        End If;

        If _isPurgeable Is Null Then
            RAISE EXCEPTION 'Is purgeable cannot be null' USING ERRCODE = 'U5203';
        End If;

        If Not _isPurgeable In (0, 1) Then
            RAISE EXCEPTION 'Is purgeable should be 0 or 1' USING ERRCODE = 'U5204';
        End If;

        If _rawDataType = '' Then
            RAISE EXCEPTION 'Raw data type must be specified' USING ERRCODE = 'U5205';
        End If;

        If Not Exists (SELECT raw_data_type_id FROM t_instrument_data_type_name WHERE raw_data_type_name = _rawDataType) Then
            RAISE EXCEPTION 'Unrecognized raw data type: %', _rawDataType USING ERRCODE = 'U5206';
        End If;

        If _params <> '' Then
            _xmlParams := public.try_cast(_params, null::XML);
            If _xmlParams Is Null Then
                RAISE EXCEPTION 'Could not convert params to XML' USING ERRCODE = 'U5207';
            End If;
        Else
            _params := null;
        End If;

        ---------------------------------------------------
        -- Note: the add mode is not enabled in this procedure
        ---------------------------------------------------

        If _mode = 'add' Then
            RAISE EXCEPTION 'The "add" instrument class mode is disabled for this page; instead directly edit table t_instrument_class' USING ERRCODE = 'U5208';
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            _logErrors := true;

            UPDATE t_instrument_class
            SET is_purgeable  = _isPurgeable,
                raw_data_type = _rawDataType,
                params        = _xmlParams,
                comment       = _comment
            WHERE instrument_class = _instrumentClass::citext;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            If Coalesce(_instrumentClass, '') = '' Then
                _logMessage := _exceptionMessage;
            Else
                _logMessage := format('%s; Instrument Class %s', _exceptionMessage, _instrumentClass);
            End If;

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.add_update_instrument_class(IN _instrumentclass text, IN _ispurgeable integer, IN _rawdatatype text, IN _params text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_instrument_class(IN _instrumentclass text, IN _ispurgeable integer, IN _rawdatatype text, IN _params text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_instrument_class(IN _instrumentclass text, IN _ispurgeable integer, IN _rawdatatype text, IN _params text, IN _comment text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateInstrumentClass';


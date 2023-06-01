--
CREATE OR REPLACE PROCEDURE public.add_update_instrument_class
(
    _instrumentClass text,
    _isPurgeable int,
    _rawDataType text,
    _params text,
    _comment text,
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates existing Instrument Class in database
**
**  Arguments:
**    _instrumentClass  Instrument class name
**    _isPurgeable      1 if datasets can be purged for this instrument class, 0 if purging is disabled
**    _rawDataType      Instrument data type; see table T_Instrument_Data_Type_Name
**    _params           XML parameters with DatasetQC options (see below)
**    _comment          Instrument class comment
**    _mode             The only valid mode is 'update', since 'add' is not allowed in this procedure; instead directly edit table T_Instrument_Class
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _xmlParams xml;
    _logErrors boolean := false;
    _logMessage text;

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

    BEGIN

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        If char_length(_instrumentClass) < 1 Then
            RAISE EXCEPTION 'Instrument Class Name cannot be blank' USING ERRCODE = 'U5201';
        End If;

        If _isPurgeable Is Null Then
            RAISE EXCEPTION 'Is Purgeable cannot be null' USING ERRCODE = 'U5202';
        End If;
        --
        If char_length(_rawDataType) < 1 Then
            RAISE EXCEPTION 'Raw Data Type cannot be blank' USING ERRCODE = 'U5203';
        End If;
        --

        _params := Coalesce(_params, '');

        If char_length(_params) > 0 Then
            _xmlParams := public.try_cast(_params, null::XML);
            If _xmlParams Is Null Then
                RAISE EXCEPTION 'Could not convert Params to XML' USING ERRCODE = 'U5205';
            End If;
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Note: the add mode is not enabled in this procedure
        ---------------------------------------------------

        If _mode = 'add' Then
            RAISE EXCEPTION 'The "add" instrument class mode is disabled for this page; instead directly edit table t_instrument_class' USING ERRCODE = 'U5206';
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then
            _logErrors := true;

            --
            UPDATE t_instrument_class
            SET
                is_purgeable = _isPurgeable,
                raw_data_type = _rawDataType,
                params = _xmlParams,
                comment = _comment
            WHERE (instrument_class = _instrumentClass)

        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Instrument Class %s', _exceptionMessage, _instrumentClass);

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

COMMENT ON PROCEDURE public.add_update_instrument_class IS 'AddUpdateInstrumentClass';

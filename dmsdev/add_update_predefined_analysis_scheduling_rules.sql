--
-- Name: add_update_predefined_analysis_scheduling_rules(integer, text, text, text, text, integer, text, integer, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_predefined_analysis_scheduling_rules(IN _evaluationorder integer, IN _instrumentclass text, IN _instrumentname text, IN _datasetname text, IN _analysistoolname text, IN _priority integer, IN _processorgroup text, IN _enabled integer, INOUT _id integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing predefined analysis scheduling rule
**
**  Arguments:
**    _evaluationOrder      Evaluation order
**    _instrumentClass      Instrument class
**    _instrumentName       Instrument name
**    _datasetName          Dataset name
**    _analysisToolName     Analysis tool name spec; typically includes wildcards, e.g. '%MSGFPlus%' or '%MASIC%'
**    _priority             Priority
**    _processorGroup       Processor group name
**    _enabled              Enabled: 1 if enabled, 0 if disabled
**    _id                   Input/output: scheduling rule ID in t_predefined_analysis_scheduling_rules
**    _mode                 Mode: 'add' or 'update'
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**          02/28/2014 mem - Now auto-converting null values to empty strings
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/15/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _processorGroupID int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _evaluationOrder  := Coalesce(_evaluationOrder, 10);
    _instrumentClass  := Trim(Coalesce(_instrumentClass, ''));
    _instrumentName   := Trim(Coalesce(_instrumentName, ''));
    _datasetName      := Trim(Coalesce(_datasetName, ''));
    _analysisToolName := Trim(Coalesce(_analysisToolName, ''));
    _priority         := Coalesce(_priority, 3);
    _processorGroup   := Trim(Coalesce(_processorGroup, ''));
    _enabled          := Coalesce(_enabled, 1);
    _mode             := Trim(Lower(Coalesce(_mode, '')));

    If _analysisToolName = '' Then
        _message := format('Analysis tool name spec must be defined');
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;

    End If;

    -- Assure that _enabled is 0 or 1
    If _enabled <> 0 Then
        _enabled = 1;
    End If;

    _processorGroupID := null;

    If _processorGroup <> '' Then
        -- Validate _processorGroup and determine the ID value

        SELECT group_id
        INTO _processorGroupID
        FROM t_analysis_job_processor_group
        WHERE group_name = _processorGroup::citext;

        If Not FOUND Then
            _message := format('Processor group not found: %s', _processorGroup);
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        If _id Is Null Then
            _message := 'Cannot update: predefine scheduling rule ID cannot be null';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If Not Exists (SELECT rule_id FROM t_predefined_analysis_scheduling_rules WHERE rule_id = _id) Then
            _message := format('Cannot update: predefine scheduling rule ID %s does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO t_predefined_analysis_scheduling_rules (
            evaluation_order,
            instrument_class,
            instrument_name,
            dataset_name,
            analysis_tool_name,
            priority,
            processor_group_id,
            enabled
        ) VALUES (
            _evaluationOrder,
            _instrumentClass,
            _instrumentName,
            _datasetName,
            _analysisToolName,
            _priority,
            _processorGroupID,
            _enabled
        )
        RETURNING rule_id
        INTO _id;

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_predefined_analysis_scheduling_rules
        SET evaluation_order   = _evaluationOrder,
            instrument_class   = _instrumentClass,
            instrument_name    = _instrumentName,
            dataset_name       = _datasetName,
            analysis_tool_name = _analysisToolName,
            priority           = _priority,
            processor_group_id = _processorGroupID,
            enabled            = _enabled
        WHERE rule_id = _id;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_predefined_analysis_scheduling_rules(IN _evaluationorder integer, IN _instrumentclass text, IN _instrumentname text, IN _datasetname text, IN _analysistoolname text, IN _priority integer, IN _processorgroup text, IN _enabled integer, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_predefined_analysis_scheduling_rules(IN _evaluationorder integer, IN _instrumentclass text, IN _instrumentname text, IN _datasetname text, IN _analysistoolname text, IN _priority integer, IN _processorgroup text, IN _enabled integer, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_predefined_analysis_scheduling_rules(IN _evaluationorder integer, IN _instrumentclass text, IN _instrumentname text, IN _datasetname text, IN _analysistoolname text, IN _priority integer, IN _processorgroup text, IN _enabled integer, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdatePredefinedAnalysisSchedulingRules';


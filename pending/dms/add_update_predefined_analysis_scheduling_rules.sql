--
CREATE OR REPLACE PROCEDURE public.add_update_predefined_analysis_scheduling_rules
(
    _evaluationOrder int,
    _instrumentClass text,
    _instrumentName text,
    _datasetName text,
    _analysisToolName text,
    _priority int,
    _processorGroup text,
    _enabled int,
    INOUT _id int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_Predefined_Analysis_Scheduling_Rules
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/15/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          03/16/2007 mem - Updated to use processor group ID (Ticket #419)
**          02/28/2014 mem - Now auto-converting null values to empty strings
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _processorGroupID int;
BEGIN
    _message := '';
    _returnCode:= '';

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

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _processorGroup := Trim(Coalesce(_processorGroup, ''));
    _processorGroupID := Null;

    _instrumentClass := Coalesce(_instrumentClass, '');
    _instrumentName := Coalesce(_instrumentName, '');
    _datasetName := Coalesce(_datasetName, '');

    If char_length(_processorGroup) > 0 Then
        -- Validate _processorGroup and determine the ID value

        SELECT group_id
        INTO _processorGroupID
        FROM t_analysis_job_processor_group
        WHERE group_name = _processorGroup;

        If Not FOUND Then
            _message := 'Processor group not found: ' || _processorGroup;
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Cannot update a non-existent entry
        --
        If Not Exists (SELECT rule_id FROM t_predefined_analysis_scheduling_rules WHERE rule_id = _id) Then
            _message := 'No entry could be found in database for update';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
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
    --
    If _mode = 'update' Then

        UPDATE t_predefined_analysis_scheduling_rules
        SET
            evaluation_order = _evaluationOrder,
            instrument_class = _instrumentClass,
            instrument_name = _instrumentName,
            dataset_name = _datasetName,
            analysis_tool_name = _analysisToolName,
            priority = _priority,
            processor_group_id = _processorGroupID,
            enabled = _enabled
        WHERE (rule_id = _id)

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_predefined_analysis_scheduling_rules IS 'AddUpdatePredefinedAnalysisSchedulingRules';

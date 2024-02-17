--
-- Name: duplicate_manager_parameter(integer, integer, text, text, text, text, boolean); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE OR REPLACE FUNCTION mc.duplicate_manager_parameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text DEFAULT NULL::text, _commentoverride text DEFAULT NULL::text, _paramvaluesearchtext text DEFAULT NULL::text, _paramvaluereplacetext text DEFAULT NULL::text, _infoonly boolean DEFAULT true) RETURNS TABLE(status text, param_type_id integer, value public.citext, mgr_id integer, comment public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Duplicate an existing parameter for all managers, creating new entries using the new param TypeID value
**
**      The new parameter type must already exist in mc.t_param_type
**
**  Arguments:
**    _sourceParamTypeId       Source param TypeID
**    _newParamTypeId          New param TypeID
**    _paramValueOverride      Optional: new parameter value; ignored if _paramValueSearchText is defined
**    _paramValueSearchText    Optional: text to search for in the source parameter value
**    _paramValueReplaceText   Optional: replacement text (ignored if _paramValueReplaceText is null)
**    _infoOnly                False to perform the update, true to preview
**
**  Example usage:
**    SELECT * FROM mc.duplicate_manager_parameter (157, 172, _paramValueSearchText => 'msfileinfoscanner', _paramValueReplaceText => 'AgilentToUimfConverter', _infoOnly => true);
**
**    SELECT * FROM mc.duplicate_manager_parameter (179, 182, _paramValueSearchText => 'PbfGen', _paramValueReplaceText => 'ProMex', _infoOnly => true);
**
**  Auth:   mem
**  Date:   08/26/2013 mem - Initial release
**          01/30/2020 mem - Ported to PostgreSQL
**          08/20/2022 mem - Update warnings shown when an exception occurs
**          08/24/2022 mem - Use function local_error_handler() to log errors
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          01/31/2023 mem - Use new column names in tables
**          05/12/2023 mem - Rename variables
**          05/22/2023 mem - Capitalize reserved word
**          05/23/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _message text;
    _returnCode text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);

    If _returnCode = '' And _sourceParamTypeID Is Null Then
        _message := '_sourceParamTypeID cannot be null; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5200';
    End If;

    If _returnCode = '' And  _newParamTypeID Is Null Then
        _message := '_newParamTypeID cannot be null; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
    End If;

    If _returnCode = '' And Not _paramValueSearchText Is Null And _paramValueReplaceText Is Null Then
        _message := '_paramValueReplaceText cannot be null when _paramValueSearchText is defined; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5202';
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 'Warning' AS status,
               0 as param_type_id,
               _message::citext as value,
               0,
               ''::citext as comment;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the soure parameter exists
    ---------------------------------------------------

    If _returnCode = '' And Not Exists (SELECT entry_id FROM mc.t_param_value PV WHERE PV.param_type_id = _sourceParamTypeID) Then
        _message := format('_sourceParamTypeID %s not found in mc.t_param_value; unable to continue', _sourceParamTypeID);
        RAISE WARNING '%', _message;
        _returnCode := 'U5203';
    End If;

    If _returnCode = '' And Exists (SELECT entry_id FROM mc.t_param_value PV WHERE PV.param_type_id = _newParamTypeID) Then
        _message := format('_newParamTypeID %s already exists in mc.t_param_value; unable to continue', _newParamTypeID);
        RAISE WARNING '%', _message;
        _returnCode := 'U5204';
    End If;

    If _returnCode = '' And Not Exists (SELECT param_type_id FROM mc.t_param_type PT Where PT.param_type_id = _newParamTypeID) Then
        _message := format('_newParamTypeID %s not found in mc.t_param_type; unable to continue', _newParamTypeID);
        RAISE WARNING '%', _message;
        _returnCode := 'U5205';
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 'Warning' AS status,
               0 as param_type_id,
               _message::citext as value,
               0 as mgr_id,
               ''::citext as comment;
        RETURN;
    End If;

    If Not _paramValueSearchText Is Null Then
        If _infoOnly Then
            RETURN QUERY
            SELECT 'Preview' as Status,
                   _newParamTypeID AS TypeID,
                   (Replace(PV.value::citext, _paramValueSearchText::citext, _paramValueReplaceText::citext))::citext AS value,
                   PV.mgr_id,
                   Coalesce(_commentOverride, '')::citext AS comment
            FROM mc.t_param_value PV
            WHERE PV.param_type_id = _sourceParamTypeID;
            RETURN;
        End If;

        INSERT INTO mc.t_param_value( param_type_id, value, mgr_id, comment )
        SELECT _newParamTypeID AS param_type_id,
               Replace(PV.value::citext, _paramValueSearchText::citext, _paramValueReplaceText::citext) AS value,
               PV.mgr_id,
               Coalesce(_commentOverride, '') AS comment
        FROM mc.t_param_value PV
        WHERE PV.param_type_id = _sourceParamTypeID;

    Else

        If _infoOnly Then
            RETURN QUERY
            SELECT 'Preview' as Status,
                   _newParamTypeID AS TypeID,
                   Coalesce(_paramValueOverride, PV.value)::citext AS value,
                   PV.mgr_id,
                   Coalesce(_commentOverride, '')::citext AS comment
            FROM mc.t_param_value PV
            WHERE PV.param_type_id = _sourceParamTypeID;
            RETURN;
        End If;

        INSERT INTO mc.t_param_value( param_type_id, value, mgr_id, comment )
        SELECT _newParamTypeID AS param_type_id,
               Coalesce(_paramValueOverride, PV.value) AS value,
               PV.mgr_id,
               Coalesce(_commentOverride, '') AS comment
        FROM mc.t_param_value PV
        WHERE PV.param_type_id = _sourceParamTypeID;
    End If;

    RETURN QUERY
        SELECT 'Duplicated' as Status, PV.param_type_id, PV.value, PV.mgr_id, PV.comment
        FROM mc.t_param_value PV
        WHERE PV.param_type_id = _newParamTypeID;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    _message := local_error_handler (
                    _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                    _logError => true);

    _returnCode := _sqlState;

    RETURN QUERY
    SELECT 'Error' AS Status,
           0 as param_type_id,
           _message::citext as value,
           0 as mgr_id,
           ''::citext as comment;

END
$$;


ALTER FUNCTION mc.duplicate_manager_parameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION duplicate_manager_parameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly boolean); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.duplicate_manager_parameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly boolean) IS 'DuplicateManagerParameter';


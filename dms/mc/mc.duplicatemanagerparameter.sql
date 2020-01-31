--
-- Name: duplicatemanagerparameter(integer, integer, text, text, text, text, integer); Type: FUNCTION; Schema: mc; Owner: d3l243
--

CREATE FUNCTION mc.duplicatemanagerparameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text DEFAULT NULL::text, _commentoverride text DEFAULT NULL::text, _paramvaluesearchtext text DEFAULT NULL::text, _paramvaluereplacetext text DEFAULT NULL::text, _infoonly integer DEFAULT 1) RETURNS TABLE(status text, type_id integer, value public.citext, mgr_id integer, comment public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Duplicates an existing parameter for all managers,
**      creating new entries using the new param TypeID value
**
**      The new parameter type must already exist in mc.t_param_type
**
**  Example usage:
**    Select * From DuplicateManagerParameter (157, 172, _paramValueSearchText := 'msfileinfoscanner', _paramValueReplaceText := 'AgilentToUimfConverter', _infoOnly := 1);
**
**    Select * From DuplicateManagerParameter (179, 182, _paramValueSearchText := 'PbfGen', _paramValueReplaceText := 'ProMex', _infoOnly := 1);
**
**  Arguments:
**    _paramValueOverride      Optional: new parameter value; ignored if _paramValueSearchText is defined
**    _paramValueSearchText    Optional: text to search for in the source parameter value
**    _paramValueReplaceText   Optional: replacement text (ignored if _paramValueReplaceText is null)
**
**  Auth:   mem
**  Date:   08/26/2013 mem - Initial release
**          01/30/2020 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text = '';
    _returnCode text = '';
    _sqlstate text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, 1);

    _message := '';
    _returnCode := '';

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

    If _returnCode = '' And Not _paramValueSearchText Is Null AND _paramValueReplaceText Is Null Then
        _message := '_paramValueReplaceText cannot be null when _paramValueSearchText is defined; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5202';
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 'Warning' AS status,
               0 as type_id,
               _message::citext as value,
               0,
               ''::citext as comment;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the soure parameter exists
    ---------------------------------------------------

    If _returnCode = '' And Not Exists (Select * From mc.t_param_value PV Where PV.type_id = _sourceParamTypeID) Then
        _message := '_sourceParamTypeID ' || _sourceParamTypeID || ' not found in mc.t_param_value; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5203';
    End If;

    If _returnCode = '' And Exists (Select * From mc.t_param_value PV Where PV.type_id = _newParamTypeID) Then
        _message := '_newParamTypeID ' || _newParamTypeID || ' already exists in mc.t_param_value; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5204';
    End If;

    If _returnCode = '' And Not Exists (Select * From mc.t_param_type PT Where PT.param_id = _newParamTypeID) Then
        _message := '_newParamTypeID ' || _newParamTypeID || ' not found in mc.t_param_type; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5205';
    End If;

    If _returnCode <> '' Then
        RETURN QUERY
        SELECT 'Warning' AS status,
               0 as type_id,
               _message::citext as value,
               0 as mgr_id,
               ''::citext as comment;
        RETURN;
    End If;

    If Not _paramValueSearchText Is Null Then
        If _infoOnly <> 0 Then
            RETURN QUERY
            SELECT 'Preview' as Status,
                   _newParamTypeID AS TypeID,
                   (Replace(PV.value::citext, _paramValueSearchText::citext, _paramValueReplaceText::citext))::citext AS value,                    
                   PV.mgr_id,
                   Coalesce(_commentOverride, '')::citext AS comment
            FROM mc.t_param_value PV
            WHERE PV.type_id = _sourceParamTypeID;
            Return;
        End If;

        INSERT INTO mc.t_param_value( type_id, value, mgr_id, comment )
        SELECT _newParamTypeID AS type_id,
               Replace(PV.value::citext, _paramValueSearchText::citext, _paramValueReplaceText::citext) AS value,
               PV.mgr_id,
               Coalesce(_commentOverride, '') AS comment
        FROM mc.t_param_value PV
        WHERE PV.type_id = _sourceParamTypeID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    Else

        If _infoOnly <> 0 Then
            RETURN QUERY
            SELECT 'Preview' as Status,
                   _newParamTypeID AS TypeID,
                   Coalesce(_paramValueOverride, PV.value)::citext AS value,
                   PV.mgr_id,
                   Coalesce(_commentOverride, '')::citext AS comment
            FROM mc.t_param_value PV
            WHERE PV.type_id = _sourceParamTypeID;
            Return;
        End If;

        INSERT INTO mc.t_param_value( type_id, value, mgr_id, comment )
        SELECT _newParamTypeID AS type_id,
               Coalesce(_paramValueOverride, PV.value) AS value,
               PV.mgr_id,
               Coalesce(_commentOverride, '') AS comment
        FROM mc.t_param_value PV
        WHERE PV.type_id = _sourceParamTypeID;
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    End If;

    RETURN QUERY
        SELECT 'Duplicated' as Status, PV.type_id, PV.value, PV.mgr_id, PV.comment
        FROM mc.t_param_value PV
        WHERE PV.type_id = _newParamTypeID;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlstate = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := 'Error duplicating a manager parameter: ' || _exceptionMessage || '; ';
    _returnCode := _sqlstate;

    RAISE Warning 'Error: %', _message;
    RAISE warning '%', _exceptionContext;

    RETURN QUERY
    SELECT 'Error' AS Status, 
           0 as type_id,
           _message::citext as value,
           0 as mgr_id,
           ''::citext as comment;

END
$$;


ALTER FUNCTION mc.duplicatemanagerparameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly integer) OWNER TO d3l243;

--
-- Name: FUNCTION duplicatemanagerparameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly integer); Type: COMMENT; Schema: mc; Owner: d3l243
--

COMMENT ON FUNCTION mc.duplicatemanagerparameter(_sourceparamtypeid integer, _newparamtypeid integer, _paramvalueoverride text, _commentoverride text, _paramvaluesearchtext text, _paramvaluereplacetext text, _infoonly integer) IS 'DuplicateManagerParameter';


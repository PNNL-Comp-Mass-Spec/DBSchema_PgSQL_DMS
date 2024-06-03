--
-- Name: delete_aux_info(text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_aux_info(IN _targettypename text DEFAULT ''::text, IN _targetentityname text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete existing auxiliary information in database for given target type and identity
**
**  Arguments:
**    _targetTypeName       Target type name: Experiment, Biomaterial, Dataset, or SamplePrepRequest
**    _targetEntityName     Target entity name (though, for sample prep requests, this is prep request ID)
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   04/08/2002
**          06/16/2022 mem - Auto change _targetTypeName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          09/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _tgtTableName text;
    _tgtTableNameCol text;
    _tgtTableIDCol text;
    _targetID int;
    _sql text;
    _deleteCount int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _targetTypeName   := Trim(Coalesce(_targetTypeName, ''));
    _targetEntityName := Trim(Coalesce(_targetEntityName, ''));

    If _targetTypeName::citext = 'Cell Culture' And Exists (SELECT target_type_name FROM t_aux_info_target WHERE target_type_name = 'Biomaterial') Then
        _targetTypeName := 'Biomaterial';
    End If;

    ---------------------------------------------------
    -- Resolve target name to target table criteria
    ---------------------------------------------------

    SELECT target_table,
           target_id_column,
           target_name_column,
           message
    INTO _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _message
    FROM public.get_aux_info_target_table_info(_targetTypeName);

    If Not FOUND Then
        _message := format('Target type %s not found in t_aux_info_target', _targetTypeName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve target name and entity name to entity ID
    ---------------------------------------------------

    _targetID := public.get_aux_info_entity_id_by_name(_targetTypeName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _targetEntityName);

    If Coalesce(_targetID, 0) = 0 Then
        _message := format('Could not determine entity ID for %s "%s"', _targetTypeName, _targetEntityName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete all entries from auxiliary info table
    -- for the given target type and identity
    ---------------------------------------------------

    DELETE FROM t_aux_info_value
    WHERE target_id = _targetID AND
          aux_description_id IN (SELECT item_id
                                 FROM V_Aux_Info_Definition_with_ID
                                 WHERE target = _targetTypeName::citext
                                );
    --
    GET DIAGNOSTICS _deleteCount = ROW_COUNT;

    If _deleteCount > 0 Then
        _message := format('Deleted %s %s from t_aux_info_value for %s "%s", ID %s',
                           _deleteCount,
                           public.check_plural(_deleteCount, 'row', 'rows'),
                           _targetTypeName,
                           _targetEntityName,
                           _targetID);

        RAISE INFO '%', _message;
    Else
        _message := format('Aux info values not found for %s "%s"',
                           _targetTypeName,
                           _targetEntityName,
                           _targetID);
    End If;
END
$$;


ALTER PROCEDURE public.delete_aux_info(IN _targettypename text, IN _targetentityname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_aux_info(IN _targettypename text, IN _targetentityname text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_aux_info(IN _targettypename text, IN _targetentityname text, INOUT _message text, INOUT _returncode text) IS 'DeleteAuxInfo';


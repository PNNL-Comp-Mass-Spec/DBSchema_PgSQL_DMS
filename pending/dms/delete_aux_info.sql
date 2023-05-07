--
CREATE OR REPLACE PROCEDURE public.delete_aux_info
(
    _targetName text = '',
    _targetEntityName text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes existing auxiliary information in database
**      for given target type and identity
**
**  Auth:   grk
**  Date:   04/08/2002
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _tgtTableName text;
    _tgtTableNameCol text;
    _tgtTableIDCol text;
    _targetID int;
    _sql text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _targetName := Trim(Coalesce(_targetName, ''));
    _targetEntityName := Trim(Coalesce(_targetEntityName, ''));

    If _targetName = 'Cell Culture' And Exists (Select * From t_aux_info_target Where target_type_name = 'Biomaterial') Then
        _targetName := 'Biomaterial';
    End If;

    ---------------------------------------------------
    -- Resolve target name to target table criteria
    ---------------------------------------------------

    SELECT target_table,
           target_id_column,
           target_name_column,
           message
    INTO _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _message
    FROM public.get_aux_info_target_table_info(_targetName);

    If Not FOUND Then
        _message := format('Target type %s not found in t_aux_info_target', _targetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve target name and entity name to entity ID
    ---------------------------------------------------

    _targetID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _targetEntityName);

    If Coalesce(_targetID, 0) = 0 Then
        _message := 'Could not resolve target name and entity name to entity ID: "' || _targetEntityName || '" ';
        RAISE EXCEPTION '%', _msg;

    If _targetID = 0 Then
        _message := 'Error resolving ID for ' || _targetName || ' "' || _targetEntityName || '"';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete all entries from auxiliary value table
    -- for the given target type and identity
    ---------------------------------------------------

    DELETE FROM t_aux_info_value
    WHERE (target_id = _targetID) AND
    (
        Aux_Description_ID IN
        (
            SELECT Item_ID
            FROM V_Aux_Info_Definition_with_ID
            WHERE (Target = _targetName)
        )
    );

END
$$;

COMMENT ON PROCEDURE public.delete_aux_info IS 'DeleteAuxInfo';

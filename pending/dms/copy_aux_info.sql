--
CREATE OR REPLACE PROCEDURE public.copy_aux_info
(
    _targetName text,
    _targetEntityName text,
    _categoryName text,
    _subCategoryName text,
    _sourceEntityName text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies aux info from a source item to a target item
**
**  Arguments:
**    _targetName           Target type name: 'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'
**    _targetEntityName     Target entity ID or name
**    _categoryName         Category name
**    _subCategoryName      Subcategory name
**    _sourceEntityName     Source entity name (experiment name, biomaterial name, etc.)
**    _mode                 Mode: 'copyCategory', 'copySubcategory', 'copyAll'
**    _message              Output message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   01/27/2003 grk - Initial version
**          07/12/2008 grk - Added error check for source
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _tgtTableName citext;
    _tgtTableNameCol citext;
    _tgtTableIDCol citext;
    _sql text;
    _destEntityID int;
    _sourceEntityID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If _targetEntityName::citext = _sourceEntityName::citext Then
        _message := 'Target and source cannot be the same'
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Resolve target name to target ID using the entity's data table, as defined in t_aux_info_target
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

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve target name and destination entity name to entity ID
    ---------------------------------------------------

    _destEntityID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _targetEntityName);

    If Coalesce(_destEntityID, 0) = 0 Then
        _message := format('Could not find "%s" in %s', _targetEntityName, _tgtTableName;
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve target name and source entity name to entity ID
    ---------------------------------------------------

    _sourceEntityID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _sourceEntityName);

    If Coalesce(_sourceEntityID, 0) = 0 Then
        _message := format('Could not find "%s" in %s', _targetEntityName, _tgtTableName;
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name and category
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopyCategory') Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (Target_ID = _destEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) ));

        -- Insert new values
        --
        INSERT INTO t_aux_info_value (target_id,
                                      Aux_Description_ID,
                                      Value )
        SELECT _destEntityID AS Target_ID,
               Aux_Description_ID,
               Value
        FROM t_aux_info_value
        WHERE (target_id = _sourceEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) ));

    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name and category and subcategory
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopySubcategory') Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (target_id = _destEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) AND
                                             (Subcategory = _subCategoryName) ));

        -- Insert new values
        --
        INSERT INTO t_aux_info_value (target_id,
                                      Aux_Description_ID,
                                      Value )
        SELECT _destEntityID AS Target_ID,
               Aux_Description_ID,
               Value
        FROM t_aux_info_value
        WHERE (target_id = _sourceEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) AND
                                             (Subcategory = _subCategoryName) ));
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopyAll') Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (target_id = _destEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) ));

        INSERT INTO t_aux_info_value( target_id,
                                      Aux_Description_ID,
                                      Value )
        SELECT _destEntityID AS Target_ID,
               Aux_Description_ID,
               Value
        FROM t_aux_info_value
        WHERE (target_id = _sourceEntityID) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) ));
    End If;

END
$$;

COMMENT ON PROCEDURE public.copy_aux_info IS 'CopyAuxInfo';

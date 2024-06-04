--
-- Name: copy_aux_info(text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.copy_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityname text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Copy aux info from a source item to a target item
**
**  Arguments:
**    _targetName           Target type name: 'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'; see t_aux_info_target
**    _targetEntityName     Target entity name (not ID) for experiment, biomaterial, and dataset; prep request ID (integer) when _targetName is 'SamplePrepRequest'
**    _categoryName         Category name, e.g. 'Lysis Method', 'Denaturing Conditions', etc.; see t_aux_info_category
**    _subCategoryName      Subcategory name, e.g. 'Procedure', 'Reagents', etc.;              see t_aux_info_subcategory
**    _sourceEntityName     Name (not ID) of the source entity to copy information from; however, for sample prep requests, use prep request ID (integer)
**    _mode                 Mode: 'CopyCategory', 'CopySubcategory', 'CopyAll'
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   01/27/2003 grk - Initial version
**          07/12/2008 grk - Added error check for source
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/04/2023 mem - Ported to PostgreSQL
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
        _message := 'Target and source cannot be the same';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

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

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve target entity name to entity ID
    ---------------------------------------------------

    _destEntityID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _targetEntityName);

    If Coalesce(_destEntityID, 0) = 0 Then
        _message := format('Could not find destination item "%s" in %s', _targetEntityName, _tgtTableName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve source entity name to entity ID
    ---------------------------------------------------

    _sourceEntityID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _sourceEntityName);

    If Coalesce(_sourceEntityID, 0) = 0 Then
        _message := format('Could not find source item "%s" in %s', _sourceEntityName, _tgtTableName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table for given target name and category
    -- from given source target entity to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopyCategory') Then

        -- Delete any existing values

        DELETE FROM t_aux_info_value
        WHERE target_id = _destEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName AND
                                           Category = _categoryName);

        -- Insert new values

        INSERT INTO t_aux_info_value (
            target_id,
            aux_description_id,
            value
        )
        SELECT _destEntityID AS Target_ID,
               aux_description_id,
               value
        FROM t_aux_info_value
        WHERE target_id = _sourceEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName AND
                                           Category = _categoryName);

    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name and category and subcategory
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopySubcategory') Then

        -- Delete any existing values

        DELETE FROM t_aux_info_value
        WHERE target_id = _destEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName AND
                                           Category = _categoryName AND
                                           Subcategory = _subCategoryName);

        -- Insert new values

        INSERT INTO t_aux_info_value (
            target_id,
            aux_description_id,
            value
        )
        SELECT _destEntityID AS Target_ID,
               aux_description_id,
               value
        FROM t_aux_info_value
        WHERE target_id = _sourceEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName AND
                                           Category = _categoryName AND
                                           Subcategory = _subCategoryName);
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode = Lower('CopyAll') Then

        -- Delete any existing values

        DELETE FROM t_aux_info_value
        WHERE target_id = _destEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName);

        INSERT INTO t_aux_info_value (
            target_id,
            aux_description_id,
            value
        )
        SELECT _destEntityID AS Target_ID,
               aux_description_id,
               value
        FROM t_aux_info_value
        WHERE target_id = _sourceEntityID AND
              aux_description_id IN (SELECT Item_ID
                                     FROM V_Aux_Info_Definition
                                     WHERE Target = _targetName);
    End If;

END
$$;


ALTER PROCEDURE public.copy_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityname text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityname text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.copy_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityname text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'CopyAuxInfo';


--
-- Name: add_update_aux_info_definition(public.citext, text, text, text, text, integer, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_aux_info_definition(IN _mode public.citext DEFAULT 'UpdateItem'::public.citext, IN _targetname text DEFAULT 'Biomaterial'::text, IN _categoryname text DEFAULT 'Prokaryote'::text, IN _subcategoryname text DEFAULT 'Starter Culture Conditions'::text, IN _itemname text DEFAULT 'Date Started'::text, IN _seq integer DEFAULT 1, IN _param1 text DEFAULT ''::text, IN _param2 text DEFAULT ''::text, IN _param3 text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing auxiliary information definition
**
**  Arguments:
**    _mode                 Mode: 'AddTarget', 'AddCategory', 'AddSubcategory', 'AddItem', 'AddAllowedValue', 'UpdateItem'
**    _targetName           Target name: 'Biomaterial', 'Dataset', 'SamplePrepRequest', or 'Experiment'
**    _categoryName         Category,    e.g. 'Growth Conditions' or 'Lysis Method';   see column aux_category    in t_aux_info_category
**    _subCategoryName      Subcategory, e.g. 'Alkylation' or 'Centrifugation';        see column aux_subcategory in t_aux_info_subcategory
**    _itemName             Item name,   e.g. 'Alkylation Agent' or 'Centrifuge Time'; see column aux_description in t_aux_info_description
**    _seq                  Sequence number, corresponding to column sequence in t_aux_info_description; only used when _mode is 'UpdateItem'
**    _param1               See parameter argument usage below
**    _param2               See below
**    _param3               See below
**    _message              Output message
**    _returnCode           Return code
**
**  Parameter argument usage:
**      When _mode is 'AddTarget' parameters correspond to columns target_table, target_id_col, and target_name_col in table t_aux_info_target
**      When _mode is 'AddItem' or 'UpdateItem', parameters _param1 and _param2 correspond to columns data_size and helper_append in table t_aux_info_description
**      When _mode is 'AddAllowedValue', parameter _param1 corresponds to column value in table t_aux_info_allowed_values
**
**  Auth:   grk
**  Date:   04/19/2002 grk - Initial release
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column names
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/27/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _targetTypeID int;
    _categoryID int;
    _subcategoryID int;
    _descriptionID int;
    _tmpSeq int;
    _tmpID int;
    _msg text;
    _sequence int;
    _dataSize int;
    _dataSizeCurrent int;
    _helperAppend text;
    _helperAppendCurrent text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mode            := Trim(Lower(Coalesce(_mode, '')));
    _targetName      := Trim(Coalesce(_targetName, ''));
    _categoryName    := Trim(Coalesce(_categoryName, ''));
    _subCategoryName := Trim(Coalesce(_subCategoryName, ''));
    _itemName        := Trim(Coalesce(_itemName, ''));
    _seq             := Coalesce(_seq, 1);
    _param1          := Trim(Coalesce(_param1, ''));
    _param2          := Trim(Coalesce(_param2, ''));
    _param3          := Trim(Coalesce(_param3, ''));

    If _targetName = '' Then
        _message := 'Cannot add or update: target name is an empty string';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _mode::citext IN ('AddCategory', 'AddSubcategory', 'AddItem', 'AddAllowedValue') Then

        If _mode::citext IN ('AddCategory', 'AddSubcategory', 'AddItem', 'AddAllowedValue') And _categoryName = '' Then
            _message := 'Cannot add: category is an empty string';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        If _mode::citext IN ('AddSubcategory', 'AddItem', 'AddAllowedValue') And _subcategoryName = '' Then
            _message := 'Cannot add: subcategory is an empty string';
            RAISE WARNING '%', _message;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If _mode::citext IN ('AddItem', 'AddAllowedValue') And _itemName = '' Then
            _message := 'Cannot add: item is an empty string';
            RAISE WARNING '%', _message;

            _returnCode := 'U5204';
            RETURN;
        End If;

    End If;

    If _mode::citext IN ('AddItem', 'UpdateItem') Then
        _dataSize := public.try_cast(_param1, null::int);

        If _mode::citext IN ('AddItem') And _dataSize Is Null Then
            _message := 'When adding or updating an item, argument _param1 must be an integer';
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;

        If _mode::citext IN ('AddItem') And _dataSize <= 0 Then
            _message := 'When adding or updating an item, argument _param1 must be a positive integer';
            RAISE WARNING '%', _message;

            _returnCode := 'U5206';
            RETURN;
        End If;

        If (_mode::citext IN ('AddItem') Or _mode::citext IN ('UpdateItem') And _param2 <> '') And Not _param2::citext IN ('N', 'Y') Then
            _message := 'When adding or updating an item, argument _param2 must be Y or N';
            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

        _helperAppend := Upper(_param2);
    End If;

    If _mode <> Lower('AddTarget') And _targetName::citext = 'Cell Culture' And Exists (SELECT target_type_id FROM t_aux_info_target WHERE target_type_name = 'Biomaterial') Then
        _targetName := 'Biomaterial';
    End If;

    ---------------------------------------------------
    -- Add Target
    ---------------------------------------------------

    If _mode = Lower('AddTarget') Then

        If _param1 = '' Then
            _message := 'Cannot add: target table is an empty string (argument _param1)';
            RAISE WARNING '%', _message;

            _returnCode := 'U5208';
            RETURN;
        End If;

        If _param2 = '' Then
            _message := 'Cannot add: target ID column is an empty string (argument _param2)';
            RAISE WARNING '%', _message;

            _returnCode := 'U5209';
            RETURN;
        End If;

        If _param3 = '' Then
            _message := 'Cannot add: target name column is an empty string (argument _param3)';
            RAISE WARNING '%', _message;

            _returnCode := 'U5210';
            RETURN;
        End If;

        -- Is target already in table?

        SELECT target_type_id
        INTO _tmpID
        FROM t_aux_info_target
        WHERE target_type_name = _targetName::citext;

        If FOUND Then
            _message := format('Cannot add: target "%s" already exists', _targetName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5211';
            RETURN;
        End If;

        -- Insert new target into table

        INSERT INTO t_aux_info_target (
            target_type_name,
            target_table,
            target_id_col,
            target_name_col
        )
        VALUES (_targetName, _param1, _param2, _param3);

    End If;

    ---------------------------------------------------
    -- Add Category
    ---------------------------------------------------

    If _mode = Lower('AddCategory') Then
        -- Resolve parent target type to ID

        SELECT target_type_id
        INTO _targetTypeID
        FROM t_aux_info_target
        WHERE target_type_name = _targetName::citext;

        If _targetTypeID = 0 Then
            _message := 'Could not resolve parent target type';
            RAISE WARNING '%', _message;

            _returnCode := 'U5212';
            RETURN;
        End If;

        -- Is category already in table?

        SELECT aux_category_id
        INTO _tmpID
        FROM t_aux_info_category
        WHERE target_type_id = _targetTypeID AND
              aux_category = _categoryName::citext;

        If FOUND Then
            _message := 'Cannot add: category already exists for this target';
            RAISE WARNING '%', _message;

            _returnCode := 'U5213';
            RETURN;
        End If;

        -- Calculate new sequence

        SELECT Coalesce(MAX(sequence), 0)
        INTO _tmpSeq
        FROM t_aux_info_category
        WHERE target_type_id = _targetTypeID;

        _tmpSeq := _tmpSeq + 1;

        -- Insert new category for parent target type

        INSERT INTO t_aux_info_category (aux_category, target_type_id, sequence)
        VALUES (_categoryName, _targetTypeID, _tmpSeq);

    End If;

    ---------------------------------------------------
    -- Add Subcategory
    ---------------------------------------------------

    If _mode = Lower('AddSubcategory') Then
        -- Resolve parent category name to ID

        SELECT t_aux_info_category.aux_category_id
        INTO _categoryID
        FROM t_aux_info_target
             INNER JOIN t_aux_info_category
               ON t_aux_info_target.target_type_id = t_aux_info_category.target_type_id
        WHERE t_aux_info_target.target_type_name = _targetName::citext AND
              t_aux_info_category.aux_category = _categoryName::citext;

        If _categoryID = 0 Then
            _message := 'Could not resolve parent category name for given target type';
            RAISE WARNING '%', _message;

            _returnCode := 'U5214';
            RETURN;
        End If;

        -- Is subcategory already in table?
        --
        SELECT aux_subcategory_id
        INTO _tmpID
        FROM t_aux_info_subcategory
        WHERE aux_category_id = _categoryID AND
              aux_subcategory = _subcategoryName::citext;

        If FOUND Then
            _message := 'Cannot add: subcategory already exists for this target';
            RAISE WARNING '%', _message;

            _returnCode := 'U5215';
            RETURN;
        End If;

        -- Calculate new sequence
        --
        SELECT Coalesce(MAX(sequence), 0)
        INTO _tmpSeq
        FROM t_aux_info_subcategory
        WHERE aux_Category_ID = _categoryID;

        _tmpSeq := _tmpSeq + 1;

        -- Insert new subcategory for parent category
        --
        INSERT INTO t_aux_info_subcategory (aux_subcategory, sequence, Aux_Category_ID)
        VALUES (_subcategoryName, _tmpSeq, _categoryID);

    End If;

    ---------------------------------------------------
    -- Add Item
    ---------------------------------------------------

    If _mode = Lower('AddItem') Then
        -- Resolve parent names to ID

        SELECT t_aux_info_subcategory.aux_subcategory_id
        INTO _subcategoryID
        FROM t_aux_info_target
             INNER JOIN t_aux_info_category
               ON t_aux_info_target.target_type_id = t_aux_info_category.target_type_id
             INNER JOIN t_aux_info_subcategory
               ON t_aux_info_category.aux_category_id = t_aux_info_subcategory.aux_category_id
        WHERE t_aux_info_target.target_type_name = _targetName::citext AND
              t_aux_info_category.aux_category = _categoryName::citext AND
              t_aux_info_subcategory.aux_subcategory = _subcategoryName::citext;

        If Not FOUND Then
            _message := 'Could not resolve parent subcategory for given category and target type';
            RAISE WARNING '%', _message;

            _returnCode := 'U5216';
            RETURN;
        End If;

        -- Is item already in table?

        SELECT aux_description_id
        INTO _tmpID
        FROM t_aux_info_description
        WHERE aux_subcategory_id = _subcategoryID AND
              aux_description = _itemName::citext;

        If FOUND Then
            _message := 'Cannot add: item already exists for this target';
            RAISE WARNING '%', _message;

            _returnCode := 'U5217';
            RETURN;
        End If;

        -- Calculate new sequence

        SELECT Coalesce(MAX(sequence), 0)
        INTO _tmpSeq
        FROM t_aux_info_description
        WHERE aux_subcategory_id = _subcategoryID;

        _tmpSeq := _tmpSeq + 1;

        -- Insert new item for parent subcategory

        INSERT INTO t_aux_info_description (
            aux_description,
            aux_subcategory_id,
            sequence,
            data_size,
            helper_append
        )
        VALUES (_itemName, _subcategoryID, _tmpSeq, _dataSize, _helperAppend);

    End If;

    ---------------------------------------------------
    -- Add Allowed Value
    ---------------------------------------------------

    If _mode = Lower('AddAllowedValue') Then
        -- Resolve parent names to ID

        SELECT t_aux_info_description.aux_description_id
        INTO _descriptionID
        FROM t_aux_info_target
             INNER JOIN t_aux_info_category
               ON t_aux_info_target.target_type_id = t_aux_info_category.target_type_id
             INNER JOIN t_aux_info_subcategory
               ON t_aux_info_category.aux_category_id = t_aux_info_subcategory.aux_category_id
             INNER JOIN t_aux_info_description
               ON t_aux_info_subcategory.aux_subcategory_id = t_aux_info_description.aux_subcategory_id
        WHERE t_aux_info_target.Target_Type_Name = _targetName::citext AND
              t_aux_info_category.Aux_Category = _categoryName::citext AND
              t_aux_info_subcategory.Aux_Subcategory = _subcategoryName::citext AND
              t_aux_info_description.aux_description = _itemName::citext;

        If Not FOUND Then
            _message := 'Could not resolve parent description ID for given target type, category, subcategory, and item';
            RAISE WARNING '%', _message;

            _returnCode := 'U5218';
            RETURN;
        End If;

        -- Is item already in table?

        SELECT aux_description_id
        INTO _tmpID
        FROM t_aux_info_allowed_values
        WHERE aux_description_id = _descriptionID AND
              value = _param1::citext;

        If FOUND Then
            _message := 'Cannot add: allowed value already exists for this target';
            RAISE WARNING '%', _message;

            _returnCode := 'U5219';
            RETURN;
        End If;

        -- Insert new allowed value for parent description ID

        INSERT INTO t_aux_info_allowed_values (Aux_Description_ID, value)
        VALUES (_descriptionID, _param1);

    End If;

    ---------------------------------------------------
    -- Update Item
    ---------------------------------------------------

    If _mode = Lower('UpdateItem') Then
        -- Find item ID

        SELECT Item_ID
        INTO _tmpID
        FROM V_Aux_Info_Definition
        WHERE Target = _targetName::citext AND
              Category = _categoryName::citext AND
              Subcategory = _subcategoryName::citext AND
              Item = _itemName::citext;

        If Not FOUND Then
            _message := 'Cannot resolve item name, category, and subcategory to ID';
            RAISE WARNING '%', _message;

            _returnCode := 'U5220';
            RETURN;
        End If;

        -- Get current values so that blank input values can default

        SELECT sequence,
               data_size,
               helper_append
        INTO _sequence, _dataSizeCurrent, _helperAppendCurrent
        FROM t_aux_info_description
        WHERE aux_description_id = _tmpID;

        If _seq <> 0 Then
            _sequence := _seq;
        End If;

        If Coalesce(_dataSize, 0) > 0 Then
            _dataSizeCurrent := _dataSize;
        End If;

        If Coalesce(_helperAppend, '') <> '' Then
            _helperAppendCurrent := _helperAppend;
        End If;

        -- Update item

        UPDATE t_aux_info_description
        SET sequence = _sequence,
            data_size = _dataSizeCurrent,
            helper_append = _helperAppendCurrent
        WHERE aux_description_id = _tmpID;

    End If;

END
$$;


ALTER PROCEDURE public.add_update_aux_info_definition(IN _mode public.citext, IN _targetname text, IN _categoryname text, IN _subcategoryname text, IN _itemname text, IN _seq integer, IN _param1 text, IN _param2 text, IN _param3 text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_aux_info_definition(IN _mode public.citext, IN _targetname text, IN _categoryname text, IN _subcategoryname text, IN _itemname text, IN _seq integer, IN _param1 text, IN _param2 text, IN _param3 text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_aux_info_definition(IN _mode public.citext, IN _targetname text, IN _categoryname text, IN _subcategoryname text, IN _itemname text, IN _seq integer, IN _param1 text, IN _param2 text, IN _param3 text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateAuxInfoDefinition';


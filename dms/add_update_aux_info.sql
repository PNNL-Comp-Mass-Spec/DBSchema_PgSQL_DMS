--
-- Name: add_update_aux_info(text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_aux_info(IN _targetname text DEFAULT ''::text, IN _targetentityname text DEFAULT ''::text, IN _categoryname text DEFAULT ''::text, IN _subcategoryname text DEFAULT ''::text, IN _itemnamelist text DEFAULT ''::text, IN _itemvaluelist text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates an existing auxiliary information item
**
**  Arguments:
**    _targetName           Target type name: 'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'
**    _targetEntityName     Target entity ID or name
**    _categoryName         Category name
**    _subCategoryName      Subcategory name
**    _itemNameList         Aux info names to update; delimiter is !
**    _itemValueList        Aux info values; delimiter is !
**    _mode                 Mode: 'add', 'update', 'check_add', 'check_update', or 'check_only'; note that 'add' will update an existing value and 'update' will add new values
**    _message              Output message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   03/27/2002 grk - Initial release
**          12/18/2007 grk - Improved ability to handle target ID if supplied as target name
**          06/30/2008 jds - Added error message to 'Resolve target name and entity name to entity ID' section
**          05/15/2009 jds - Added a return if just performing a check_add or check_update
**          08/21/2010 grk - Use try-catch for error handling
**          02/20/2012 mem - Now using temporary tables to parse _itemNameList and _itemValueList
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/10/2018 mem - Remove invalid check of _mode against check_add or check_update
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to parse_delimited_list_ordered
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/29/2022 mem - Require that _targetEntityName be an integer when _targetName is SamplePrepRequest
**          12/19/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _targetID int;
    _tgtTableName citext;
    _tgtTableNameCol citext;
    _tgtTableIDCol citext;

    _dropTempTables boolean := false;

    _nameCount int;
    _valueCount int;
    _count int := 0;

    _inFld text;
    _entryID int;
    _descriptionID int;
    _vFld text;
    _tVal text;

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, 'undefined_mode')));

        If _mode In ('check_update', 'check_add') Then
            _mode := 'check_only';
        End If;

        If Not _mode In ('add', 'update', 'check_only') Then
            RAISE EXCEPTION 'Invalid _mode: %', _mode;
        End If;

        _targetName       := Trim(Coalesce(_targetName, ''));
        _targetEntityName := Trim(Coalesce(_targetEntityName, ''));
        _categoryName     := Trim(Coalesce(_categoryName, ''));
        _subCategoryName  := Trim(Coalesce(_subCategoryName, ''));
        _itemNameList     := Trim(Coalesce(_itemNameList, ''));
        _itemValueList    := Trim(Coalesce(_itemValueList, ''));

        If _targetName::citext = 'Cell Culture' And Exists (SELECT target_type_id FROM t_aux_info_target WHERE target_type_name = 'Biomaterial') Then
            _targetName := 'Biomaterial';
        End If;

        If _targetName::citext = 'Sample Prep Request' Then
            _targetName := 'SamplePrepRequest';
        End If;

        ---------------------------------------------------
        -- For sample prep requests, _targetEntityName should have a sample prep request ID
        -- For experiments and biomaterial, it can have experiment name, experiment ID, biomaterial name, or biomaterial ID
        -- If the value is an integer, we will assume it is experiment ID or biomaterial ID, since experiment names and biomaterial names should not be integers
        ---------------------------------------------------

        _targetID := public.try_cast(_targetEntityName, null::int);

        If _targetName::citext = 'SamplePrepRequest' And _targetID Is Null Then

            RAISE EXCEPTION 'Cannot update aux info for the sample prep request since argument _targetEntityName is not an integer: %', _targetEntityName;

        ElsIf _targetID Is Null Then

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
                RAISE EXCEPTION 'Target type % not found in t_aux_info_target', _targetName;
            End If;

            If _message ILike 'Switched from T_Cell_Culture to t_biomaterial%' Or
               _message ILike 'Switched column name from%'
            Then
                _message := '';
            End If;

            If _mode <> 'check_only' Then
                ---------------------------------------------------
                -- Resolve target name and entity name to entity ID
                ---------------------------------------------------

                _targetID := public.get_aux_info_entity_id_by_name(_targetName, _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _targetEntityName);

                If Coalesce(_targetID, 0) = 0 Then
                    RAISE EXCEPTION 'Could not resolve target name and entity name to entity ID: "%"', _targetEntityName;
                End If;
            End If;

        End If;

        ---------------------------------------------------
        -- If list is empty, we are done
        ---------------------------------------------------

        If _itemNameList = '' Then
            RETURN;
        End If;

        ---------------------------------------------------
        -- Populate temorary tables using _itemNameList and _itemValueList
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_AuxInfoNames
        (
            EntryID int,
            ItemName text
        );

        CREATE TEMP TABLE Tmp_AuxInfoValues
        (
            EntryID int,
            ItemValue text
        );

        _dropTempTables := true;

        INSERT INTO Tmp_AuxInfoNames (EntryID, ItemName)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_itemNameList, '!', 0)
        ORDER BY Entry_ID;

        INSERT INTO Tmp_AuxInfoValues (EntryID, ItemValue)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_itemValueList, '!', 0)
        ORDER BY Entry_ID;

        SELECT COUNT(*)
        INTO _nameCount
        FROM Tmp_AuxInfoNames;

        SELECT COUNT(*)
        INTO _valueCount
        FROM Tmp_AuxInfoValues;

        ---------------------------------------------------
        -- Process Tmp_AuxInfoNames
        ---------------------------------------------------

        FOR _inFld, _entryID IN
            SELECT ItemName, EntryID
            FROM Tmp_AuxInfoNames
            ORDER BY EntryID
        LOOP

            If Trim(Coalesce(_inFld, '')) = '' Then
                CONTINUE;
            End If;

            _count := _count + 1;

            -- Lookup the value for this aux info entry

            SELECT Trim(Coalesce(ItemValue, ''))
            INTO _vFld
            FROM Tmp_AuxInfoValues
            WHERE EntryID = _entryID;

            If Not FOUND Then
                RAISE EXCEPTION 'Aux info item "%" does not have an associated value (_itemNameList has % % while _itemValueList has % %)',
                                  _inFld,
                                  _nameCount,  public.check_plural(_nameCount,  'item', 'items'),
                                  _valueCount, public.check_plural(_valueCount, 'item', 'items');
            End If;

            -- Resolve item name to aux description ID

            SELECT Item_ID
            INTO _descriptionID
            FROM V_Aux_Info_Definition
            WHERE Target      = _targetName::citext AND
                  Category    = _categoryName::citext AND
                  Subcategory = _subCategoryName::citext AND
                  Item        = _inFld::citext;

            If Not FOUND Then
                If _targetName::citext = 'Dataset' And Not Exists (SELECT item_id FROM v_aux_info_definition WHERE target = 'Dataset') Then
                    RAISE EXCEPTION 'Aux info values are not supported for datasets (every dataset-related aux info definition is inactive)';
                Else
                    RAISE EXCEPTION 'Could not resolve item to ID: aux info "%" with category "%" and subcategory "%"', _inFld, _categoryName, _subCategoryName;
                End If;
            End If;

            If _mode <> 'check_only' Then

                -- If value is blank, delete any existing entry from value table

                If _vFld = '' Then
                    DELETE FROM t_aux_info_value
                    WHERE aux_description_id = _descriptionID AND target_id = _targetID;
                Else

                    -- Does entry exist in value table?

                    SELECT value
                    INTO _tVal
                    FROM t_aux_info_value
                    WHERE aux_description_id = _descriptionID AND
                          target_id = _targetID;

                    -- If entry exists in value table, update it, otherwise insert it

                    If FOUND Then
                        If _tVal Is Distinct From _vFld Then
                            UPDATE t_aux_info_value
                            SET value = _vFld
                            WHERE aux_description_id = _descriptionID AND target_id = _targetID;
                        End If;
                    Else
                        INSERT INTO t_aux_info_value( target_id,
                                                      aux_description_id,
                                                      value )
                        VALUES (_targetID, _descriptionID, _vFld);
                    End If;

                End If;

            End If;

        END LOOP;

        If _dropTempTables Then
            DROP TABLE Tmp_AuxInfoNames;
            DROP TABLE Tmp_AuxInfoValues;
        End If;

        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := _exceptionMessage;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_AuxInfoNames;
    DROP TABLE IF EXISTS Tmp_AuxInfoValues;
END
$$;


ALTER PROCEDURE public.add_update_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _itemnamelist text, IN _itemvaluelist text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _itemnamelist text, IN _itemvaluelist text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_aux_info(IN _targetname text, IN _targetentityname text, IN _categoryname text, IN _subcategoryname text, IN _itemnamelist text, IN _itemvaluelist text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateAuxInfo';


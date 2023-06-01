--
CREATE OR REPLACE PROCEDURE public.add_update_aux_info
(
    _targetName text = '',
    _targetEntityName text = '',
    _categoryName text = '',
    _subCategoryName text = '',
    _itemNameList text = '',
    _itemValueList text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Adds new or updates existing auxiliary information in database
**
**  Arguments:
**    _targetName         Target type name: Experiment, Biomaterial (previously 'Cell Culture'), Dataset, or SamplePrepRequest
**    _targetEntityName   Target entity ID or name
**    _itemNameList       Aux Info names to update; delimiter is !
**    _itemValueList      Aux Info values; delimiter is !
**    _mode               add, update, check_add, check_update, or check_only
**
**  Auth:   grk
**  Date:   03/27/2002 grk - Initial release
**          12/18/2007 grk - Improved ability to handle target ID if supplied as target name
**          06/30/2008 jds - Added error message to 'Resolve target name and entity name to entity ID' section
**          05/15/2009 jds - Added a return if just performing a check_add or check_update
**          08/21/2010 grk - Try-catch for error handling
**          02/20/2012 mem - Now using temporary tables to parse _itemNameList and _itemValueList
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/10/2018 mem - Remove invalid check of _mode against check_add or check_update
**          11/19/2018 mem - Pass 0 to the _maxRows parameter to udfParseDelimitedListOrdered
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column name
**          11/29/2022 mem - Require that _targetEntityName be an integer when _targetName is SamplePrepRequest
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _targetID int := 0;
    _tgtTableName citext;
    _tgtTableNameCol citext;
    _tgtTableIDCol citext;
    _sql text;
    _count int := 0;
    _entryID int := -1;
    _descriptionID int;
    _inFld text;
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

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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
        -- What mode are we in?
        ---------------------------------------------------

        _mode := Lower(Coalesce(_mode, 'undefined_mode'));

        If _mode::citext In ('check_update', 'check_add') Then
            _mode := 'check_only';
        End If;

        If Not _mode::citext In ('add', 'update', 'check_only') Then
            RAISE EXCEPTION 'Invalid _mode: %', _mode;
        End If;

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        _targetName := Trim(Coalesce(_targetName, ''));
        _targetEntityName := Trim(Coalesce(_targetEntityName, ''));
        _categoryName := Trim(Coalesce(_categoryName, ''));
        _subCategoryName := Trim(Coalesce(_subCategoryName, ''));
        _itemNameList := Trim(Coalesce(_itemNameList, ''));
        _itemValueList := Trim(Coalesce(_itemValueList, ''));

        If _targetName::citext = 'Cell Culture' And Exists (Select * From t_aux_info_target Where target_type_name = 'Biomaterial') Then
            _targetName := 'Biomaterial';
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
            --
            SELECT target_table,
                   target_id_column,
                   target_name_column,
                   message
            INTO _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _message
            FROM public.get_aux_info_target_table_info(_targetName);

            If Not FOUND Then
                RAISE EXCEPTION 'Target type % not found in t_aux_info_target', _targetName;
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

        If char_length(_itemNameList) = 0 Then
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

        INSERT INTO Tmp_AuxInfoNames (EntryID, ItemName)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_itemNameList, '!', 0)
        ORDER BY EntryID;

        INSERT INTO Tmp_AuxInfoValues (EntryID, ItemValue)
        SELECT Entry_ID, Value
        FROM public.parse_delimited_list_ordered(_itemValueList, '!', 0)
        ORDER BY EntryID;

        ---------------------------------------------------
        -- Process Tmp_AuxInfoNames
        ---------------------------------------------------

        FOR _inFld IN
            SELECT ItemName
            FROM Tmp_AuxInfoNames
            ORDER BY EntryID
        LOOP

            If Coalesce(_inFld, '')) = '' Then
                CONTINUE;
            End If;

            _count := _count + 1;

            -- Lookup the value for this aux info entry
            --
            _vFld := '';
            --
            SELECT ItemValue
            INTO _vFld
            FROM Tmp_AuxInfoValues
            WHERE EntryID = _entryID;

            -- Resolve item name to aux description ID
            --
            _descriptionID := 0;

            SELECT Item_ID
            INTO _descriptionID
            FROM V_Aux_Info_Definition
            WHERE Target = _targetName AND
                  Category = _categoryName AND
                  Subcategory = _subCategoryName AND
                  Item = _inFld;

            If Not FOUND Then
                RAISE EXCEPTION 'Could not resolve item to ID: "%" for category %, subcategory %', _inFld, _categoryName, _subCategoryName;
            End If;

            If _mode <> 'check_only' Then
            --<c>
                -- If value is blank, delete any existing entry from value table
                --
                If _vFld = '' Then
                    DELETE FROM t_aux_info_value
                    WHERE Aux_Description_ID = _descriptionID AND target_id = _targetID;
                Else
                -- <d>

                    -- Does entry exist in value table?
                    --
                    SELECT value
                    INTO _tVal
                    FROM t_aux_info_value
                    WHERE Aux_Description_ID = _descriptionID AND
                          target_id = _targetID;

                    -- If entry exists in value table, update it
                    -- otherwise insert it
                    --
                    If FOUND Then
                        If _tVal <> _vFld Then
                            UPDATE t_aux_info_value
                            SET value = _vFld
                            WHERE Aux_Description_ID = _descriptionID AND target_id = _targetID;
                        End If;
                    Else
                        INSERT INTO t_aux_info_value( target_id,
                                                     Aux_Description_ID,
                                                     value )
                        VALUES (_targetID, _descriptionID, _vFld);
                    End If;

                End If; -- </d>

            End If; -- </c>

        END LOOP;

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

COMMENT ON PROCEDURE public.add_update_aux_info IS 'AddUpdateAuxInfo';

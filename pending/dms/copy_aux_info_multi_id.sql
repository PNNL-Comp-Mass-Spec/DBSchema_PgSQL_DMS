--
CREATE OR REPLACE PROCEDURE public.copy_aux_info_multi_id
(
    _targetName text,
    _targetEntityIDList text,
    _categoryName text,
    _subCategoryName text,
    _sourceEntityID int,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copies aux info from a source item to multiple targets
**
**  Arguments:
**    _targetName           'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'; see See T_Aux_Info_Target
**    _targetEntityIDList   Comma separated list of entity IDs; must all be of the same type
**    _categoryName         'Lysis Method', 'Denaturing Conditions', etc.; see T_Aux_Info_Category; Note: Ignored if _mode = 'copyAll'
**    _subCategoryName      'Procedure', 'Reagents', etc.; see T_Aux_Info_Subcategory; Note: Ignored if _mode = 'copyAll'
**    _sourceEntityID       ID of the source to copy information from
**    _mode                 'copyCategory', 'copySubcategory', 'copyAll'
**
**  Auth:   grk
**  Date:   01/27/2003
**          09/27/2007 mem - Extended CopyAuxInfo to accept a comma separated list of entity IDs to process, rather than a single entity name (Ticket #538)
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column names
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _sql text;
    _matchVal int;
    _tgtTableName text;
    _tgtTableNameCol text;
    _tgtTableIDCol text;
    _idList text;
    _idListMaxLength int;
    _transName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If Not _mode::citext In ('copyCategory', 'copySubcategory', 'copyAll') Then

        _msg := 'Mode must be copyCategory, copySubcategory, or copyAll';
        RAISE EXCEPTION '%', _msg;

        _message := 'message';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

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

        _returnCode := 'U5202';
    End If;

    ---------------------------------------------------
    -- Validate that the source entity ID is present in _tgtTableName
    ---------------------------------------------------

    _matchVal := Null;

    _sql := ' SELECT ' || quote_ident(_tgtTableIDCol) ||
            ' FROM '   || quote_ident(_tgtTableName)  ||
            ' WHERE '  || quote_ident(_tgtTableIDCol) || ' = $1';

    EXECUTE _sql
    INTO _matchVal
    USING _sourceEntityID;    -- $1 will be replaced with the text in _targetEntityName

    If _matchVal Is Null Then
        _message := format('Source ID %s not found in %s', _sourceEntityID, _tgtTableName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate a temporary table with the IDs in _targetEntityIDList
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_TargetEntities (
        EntityID int,
        Valid int Default 0
    );

    INSERT INTO Tmp_TargetEntities( EntityID,
                                    Valid )
    SELECT LookupQ.value, 0 as Valid
    FROM ( SELECT DISTINCT public.try_cast(value, null::int) as value
           FROM public.parse_delimited_list ( _targetEntityIDList )
         ) LookupQ
    WHERE Not LookupQ.Value Is Null;

    ---------------------------------------------------
    -- Look for unknown IDs in Tmp_TargetEntities
    ---------------------------------------------------

    _sql := ' UPDATE Tmp_TargetEntities' ||
            ' SET Valid = 1' ||
            ' FROM Tmp_TargetEntities TE INNER JOIN ' ||
            quote_ident(_tgtTableName) || ' T ON TE.EntityID = T.' || quote_ident(_tgtTableIDCol);

    EXECUTE _sql;

    -- Create a list of Entitites that have Valid = 0 in Tmp_TargetEntities
    _idListMaxLength := 200;

    SELECT string_agg(EntityID::text, ', ')
    INTO _idList
    FROM Tmp_TargetEntities
    WHERE Valid = 0;

    If Coalesce(_idList, '') <> '' Then
        -- Unknown entries found; inform the caller

        -- Make sure the list is no longer than _idListMaxLength + 15 characters
        If char_length(_idList) > _idListMaxLength + 15 Then
            _idList := Left(_idList, _idListMaxLength + 15);
        End If;

        SELECT COUNT(*)
        INTO _myRowCount
        FROM Tmp_TargetEntities
        WHERE Valid = 0;

        If _myRowCount = 1 Then
            _message := format('Error: Target ID %s is not defined in %s; unable to continue', _idList, _tgtTableName);
        Else
            _message := format('Error: found %s invalid target IDs not defined in %s: %s', _myRowCount, _tgtTableName, _idList);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Generate a list of the IDs in Tmp_TargetEntities
    ---------------------------------------------------

    SELECT string_agg(EntityID::text, ', ')
    INTO _idList
    FROM Tmp_TargetEntities
    ORDER BY EntityID;

    If Coalesce(_idList, '') <> '' Then

        -- Make sure the list is no longer than _idListMaxLength + 15 characters
        If char_length(_idList) > _idListMaxLength + 15 Then
            _idList := Left(_idList, _idListMaxLength + 15);
        End If;
    Else
        -- No entries found
        _message := 'Error: Target ID list was empty (or invalid); unable to continue';

        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name and category
    -- from given source target entity
    -- to given destination entities
    ---------------------------------------------------

    If _mode::citext = 'copyCategory' Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (target_id IN ( SELECT EntityID
                              FROM Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) ))

        -- Insert new values
        --
        INSERT INTO t_aux_info_value( target_id,
                                     Aux_Description_ID,
                                     value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE (AI.target_id = _sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = _targetName) AND
                                                (Category = _categoryName) ))

        COMMIT;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name and category and subcategory
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode::citext = 'copySubcategory' Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (target_id IN ( SELECT EntityID
                              FROM Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) AND
                                             (Category = _categoryName) AND
                                             (Subcategory = _subCategoryName) ))

        -- Insert new values
        --
        INSERT INTO t_aux_info_value( target_id,
                                     Aux_Description_ID,
                                     value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE (AI.target_id = _sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = _targetName) AND
                                                (Category = _categoryName) AND
                                                (Subcategory = _subCategoryName) ))

        COMMIT;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table
    -- for given target name
    -- from given source target entity
    -- to given destination entity
    ---------------------------------------------------

    If _mode::citext = 'copyAll' Then

        -- Delete any existing values
        --
        DELETE FROM t_aux_info_value
        WHERE (target_id IN ( SELECT EntityID
                              FROM Tmp_TargetEntities )) AND
              (Aux_Description_ID IN ( SELECT Item_ID
                                       FROM V_Aux_Info_Definition
                                       WHERE (Target = _targetName) ))

        INSERT INTO t_aux_info_value( target_id,
                                     Aux_Description_ID,
                                     value )
        SELECT TE.EntityID AS Target_ID,
               AI.Aux_Description_ID,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE (AI.target_id = _sourceEntityID) AND
              (AI.Aux_Description_ID IN ( SELECT Item_ID
                                          FROM V_Aux_Info_Definition
                                          WHERE (Target = _targetName) ))

        COMMIT;
    End If;

    DROP TABLE Tmp_TargetEntities;
END
$$;

COMMENT ON PROCEDURE public.copy_aux_info_multi_id IS 'CopyAuxInfoMultiID';

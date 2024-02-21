--
-- Name: copy_aux_info_multi_id(text, text, text, text, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.copy_aux_info_multi_id(IN _targetname text, IN _targetentityidlist text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityid integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Copy aux info from a source item to multiple targets
**
**  Arguments:
**    _targetName           Target type name: 'Experiment', 'Biomaterial' (previously 'Cell Culture'), 'Dataset', or 'SamplePrepRequest'; see t_aux_info_target
**    _targetEntityIDList   Comma-separated list of entity IDs; must all be of the same target type
**    _categoryName         Category name, e.g. 'Lysis Method', 'Denaturing Conditions', etc.; see t_aux_info_category;    ignored if _mode is 'CopyAll'
**    _subCategoryName      Subcategory name, e.g. 'Procedure', 'Reagents', etc.;              see t_aux_info_subcategory; ignored if _mode is 'CopyAll' or 'CopySubcategory'
**    _sourceEntityID       ID of the source entity to copy information from
**    _mode                 Mode: 'CopyCategory', 'CopySubcategory', 'CopyAll'
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   01/27/2003
**          09/27/2007 mem - Extended CopyAuxInfo to accept a comma-separated list of entity IDs to process, rather than a single entity name (Ticket #538)
**          06/16/2022 mem - Auto change _targetName from 'Cell Culture' to 'Biomaterial' if T_Aux_Info_Target has an entry for 'Biomaterial
**          07/06/2022 mem - Use new aux info definition view name
**          08/15/2022 mem - Use new column names
**          11/21/2022 mem - Use new column names in t_aux_info_target
**          12/04/2023 mem - Ported to PostgreSQL
**          01/17/2024 mem - Remove unreachable code
**
*****************************************************/
DECLARE
    _invalidCount int;
    _sql text;
    _matchVal int;
    _tgtTableName text;
    _tgtTableNameCol text;
    _tgtTableIDCol text;
    _idList text;
    _idListMaxLength int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    -- On the DMS website, file app/Views/special/aux_info_entry.php defines the modes as
    -- 'copyCategory', 'copySubcategory', and 'copyAll'

    If Not _mode::citext In ('CopyCategory', 'CopySubcategory', 'CopyAll') Then
        _returnCode := 'U5201';
        _message := 'Mode must be copyCategory, copySubcategory, or copyAll';
        RAISE EXCEPTION '%', _message;
    End If;

    If _targetName::citext = 'Cell Culture' And Exists (SELECT target_type_id FROM t_aux_info_target WHERE target_type_name = 'Biomaterial') Then
        _targetName := 'Biomaterial';
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
    -- Validate that the source entity ID is present in _tgtTableName
    ---------------------------------------------------

    _matchVal := Null;

    _sql := format('SELECT %s FROM %s WHERE %s = $1',
                    quote_ident(_tgtTableIDCol),
                    quote_ident(_tgtTableName),
                    quote_ident(_tgtTableIDCol));

    EXECUTE _sql
    INTO _matchVal
    USING _sourceEntityID;    -- $1 will be replaced with the text in _sourceEntityID

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
        Valid boolean
    );

    INSERT INTO Tmp_TargetEntities( EntityID,
                                    Valid )
    SELECT LookupQ.value, false AS Valid
    FROM ( SELECT DISTINCT public.try_cast(value, null::int) AS value
           FROM public.parse_delimited_list(_targetEntityIDList)
         ) LookupQ
    WHERE NOT LookupQ.Value IS NULL;

    ---------------------------------------------------
    -- Look for unknown IDs in Tmp_TargetEntities
    ---------------------------------------------------

    _sql := format('UPDATE Tmp_TargetEntities TE '
                   'SET Valid = true '
                   'FROM %s T '
                   'WHERE TE.EntityID = T.%s',
                         quote_ident(_tgtTableName), quote_ident(_tgtTableIDCol));

    EXECUTE _sql;

    -- Create a list of entitites that have Valid = false in Tmp_TargetEntities
    _idListMaxLength := 200;

    SELECT string_agg(EntityID::text, ', ' ORDER BY EntityID)
    INTO _idList
    FROM Tmp_TargetEntities
    WHERE NOT Valid;

    If Coalesce(_idList, '') <> '' Then
        -- Unknown entries found; inform the caller

        -- Make sure the list is no longer than _idListMaxLength + 15 characters
        If char_length(_idList) > _idListMaxLength + 15 Then
            _idList := Left(_idList, _idListMaxLength + 15);
        End If;

        SELECT COUNT(*)
        INTO _invalidCount
        FROM Tmp_TargetEntities
        WHERE NOT Valid;

        If _invalidCount = 1 Then
            _message := format('Error: Target ID %s is not defined in %s; unable to continue', _idList, _tgtTableName);
        Else
            _message := format('Error: found %s invalid target IDs not defined in %s: %s', _invalidCount, _tgtTableName, _idList);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5204';

        DROP TABLE Tmp_TargetEntities;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Generate a list of the IDs in Tmp_TargetEntities
    ---------------------------------------------------

    SELECT string_agg(EntityID::text, ', ' ORDER BY EntityID)
    INTO _idList
    FROM Tmp_TargetEntities;

    If Coalesce(_idList, '') = '' Then
        _message := 'Error: Target ID list was empty (or invalid); unable to continue';

        RAISE WARNING '%', _message;

        _returnCode := 'U5205';

        DROP TABLE Tmp_TargetEntities;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Copy existing values in aux info table for given target name and category
    -- from given source target entity to given destination entities
    ---------------------------------------------------

    If _mode = Lower('CopyCategory') Then

        -- Delete any existing values

        DELETE FROM t_aux_info_value
        WHERE target_id IN ( SELECT EntityID FROM Tmp_TargetEntities ) AND
              aux_description_id IN ( SELECT Item_ID
                                      FROM V_Aux_Info_Definition
                                      WHERE Target = _targetName AND
                                            Category = _categoryName );

        -- Insert new values

        INSERT INTO t_aux_info_value (target_id,
                                      aux_description_id,
                                      value )
        SELECT TE.EntityID AS Target_ID,
               AI.aux_description_id,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE AI.target_id = _sourceEntityID AND
              AI.aux_description_id IN ( SELECT Item_ID
                                         FROM V_Aux_Info_Definition
                                         WHERE Target = _targetName AND
                                               Category = _categoryName );
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
        WHERE target_id IN ( SELECT EntityID
                             FROM Tmp_TargetEntities ) AND
              aux_description_id IN ( SELECT Item_ID
                                      FROM V_Aux_Info_Definition
                                      WHERE Target = _targetName AND
                                            Category = _categoryName AND
                                            Subcategory = _subCategoryName );

        -- Insert new values

        INSERT INTO t_aux_info_value (target_id,
                                      aux_description_id,
                                      value )
        SELECT TE.EntityID AS Target_ID,
               AI.aux_description_id,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE AI.target_id = _sourceEntityID AND
              AI.aux_description_id IN ( SELECT Item_ID
                                         FROM V_Aux_Info_Definition
                                         WHERE Target = _targetName AND
                                               Category = _categoryName AND
                                               Subcategory = _subCategoryName );
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
        WHERE target_id IN ( SELECT EntityID
                              FROM Tmp_TargetEntities ) AND
              aux_description_id IN ( SELECT Item_ID
                                      FROM V_Aux_Info_Definition
                                      WHERE Target = _targetName );

        INSERT INTO t_aux_info_value (target_id,
                                      aux_description_id,
                                      value )
        SELECT TE.EntityID AS Target_ID,
               AI.aux_description_id,
               AI.value
        FROM t_aux_info_value AI
             CROSS JOIN Tmp_TargetEntities TE
        WHERE AI.target_id = _sourceEntityID AND
              AI.aux_description_id IN ( SELECT Item_ID
                                         FROM V_Aux_Info_Definition
                                         WHERE Target = _targetName );
    End If;

    DROP TABLE Tmp_TargetEntities;
END
$_$;


ALTER PROCEDURE public.copy_aux_info_multi_id(IN _targetname text, IN _targetentityidlist text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityid integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_aux_info_multi_id(IN _targetname text, IN _targetentityidlist text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityid integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.copy_aux_info_multi_id(IN _targetname text, IN _targetentityidlist text, IN _categoryname text, IN _subcategoryname text, IN _sourceentityid integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'CopyAuxInfoMultiID';


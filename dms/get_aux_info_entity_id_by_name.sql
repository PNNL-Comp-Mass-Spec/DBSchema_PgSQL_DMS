--
-- Name: get_aux_info_entity_id_by_name(text, text, text, text, text, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aux_info_entity_id_by_name(_targettypename text, _targettablename text, _targettableidcol text, _targettablenamecol text, _targetentityname text, _showdebug boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Lookup entity for the given entity name using the specified table
**      For example, determine the experiment ID given experiment name
**
**      The table and column names in _targetTableName, _targetTableIDCol, and _targetTableNameCol
**      come from t_aux_info_target and should have been looked up
**      by querying function get_aux_info_target_table_info
**
**  Arguments:
**    _targetTypeName       Should be Experiment, Biomaterial, Dataset, or SamplePrepRequest
**    _targetTableName      Table name to query (t_experiments, t_biomaterial, t_sample_prep_request, or t_dataset)
**    _targetTableIDCol     Column name with the entity ID value (exp_id, biomaterial_id, prep_request_id, or dataset_id)
**    _targetTableNameCol   Column name with the entity name (experiment, biomaterial, prep_request, or dataset)
**    _targetEntityName     Entity name to look for
**
**  Returns:
**      Entity ID value if found, otherwise 0
**
**  Auth:   mem
**  Date:   11/29/2022 mem - Initial release
**
*****************************************************/
DECLARE
    _sql text;
    _targetID int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _targetTypeName := Coalesce(_targetTypeName, '');
    _showDebug := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Resolve target name and entity name to entity ID
    ---------------------------------------------------

    If _targetTypeName::citext = 'SamplePrepRequest' And _targetTableNameCol::citext = 'prep_request_id' Then

        _sql := ' SELECT ' || quote_ident(_targetTableIDCol)   || '::text' ||
                ' FROM '   || quote_ident(_targetTableName)    ||
                ' WHERE '  || quote_ident(_targetTableNameCol) || ' = $1::int';

    Else
        _sql := ' SELECT ' || quote_ident(_targetTableIDCol)   ||
                ' FROM '   || quote_ident(_targetTableName)    ||
                ' WHERE '  || quote_ident(_targetTableNameCol) || ' = $1';
    End If;

    If _showDebug Then
        RAISE INFO '%', trim(_sql);
    End If;

    EXECUTE _sql
    INTO _targetID
    USING _targetEntityName;    -- $1 will be replaced with the text in _targetEntityName

    If _targetID Is Null Then
        RETURN 0;
    End If;

    RETURN _targetID;
END
$_$;


ALTER FUNCTION public.get_aux_info_entity_id_by_name(_targettypename text, _targettablename text, _targettableidcol text, _targettablenamecol text, _targetentityname text, _showdebug boolean) OWNER TO d3l243;


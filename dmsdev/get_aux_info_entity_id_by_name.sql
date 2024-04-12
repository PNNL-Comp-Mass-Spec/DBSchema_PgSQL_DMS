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
**      by querying function get_aux_info_target_table_info()
**
**  Arguments:
**    _targetTypeName       Should be Experiment, Biomaterial, Dataset, or SamplePrepRequest
**    _targetTableName      Table name to query                  (t_experiments, t_biomaterial,    t_sample_prep_request, or t_dataset)
**    _targetTableIDCol     Column name with the entity ID value (exp_id,        biomaterial_id,   prep_request_id,       or dataset_id)
**    _targetTableNameCol   Column name with the entity name     (experiment,    biomaterial_name, prep_request_id,       or dataset)
**                          Aux info for sample prep requests is tracked by prep request ID, and not request name
**    _targetEntityName     Entity name to look for
**
**  Returns:
**      Entity ID value if found, otherwise 0
**
**  Auth:   mem
**  Date:   11/29/2022 mem - Initial release
**          05/31/2023 mem - Use format() for string concatenation
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          09/15/2023 mem - Trim whitespace from _targetEntityName and cast to citext
**
*****************************************************/
DECLARE
    _sql text;
    _targetID int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _targetTypeName     := Trim(Coalesce(_targetTypeName, ''));
    _targetTableName    := Trim(Coalesce(_targetTableName, ''));
    _targetTableIDCol   := Trim(Coalesce(_targetTableIDCol, ''));
    _targetTableNameCol := Trim(Coalesce(_targetTableNameCol, ''));
    _targetEntityName   := Trim(Coalesce(_targetEntityName, ''));
    _showDebug          := Coalesce(_showDebug, false);

    ---------------------------------------------------
    -- Resolve target name and entity name to entity ID
    ---------------------------------------------------

    If _targetTypeName::citext = 'SamplePrepRequest' And _targetTableNameCol::citext = 'prep_request_id' Then

        _sql := format('SELECT %s FROM %s WHERE %s = $1::int',
                       quote_ident(_targetTableIDCol),
                       quote_ident(_targetTableName),
                       quote_ident(_targetTableNameCol));
    Else
        _sql := format('SELECT %s FROM %s WHERE %s = $1',
                       quote_ident(_targetTableIDCol),
                       quote_ident(_targetTableName),
                       quote_ident(_targetTableNameCol));
    End If;

    If _showDebug Then
        RAISE INFO '%', trim(_sql);
    End If;

    EXECUTE _sql
    INTO _targetID
    USING _targetEntityName::citext;    -- $1 will be replaced with the text in _targetEntityName

    If _targetID Is Null Then
        RETURN 0;
    End If;

    RETURN _targetID;
END
$_$;


ALTER FUNCTION public.get_aux_info_entity_id_by_name(_targettypename text, _targettablename text, _targettableidcol text, _targettablenamecol text, _targetentityname text, _showdebug boolean) OWNER TO d3l243;


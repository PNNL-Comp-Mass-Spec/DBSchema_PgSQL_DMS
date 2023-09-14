--
-- Name: get_aux_info_target_table_info(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aux_info_target_table_info(_targettypename text) RETURNS TABLE(target_table public.citext, target_id_column public.citext, target_name_column public.citext, message public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Lookup the target table info in t_aux_info_target for _targetTypeName
**
**  Arguments:
**    _targetTypeName       Should be Experiment, Biomaterial, Dataset, or SamplePrepRequest
*
**  Returns:
**    One-row table with the name of the target table and
**    the column names of the ID column and entity name column in that table
**
**  Auth:   mem
**  Date:   11/29/2022 mem - Initial release
**          03/22/2023 mem - Use lowercase strings in comparisons
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _tgtTableName citext;
    _tgtTableIDCol citext;
    _tgtTableNameCol citext;
    _message citext;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _targetTypeName := Trim(Coalesce(_targetTypeName, ''));

    ---------------------------------------------------
    -- Resolve target name to target ID using the entity's data table, as defined in t_aux_info_target
    ---------------------------------------------------

    SELECT Lower(T.target_table),
           Lower(T.target_id_col),
           Lower(T.target_name_col)
    INTO _tgtTableName, _tgtTableIDCol, _tgtTableNameCol
    FROM t_aux_info_target T
    WHERE T.target_type_name = _targetTypeName::citext;

    If Not FOUND Then
        RAISE WARNING '%', format('Target type %s not found in t_aux_info_target', _targetTypeName);
        RETURN;
    End If;

    If _tgtTableName = 't_cell_culture' Then

        -- Auto-switch the target table to t_biomaterial if T_Cell_Culture does not exist but t_biomaterial does
        If Not Exists (Select * From information_schema.tables Where table_name::citext = 'T_Cell_Culture' And table_type::citext = 'BASE TABLE')
           And Exists (Select * From information_schema.tables Where table_name::citext = 't_biomaterial'  And table_type::citext = 'BASE TABLE') Then

            _tgtTableName    := 't_biomaterial';
            _tgtTableIDCol   := 'biomaterial_id';
            _tgtTableNameCol := 'biomaterial_name';

            _message := 'Switched from T_Cell_Culture to t_biomaterial';
        End If;

    ElsIf _tgtTableName = 't_experiments' And _tgtTableNameCol = 'experiment_num' Then
        _tgtTableNameCol := 'experiment';
        _message := 'Switched column name from Experiment_Num to experiment';

    ElsIf _tgtTableName = 't_dataset' And _tgtTableNameCol = 'dataset_num' Then
        _tgtTableNameCol := 'dataset';
        _message := 'Switched column name from Dataset_Num to dataset';

    ElsIf _tgtTableName = 't_sample_prep_request' And _tgtTableNameCol = 'id' Then
        _tgtTableIDCol := 'prep_request_id';
        _tgtTableNameCol := 'prep_request_id';
        _message := 'Switched column name from ID to prep_request_id';

    End If;

    RETURN QUERY
    SELECT _tgtTableName, _tgtTableIDCol, _tgtTableNameCol, _message;
END
$$;


ALTER FUNCTION public.get_aux_info_target_table_info(_targettypename text) OWNER TO d3l243;


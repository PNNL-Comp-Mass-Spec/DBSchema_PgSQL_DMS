--
-- Name: get_requested_runs_from_item_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text DEFAULT 'Batch_ID'::text) RETURNS TABLE(request_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a table of the requested runs associated with
**      the comma-separated list of item IDs
**
**  Arguments:
**    _itemList     Comma separated list of item IDs
**    _itemType     Item type: Batch_ID, Requested_Run_ID, Dataset_Name, Dataset_ID, Experiment_Name, Experiment_ID, or Data_Package_ID
**
**  Example usage:
**      SELECT request_id FROM get_requested_runs_from_item_list ('1400,1401', 'Requested_Run_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list ('MNST_bil_E_30_470_R1_MRM_01_20220811, MNST_bil_J_10_990_R2_01_20220811', 'Dataset_Name');
**      SELECT request_id FROM get_requested_runs_from_item_list ('1066204,1066226', 'Dataset_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list ('MNST_bil_A_10-490_R1', 'Experiment_Name');
**      SELECT request_id FROM get_requested_runs_from_item_list ('332440,238638', 'Experiment_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list ('3324', 'Data_Package_ID');
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - Initial release
**          03/12/2012 grk - Added 'Data_Package_ID' mode
**          10/19/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use ElsIf for Else If
**          06/07/2023 mem - Add Order By to string_agg()
**
*****************************************************/
DECLARE
    _message text;
    _invalidItems text;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    IF Coalesce(_itemType, '') = '' Then
        _message := 'Item Type may not be blank';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    IF char_length(_itemList) = 0 Then
        _message := 'Item List may not be blank';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    -----------------------------------------
    -- convert item list into temp table
    -----------------------------------------
    --
    CREATE TEMP TABLE Tmp_Items (
        Item text
    );

    INSERT INTO Tmp_Items (Item)
    SELECT Value
    FROM public.parse_delimited_list(_itemList);

    -----------------------------------------
    -- Validate the list items
    -----------------------------------------

    _invalidItems := '';

    If _itemType::citext = 'Batch_ID'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT batch_id::text AS Item FROM t_requested_run_batches);

    ElsIf _itemType::citext = 'Requested_Run_ID'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT t_requested_run.request_id::text AS Item FROM t_requested_run);

    ElsIf _itemType::citext = 'Dataset_Name'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT dataset FROM t_dataset);

    ElsIf _itemType::citext = 'Dataset_ID'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT dataset_id::text AS Item FROM t_dataset);

    ElsIf _itemType::citext = 'Experiment_Name'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT experiment FROM t_experiments);

    ElsIf _itemType::citext = 'Experiment_ID'::citext Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE Item NOT IN (SELECT exp_id::text AS Item FROM t_experiments);

    ElsIf _itemType::citext = 'Data_Package_ID'::citext Then
        -- Assume valid
        _invalidItems := '';
    End If;

    If _invalidItems <> '' Then
        If position(',' in _invalidItems) > 0 Then
            _message := format('"%s" are not valid %ss', _invalidItems, replace(_itemType, '_', ' '));
        Else
            _message := format('"%s" is not a valid %s', _invalidItems, replace(_itemType, '_', ' '));
        End If;

        RAISE WARNING '%', _message;
    End If;

    -----------------------------------------
    -- Return requsets runs based on items in list
    -----------------------------------------
    --
    If _itemType::citext = 'Batch_ID'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE batch_id IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Requested_Run_ID'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Request IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Dataset_Name'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Dataset IN (SELECT Item FROM Tmp_Items);

    ElsIf _itemType::citext = 'Dataset_ID'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Dataset_ID IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Experiment_Name'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Experiment IN (SELECT Item FROM Tmp_Items);

    ElsIf _itemType::citext = 'Experiment_ID'::citext Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Experiment_ID IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Data_Package_ID'::citext Then
        RETURN QUERY
        SELECT DISTINCT TR.request_id
        FROM t_requested_run TR
        INNER join dpkg.v_data_package_dataset_export DS ON TR.dataset_id = DS.dataset_id
        WHERE Data_Package_ID IN (SELECT try_cast(Item, 0) FROM Tmp_Items);
    End If;

    DROP TABLE Tmp_Items;
END
$$;


ALTER FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_runs_from_item_list(_itemlist text, _itemtype text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text) IS 'GetRequestedRunsFromItemList';


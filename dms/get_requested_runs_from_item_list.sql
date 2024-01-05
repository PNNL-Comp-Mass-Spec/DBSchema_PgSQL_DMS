--
-- Name: get_requested_runs_from_item_list(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text DEFAULT 'Batch_ID'::text) RETURNS TABLE(request_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return a table of the requested runs associated with the comma-separated list of request IDs
**
**  Arguments:
**    _itemList     Comma-separated list of item IDs
**    _itemType     Item type: Batch_ID, Requested_Run_ID, Dataset_Name, Dataset_ID, Experiment_Name, Experiment_ID, or Data_Package_ID
**
**  Example usage:
**      SELECT request_id FROM get_requested_runs_from_item_list('1400,1401', 'Requested_Run_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list('MNST_bil_E_30_470_R1_MRM_01_20220811, MNST_bil_J_10_990_R2_01_20220811', 'Dataset_Name');
**      SELECT request_id FROM get_requested_runs_from_item_list('1066204,1066226', 'Dataset_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list('MNST_bil_A_10-490_R1', 'Experiment_Name');
**      SELECT request_id FROM get_requested_runs_from_item_list('332440,238638', 'Experiment_ID');
**      SELECT request_id FROM get_requested_runs_from_item_list('3324', 'Data_Package_ID');
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - Initial release
**          03/12/2012 grk - Added 'Data_Package_ID' mode
**          10/19/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use ElsIf for Else If
**          06/07/2023 mem - Add ORDER BY to string_agg()
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          07/27/2023 mem - Use table alias when referencing column
**          08/16/2023 mem - Update table alias
**          08/17/2023 mem - Use renamed column data_pkg_id in V_Data_Package_Dataset_Export
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          09/07/2023 mem - Update warning messages
**          09/11/2023 mem - Adjust capitalization of keywords
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _message text;
    _invalidItems text;
BEGIN
    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    If Trim(Coalesce(_itemType, '')) = '' Then
        _message := 'Item type must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Trim(Coalesce(_itemList)) = '' Then
        _message := 'Item list must be specified';
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    -----------------------------------------
    -- convert item list into temp table
    -----------------------------------------

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

    If _itemType::citext = 'Batch_ID' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT batch_id::text AS Item FROM t_requested_run_batches);

    ElsIf _itemType::citext = 'Requested_Run_ID' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT t_requested_run.request_id::text AS Item FROM t_requested_run);

    ElsIf _itemType::citext = 'Dataset_Name' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT dataset FROM t_dataset);

    ElsIf _itemType::citext = 'Dataset_ID' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT dataset_id::text AS Item FROM t_dataset);

    ElsIf _itemType::citext = 'Experiment_Name' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT experiment FROM t_experiments);

    ElsIf _itemType::citext = 'Experiment_ID' Then
        SELECT string_agg(Item, ', ' ORDER BY Item)
        INTO _invalidItems
        FROM Tmp_Items
        WHERE NOT Item IN (SELECT exp_id::text AS Item FROM t_experiments);

    ElsIf _itemType::citext = 'Data_Package_ID' Then
        -- Assume valid
        _invalidItems := '';
    End If;

    If _invalidItems <> '' Then
        If Position(',' In _invalidItems) > 0 Then
            _message := format('"%s" are not valid %ss', _invalidItems, replace(_itemType, '_', ' '));
        Else
            _message := format('"%s" is not a valid %s', _invalidItems, replace(_itemType, '_', ' '));
        End If;

        RAISE WARNING '%', _message;
    End If;

    -----------------------------------------
    -- Return requested runs based on items in list
    -----------------------------------------

    If _itemType::citext = 'Batch_ID' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE batch_id IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Requested_Run_ID' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Request IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Dataset_Name' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Dataset IN (SELECT Item FROM Tmp_Items);

    ElsIf _itemType::citext = 'Dataset_ID' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Dataset_ID IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Experiment_Name' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Experiment IN (SELECT Item FROM Tmp_Items);

    ElsIf _itemType::citext = 'Experiment_ID' Then
        RETURN QUERY
        SELECT Request
        FROM V_Requested_Run_Unified_List
        WHERE Experiment_ID IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);

    ElsIf _itemType::citext = 'Data_Package_ID' Then
        RETURN QUERY
        SELECT DISTINCT RR.request_id
        FROM t_requested_run RR
             INNER JOIN dpkg.V_Data_Package_Dataset_Export DPDE
               ON RR.dataset_id = DPDE.dataset_id
        WHERE DPDE.data_pkg_id IN (SELECT public.try_cast(Item, 0) FROM Tmp_Items);
    End If;

    DROP TABLE Tmp_Items;
END
$$;


ALTER FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text) OWNER TO d3l243;

--
-- Name: FUNCTION get_requested_runs_from_item_list(_itemlist text, _itemtype text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_requested_runs_from_item_list(_itemlist text, _itemtype text) IS 'GetRequestedRunsFromItemList';


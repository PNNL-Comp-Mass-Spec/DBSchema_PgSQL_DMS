--
-- Name: refresh_data_package_items_using_dms(integer, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.refresh_data_package_items_using_dms(IN _packageid integer, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates metadata for items associated with the given data package
**
**  Arguments:
**    _packageID    Data package ID
**   _showDebug     When true, show the number of updated rows (using RAISE INFO)
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - Changed size of item list to max
**          03/07/2012 grk - Changed data type of _itemList from varchar(max) to text
**          08/16/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _message text;
BEGIN
    _message := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _packageID := Coalesce(_packageID, 0);
    _showDebug := Coalesce(_showDebug, false);

    If _showDebug Then
        RAISE INFO '';
    End If;

    If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _packageID) Then
        _message := format('Data package ID %s not found in dpkg.t_data_package', _packageID);
        RAISE WARNING '%', _message
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the experiment name associated with each dataset
    ---------------------------------------------------

    UPDATE dpkg.t_data_package_datasets Target
    SET experiment = E.Experiment
    FROM public.t_dataset DS INNER JOIN
         public.t_experiments E ON DS.Exp_ID = E.Exp_ID
    WHERE Target.data_pkg_id = _packageID And
          Target.dataset_id = DS.Dataset_ID And
          Target.experiment Is Distinct From E.Experiment;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _message := format('Updated the experiment name for %s %s associated with data package %s',
                           _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'), _packageID);

        CALL public.post_log_entry ('Info', _message, 'Refresh_Data_Package_Items_Using_DMS', 'dpkg');

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
    ElsIf _showDebug And Exists (SELECT data_pkg_id FROM dpkg.t_data_package_datasets WHERE data_pkg_id = _packageID) Then
        RAISE INFO 'Datasets in t_data_package_datasets all have the correct experiment name for data package ID %', _packageID;
    End If;

    ---------------------------------------------------
    -- Update the campaign name associated with biomaterial (cell culture) entities
    ---------------------------------------------------

    UPDATE dpkg.t_data_package_biomaterial Target
    SET campaign = C.Campaign
    FROM public.t_campaign C INNER JOIN
         public.t_biomaterial B ON C.Campaign_ID = B.Campaign_ID
    WHERE Target.data_pkg_id = _packageID AND
          Target.biomaterial_id = B.biomaterial_id AND
          Target.campaign <> C.Campaign;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _message := format('Updated the campaign name for %s biomaterial %s associated with data package %s',
                           _updateCount, public.check_plural(_updateCount, 'item', 'items'), _packageID);

        CALL public.post_log_entry ('Info', _message, 'Refresh_Data_Package_Items_Using_DMS', 'dpkg');

        If _showDebug Then
            RAISE INFO '%', _message;
        End If;
    ElsIf _showDebug And Exists (SELECT data_pkg_id FROM dpkg.t_data_package_biomaterial WHERE data_pkg_id = _packageID) Then
        RAISE INFO 'Biomaterial in t_data_package_biomaterial all have the correct campaign name for data package ID %', _packageID;
    End If;

END
$$;


ALTER PROCEDURE dpkg.refresh_data_package_items_using_dms(IN _packageid integer, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE refresh_data_package_items_using_dms(IN _packageid integer, IN _showdebug boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.refresh_data_package_items_using_dms(IN _packageid integer, IN _showdebug boolean) IS 'RefreshDataPackageItemsUsingDMS';


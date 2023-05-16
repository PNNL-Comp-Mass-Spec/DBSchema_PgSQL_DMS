--
CREATE OR REPLACE PROCEDURE dpkg.refresh_data_package_items_using_dms
(
    _packageID int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates metadata for items associated with the given data package
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - Changed size of item list to max
**          03/07/2012 grk - Changed data type of _itemList from varchar(max) to text
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Update the experiment name associated with each dataset
    ---------------------------------------------------
    --
    UPDATE dpkg.t_data_package_datasets
    SET experiment = E.Experiment_Num
    FROM public.T_Dataset DS INNER JOIN
         public.T_Experiments E ON DS.Exp_ID = E.Exp_ID AND Target.Experiment <> E.Experiment_Num
    WHERE Target.Data_Package_ID = _packageID And
          Target.Dataset_ID = DS.Dataset_ID;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount > 0 Then
        _message := 'Updated the experiment name for ' || _myRowCount::text || ' datasets associated with data package ' || _packageID::text;

        Call public.post_log_entry ('Info', _message, 'Refresh_Data_Package_Items_Using_DMS', 'dpkg');
    End If;

    ---------------------------------------------------
    -- Update the campaign name associated with biomaterial (cell culture) entities
    ---------------------------------------------------
    --
    UPDATE dpkg.t_data_package_biomaterial
    SET campaign = C.Campaign_Num
    FROM public.T_Campaign C INNER JOIN
        public.T_Cell_Culture CC ON C.Campaign_ID = CC.CC_Campaign_ID INNER JOIN
        dpkg.t_data_package_biomaterial Target ON CC.CC_ID = Target.biomaterial_id AND C.Campaign_Num <> Target.campaign
    WHERE (Target.data_pkg_id = _packageID)

    If _myRowCount > 0 Then
        _message := 'Updated the campaign name for ' || _myRowCount::text || ' biomaterial entries associated with data package ' || _packageID::text;

        Call public.post_log_entry ('Info', _message, 'Refresh_Data_Package_Items_Using_DMS', 'dpkg');
    End If;

     ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.refresh_data_package_items_using_dms IS 'RefreshDataPackageItemsUsingDMS';

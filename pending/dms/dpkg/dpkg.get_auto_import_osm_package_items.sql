--
CREATE OR REPLACE PROCEDURE dpkg.get_auto_import_osm_package_items
(
    _packageID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**   Populates supplied temp table with items
**   to be imported into given OSM package
**   based on other items in package
**
**  Auth:   grk
**  Date:
**          03/20/2013 grk - initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

     ---------------------------------------------------
    --
    ---------------------------------------------------

     ---------------------------------------------------
    -- Get OSM package status and auto import settings
    ---------------------------------------------------

    DECLARE
        _packageState text = '',
        _datasetsFromPackageExperiments int = 0,
        _datasetsFromPackageRequests int = 0

    -- FUTURE: add auto import control fields to OSM package table
     SELECT
        _packageState = state,
        _datasetsFromPackageExperiments = CASE WHEN state = 'Active' THEN 1 ELSE 0 END,
        _datasetsFromPackageRequests = CASE WHEN state = 'Active' THEN 1 ELSE 0 END
     FROM   dbo.t_osm_package
     WHERE  dbo.t_osm_package.osm_pkg_id = _packageID

     ---------------------------------------------------
    -- datasets from experiments in package not already in package
    ---------------------------------------------------

    If _datasetsFromPackageExperiments = 1 Then
    --<a>
        INSERT INTO Tmp_DataPackageItems (OSM_Package_ID, Item_Type, Item)
        SELECT  DISTINCT _packageID, 'Datasets', TDS.Dataset
        FROM    public.V_Dataset_List_Report_2 AS TDS
                INNER JOIN T_OSM_Package_Items AS TOPI ON TOPI.Item = TDS.Experiment
        WHERE   ( TOPI.Item_Type = 'Experiments' )
                AND TOPI.OSM_Package_ID = _packageID
                AND NOT TDS.Dataset IN (
                    SELECT Item
                    FROM   T_OSM_Package_Items
                    WHERE  OSM_Package_ID = _packageID
                    AND Item_Type = 'Datasets'
                )
                AND NOT TDS.Dataset IN (
                    SELECT Item FROM Tmp_DataPackageItems
                )
    End If; --<a>
     ---------------------------------------------------
    -- datasets from requests in package not already in package (dispositioned?)
    ---------------------------------------------------

    If _datasetsFromPackageRequests = 1 Then
    --<b>
        INSERT INTO Tmp_DataPackageItems (OSM_Package_ID, Item_Type, Item)
        SELECT  DISTINCT _packageID, 'Datasets', Dataset
        FROM    public.V_Dataset_List_Report_2 AS TDS
                INNER JOIN T_OSM_Package_Items TOPI ON TOPI.Item_ID = TDS.Request
        WHERE   TOPI.Item_Type = 'Requested_Runs'
                AND TOPI.OSM_Package_ID = _packageID
                AND NOT TDS.Dataset IN (
                    SELECT Item
                    FROM   T_OSM_Package_Items
                    WHERE  OSM_Package_ID = _packageID
                    AND Item_Type = 'Datasets'
                )
                AND NOT TDS.Dataset IN (
                    SELECT Item FROM Tmp_DataPackageItems
                )
    End If; --<b>

     ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.get_auto_import_osm_package_items IS 'GetAutoImportOSMPackageItems';

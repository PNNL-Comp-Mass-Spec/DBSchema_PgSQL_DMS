--
CREATE OR REPLACE PROCEDURE dpkg.regenerate_data_package_folder_name
(
    _dataPkgID int,
    _infoOnly boolean default true,
    _updateWikiLink boolean default true,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:   Updates the auto-generated data package folder name for a given data package
**          Also updates the auto-generated wiki name (unless _updateWikiLink is false)
**
**  Arguments:
**    _dataPkgID        ID of the data package to update
**    _infoOnly         False to update the name, true to preview the new name
**    _updateWikiLink   True to update the Wiki Link; false to not update the link
**
**  Auth:   mem
**  Date:   06/09/2009
**          06/26/2009 mem - Now also updating the wiki page (if parameter _updateWikiLink is true)
**          10/23/2009 mem - Expanded _currentDataPackageWiki and _newDataPackageWiki to varchar(1024)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dataPackageName text;
    _currentDataPkgID int;
    _currentDataPackageFolder text;
    _currentDataPackageWiki text;
    _newDataPackageFolder text;
    _newDataPackageWiki text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, true);
    _message := '';
    _returnCode:= '';

    If _dataPkgID Is Null Then
        _message := 'Data Package ID cannot be null; unable to continue';
        RAISERROR (_message, 10, 1)
        return 51005
    End If;

    ---------------------------------------------------
    -- Lookup the current name for this data package
    ---------------------------------------------------
    --
    _currentDataPkgID := 0;
    --
    SELECT data_pkg_id, INTO _currentDataPkgID
           _dataPackageName = "package_name",
           _currentDataPackageFolder = package_directory,
           _currentDataPackageWiki = wiki_page_link
    FROM dpkg.t_data_package
    WHERE (data_pkg_id = _dataPkgID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    if _myError <> 0 OR _currentDataPkgID = 0 Then
        _message := 'No entry could be found in database for data package: ' || _dataPkgID;
        RAISERROR (_message, 10, 1)
        return 51006
    End If;

    -- Generate the new data package folder name
    _newDataPackageFolder := dbo.MakePackageFolderName(_dataPkgID, _dataPackageName);

    If _updateWikiLink = false Then
        _newDataPackageWiki := _currentDataPackageWiki;
    Else
        _newDataPackageWiki := public.Make_PRISMWiki_Page_Link(_dataPkgID, _dataPackageName);
    End If;

    If _newDataPackageFolder = _currentDataPackageFolder Then
        _message := 'Data package folder name is already up-to-date: ' || _newDataPackageFolder;
        If _infoOnly Then
            SELECT _message AS Message;
        End If;
    Else
        If _infoOnly Then
            _message := 'Will change data package folder name from "' || _currentDataPackageFolder || '" to "' || _newDataPackageFolder || '"';
            SELECT _message AS Message
        Else
            UPDATE dpkg.t_data_package
            SET package_directory = _newDataPackageFolder
            WHERE data_pkg_id = _dataPkgID
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            --
            if _myError <> 0 Then
                _message := 'Error updating data package folder to "' || _newDataPackageFolder || '" for data package: ' || _dataPkgID::text;
                RAISERROR (_message, 10, 1)
                return 51007
            End If;

            _message := 'Changed data package folder name to "' || _newDataPackageFolder || '" for ID ' || _dataPkgID::text;

        End If;
    End If;

    If _newDataPackageWiki = _currentDataPackageWiki Then
        _message := 'Data package wiki link is already up-to-date: ' || _newDataPackageWiki;
        If _infoOnly Then
            SELECT _message AS Message;
        End If;
    Else
        If _infoOnly Then
            _message := 'Will change data package wiki link from "' || _currentDataPackageWiki || '" to "' || _newDataPackageWiki || '"';
            SELECT _message AS Message
        Else
            UPDATE dpkg.t_data_package
            SET wiki_page_link = _newDataPackageWiki
            WHERE data_pkg_id = _dataPkgID
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            --
            if _myError <> 0 Then
                _message := 'Error updating data package wiki link to "' || _newDataPackageWiki || '" for data package: ' || _dataPkgID::text;
                RAISERROR (_message, 10, 1)
                return 51007
            End If;

            _message := 'Changed data package wiki link to "' || _newDataPackageWiki || '" for ID ' || _dataPkgID::text;

        End If;
    End If;

    ---------------------------------------------------
    --
    ---------------------------------------------------

    return _myError
END
$$;

COMMENT ON PROCEDURE dpkg.regenerate_data_package_folder_name IS 'RegenerateDataPackageFolderName';

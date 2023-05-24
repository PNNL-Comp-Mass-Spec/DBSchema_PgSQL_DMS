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
        RAISE WARNING '%', _message;
        RETURN 'U5105';
    End If;

    ---------------------------------------------------
    -- Lookup the current name for this data package
    ---------------------------------------------------
    --
    SELECT data_pkg_id,
           package_name,
           package_directory,
           wiki_page_link
    INTO _currentDataPkgID, _dataPackageName, _currentDataPackageFolder, _currentDataPackageWiki
    FROM dpkg.t_data_package
    WHERE data_pkg_id = _dataPkgID;

    If Not FOUND Then
        _message := format('No entry could be found in database for data package: %s', _dataPkgID);
        RAISE WARNING '%', _message;
        RETURN 'U5106';
    End If;

    -- Generate the new data package folder name
    _newDataPackageFolder := dpkg.make_package_folder_name(_dataPkgID, _dataPackageName);

    If _updateWikiLink = false Then
        _newDataPackageWiki := _currentDataPackageWiki;
    Else
        _newDataPackageWiki := public.Make_PRISMWiki_Page_Link(_dataPkgID, _dataPackageName);
    End If;

    If _newDataPackageFolder = _currentDataPackageFolder Then
        _message := format('Data package folder name is already up-to-date: %s', _newDataPackageFolder);
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
    Else
        If _infoOnly Then
            _message := format('Will change data package folder name from "%s" to "%s"', _currentDataPackageFolder, _newDataPackageFolder);
            RAISE INFO '%', _message;
        Else
            UPDATE dpkg.t_data_package
            SET package_directory = _newDataPackageFolder
            WHERE data_pkg_id = _dataPkgID;

            _message := format('Changed data package folder name to "%s" for ID %s', _newDataPackageFolder, _dataPkgID);

        End If;
    End If;

    If _newDataPackageWiki = _currentDataPackageWiki Then
        _message := format('Data package wiki link is already up-to-date: %s', _newDataPackageWiki);
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
    Else
        If _infoOnly Then
            _message := format('Will change data package wiki link from "%s" to "%s"', _currentDataPackageWiki, _newDataPackageWiki);
            RAISE INFO '%', _message;
        Else
            UPDATE dpkg.t_data_package
            SET wiki_page_link = _newDataPackageWiki
            WHERE data_pkg_id = _dataPkgID

            _message := format('Changed data package wiki link to "%s" for ID %s', _newDataPackageWiki, _dataPkgID);

        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE dpkg.regenerate_data_package_folder_name IS 'RegenerateDataPackageFolderName';

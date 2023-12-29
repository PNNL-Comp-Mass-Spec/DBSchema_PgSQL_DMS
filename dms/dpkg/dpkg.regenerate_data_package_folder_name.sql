--
-- Name: regenerate_data_package_folder_name(integer, boolean, boolean, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.regenerate_data_package_folder_name(IN _datapkgid integer, IN _infoonly boolean DEFAULT true, IN _updatewikilink boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the auto-generated data package folder name for a given data package
**      Also update the auto-generated wiki name (unless _updateWikiLink is false)
**
**  Arguments:
**    _dataPkgID        ID of the data package to update
**    _infoOnly         When true, preview updated info
**    _updateWikiLink   When true, update column wiki_page_link in t_data_package
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   mem
**  Date:   06/09/2009
**          06/26/2009 mem - Now also updating the wiki page (if parameter _updateWikiLink is true)
**          10/23/2009 mem - Expanded _currentDataPackageWiki and _newDataPackageWiki to varchar(1024)
**          08/15/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _dataPackageName text;
    _currentDataPkgID int;
    _currentDataPackageFolder text;
    _currentDataPackageWiki text;
    _newDataPackageFolder text;
    _newDataPackageWiki text;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly       := Coalesce(_infoOnly, true);
    _updateWikiLink := Coalesce(_updateWikiLink, true);

    If _dataPkgID Is Null Then
        _message := 'Data package ID cannot be null; unable to continue';
        RAISE WARNING '%', _message;
        _returnCode := 'U5105';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the current name for this data package
    ---------------------------------------------------

    SELECT data_pkg_id,
           package_name,
           package_folder,
           wiki_page_link
    INTO _currentDataPkgID, _dataPackageName, _currentDataPackageFolder, _currentDataPackageWiki
    FROM dpkg.t_data_package
    WHERE data_pkg_id = _dataPkgID;

    If Not FOUND Then
        _message := format('No entry could be found in database for data package: %s', _dataPkgID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5106';
        RETURN;
    End If;

    -- Generate the new data package folder name
    _newDataPackageFolder := dpkg.make_package_folder_name(_dataPkgID, _dataPackageName);

    If _updateWikiLink Then
        _newDataPackageWiki := dpkg.make_prismwiki_page_link(_dataPackageName);
    Else
        _newDataPackageWiki := _currentDataPackageWiki;
    End If;

    If _infoOnly Then
        RAISE INFO '';
    End If;

    If _newDataPackageFolder = Coalesce(_currentDataPackageFolder, '') Then
        _message := format('Data package folder name is already up-to-date: %s', _newDataPackageFolder);
        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;
    Else
        If _infoOnly Then
            _message := format('Would change data package folder name from "%s" to "%s"', _currentDataPackageFolder, _newDataPackageFolder);
            RAISE INFO '%', _message;
        Else
            UPDATE dpkg.t_data_package
            SET package_folder = _newDataPackageFolder
            WHERE data_pkg_id = _dataPkgID;

            _message := format('Changed data package folder name to "%s" for ID %s', _newDataPackageFolder, _dataPkgID);
        End If;
    End If;

    If _updateWikiLink Then
        If _newDataPackageWiki = Coalesce(_currentDataPackageWiki, '') Then
            _msg := format('Data package wiki link is already up-to-date: %s', _newDataPackageWiki);
            If _infoOnly Then
                RAISE INFO '%', _msg;
            End If;
        Else
            If _infoOnly Then
                _msg := format('Would change data package wiki link from "%s" to "%s"', _currentDataPackageWiki, _newDataPackageWiki);
                RAISE INFO '%', _msg;
            Else
                UPDATE dpkg.t_data_package
                SET wiki_page_link = _newDataPackageWiki
                WHERE data_pkg_id = _dataPkgID;

                _msg := format('Changed data package wiki link to "%s" for ID %s', _newDataPackageWiki, _dataPkgID);
            End If;
        End If;

        _message := public.append_to_text(_message, _msg);
    End If;

END
$$;


ALTER PROCEDURE dpkg.regenerate_data_package_folder_name(IN _datapkgid integer, IN _infoonly boolean, IN _updatewikilink boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE regenerate_data_package_folder_name(IN _datapkgid integer, IN _infoonly boolean, IN _updatewikilink boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.regenerate_data_package_folder_name(IN _datapkgid integer, IN _infoonly boolean, IN _updatewikilink boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'RegenerateDataPackageFolderName';


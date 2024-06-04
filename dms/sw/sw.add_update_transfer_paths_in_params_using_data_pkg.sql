--
-- Name: add_update_transfer_paths_in_params_using_data_pkg(integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_transfer_paths_in_params_using_data_pkg(IN _datapackageid integer, INOUT _paramsupdated boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      If a job has a data package ID defined, determine the appropriate paths for 'CacheFolderPath' and 'TransferFolderPath'
**
**      Update Tmp_Job_Params to have these paths defined if not yet defined or if different
**      If Tmp_Job_Params is updated, _paramsUpdated will be set to true
**
**      The calling procedure must create and populate table Tmp_Job_Params
**
**      CREATE TEMP TABLE Tmp_Job_Params (
**          Section citext,
**          Name citext,
**          Value citext
**      );
**
**  Arguments:
**    _dataPackageID    If 0 or null, will auto-define using parameter 'DataPackageID' in the Tmp_Job_Params table (in section 'JobParameters')
**    _paramsUpdated    Output: true if table Tmp_Job_Params was updated
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   06/16/2016 mem - Initial version
**          06/09/2021 mem - Tabs to spaces
**          06/24/2012 mem - Add parameter DataPackagePath
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          07/27/2023 mem - Ported to PostgreSQL
**          08/17/2023 mem - Use renamed column data_pkg_id in view V_Data_Package_Paths
**          09/11/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _value text;
    _dataPkgSharePath text := '';
    _dataPkgName text := '';
    _xferPath text := '';
    _cacheFolderPath text := '';
    _cacheRootFolderPath text := '';
    _cacheFolderPathOld text := '';
    _xferPathOld text := '';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _paramsUpdated := false;

    ---------------------------------------------------
    -- Update _dataPackageID if 0 yet defined in Tmp_Job_Params
    ---------------------------------------------------

    If _dataPackageID <= 0 Then

        SELECT Value
        INTO _value
        FROM Tmp_Job_Params
        WHERE Section = 'JobParameters' and Name = 'DataPackageID';

        If FOUND And Coalesce(_value, '') <> '' Then
            _dataPackageID := public.try_cast(_value, 0);
        End If;
    End If;

    ---------------------------------------------------
    -- Get data package info (if one is specified)
    ---------------------------------------------------

    If _dataPackageID <> 0 Then
        SELECT dp.package_name,
               dpp.share_path
        INTO _dataPkgName, _dataPkgSharePath
        FROM dpkg.t_data_package dp
             INNER JOIN dpkg.v_data_package_paths dpp
               ON dp.data_pkg_id = dpp.data_pkg_id
        WHERE dp.data_pkg_id = _dataPackageID;

        If Not FOUND Then
            RAISE WARNING 'Data Package ID % not found in dpkg.t_data_package', _dataPackageID;
            _dataPkgName := '';
            _dataPkgSharePath := '';
        End If;
    End If;

    ---------------------------------------------------
    -- Check whether job parameter CacheFolderRootPath has a cache root folder path defined
    ---------------------------------------------------

    -- Step Tool         Default Value for CacheFolderRootPath
    -- ---------------   -------------------------------------
    -- PRIDE_Converter   \\protoapps\MassIVE_Staging
    -- MaxQuant          \\protoapps\MaxQuant_Staging
    -- MSFragger         \\proto-9\MSFragger_Staging
    -- DiaNN             \\proto-9\DiaNN_Staging
    --
    -- PeptideAtlas      \\protoapps\PeptideAtlas_Staging   (tool retired in 2020)

    SELECT Value
    INTO _cacheRootFolderPath
    FROM Tmp_Job_Params
    WHERE Name = 'CacheFolderRootPath';

    ---------------------------------------------------
    -- Define the path parameters
    ---------------------------------------------------

    If _dataPackageID > 0 Then

        -- Lookup paths already defined in Tmp_Job_Params

        SELECT Value
        INTO _cacheFolderPathOld
        FROM Tmp_Job_Params
        WHERE Section = 'JobParameters' AND Name = 'CacheFolderPath';

        SELECT Value
        INTO _xferPathOld
        FROM Tmp_Job_Params
        WHERE Section = 'JobParameters' AND Name = 'TransferFolderPath';

        If Coalesce(_cacheRootFolderPath, '') = '' Then
            _xferPath := _dataPkgSharePath;
        Else
            _cacheFolderPath := format('%s\%s_%s', _cacheRootFolderPath, _dataPackageID, Replace(_dataPkgName, ' ', '_'));
            _xferPath := _cacheRootFolderPath;

            If _cacheFolderPathOld IS DISTINCT FROM _cacheFolderPath Then
                DELETE FROM Tmp_Job_Params
                WHERE Name = 'CacheFolderPath';

                INSERT INTO Tmp_Job_Params (Section, Name, Value)
                VALUES ( 'JobParameters', 'CacheFolderPath', _cacheFolderPath);
            End If;
        End If;

        If _xferPathOld IS DISTINCT FROM _xferPath Then
            DELETE FROM Tmp_Job_Params
            WHERE Name = 'TransferFolderPath';

            INSERT INTO Tmp_Job_Params (Section, Name, Value)
            VALUES ( 'JobParameters', 'TransferFolderPath', _xferPath);
        End If;

        DELETE FROM Tmp_Job_Params
        WHERE Name = 'DataPackagePath';

        INSERT INTO Tmp_Job_Params (Section, Name, Value)
        VALUES ('JobParameters', 'DataPackagePath', _dataPkgSharePath);

        _paramsUpdated := true;
    End If;

END
$$;


ALTER PROCEDURE sw.add_update_transfer_paths_in_params_using_data_pkg(IN _datapackageid integer, INOUT _paramsupdated boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_transfer_paths_in_params_using_data_pkg(IN _datapackageid integer, INOUT _paramsupdated boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_transfer_paths_in_params_using_data_pkg(IN _datapackageid integer, INOUT _paramsupdated boolean, INOUT _message text, INOUT _returncode text) IS 'AddUpdateTransferPathsInParamsUsingDataPkg';


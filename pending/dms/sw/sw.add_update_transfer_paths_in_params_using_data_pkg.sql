--
CREATE OR REPLACE PROCEDURE sw.add_update_transfer_paths_in_params_using_data_pkg
(
    _dataPackageID int,
    INOUT _paramsUpdated int = 0,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      If a job has a data package ID defined, determines the
**      appropriate paths for 'CacheFolderPath' and 'TransferFolderPath'
**
**      Updates Tmp_Job_Params to have these paths defined if not yet defined or if different
**      If Tmp_Job_Params is updated, _paramsUpdated will be set to 1
**
**      The calling procedure must create and populate table Tmp_Job_Params
**
**      CREATE TEMP TABLE Tmp_Job_Params (
**          Section citext,
**          Name citext,
**          Value citext
**      )
**
**  Arguments:
**    _dataPackageID   If 0 or null, will auto-define using parameter 'DataPackageID' in the Tmp_Job_Params table (in section 'JobParameters')
**    _paramsUpdated   Output: will be 1 if Tmp_Job_Params is updated
**
**  Auth:   mem
**  Date:   06/16/2016 mem - Initial version
**          06/09/2021 mem - Tabs to spaces
**          06/24/2012 mem - Add parameter DataPackagePath
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _value text;
    _dataPkgSharePath text := '';
    _dataPkgName text := '';
    _xferPath text := '';
    _cacheFolderPath text := '';
    _cacheRootFolderPath text := '';
    _cacheFolderPathOld text := '';
    _xferPathOld text := '';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _dataPackageID := Coalesce(_dataPackageID, 0);
    _paramsUpdated := 0;
    _message := '';

    ---------------------------------------------------
    -- Update _dataPackageID if 0 yet defined in Tmp_Job_Params
    ---------------------------------------------------
    --
    If _dataPackageID <= 0 Then

        SELECT Value
        INTO _value
        FROM Tmp_Job_Params
        WHERE Section = 'JobParameters' and Name = 'DataPackageID'

        If FOUND And Coalesce(_value, '') <> '' Then
            _dataPackageID := public.try_cast(_value, 0);
        End If;
    End If;

    ---------------------------------------------------
    -- Get data package info (if one is specified)
    ---------------------------------------------------
    --
    If _dataPackageID <> 0 Then
        SELECT dp.package_name,
               dpp.share_path
        INTO _dataPkgName, _dataPkgSharePath
        FROM dpkg.t_data_package dp
             INNER JOIN dpkg.v_data_package_paths dpp
               ON dp.data_pkg_id = dpp.id
        WHERE dp.data_pkg_id = _dataPackageID
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
    --
    If _dataPackageID > 0 Then
        -- Lookup paths already defined in Tmp_Job_Params
        --

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
            _cacheFolderPath := _cacheRootFolderPath || '\' || _dataPackageID::text || '_' || REPLACE(_dataPkgName, ' ', '_');
            _xferPath := _cacheRootFolderPath;

            If _cacheFolderPathOld <> _cacheFolderPath Then
                DELETE FROM Tmp_Job_Params
                WHERE Name = 'CacheFolderPath'
                --
                INSERT INTO Tmp_Job_Params ( Section, Name, Value )
                VALUES ( 'JobParameters', 'CacheFolderPath', _cacheFolderPath )
            End If;
        End If;

        If _xferPathOld <> _xferPath Then
            DELETE FROM Tmp_Job_Params
            WHERE Name = 'TransferFolderPath'
            --
            INSERT INTO Tmp_Job_Params ( Section, Name, Value )
            VALUES ( 'JobParameters', 'TransferFolderPath', _xferPath )
        End If;

        Delete From Tmp_Job_Params
        Where Name = 'DataPackagePath'
        --
        INSERT INTO Tmp_Job_Params( Section, Name, Value )
        VALUES('JobParameters', 'DataPackagePath', _dataPkgSharePath);

        _paramsUpdated := 1;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_transfer_paths_in_params_using_data_pkg IS 'AddUpdateTransferPathsInParamsUsingDataPkg';

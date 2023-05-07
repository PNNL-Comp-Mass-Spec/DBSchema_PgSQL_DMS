--
CREATE OR REPLACE PROCEDURE sw.validate_protein_collection_list_for_data_package
(
    _dataPackageID int,
    INOUT _protCollNameList text = '',
    INOUT _collectionCountAdded int = 0,
    _showMessages boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Check input parameters against the definition for the script
**
**  Auth:   grk
**  Date:   10/06/2010 grk - Initial release
**          11/25/2010 mem - Now validating that the script exists in T_Scripts
**          12/10/2013 grk - problem inserting null values into Tmp_ParamDefinition
**          04/08/2016 mem - Clear _message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add argument _debugMode
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dataPackageName text;
BEGIN
    _message := Coalesce(_message, '');
    _returnCode := 0;

    ---------------------------------------------------
    -- Create a temporary table to hold dataset names
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_DatasetList (
        Dataset_Name text,
    );

    ---------------------------------------------------
    -- Validate the data package ID
    ---------------------------------------------------
    --
    SELECT package_name
    INTO _dataPackageName
    FROM dpkg.t_data_package
    WHERE data_pkg_id = _dataPackageID;

    If Not FOUND Then
        _message := format('Data package ID is invalid: %s', _dataPackageID);
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------
    --
    INSERT INTO Tmp_DatasetList (Dataset_Name)
    SELECT Dataset
    FROM dpkg.t_Data_Package_Datasets
    WHERE data_pkg_id = _dataPackageID;

    If Not FOUND Then
        _message := format('Data package does not have any datasets, ID: %s', _dataPackageID);
        _returnCode := 'U5203';
        RETURN;
    End If;

    Call public.validate_protein_collection_list_for_dataset_table (
                        _protCollNameList => _protCollNameList,             -- Output
                        _collectionCountAdded => _collectionCountAdded,     -- Output
                        _showMessages => _showMessages,
                        _message => _message,                               -- Output
                        _returncode => _returnCode,                         -- Output
                        _showDebug => false);

    DROP TABLE Tmp_DatasetList;
END
$$;

COMMENT ON PROCEDURE sw.validate_protein_collection_list_for_data_package IS 'ValidateProteinCollectionListForDataPackage';

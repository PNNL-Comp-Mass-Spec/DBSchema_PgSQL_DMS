--
-- Name: validate_protein_collection_list_for_data_package(integer, text, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.validate_protein_collection_list_for_data_package(IN _datapackageid integer, INOUT _protcollnamelist text DEFAULT ''::text, INOUT _collectioncountadded integer DEFAULT 0, IN _showmessages boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Check input parameters against the definition for the script
**
**  Arguments:
**    _dataPackageID            Data package ID
**    _protCollNameList         Comma-separated list of protein collection names
**    _collectionCountAdded     Output: Number of protein collections added
**    _showMessages             When true, update _message to list any protein collections that were added
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   grk
**  Date:   10/06/2010 grk - Initial release
**          11/25/2010 mem - Now validating that the script exists in T_Scripts
**          12/10/2013 grk - Problem inserting null values into Tmp_ParamDefinition
**          04/08/2016 mem - Clear _message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add argument _debugMode
**          07/27/2023 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/03/2023 mem - Obtain dataset name from public.t_dataset since the name in dpkg.t_data_package_datasets is a cached name and could be an old dataset name
**
*****************************************************/
DECLARE

BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := 0;

    ---------------------------------------------------
    -- Validate the data package ID
    ---------------------------------------------------

    If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _dataPackageID) Then
        _message := format('Data package ID is invalid: %s', _dataPackageID);
        _returnCode := 'U5220';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create a temporary table to hold dataset names
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetList (
        Dataset_Name text
    );

    CREATE UNIQUE INDEX IX_Tmp_DatasetList ON Tmp_DatasetList ( Dataset_Name );

    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------

    INSERT INTO Tmp_DatasetList (Dataset_Name)
    SELECT DISTINCT DS.dataset
    FROM dpkg.t_Data_Package_Datasets DPD
         INNER JOIN public.t_dataset DS
           ON DPD.dataset_id = DS.dataset_id
    WHERE DPD.data_pkg_id = _dataPackageID;

    If Not FOUND Then
        _message := format('Data package does not have any datasets, ID: %s', _dataPackageID);
        _returnCode := 'U5221';

        DROP TABLE Tmp_DatasetList;
        RETURN;
    End If;

    CALL public.validate_protein_collection_list_for_dataset_table (
                        _protCollNameList => _protCollNameList,             -- Output
                        _collectionCountAdded => _collectionCountAdded,     -- Output
                        _showMessages => _showMessages,
                        _message => _message,                               -- Output
                        _returncode => _returnCode,                         -- Output
                        _showDebug => false);

    DROP TABLE Tmp_DatasetList;
END
$$;


ALTER PROCEDURE sw.validate_protein_collection_list_for_data_package(IN _datapackageid integer, INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_protein_collection_list_for_data_package(IN _datapackageid integer, INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.validate_protein_collection_list_for_data_package(IN _datapackageid integer, INOUT _protcollnamelist text, INOUT _collectioncountadded integer, IN _showmessages boolean, INOUT _message text, INOUT _returncode text) IS 'ValidateProteinCollectionListForDataPackage';


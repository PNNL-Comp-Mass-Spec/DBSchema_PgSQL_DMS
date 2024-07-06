--
-- Name: get_metadata_for_multiple_datasets(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_metadata_for_multiple_datasets(_datasetlist text) RETURNS TABLE(dataset_name text, attribute_type text, attribute_name text, attribute_value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Dump metadata for datasets in given list
**
**  Arguments:
**    _datasetList      Comma-separated list of dataset names
**
**  Auth:   grk
**  Date:   11/01/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/05/2024 mem - Ported to PostgreSQL (based on stored procedures dump_metadata_for_multiple_datasets and load_metadata_for_multiple_datasets)
**
*****************************************************/
DECLARE
    _datasetCount int;
BEGIN

    ---------------------------------------------------
    -- Create and populate temporary tables
    ---------------------------------------------------

    CREATE TABLE Tmp_Datasets (
        Dataset text NOT NULL
    );

    ---------------------------------------------------
    -- Temporary table to hold metadata
    ---------------------------------------------------

    CREATE TABLE Tmp_Metadata (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Dataset_Name text NOT NULL,
        Attribute_Type text NULL,
        Attribute_Name text NOT NULL,
        Attribute_Value text NULL
    );

    ---------------------------------------------------
    -- Load temporary table with list of datasets
    ---------------------------------------------------

    INSERT INTO Tmp_Datasets (Dataset)
    SELECT DISTINCT Trim(Value)
    FROM public.parse_delimited_list(_datasetList);
    --
    GET DIAGNOSTICS _datasetCount = ROW_COUNT;

    RAISE INFO 'Obtaining metadata for % %', _datasetCount, public.check_plural(_datasetCount, 'dataset', 'datasets');

    ---------------------------------------------------
    -- Load tracking info for the datasets
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata (Dataset_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Name,
           'Dataset',
           Unnest(Array['Name', 'ID',         'Experiment',  'Instrument', 'Separation Type',   'LC Column',  'Wellplate',  'Well',  'Type',  'Operator',  'Comment',  'Rating',  'Request',        'State',  'Archive State',  'Created',                         'Folder Name',  'Acquisition Start',                         'Acquisition End',                         'Scan Count',        'File Size MB']),
           Unnest(Array[MD.Name, MD.ID::text, MD.Experiment, MD.Instrument, MD.Separation_Type, MD.LC_Column, MD.Wellplate, MD.Well, MD.Type, MD.Operator, MD.Comment, MD.Rating, MD.Request::text, MD.State, MD.Archive_State, public.timestamp_text(MD.Created), MD.Folder_Name, public.timestamp_text(MD.Acquisition_Start), public.timestamp_text(MD.Acquisition_End), MD.Scan_Count::text, MD.File_Size_MB::text])
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT Dataset FROM Tmp_Datasets);

    /*
     * Deprecated

    INSERT INTO Tmp_Metadata (Dataset_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Name, 'Dataset', 'Compressed State', MD.Compressed_State::text
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT Dataset FROM Tmp_Datasets);

    INSERT INTO Tmp_Metadata (Dataset_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT Name, 'Dataset', 'Compressed Date', public.timestamp_text(MD.Compressed_Date)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT Dataset FROM Tmp_Datasets);
    */

    ---------------------------------------------------
    -- Append aux info for the datasets
    ---------------------------------------------------

    INSERT INTO Tmp_Metadata(Dataset_Name, Attribute_Type, Attribute_Name, Attribute_Value)
    SELECT DS.Dataset, 'Dataset', format('%s.%s.%s', AI.Category, AI.Subcategory, AI.Item) AS Tag, AI.Value
    FROM T_Dataset DS
         INNER JOIN V_Aux_Info_Value AI
           ON DS.Dataset_ID = AI.Target_ID
    WHERE AI.Target = 'Dataset' AND
          DS.Dataset IN (SELECT Dataset FROM Tmp_Datasets)
    ORDER BY SC, SS, SI;

    ---------------------------------------------------
    -- Return the metadata
    ---------------------------------------------------

    RETURN QUERY
    SELECT Src.Dataset_Name,
           Src.Attribute_Type,
           Src.Attribute_Name,
           Src.Attribute_Value
    FROM Tmp_Metadata Src
    ORDER BY Src.Dataset_Name, Src.Entry_ID;

    DROP TABLE Tmp_Datasets;
    DROP TABLE Tmp_Metadata;
END;
$$;


ALTER FUNCTION public.get_metadata_for_multiple_datasets(_datasetlist text) OWNER TO d3l243;


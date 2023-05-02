--
CREATE OR REPLACE PROCEDURE public.store_qcart_results
(
    _datasetID int = 0,
    _resultsXML xml,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the QC-ART information for the dataset specified by _datasetID
**      If _datasetID is 0, will use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <QCART_Results>
**        <Dataset>TEDDY_DISCOVERY_SET_35_14_25Oct15_Frodo_15-08-15</Dataset>
**        <MASIC_Job>1242856</MASIC_Job>
**        <Measurements>
**           <Measurement Name="QCART">0.12345</Measurement>
**        </Measurements>
**      </QCART_Results>
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the QCART results for a single dataset
**
**  Auth:   mem
**  Date:   11/05/2015 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _datasetName text;
    _datasetIDCheck int;
    _usageMessage text;
BEGIN
    -----------------------------------------------------------
    -- Create the table to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name text NOT NULL,
        MASIC_Job int NULL                            -- Analysis job used to generate the MASIC results; not stored in the QC table
    )

    CREATE TEMP TABLE Tmp_Measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    )

    CREATE TEMP TABLE Tmp_KnownMetrics (
        Dataset_ID int NOT NULL,
        QCART real NULL
    )

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
    _message := '';
    _returnCode:= '';
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Parse out the dataset name from _resultsXML
    -- If this parse fails, there is no point in continuing
    --
    -- Note that "text()" means to return the text inside the <Dataset></Dataset> node
    -- [1] is used to select the first match (there should only be one matching node, but xpath() returns an array)
    ---------------------------------------------------

    _datasetName := (xpath('//QCART_Results/Dataset/text()', _resultsXML))[1]::text;

    If Coalesce(_datasetName, '') = '' Then
        _message := 'XML in _resultsXML is not in the expected form; Could not match //QCART_Results/Dataset';
        RAISE WARNING '%', _message;

        DROP TABLE Tmp_DatasetInfo;
        DROP TABLE Tmp_Measurements;
        DROP TABLE Tmp_KnownMetrics;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Parse the contents of _resultsXML to populate Tmp_DatasetInfo
    ---------------------------------------------------
    --
    INSERT INTO Tmp_DatasetInfo (
        Dataset_ID,
        Dataset_Name,
        MASIC_Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//QCART_Results/MASIC_Job/text()', _resultsXML))[1]::text, 0) AS MASIC_Job;

    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Now extract out the Measurement information
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML as rooted_xml
             ) Src,
             XMLTABLE('//QCART_Results/Measurements/Measurement'
                      PASSING Src.rooted_xml
                      COLUMNS ValueText text PATH '.',
                              name text PATH '@Name')
         ) XmlQ
    WHERE NOT XmlQ.ValueText IS NULL;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in Tmp_DatasetInfo
    ---------------------------------------------------
    --
    If _datasetID = 0 Then
        UPDATE Tmp_DatasetInfo
        SET Dataset_ID = DS.Dataset_ID
        FROM Tmp_DatasetInfo Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE Tmp_DatasetInfo
        **   SET ...
        **   FROM source
        **   WHERE source.id = Tmp_DatasetInfo.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN t_dataset DS
               ON Target.Dataset_Name = DS.dataset
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 Then
            _message := 'Warning: dataset not found in table t_dataset: ' || _datasetName;
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_DatasetInfo;
            DROP TABLE Tmp_Measurements;
            DROP TABLE Tmp_KnownMetrics;

            _returnCode := 'U5202';
            RETURN;

        End If;

        -- Update _datasetID
        SELECT Dataset_ID INTO _datasetID
        FROM Tmp_DatasetInfo

    Else

        -- _datasetID was non-zero
        -- Validate the dataset name in Tmp_DatasetInfo against t_dataset

        SELECT DS.dataset_id INTO _datasetIDCheck
        FROM Tmp_DatasetInfo Target
             INNER JOIN t_dataset DS
             ON Target.Dataset_Name = DS.dataset

        If _datasetIDCheck <> _datasetID Then
            _message := 'Error: dataset ID values for ' || _datasetName || ' do not match; expecting ' || _datasetIDCheck::text || ' but stored procedure param _datasetID is ' || _datasetID::text;
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_DatasetInfo;
            DROP TABLE Tmp_Measurements;
            DROP TABLE Tmp_KnownMetrics;

            _returnCode := 'U5203';
            RETURN;
        End If;
    End If;

    -----------------------------------------------
    -- Populate the Value column in Tmp_Measurements
    -- If any of the metrics has a non-numeric value, the Value column will remain Null
    -----------------------------------------------

    UPDATE Tmp_Measurements
    SET Value = FilterQ.Value
    FROM ( SELECT Name,
                  ValueText,
                  public.try_cast(ValueText, null::float8) As Value
           FROM Tmp_Measurements
           WHERE Not public.try_cast(ValueText, null::float8) Is Null
         ) FilterQ
    WHERE Target.Name = FilterQ.Name;

    -- Do not allow values to be larger than 1E+37 or smaller than -1E+37
    UPDATE Tmp_Measurements
    SET Value = 1E+37
    WHERE Value > 1E+37;

    UPDATE Tmp_Measurements
    SET Value = -1E+37
    WHERE Value < -1E+37;

    -----------------------------------------------
    -- Populate Tmp_KnownMetrics using data in Tmp_Measurements
    -- Use a Pivot to extract out the known columns
    -----------------------------------------------


    -- ToDo: Convert the PIVOT query to PostgreSQL syntax


    INSERT INTO Tmp_KnownMetrics ( Dataset_ID,
                                   QCART
                                 )
    SELECT _datasetID,
           QCART
    FROM ( SELECT Name,
                  Value
           FROM Tmp_Measurements ) AS SourceTable
         PIVOT ( MAX(Value)
                 FOR Name
                 IN ( QCART )
                ) AS PivotData

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        -- ToDo: Preview this data using RAISE INFO

        SELECT *
        FROM Tmp_DatasetInfo

        SELECT *
        FROM Tmp_Measurements

        SELECT *
        FROM Tmp_KnownMetrics

        DROP TABLE Tmp_DatasetInfo;
        DROP TABLE Tmp_Measurements;
        DROP TABLE Tmp_KnownMetrics;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_dataset_qc using a MERGE statement
    -----------------------------------------------
    --
    MERGE INTO t_dataset_qc AS target
    USING ( SELECT M.dataset_id,
                   M.qcart
            FROM Tmp_KnownMetrics M INNER JOIN
                 Tmp_DatasetInfo DI ON M.dataset_id = DI.dataset_id
          ) AS Source
    ON (target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            QCART = Source.QCART
    WHEN NOT MATCHED THEN
        INSERT (Dataset_ID, QCART)
        VALUES (Source.Dataset_ID, Source.QCART);

    _message := 'QCART measurement storage successful';

    If _returnCode <> '' Then
        If _message = '' Then
            _message := 'Error in StoreQCARTResults';
        End If;

        _message := _message || '; error code = ' || _myError::text;

        If Not _infoOnly Then
            Call post_log_entry ('Error', _message, 'StoreQCARTResults');
        End If;
    End If;

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := 'Dataset ID: ' || _datasetID::text;
    Else
        _usageMessage := 'Dataset: ' || _datasetName;
    End If;

    If Not _infoOnly Then
        Call post_usage_log_entry ('StoreQCARTResults', _usageMessage;);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;
END
$$;

COMMENT ON PROCEDURE public.store_qcartresults IS 'StoreQCARTResults';

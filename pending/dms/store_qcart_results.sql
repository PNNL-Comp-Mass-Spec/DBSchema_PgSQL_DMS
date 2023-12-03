--
CREATE OR REPLACE PROCEDURE public.store_qcart_results
(
    _datasetID int = 0,
    _resultsXML xml,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the QC-ART information for the dataset specified by _datasetID
**
**      If _datasetID is 0, will use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, will validate that the dataset name in the XML corresponds to the dataset ID specified by _datasetID
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
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   11/05/2015 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetIDCheck int;
    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Create the tables to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name text NOT NULL,
        MASIC_Job int NULL                            -- Analysis job used to generate the MASIC results; not stored in the QC table
    );

    CREATE TEMP TABLE Tmp_Measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    );

    CREATE TEMP TABLE Tmp_KnownMetrics (
        Dataset_ID int NOT NULL,
        QCART real NULL
    );

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
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

    INSERT INTO Tmp_DatasetInfo (
        Dataset_ID,
        Dataset_Name,
        MASIC_Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//QCART_Results/MASIC_Job/text()', _resultsXML))[1]::text, 0) AS MASIC_Job;

    ---------------------------------------------------
    -- Now extract out the Measurement information
    ---------------------------------------------------

    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML As rooted_xml
             ) Src,
             XMLTABLE('//QCART_Results/Measurements/Measurement'
                      PASSING Src.rooted_xml
                      COLUMNS ValueText text PATH '.',
                              name text PATH '@Name')
         ) XmlQ
    WHERE NOT XmlQ.ValueText IS NULL;

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in Tmp_DatasetInfo
    ---------------------------------------------------

    If _datasetID = 0 Then
        UPDATE Tmp_DatasetInfo
        SET Dataset_ID = DS.Dataset_ID
        FROM t_dataset DS
        WHERE Tmp_DatasetInfo.Dataset_Name = DS.dataset;

        If Not FOUND Then
            _message := format('Warning: dataset not found in table t_dataset: %s', _datasetName);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_DatasetInfo;
            DROP TABLE Tmp_Measurements;
            DROP TABLE Tmp_KnownMetrics;

            _returnCode := 'U5202';
            RETURN;

        End If;

        -- Update _datasetID
        SELECT Dataset_ID
        INTO _datasetID
        FROM Tmp_DatasetInfo;

    Else

        -- _datasetID was non-zero
        -- Validate the dataset name in Tmp_DatasetInfo against t_dataset

        SELECT DS.dataset_id
        INTO _datasetIDCheck
        FROM Tmp_DatasetInfo Target
             INNER JOIN t_dataset DS
             ON Target.Dataset_Name = DS.dataset;

        If _datasetIDCheck <> _datasetID Then
            _message := format('Error: dataset ID values for %s do not match; expecting %s but procedure argument _datasetID is %s',
                                _datasetName, _datasetIDCheck, _datasetID);

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
    -- Use a Crosstab to extract out the known columns
    -----------------------------------------------

    INSERT INTO Tmp_KnownMetrics ( Dataset_ID,
                                   QCART
                                 )
    SELECT _datasetID,
           ct."QCART",
    FROM crosstab(
       'SELECT 1 As RowID,
               Name,
               Value
        FROM Tmp_Measurements
        ORDER BY 1,2',
       $$SELECT unnest('{QCART}'::text[])$$
       ) AS ct (RowID int,
                "QCART" float8);

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-80s %-9s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Dataset_Name',
                            'MASIC_Job'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '---------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   Dataset_Name,
                   MASIC_Job
            FROM Tmp_DatasetInfo
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Dataset_Name,
                                _previewData.MASIC_Job
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _formatSpecifier := '%-9s %-9s %-9s';

        _infoHead := format(_formatSpecifier,
                            'Name',
                            'ValueText',
                            'Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '---------',
                                     '---------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Name,
                   ValueText,
                   Value
            FROM Tmp_Measurements
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Name,
                                _previewData.ValueText,
                                _previewData.Value
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'QCART'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   QCART
            FROM Tmp_KnownMetrics
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.QCART
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_DatasetInfo;
        DROP TABLE Tmp_Measurements;
        DROP TABLE Tmp_KnownMetrics;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/Update t_dataset_qc using a MERGE statement
    -----------------------------------------------

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

    If char_length(_message) > 0 And _infoOnly Then
        RAISE INFO '%', _message;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetID);
    Else
        _usageMessage := format('Dataset: %s', _datasetName);
    End If;

    If Not _infoOnly Then
        CALL post_usage_log_entry ('store_qcart_results', _usageMessage;);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;
END
$$;

COMMENT ON PROCEDURE public.store_qcartresults IS 'StoreQCARTResults';

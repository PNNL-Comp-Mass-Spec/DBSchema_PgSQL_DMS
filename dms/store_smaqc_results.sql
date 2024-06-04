--
-- Name: store_smaqc_results(integer, xml, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_smaqc_results(IN _datasetid integer DEFAULT 0, IN _resultsxml xml DEFAULT NULL::xml, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Update the SMAQC information for the dataset specified by _datasetID
**
**      If _datasetID is 0, use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, validate that the dataset name in the XML corresponds to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <SMAQC_Results>
**        <Dataset>Shew119-01_17july02_earth_0402-10_4-20</Dataset>
**        <Job>780000</Job>
**        <Measurements>
**          <Measurement Name="C_1A">0.002028</Measurement>
**          <Measurement Name="C_1B">0.00583</Measurement>
**          <Measurement Name="C_2A">23.5009</Measurement>
**          <Measurement Name="C_3B">25.99</Measurement>
**          <Measurement Name="C_4A">23.28</Measurement>
**          <Measurement Name="C_4B">26.8</Measurement>
**          <Measurement Name="C_4C">27.18</Measurement>
**        </Measurements>
**      </SMAQC_Results>
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the SMAQC results for a single dataset
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   12/06/2011 mem - Initial version (modelled after UpdateDatasetFileInfoXML)
**          02/13/2012 mem - Added 32 more metrics
**          04/29/2012 mem - Replaced P_1 with P_1A and P_1B
**          05/02/2012 mem - Added C_2B, C_3A, and P_2B
**          09/17/2012 mem - Now assuring that the values are no larger than 1E+38
**          07/01/2013 mem - Added support for PSM_Source_Job
**          08/08/2013 mem - Now storing MS1_5C in MassErrorPPM if MassErrorPPM is null;
**                             Note that when running Dta_Refinery, MassErrorPPM will be populated with the mass error value prior to DtaRefinery
**                             while MassErrorPPM_Refined will have the post-refinement error.  In that case, MS1_5C will have the
**                             post-refinement mass error (because that value comes from MSGF+ and MSGF+ uses the refined _dta.txt file)
**          01/08/2014 mem - Added Phos_2A and Phos_2C
**          10/07/2015 mem - Added Keratin_2A, Keratin_2C, P_4A, P_4B
**          02/03/2016 mem - Added Trypsin_2A and Trypsin_2C
**          02/08/2016 mem - Added MS2_Rep_Ion_All, MS2_Rep_Ion_1Missing, MS2_Rep_Ion_2Missing, MS2_Rep_Ion_3Missing
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/22/2024 mem - Ported to PostgreSQL
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _updateCount int := 0;
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
    -- Create the table to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name citext NOT NULL,
        SMAQC_Job int NULL,             -- Analysis job used to generate the SMAQC results
        PSM_Source_Job int NULL         -- MS_GF+ or X!Tandem job whose results were used by SMAQDC
    );

    CREATE TEMP TABLE Tmp_Measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    );

    CREATE TEMP TABLE Tmp_KnownMetrics (
        Dataset_ID int NOT NULL,
        C_1A real NULL,
        C_1B real NULL,
        C_2A real NULL,
        C_2B real NULL,
        C_3A real NULL,
        C_3B real NULL,
        C_4A real NULL,
        C_4B real NULL,
        C_4C real NULL,
        DS_1A real NULL,
        DS_1B real NULL,
        DS_2A real NULL,
        DS_2B real NULL,
        DS_3A real NULL,
        DS_3B real NULL,
        IS_1A real NULL,
        IS_1B real NULL,
        IS_2 real NULL,
        IS_3A real NULL,
        IS_3B real NULL,
        IS_3C real NULL,
        MS1_1 real NULL,
        MS1_2A real NULL,
        MS1_2B real NULL,
        MS1_3A real NULL,
        MS1_3B real NULL,
        MS1_5A real NULL,
        MS1_5B real NULL,
        MS1_5C real NULL,
        MS1_5D real NULL,
        MS2_1 real NULL,
        MS2_2 real NULL,
        MS2_3 real NULL,
        MS2_4A real NULL,
        MS2_4B real NULL,
        MS2_4C real NULL,
        MS2_4D real NULL,
        P_1A real NULL,
        P_1B real NULL,
        P_2A real NULL,
        P_2B real NULL,
        P_2C real NULL,
        P_3 real NULL,
        Phos_2A real NULL,
        Phos_2C real NULL,
        Keratin_2A real NULL,
        Keratin_2C real NULL,
        P_4A real NULL,
        P_4B real NULL,
        Trypsin_2A real NULL,
        Trypsin_2C real NULL,
        MS2_Rep_Ion_All real NULL,
        MS2_Rep_Ion_1Missing real NULL,
        MS2_Rep_Ion_2Missing real NULL,
        MS2_Rep_Ion_3Missing real NULL
    );

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
    _infoOnly  := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Parse out the dataset name from _resultsXML
    -- If this parse fails, there is no point in continuing
    --
    -- Note that "text()" means to return the text inside the <Dataset></Dataset> node
    -- [1] is used to select the first match (there should only be one matching node, but xpath() returns an array)
    ---------------------------------------------------

    _datasetName := (xpath('//SMAQC_Results/Dataset/text()', _resultsXML))[1]::text;

    If Coalesce(_datasetName, '') = '' Then
        _message := 'XML in _resultsXML is not in the expected form; Could not match //SMAQC_Results/Dataset';
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
        SMAQC_Job,
        PSM_Source_Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//SMAQC_Results/Job/text()',            _resultsXML))[1]::text, 0) AS SMAQC_Job,
           public.try_cast((xpath('//SMAQC_Results/PSM_Source_Job/text()', _resultsXML))[1]::text, 0) AS PSM_Source_Job;

    ---------------------------------------------------
    -- Now extract out the SMAQC Measurement information
    ---------------------------------------------------

    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT Trim(XmlQ.Name), Trim(XmlQ.ValueText)
    FROM (
        SELECT xmltable.*
        FROM (SELECT _resultsXML AS rooted_xml
             ) Src,
             XMLTABLE('//SMAQC_Results/Measurements/Measurement'
                      PASSING Src.rooted_xml
                      COLUMNS ValueText text PATH '.',
                              name      text PATH '@Name')
         ) XmlQ
    WHERE NOT XmlQ.ValueText IS NULL;

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in Tmp_DatasetInfo
    ---------------------------------------------------

    If _datasetID = 0 Then
        UPDATE Tmp_DatasetInfo Target
        SET Dataset_ID = DS.Dataset_ID
        FROM t_dataset DS
        WHERE Target.Dataset_Name = DS.dataset;

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
        -- _datasetID is non-zero
        -- Validate the dataset name in Tmp_DatasetInfo against t_dataset

        SELECT DS.dataset_id
        INTO _datasetIDCheck
        FROM Tmp_DatasetInfo Target
             INNER JOIN t_dataset DS
               ON Target.Dataset_Name = DS.dataset;

        If Not FOUND Or _datasetIDCheck <> _datasetID Then
            If Not FOUND Then
                _message := format('Error: unrecognized dataset name for dataset ID %s: %s',
                                    _datasetID, _datasetName);
            Else
                _message := format('Error: dataset ID values for %s do not match; expecting %s but procedure argument _datasetID is %s',
                                    _datasetName, _datasetIDCheck, _datasetID);
            End If;

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

    UPDATE Tmp_Measurements Target
    SET Value = FilterQ.Value
    FROM (SELECT Name,
                 ValueText,
                 public.try_cast(ValueText, null::float8) AS Value
          FROM Tmp_Measurements
          WHERE NOT public.try_cast(ValueText, null::float8) IS NULL
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

    INSERT INTO Tmp_KnownMetrics (
        Dataset_ID,
        C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
        DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
        IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
        MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
        MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
        P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
        Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
        MS2_Rep_Ion_All, MS2_Rep_Ion_1Missing, MS2_Rep_Ion_2Missing, MS2_Rep_Ion_3Missing
    )
    SELECT _datasetID,
           ct."C_1A", ct."C_1B", ct."C_2A", ct."C_2B", ct."C_3A", ct."C_3B", ct."C_4A", ct."C_4B", ct."C_4C",
           ct."DS_1A", ct."DS_1B", ct."DS_2A", ct."DS_2B", ct."DS_3A", ct."DS_3B",
           ct."IS_1A", ct."IS_1B", ct."IS_2", ct."IS_3A", ct."IS_3B", ct."IS_3C",
           ct."MS1_1", ct."MS1_2A", ct."MS1_2B", ct."MS1_3A", ct."MS1_3B", ct."MS1_5A", ct."MS1_5B", ct."MS1_5C", ct."MS1_5D",
           ct."MS2_1", ct."MS2_2", ct."MS2_3", ct."MS2_4A", ct."MS2_4B", ct."MS2_4C", ct."MS2_4D",
           ct."P_1A", ct."P_1B", ct."P_2A", ct."P_2B", ct."P_2C", ct."P_3", ct."Phos_2A", ct."Phos_2C",
           ct."Keratin_2A", ct."Keratin_2C", ct."P_4A", ct."P_4B", ct."Trypsin_2A", ct."Trypsin_2C",
           ct."MS2_RepIon_All", ct."MS2_RepIon_1Missing", ct."MS2_RepIon_2Missing", ct."MS2_RepIon_3Missing"
    FROM crosstab(
       'SELECT 1 AS RowID,
               Name,
               Value
        FROM Tmp_Measurements
        ORDER BY 1,2',
       $$SELECT unnest('{C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                         DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
                         IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
                         MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                         MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                         P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                         Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
                         MS2_RepIon_All, MS2_RepIon_1Missing, MS2_RepIon_2Missing, MS2_RepIon_3Missing}'::text[])$$
       ) AS ct (RowID int,
                "C_1A"  float8, "C_1B"   float8, "C_2A"   float8, "C_2B"   float8, "C_3A"   float8, "C_3B"   float8, "C_4A" float8, "C_4B" float8, "C_4C" float8,
                "DS_1A" float8, "DS_1B"  float8, "DS_2A"  float8, "DS_2B"  float8, "DS_3A"  float8, "DS_3B"  float8,
                "IS_1A" float8, "IS_1B"  float8, "IS_2"   float8, "IS_3A"  float8, "IS_3B"  float8, "IS_3C"  float8,
                "MS1_1" float8, "MS1_2A" float8, "MS1_2B" float8, "MS1_3A" float8, "MS1_3B" float8, "MS1_5A" float8, "MS1_5B" float8, "MS1_5C" float8, "MS1_5D" float8,
                "MS2_1" float8, "MS2_2"  float8, "MS2_3"  float8, "MS2_4A" float8, "MS2_4B" float8, "MS2_4C" float8, "MS2_4D" float8,
                "P_1A"  float8, "P_1B"   float8, "P_2A"   float8, "P_2B"   float8, "P_2C"   float8, "P_3"    float8, "Phos_2A" float8, "Phos_2C" float8,
                "Keratin_2A" float8, "Keratin_2C" float8, "P_4A" float8, "P_4B" float8, "Trypsin_2A" float8, "Trypsin_2C" float8,
                "MS2_RepIon_All" float8, "MS2_RepIon_1Missing" float8, "MS2_RepIon_2Missing" float8, "MS2_RepIon_3Missing" float8);

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-80s %-10s %-14s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Dataset_Name',
                            'SMAQC_Job',
                            'PSM_Source_Job'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '----------',
                                     '--------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   Dataset_Name,
                   SMAQC_Job,
                   PSM_Source_Job
            FROM Tmp_DatasetInfo
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Dataset_Name,
                                _previewData.SMAQC_Job,
                                _previewData.PSM_Source_Job
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _formatSpecifier := '%-20s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Name',
                            'ValueText',
                            'Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '----------',
                                     '----------'
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

        _formatSpecifier := '%-10s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-10s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-10s %-10s %-8s %-8s %-10s %-10s %-15s %-20s %-20s %-20s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'C_1A',
                            'C_1B',
                            'C_2A',
                            'C_2B',
                            'C_3A',
                            'C_3B',
                            'C_4A',
                            'C_4B',
                            'C_4C',
                            'DS_1A',
                            'DS_1B',
                            'DS_2A',
                            'DS_2B',
                            'DS_3A',
                            'DS_3B',
                            'IS_1A',
                            'IS_1B',
                            'IS_2',
                            'IS_3A',
                            'IS_3B',
                            'IS_3C',
                            'MS1_1',
                            'MS1_2A',
                            'MS1_2B',
                            'MS1_3A',
                            'MS1_3B',
                            'MS1_5A',
                            'MS1_5B',
                            'MS1_5C',
                            'MS1_5D',
                            'MS2_1',
                            'MS2_2',
                            'MS2_3',
                            'MS2_4A',
                            'MS2_4B',
                            'MS2_4C',
                            'MS2_4D',
                            'P_1A',
                            'P_1B',
                            'P_2A',
                            'P_2B',
                            'P_2C',
                            'P_3',
                            'Phos_2A',
                            'Phos_2C',
                            'Keratin_2A',
                            'Keratin_2C',
                            'P_4A',
                            'P_4B',
                            'Trypsin_2A',
                            'Trypsin_2C',
                            'MS2_Rep_Ion_All',
                            'MS2_Rep_Ion_1Missing',
                            'MS2_Rep_Ion_2Missing',
                            'MS2_Rep_Ion_3Missing'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '----------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '--------',
                                     '----------',
                                     '----------',
                                     '--------',
                                     '--------',
                                     '----------',
                                     '----------',
                                     '---------------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                   DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
                   IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
                   MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                   MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                   P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                   Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
                   MS2_Rep_Ion_All, MS2_Rep_Ion_1Missing, MS2_Rep_Ion_2Missing, MS2_Rep_Ion_3Missing
            FROM Tmp_KnownMetrics
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.C_1A,
                                _previewData.C_1B,
                                _previewData.C_2A,
                                _previewData.C_2B,
                                _previewData.C_3A,
                                _previewData.C_3B,
                                _previewData.C_4A,
                                _previewData.C_4B,
                                _previewData.C_4C,
                                _previewData.DS_1A,
                                _previewData.DS_1B,
                                _previewData.DS_2A,
                                _previewData.DS_2B,
                                _previewData.DS_3A,
                                _previewData.DS_3B,
                                _previewData.IS_1A,
                                _previewData.IS_1B,
                                _previewData.IS_2,
                                _previewData.IS_3A,
                                _previewData.IS_3B,
                                _previewData.IS_3C,
                                _previewData.MS1_1,
                                _previewData.MS1_2A,
                                _previewData.MS1_2B,
                                _previewData.MS1_3A,
                                _previewData.MS1_3B,
                                _previewData.MS1_5A,
                                _previewData.MS1_5B,
                                _previewData.MS1_5C,
                                _previewData.MS1_5D,
                                _previewData.MS2_1,
                                _previewData.MS2_2,
                                _previewData.MS2_3,
                                _previewData.MS2_4A,
                                _previewData.MS2_4B,
                                _previewData.MS2_4C,
                                _previewData.MS2_4D,
                                _previewData.P_1A,
                                _previewData.P_1B,
                                _previewData.P_2A,
                                _previewData.P_2B,
                                _previewData.P_2C,
                                _previewData.P_3,
                                _previewData.Phos_2A,
                                _previewData.Phos_2C,
                                _previewData.Keratin_2A,
                                _previewData.Keratin_2C,
                                _previewData.P_4A,
                                _previewData.P_4B,
                                _previewData.Trypsin_2A,
                                _previewData.Trypsin_2C,
                                _previewData.MS2_Rep_Ion_All,
                                _previewData.MS2_Rep_Ion_1Missing,
                                _previewData.MS2_Rep_Ion_2Missing,
                                _previewData.MS2_Rep_Ion_3Missing
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_DatasetInfo;
        DROP TABLE Tmp_Measurements;
        DROP TABLE Tmp_KnownMetrics;

        RETURN;
    End If;

    -----------------------------------------------
    -- Add/update t_dataset_qc using a merge statement
    -----------------------------------------------

    MERGE INTO t_dataset_qc AS target
    USING (SELECT M.dataset_id,
                  DI.SMAQC_Job,
                  DI.psm_source_job,
                  c_1a, c_1b, c_2a, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                  ds_1a, ds_1b, ds_2a, DS_2B, DS_3A, DS_3B,
                  is_1a, is_1b, is_2, IS_3A, IS_3B, IS_3C,
                  ms1_1, ms1_2a, ms1_2b, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                  ms2_1, ms2_2, ms2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                  p_1a, p_1b, p_2a, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                  keratin_2a, keratin_2c, p_4a, P_4B, Trypsin_2A, Trypsin_2C,
                  ms2_rep_ion_all, ms2_rep_ion_1missing, ms2_rep_ion_2missing, MS2_rep_ion_3Missing
           FROM Tmp_KnownMetrics M INNER JOIN
                Tmp_DatasetInfo DI ON M.dataset_id = DI.dataset_id
          ) AS Source
    ON (target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            SMAQC_Job = Source.SMAQC_Job,
            PSM_Source_Job = Source.PSM_Source_Job,
            C_1A = Source.C_1A, C_1B = Source.C_1B, C_2A = Source.C_2A, C_2B = Source.C_2B, C_3A = Source.C_3A, C_3B = Source.C_3B, C_4A = Source.C_4A, C_4B = Source.C_4B, C_4C = Source.C_4C,
            DS_1A = Source.DS_1A, DS_1B = Source.DS_1B, DS_2A = Source.DS_2A, DS_2B = Source.DS_2B, DS_3A = Source.DS_3A, DS_3B = Source.DS_3B,
            IS_1A = Source.IS_1A, IS_1B = Source.IS_1B, IS_2 = Source.IS_2, IS_3A = Source.IS_3A, IS_3B = Source.IS_3B, IS_3C = Source.IS_3C,
            MS1_1 = Source.MS1_1, MS1_2A = Source.MS1_2A, MS1_2B = Source.MS1_2B, MS1_3A = Source.MS1_3A, MS1_3B = Source.MS1_3B, MS1_5A = Source.MS1_5A, MS1_5B = Source.MS1_5B, MS1_5C = Source.MS1_5C, MS1_5D = Source.MS1_5D,
            MS2_1 = Source.MS2_1, MS2_2 = Source.MS2_2, MS2_3 = Source.MS2_3, MS2_4A = Source.MS2_4A, MS2_4B = Source.MS2_4B, MS2_4C = Source.MS2_4C, MS2_4D = Source.MS2_4D,
            P_1A = Source.P_1A, P_1B = Source.P_1B, P_2A = Source.P_2A, P_2B = Source.P_2B, P_2C = Source.P_2C, P_3 = Source.P_3,
            Phos_2A = Source.Phos_2A, Phos_2C = Source.Phos_2C,
            Keratin_2A = Source.Keratin_2A, Keratin_2C = Source.Keratin_2C,
            P_4A = Source.P_4A, P_4B = Source.P_4B,
            Trypsin_2A = Source.Trypsin_2A, Trypsin_2C = Source.Trypsin_2C,
            MS2_Rep_Ion_All = Source.MS2_Rep_Ion_All, MS2_Rep_Ion_1Missing = Source.MS2_Rep_Ion_1Missing,
            MS2_Rep_Ion_2Missing = Source.MS2_Rep_Ion_2Missing, MS2_Rep_Ion_3Missing = Source.MS2_Rep_Ion_3Missing,
            mass_error_ppm = Coalesce(Target.mass_error_ppm, Source.MS1_5C),
            Last_Affected = CURRENT_TIMESTAMP

    WHEN NOT MATCHED THEN
        INSERT (Dataset_ID,
                SMAQC_Job,
                PSM_Source_Job,
                C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
                IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
                MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
                MS2_Rep_Ion_All, MS2_Rep_Ion_1Missing, MS2_Rep_Ion_2Missing, MS2_Rep_Ion_3Missing,
                mass_error_ppm,
                Last_Affected)
        VALUES (Source.Dataset_ID,
                Source.SMAQC_Job,
                Source.PSM_Source_Job,
                Source.C_1A, Source.C_1B, Source.C_2A, Source.C_2B, Source.C_3A, Source.C_3B, Source.C_4A, Source.C_4B, Source.C_4C,
                Source.DS_1A, Source.DS_1B, Source.DS_2A, Source.DS_2B, Source.DS_3A, Source.DS_3B,
                Source.IS_1A, Source.IS_1B, Source.IS_2, Source.IS_3A, Source.IS_3B, Source.IS_3C,
                Source.MS1_1, Source.MS1_2A, Source.MS1_2B, Source.MS1_3A, Source.MS1_3B, Source.MS1_5A, Source.MS1_5B, Source.MS1_5C, Source.MS1_5D,
                Source.MS2_1, Source.MS2_2, Source.MS2_3, Source.MS2_4A, Source.MS2_4B, Source.MS2_4C, Source.MS2_4D,
                Source.P_1A, Source.P_1B, Source.P_2A, Source.P_2B, Source.P_2C, Source.P_3,
                Source.Phos_2A, Source.Phos_2C,
                Source.Keratin_2A, Source.Keratin_2C,
                Source.P_4A, Source.P_4B,
                Source.Trypsin_2A, Source.Trypsin_2C,
                Source.MS2_Rep_Ion_All, Source.MS2_Rep_Ion_1Missing, Source.MS2_Rep_Ion_2Missing, Source.MS2_Rep_Ion_3Missing,
                Source.MS1_5C,  -- Store MS1_5C in mass_error_ppm; if DTA_Refinery is run in the future, mass_error_ppm will get auto-updated to the pre-refinement value computed by DTA_Refinery
                CURRENT_TIMESTAMP);

    _message := 'SMAQC measurement storage successful';

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetID);
    Else
        _usageMessage := format('Dataset: %s', _datasetName);
    End If;

    If Not _infoOnly Then
        CALL post_usage_log_entry ('store_smaqc_results', _usageMessage);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;
END
$_$;


ALTER PROCEDURE public.store_smaqc_results(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_smaqc_results(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_smaqc_results(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'StoreSMAQCResults';


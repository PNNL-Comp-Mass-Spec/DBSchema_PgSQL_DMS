--
CREATE OR REPLACE PROCEDURE public.store_smaqc_results
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
**      Updates the SMAQC information for the dataset specified by _datasetID
**      If _datasetID is 0, will use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by _datasetID
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
**          02/08/2016 mem - Added MS2_RepIon_All, MS2_RepIon_1Missing, MS2_RepIon_2Missing, MS2_RepIon_3Missing
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int := 0;
    _datasetName text;
    _datasetIDCheck int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Create the table to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name text NOT NULL,
        Job int NULL,                   -- Analysis job used to generate the SMAQC results
        PSM_Source_Job int NULL         -- MS_GF+ or X!Tandem job whose results were used by SMAQDC
    )

    CREATE TEMP TABLE Tmp_Measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    )

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
        MS2_RepIon_All real NULL,
        MS2_RepIon_1Missing real NULL,
        MS2_RepIon_2Missing real NULL,
        MS2_RepIon_3Missing real NULL
    )

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
        Job,
        PSM_Source_Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//SMAQC_Results/Job/text()', _resultsXML))[1]::text, 0) AS Job,
           public.try_cast((xpath('//SMAQC_Results/PSM_Source_Job/text()', _resultsXML))[1]::text, 0) AS PSM_Source_Job;

    ---------------------------------------------------
    -- Now extract out the SMAQC Measurement information
    ---------------------------------------------------

    --
    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML As rooted_xml
             ) Src,
             XMLTABLE('//SMAQC_Results/Measurements/Measurement'
                      PASSING Src.rooted_xml
                      COLUMNS ValueText text PATH '.',
                              name text PATH '@Name')
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
        --
        GET DIAGNOSTICS __updateCount = ROW_COUNT;

        If __updateCount = 0 Then
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
    -- Use a Pivot to extract out the known columns
    -----------------------------------------------


    -- ToDo: Convert the PIVOT query to PostgreSQL syntax


    INSERT INTO Tmp_KnownMetrics( Dataset_ID,
                                  C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                                  DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
                                  IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
                                  MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                                  MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                                  P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                                  Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
                                  MS2_RepIon_All, MS2_RepIon_1Missing, MS2_RepIon_2Missing, MS2_RepIon_3Missing
                                )
    SELECT _datasetID,
           C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
           DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B,
           IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C,
           MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
           MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
           P_1A, P_1B, P_2A, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
           Keratin_2A, Keratin_2C, P_4A, P_4B, Trypsin_2A, Trypsin_2C,
           MS2_RepIon_All, MS2_RepIon_1Missing, MS2_RepIon_2Missing, MS2_RepIon_3Missing
    FROM ( SELECT Name,
                  Value
           FROM Tmp_Measurements ) AS SourceTable
         PIVOT ( MAX(Value)
                 FOR Name
                 IN ( [C_1A], [C_1B], [C_2A], [C_2B], [C_3A], [C_3B], [C_4A], [C_4B], [C_4C],
                      [DS_1A], [DS_1B], [DS_2A], [DS_2B], [DS_3A], [DS_3B],
                      [IS_1A], [IS_1B], [IS_2], [IS_3A], [IS_3B], [IS_3C],
                      [MS1_1], [MS1_2A], [MS1_2B], [MS1_3A], [MS1_3B], [MS1_5A], [MS1_5B], [MS1_5C], [MS1_5D],
                      [MS2_1], [MS2_2], [MS2_3], [MS2_4A], [MS2_4B], [MS2_4C], [MS2_4D],
                      [P_1A], [P_1B], [P_2A], [P_2B], [P_2C], [P_3], [Phos_2A], [Phos_2C],
                      [Keratin_2A], [Keratin_2C], [P_4A], [P_4B], [Trypsin_2A], [Trypsin_2C],
                      [MS2_RepIon_All], [MS2_RepIon_1Missing], [MS2_RepIon_2Missing], [MS2_RepIon_3Missing] ) ) AS PivotData

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

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

    MERGE INTO t_dataset_qc AS target
    USING ( SELECT M.dataset_id,
                   DI.Job,
                   DI.psm_source_job,
                   c_1a, c_1b, c_2a, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C,
                   ds_1a, ds_1b, ds_2a, DS_2B, DS_3A, DS_3B,
                   is_1a, is_1b, is_2, IS_3A, IS_3B, IS_3C,
                   ms1_1, ms1_2a, ms1_2b, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D,
                   ms2_1, ms2_2, ms2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                   p_1a, p_1b, p_2a, P_2B, P_2C, P_3, Phos_2A, Phos_2C,
                   keratin_2a, keratin_2c, p_4a, P_4B, Trypsin_2A, Trypsin_2C,
                   ms2_rep_ion_all, ms2_rep_ion_1missing, ms2_rep_ion_2missing, MS2_RepIon_3Missing
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
            MS2_RepIon_All = Source.MS2_RepIon_All, MS2_RepIon_1Missing = Source.MS2_RepIon_1Missing,
            MS2_RepIon_2Missing = Source.MS2_RepIon_2Missing, MS2_RepIon_3Missing = Source.MS2_RepIon_3Missing,
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
                MS2_RepIon_All, MS2_RepIon_1Missing, MS2_RepIon_2Missing, MS2_RepIon_3Missing,
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
                Source.MS2_RepIon_All, Source.MS2_RepIon_1Missing, Source.MS2_RepIon_2Missing, Source.MS2_RepIon_3Missing,
                Source.MS1_5C,  -- Store MS1_5C in mass_error_ppm; if DTA_Refinery is run in the future, mass_error_ppm will get auto-updated to the pre-refinement value computed by DTA_Refinery
                CURRENT_TIMESTAMP);

    _message := 'SMAQC measurement storage successful';

    If char_length(_message) > 0 AND _infoOnly Then
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
        CALL post_usage_log_entry ('Store_SMAQC_Results', _usageMessage;);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;
END
$$;

COMMENT ON PROCEDURE public.store_smaqcresults IS 'StoreSMAQCResults';

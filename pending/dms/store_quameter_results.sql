--
CREATE OR REPLACE PROCEDURE public.store_quameter_results
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
**      Updates the Quameter information for the dataset specified by _datasetID
**      If _datasetID is 0, will use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <Quameter_Results>
**        <Dataset>Shew119-01_17july02_earth_0402-10_4-20</Dataset>
**        <Job>780000</Job>
**        <Measurements>
**          <Measurement Name="XIC-WideFrac">0.35347</Measurement>
**          <Measurement Name="XIC-FWHM-Q1">20.7009</Measurement>
**          <Measurement Name="XIC-FWHM-Q2">22.3192</Measurement>
**          <Measurement Name="XIC-FWHM-Q3">24.794</Measurement>
**          <Measurement Name="XIC-Height-Q2">1.08473</Measurement>
**          etc.
**        </Measurements>
**      </Quameter_Results>
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the Quameter results for a single dataset
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetIDCheck int;
    _usageMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Create the tables to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name text NOT NULL,
        Job int NULL                -- Analysis job used to generate the Quameter results
    )

    CREATE TEMP TABLE Tmp_measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    )

    CREATE TEMP TABLE Tmp_knownMetrics (
        Dataset_ID int NOT NULL,
        XIC_WideFrac real Null,
        XIC_FWHM_Q1 real Null,
        XIC_FWHM_Q2 real Null,
        XIC_FWHM_Q3 real Null,
        XIC_Height_Q2 real Null,
        XIC_Height_Q3 real Null,
        XIC_Height_Q4 real Null,
        RT_Duration real Null,
        RT_TIC_Q1 real Null,
        RT_TIC_Q2 real Null,
        RT_TIC_Q3 real Null,
        RT_TIC_Q4 real Null,
        RT_MS_Q1 real Null,
        RT_MS_Q2 real Null,
        RT_MS_Q3 real Null,
        RT_MS_Q4 real Null,
        RT_MSMS_Q1 real Null,
        RT_MSMS_Q2 real Null,
        RT_MSMS_Q3 real Null,
        RT_MSMS_Q4 real Null,
        MS1_TIC_Change_Q2 real Null,
        MS1_TIC_Change_Q3 real Null,
        MS1_TIC_Change_Q4 real Null,
        MS1_TIC_Q2 real Null,
        MS1_TIC_Q3 real Null,
        MS1_TIC_Q4 real Null,
        MS1_Count real Null,
        MS1_Freq_Max real Null,
        MS1_Density_Q1 real Null,
        MS1_Density_Q2 real Null,
        MS1_Density_Q3 real Null,
        MS2_Count real Null,
        MS2_Freq_Max real Null,
        MS2_Density_Q1 real Null,
        MS2_Density_Q2 real Null,
        MS2_Density_Q3 real Null,
        MS2_PrecZ_1 real Null,
        MS2_PrecZ_2 real Null,
        MS2_PrecZ_3 real Null,
        MS2_PrecZ_4 real Null,
        MS2_PrecZ_5 real Null,
        MS2_PrecZ_more real Null,
        MS2_PrecZ_likely_1 real Null,
        MS2_PrecZ_likely_multi real Null
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

    _datasetName := (xpath('//Quameter_Results/Dataset/text()', _resultsXML))[1]::text;

    If Coalesce(_datasetName, '') = '' Then
        _message := 'XML in _resultsXML is not in the expected form; Could not match //Quameter_Results/Dataset';
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
        Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//Quameter_Results/Job/text()', _resultsXML))[1]::text, 0) AS Job;

    ---------------------------------------------------
    -- Now extract out the Quameter Measurement information
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML as rooted_xml
             ) Src,
             XMLTABLE('//Quameter_Results/Measurements/Measurement'
                      PASSING Src.rooted_xml
                      COLUMNS ValueText text PATH '.',
                              name text PATH '@Name')
         ) XmlQ
    WHERE NOT XmlQ.ValueText IS NULL;

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in Tmp_DatasetInfo
    ---------------------------------------------------
    --
    If _datasetID = 0 Then
        UPDATE Tmp_DatasetInfo Target
        SET Dataset_ID = DS.Dataset_ID
        FROM t_dataset DS
        WHERE Target.Dataset_Name = DS.dataset;

        If Not FOUND Then
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
            _message := 'Error: dataset ID values for ' || _datasetName || ' do not match; expecting ' || _datasetIDCheck::text || ' but procedure argument _datasetID is ' || _datasetID::text;
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
                                   XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                                   RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                                   RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                                   RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                                   MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                                   MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                                   MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                                   MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                                   MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                                   MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi
                                 )
    SELECT _datasetID,
            XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
            RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
            RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
            RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
            MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
            MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
            MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
            MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
            MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
            MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi
    FROM ( SELECT Name,
                  Value
           FROM Tmp_Measurements ) AS SourceTable
         PIVOT ( MAX(Value)
                 FOR Name
                 IN ( XIC_WideFrac, [XIC_FWHM_Q1], [XIC_FWHM_Q2], [XIC_FWHM_Q3], [XIC_Height_Q2], [XIC_Height_Q3], [XIC_Height_Q4],
                      RT_Duration, [RT_TIC_Q1], [RT_TIC_Q2], [RT_TIC_Q3], [RT_TIC_Q4],
                      [RT_MS_Q1], [RT_MS_Q2], [RT_MS_Q3], [RT_MS_Q4],
                      [RT_MSMS_Q1], [RT_MSMS_Q2], [RT_MSMS_Q3], [RT_MSMS_Q4],
                      [MS1_TIC_Change_Q2], [MS1_TIC_Change_Q3], [MS1_TIC_Change_Q4],
                      [MS1_TIC_Q2], [MS1_TIC_Q3], [MS1_TIC_Q4],
                      [MS1_Count], [MS1_Freq_Max], [MS1_Density_Q1], [MS1_Density_Q2], [MS1_Density_Q3],
                      [MS2_Count], [MS2_Freq_Max], [MS2_Density_Q1], [MS2_Density_Q2], [MS2_Density_Q3],
                      [MS2_PrecZ_1], [MS2_PrecZ_2], [MS2_PrecZ_3], [MS2_PrecZ_4], [MS2_PrecZ_5], [MS2_PrecZ_more],
                      [MS2_PrecZ_likely_1], [MS2_PrecZ_likely_multi] )
                ) AS PivotData

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
    --
    MERGE INTO t_dataset_qc AS target
    USING ( SELECT M.dataset_id,
                   DI.Job AS Quameter_Job,
                   xic_wide_frac, xic_fwhm_q1, xic_fwhm_q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                   rt_duration, rt_tic_q1, rt_tic_q2, RT_TIC_Q3, RT_TIC_Q4,
                   rt_ms_q1, rt_ms_q2, rt_ms_q3, RT_MS_Q4,
                   rt_msms_q1, rt_msms_q2, rt_msms_q3, RT_MSMS_Q4,
                   ms1_tic_change_q2, ms1_tic_change_q3, ms1_tic_change_q4,
                   ms1_tic_q2, ms1_tic_q3, ms1_tic_q4,
                   ms1_count, ms1_freq_max, ms1_density_q1, MS1_Density_Q2, MS1_Density_Q3,
                   ms2_count, ms2_freq_max, ms2_density_q1, MS2_Density_Q2, MS2_Density_Q3,
                   ms2_prec_z_1, ms2_prec_z_2, ms2_prec_z_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                   ms2_prec_z_likely_1, ms2_prec_z_likely_multi
            FROM Tmp_KnownMetrics M INNER JOIN
                 Tmp_DatasetInfo DI ON M.dataset_id = DI.dataset_id
          ) AS Source
    ON (target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            Quameter_Job = Source.Quameter_Job,
            XIC_WideFrac = Source.XIC_WideFrac, XIC_FWHM_Q1 = Source.XIC_FWHM_Q1, XIC_FWHM_Q2 = Source.XIC_FWHM_Q2, XIC_FWHM_Q3 = Source.XIC_FWHM_Q3, XIC_Height_Q2 = Source.XIC_Height_Q2, XIC_Height_Q3 = Source.XIC_Height_Q3, XIC_Height_Q4 = Source.XIC_Height_Q4,
            RT_Duration = Source.RT_Duration, RT_TIC_Q1 = Source.RT_TIC_Q1, RT_TIC_Q2 = Source.RT_TIC_Q2, RT_TIC_Q3 = Source.RT_TIC_Q3, RT_TIC_Q4 = Source.RT_TIC_Q4,
            RT_MS_Q1 = Source.RT_MS_Q1, RT_MS_Q2 = Source.RT_MS_Q2, RT_MS_Q3 = Source.RT_MS_Q3, RT_MS_Q4 = Source.RT_MS_Q4,
            RT_MSMS_Q1 = Source.RT_MSMS_Q1, RT_MSMS_Q2 = Source.RT_MSMS_Q2, RT_MSMS_Q3 = Source.RT_MSMS_Q3, RT_MSMS_Q4 = Source.RT_MSMS_Q4,
            MS1_TIC_Change_Q2 = Source.MS1_TIC_Change_Q2, MS1_TIC_Change_Q3 = Source.MS1_TIC_Change_Q3, MS1_TIC_Change_Q4 = Source.MS1_TIC_Change_Q4,
            MS1_TIC_Q2 = Source.MS1_TIC_Q2, MS1_TIC_Q3 = Source.MS1_TIC_Q3, MS1_TIC_Q4 = Source.MS1_TIC_Q4,
            MS1_Count = Source.MS1_Count, MS1_Freq_Max = Source.MS1_Freq_Max, MS1_Density_Q1 = Source.MS1_Density_Q1, MS1_Density_Q2 = Source.MS1_Density_Q2, MS1_Density_Q3 = Source.MS1_Density_Q3,
            MS2_Count = Source.MS2_Count, MS2_Freq_Max = Source.MS2_Freq_Max, MS2_Density_Q1 = Source.MS2_Density_Q1, MS2_Density_Q2 = Source.MS2_Density_Q2, MS2_Density_Q3 = Source.MS2_Density_Q3,
            MS2_PrecZ_1 = Source.MS2_PrecZ_1, MS2_PrecZ_2 = Source.MS2_PrecZ_2, MS2_PrecZ_3 = Source.MS2_PrecZ_3, MS2_PrecZ_4 = Source.MS2_PrecZ_4, MS2_PrecZ_5 = Source.MS2_PrecZ_5, MS2_PrecZ_more = Source.MS2_PrecZ_more,
            MS2_PrecZ_likely_1 = Source.MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi = Source.MS2_PrecZ_likely_multi,
            Quameter_Last_Affected = CURRENT_TIMESTAMP

    WHEN NOT MATCHED THEN
        INSERT (Dataset_ID,
                Quameter_Job,
                XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi,
                Quameter_Last_Affected)
        VALUES (Source.Dataset_ID,
                Source.Quameter_Job,
                XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi,
                CURRENT_TIMESTAMP);

    _message := 'Quameter measurement storage successful';

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
        Call post_usage_log_entry ('Store_Quameter_Results', _usageMessage;);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;

END
$$;

COMMENT ON PROCEDURE public.store_quameter_results IS 'StoreQuameterResults';

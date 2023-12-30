--
-- Name: store_quameter_results(integer, xml, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_quameter_results(IN _datasetid integer DEFAULT 0, IN _resultsxml xml DEFAULT '<Quameter_Results></Quameter_Results>'::xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Update the Quameter information for the dataset specified by _datasetID
**
**      If _datasetID is 0, will use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, will validate that the Dataset Name in the XML corresponds
**      to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <Quameter_Results>
**        <Dataset>QC_BTLE_01_Lipid_Pos_28Jun23_Crater_WCSH315309</Dataset>
**        <Job>6041131</Job>
**        <Measurements>
**          <Measurement Name="XIC_WideFrac">0.150247</Measurement><Measurement Name="XIC_FWHM_Q1">154.879</Measurement><Measurement Name="XIC_FWHM_Q2">197.899</Measurement><Measurement Name="XIC_FWHM_Q3">236.983</Measurement><Measurement Name="XIC_Height_Q2">0.533508</Measurement><Measurement Name="XIC_Height_Q3">0.427546</Measurement><Measurement Name="XIC_Height_Q4">1.32528</Measurement>
**          <Measurement Name="RT_Duration">2461.28</Measurement><Measurement Name="RT_TIC_Q1">0.520133</Measurement><Measurement Name="RT_TIC_Q2">0.11564</Measurement><Measurement Name="RT_TIC_Q3">0.147399</Measurement><Measurement Name="RT_TIC_Q4">0.216828</Measurement><Measurement Name="RT_MS_Q1">0.253362</Measurement><Measurement Name="RT_MS_Q2">0.25316</Measurement><Measurement Name="RT_MS_Q3">0.241555</Measurement><Measurement Name="RT_MS_Q4">0.251923</Measurement>
**          <Measurement Name="RT_MSMS_Q1">0.252978</Measurement><Measurement Name="RT_MSMS_Q2">0.253037</Measurement><Measurement Name="RT_MSMS_Q3">0.242426</Measurement><Measurement Name="RT_MSMS_Q4">0.251559</Measurement><Measurement Name="MS1_TIC_Change_Q2">0.938397</Measurement><Measurement Name="MS1_TIC_Change_Q3">0.945567</Measurement><Measurement Name="MS1_TIC_Change_Q4">3.247</Measurement>
**          <Measurement Name="MS1_TIC_Q2">0.551227</Measurement><Measurement Name="MS1_TIC_Q3">0.332419</Measurement><Measurement Name="MS1_TIC_Q4">1.43225</Measurement><Measurement Name="MS1_Count">936</Measurement><Measurement Name="MS1_Freq_Max">0.416628</Measurement><Measurement Name="MS1_Density_Q1">1789</Measurement><Measurement Name="MS1_Density_Q2">2287.5</Measurement><Measurement Name="MS1_Density_Q3">3086.5</Measurement>
**          <Measurement Name="MS2_Count">7481</Measurement><Measurement Name="MS2_Freq_Max">3.31577</Measurement><Measurement Name="MS2_Density_Q1">18</Measurement><Measurement Name="MS2_Density_Q2">27</Measurement><Measurement Name="MS2_Density_Q3">47</Measurement>
**          <Measurement Name="MS2_PrecZ_1">0.947868</Measurement><Measurement Name="MS2_PrecZ_2">0.00641625</Measurement><Measurement Name="MS2_PrecZ_3">0</Measurement><Measurement Name="MS2_PrecZ_4">0</Measurement><Measurement Name="MS2_PrecZ_5">0</Measurement><Measurement Name="MS2_PrecZ_more">0</Measurement>
**          <Measurement Name="MS2_PrecZ_likely_1">0.0274028</Measurement><Measurement Name="MS2_PrecZ_likely_multi">0.0183131</Measurement>
**        </Measurements>
**      </Quameter_Results>
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the Quameter results for a single dataset
**    _message      Status message
**    _returnCode   Return code
**    _infoOnly     When true, preview updates
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/28/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetIDCheck int;
    _job int;
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
        Job int NULL                -- Analysis job used to generate the Quameter results
    );

    CREATE TEMP TABLE Tmp_measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    );

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

    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML As rooted_xml
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

        -- _datasetID was non-zero
        -- Validate the dataset name in Tmp_DatasetInfo against t_dataset

        SELECT DS.dataset_id
        INTO _datasetIDCheck
        FROM Tmp_DatasetInfo Target
             INNER JOIN t_dataset DS
             ON Target.Dataset_Name = DS.dataset;

        If Not FOUND Then
            _message := format('Error: dataset %s not found in t_dataset; unable to validate Dataset ID %s', _datasetName, _datasetID);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_DatasetInfo;
            DROP TABLE Tmp_Measurements;
            DROP TABLE Tmp_KnownMetrics;

            _returnCode := 'U5203';
            RETURN;
        End If;

        If _datasetIDCheck <> _datasetID Then
            _message := format('Error: dataset ID values for %s do not match; expecting %s but procedure argument _datasetID is %s', _datasetName, _datasetIDCheck, _datasetID);
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_DatasetInfo;
            DROP TABLE Tmp_Measurements;
            DROP TABLE Tmp_KnownMetrics;

            _returnCode := 'U5204';
            RETURN;
        End If;
    End If;

    -----------------------------------------------
    -- Populate the Value column in Tmp_Measurements
    -- If any of the metrics has a non-numeric value, the Value column will remain Null
    -----------------------------------------------

    UPDATE Tmp_Measurements Target
    SET Value = FilterQ.Value
    FROM ( SELECT Name,
                  ValueText,
                  public.try_cast(ValueText, null::float8) As Value
           FROM Tmp_Measurements
         ) FilterQ
    WHERE Target.Name = FilterQ.Name AND
          Not FilterQ.Value Is Null;

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
    SELECT DatasetID,
           "XIC_WideFrac", "XIC_FWHM_Q1", "XIC_FWHM_Q2", "XIC_FWHM_Q3", "XIC_Height_Q2", "XIC_Height_Q3", "XIC_Height_Q4",
           "RT_Duration", "RT_TIC_Q1", "RT_TIC_Q2", "RT_TIC_Q3", "RT_TIC_Q4",
           "RT_MS_Q1", "RT_MS_Q2", "RT_MS_Q3", "RT_MS_Q4",
           "RT_MSMS_Q1", "RT_MSMS_Q2", "RT_MSMS_Q3", "RT_MSMS_Q4",
           "MS1_TIC_Change_Q2", "MS1_TIC_Change_Q3", "MS1_TIC_Change_Q4",
           "MS1_TIC_Q2", "MS1_TIC_Q3", "MS1_TIC_Q4",
           "MS1_Count", "MS1_Freq_Max", "MS1_Density_Q1", "MS1_Density_Q2", "MS1_Density_Q3",
           "MS2_Count", "MS2_Freq_Max", "MS2_Density_Q1", "MS2_Density_Q2", "MS2_Density_Q3",
           "MS2_PrecZ_1", "MS2_PrecZ_2", "MS2_PrecZ_3", "MS2_PrecZ_4", "MS2_PrecZ_5", "MS2_PrecZ_more",
           "MS2_PrecZ_likely_1", "MS2_PrecZ_likely_multi"
    FROM crosstab(
       format('SELECT %s As DatasetID, Name, Value
               FROM Tmp_Measurements
               ORDER BY 1,2', _datasetID),
       $$SELECT unnest('{XIC_WideFrac, XIC_FWHM_Q1, XIC_FWHM_Q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                         RT_Duration, RT_TIC_Q1, RT_TIC_Q2, RT_TIC_Q3, RT_TIC_Q4,
                         RT_MS_Q1, RT_MS_Q2, RT_MS_Q3, RT_MS_Q4,
                         RT_MSMS_Q1, RT_MSMS_Q2, RT_MSMS_Q3, RT_MSMS_Q4,
                         MS1_TIC_Change_Q2, MS1_TIC_Change_Q3, MS1_TIC_Change_Q4,
                         MS1_TIC_Q2, MS1_TIC_Q3, MS1_TIC_Q4,
                         MS1_Count, MS1_Freq_Max, MS1_Density_Q1, MS1_Density_Q2, MS1_Density_Q3,
                         MS2_Count, MS2_Freq_Max, MS2_Density_Q1, MS2_Density_Q2, MS2_Density_Q3,
                         MS2_PrecZ_1, MS2_PrecZ_2, MS2_PrecZ_3, MS2_PrecZ_4, MS2_PrecZ_5, MS2_PrecZ_more,
                         MS2_PrecZ_likely_1, MS2_PrecZ_likely_multi}'::text[])$$
       ) AS ct (DatasetID int,
                "XIC_WideFrac" real,
                "XIC_FWHM_Q1" real,        "XIC_FWHM_Q2" real,        "XIC_FWHM_Q3" real,
                "XIC_Height_Q2" real,      "XIC_Height_Q3" real,      "XIC_Height_Q4" real,     "RT_Duration" real,
                "RT_TIC_Q1" real,          "RT_TIC_Q2" real,          "RT_TIC_Q3" real,         "RT_TIC_Q4" real,
                "RT_MS_Q1" real,           "RT_MS_Q2" real,           "RT_MS_Q3" real,          "RT_MS_Q4" real,
                "RT_MSMS_Q1" real,         "RT_MSMS_Q2" real,         "RT_MSMS_Q3" real,        "RT_MSMS_Q4" real,
                "MS1_TIC_Change_Q2" real,  "MS1_TIC_Change_Q3" real,  "MS1_TIC_Change_Q4" real,
                "MS1_TIC_Q2" real,         "MS1_TIC_Q3" real,         "MS1_TIC_Q4" real,
                "MS1_Count" real,          "MS1_Freq_Max" real,
                "MS1_Density_Q1" real,     "MS1_Density_Q2" real,     "MS1_Density_Q3" real,
                "MS2_Count" real,          "MS2_Freq_Max" real,
                "MS2_Density_Q1" real,     "MS2_Density_Q2" real,     "MS2_Density_Q3" real,
                "MS2_PrecZ_1" real,        "MS2_PrecZ_2" real,        "MS2_PrecZ_3" real,
                "MS2_PrecZ_4" real,        "MS2_PrecZ_5" real,        "MS2_PrecZ_more" real,
                "MS2_PrecZ_likely_1" real, "MS2_PrecZ_likely_multi" real);

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        RAISE INFO '';

        SELECT Job
        INTO _job
        FROM Tmp_DatasetInfo
        LIMIT 1;

        RAISE INFO 'Job % for Dataset ID %: %', _job, _datasetID, _datasetName;

        RAISE INFO '';

        _formatSpecifier := '%-22s %-12s';

        _infoHead := format(_formatSpecifier,
                            'Name',
                            'Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------------------',
                                     '------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Name, Value
            FROM Tmp_Measurements
            ORDER BY Name
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Name,
                                _previewData.Value
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

    MERGE INTO t_dataset_qc AS Target
    USING ( SELECT M.Dataset_ID,
                   DI.Job AS Quameter_Job,
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
            FROM Tmp_KnownMetrics M INNER JOIN
                 Tmp_DatasetInfo DI ON M.dataset_id = DI.dataset_id
          ) AS source
    ON (Target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            quameter_job = Source.Quameter_Job,
            xic_wide_frac = Source.XIC_WideFrac, xic_fwhm_q1 = Source.XIC_FWHM_Q1, xic_fwhm_q2 = Source.XIC_FWHM_Q2, xic_fwhm_q3 = Source.XIC_FWHM_Q3, xic_height_q2 = Source.XIC_Height_Q2, xic_height_q3 = Source.XIC_Height_Q3, xic_height_q4 = Source.XIC_Height_Q4,
            rt_duration = Source.RT_Duration, rt_tic_q1 = Source.RT_TIC_Q1, rt_tic_q2 = Source.RT_TIC_Q2, rt_tic_q3 = Source.RT_TIC_Q3, rt_tic_q4 = Source.RT_TIC_Q4,
            rt_ms_q1 = Source.RT_MS_Q1, rt_ms_q2 = Source.RT_MS_Q2, rt_ms_q3 = Source.RT_MS_Q3, rt_ms_q4 = Source.RT_MS_Q4,
            rt_msms_q1 = Source.RT_MSMS_Q1, rt_msms_q2 = Source.RT_MSMS_Q2, rt_msms_q3 = Source.RT_MSMS_Q3, rt_msms_q4 = Source.RT_MSMS_Q4,
            ms1_tic_change_q2 = Source.MS1_TIC_Change_Q2, ms1_tic_change_q3 = Source.MS1_TIC_Change_Q3, ms1_tic_change_q4 = Source.MS1_TIC_Change_Q4,
            ms1_tic_q2 = Source.MS1_TIC_Q2, ms1_tic_q3 = Source.MS1_TIC_Q3, ms1_tic_q4 = Source.MS1_TIC_Q4,
            ms1_count = Source.MS1_Count, ms1_freq_max = Source.MS1_Freq_Max, ms1_density_q1 = Source.MS1_Density_Q1, ms1_density_q2 = Source.MS1_Density_Q2, ms1_density_q3 = Source.MS1_Density_Q3,
            ms2_count = Source.MS2_Count, ms2_freq_max = Source.MS2_Freq_Max, ms2_density_q1 = Source.MS2_Density_Q1, ms2_density_q2 = Source.MS2_Density_Q2, ms2_density_q3 = Source.MS2_Density_Q3,
            ms2_prec_z_1 = Source.MS2_PrecZ_1, ms2_prec_z_2 = Source.MS2_PrecZ_2, ms2_prec_z_3 = Source.MS2_PrecZ_3, ms2_prec_z_4 = Source.MS2_PrecZ_4, ms2_prec_z_5 = Source.MS2_PrecZ_5, ms2_prec_z_more = Source.MS2_PrecZ_more,
            ms2_prec_z_likely_1 = Source.MS2_PrecZ_likely_1, ms2_prec_z_likely_multi = Source.MS2_PrecZ_likely_multi,
            quameter_last_affected = CURRENT_TIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (dataset_id,
                quameter_job,
                xic_wide_frac, xic_fwhm_q1, xic_fwhm_q2, XIC_FWHM_Q3, XIC_Height_Q2, XIC_Height_Q3, XIC_Height_Q4,
                rt_duration, rt_tic_q1, rt_tic_q2, RT_TIC_Q3, RT_TIC_Q4,
                rt_ms_q1, rt_ms_q2, rt_ms_q3, RT_MS_Q4,
                rt_msms_q1, rt_msms_q2, rt_msms_q3, RT_MSMS_Q4,
                ms1_tic_change_q2, ms1_tic_change_q3, ms1_tic_change_q4,
                ms1_tic_q2, ms1_tic_q3, ms1_tic_q4,
                ms1_count, ms1_freq_max, ms1_density_q1, MS1_Density_Q2, MS1_Density_Q3,
                ms2_count, ms2_freq_max, ms2_density_q1, MS2_Density_Q2, MS2_Density_Q3,
                ms2_prec_z_1, ms2_prec_z_2, ms2_prec_z_3, MS2_prec_z_4, MS2_prec_z_5, MS2_prec_z_more,
                ms2_prec_z_likely_1, ms2_prec_z_likely_multi,
                quameter_last_affected)
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

    If _infoOnly Then
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
        CALL post_usage_log_entry ('store_quameter_results', _usageMessage);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;

END
$_$;


ALTER PROCEDURE public.store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_quameter_results(IN _datasetid integer, IN _resultsxml xml, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'StoreQuameterResults';


--
-- Name: store_dta_ref_mass_error_stats(integer, xml, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.store_dta_ref_mass_error_stats(IN _datasetid integer DEFAULT 0, IN _resultsxml xml DEFAULT NULL::xml, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Update the mass error stats specified by _datasetID
**
**      If _datasetID is 0, use the dataset name defined in _resultsXML
**      If _datasetID is non-zero, validate that the dataset name in the XML corresponds to the dataset ID specified by _datasetID
**
**      Typical XML file contents:
**
**      <DTARef_MassErrorStats>
**        <Dataset>TCGA_24-1467_29-2432_25-1321_117C_W_PNNL_B1S2_f23</Dataset>
**        <PSM_Source_Job>927729</PSM_Source_Job>
**        <Measurements>
**           <Measurement Name="MassErrorPPM">-2.58</Measurement>
**           <Measurement Name="MassErrorPPM_Refined">0.01</Measurement>
**        </Measurements>
**      </DTARef_MassErrorStats>
**
**  Arguments:
**    _datasetID    If this value is 0, will determine the dataset name using the contents of _resultsXML
**    _resultsXML   XML holding the Mass Error results for a single dataset
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   08/08/2013 mem - Initial version (modelled after StoreSMAQCResults)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/22/2024 mem - Ported to PostgreSQL
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
    -- Create the temporary tables to hold the data
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_ID int NULL,
        Dataset_Name citext NOT NULL,
        PSM_Source_Job int NULL                -- Analysis job used by DTA_Refinery
    );

    CREATE TEMP TABLE Tmp_Measurements (
        Name text NOT NULL,
        ValueText text NULL,
        Value float8 NULL   -- Double precision float initially, but values are restricted to -1E+37 to 1E+37 since stored as float4 (aka real)
    );

    CREATE TEMP TABLE Tmp_KnownMetrics (
        Dataset_ID int NOT NULL,
        Mass_Error_PPM real NULL,
        Mass_Error_PPM_Refined real NULL
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

    _datasetName := (xpath('//DTARef_MassErrorStats/Dataset/text()', _resultsXML))[1]::text;

    If Coalesce(_datasetName, '') = '' Then
        _message := 'XML in _resultsXML is not in the expected form; Could not match //DTARef_MassErrorStats/Dataset';
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
        PSM_Source_Job
    )
    SELECT _datasetID AS DatasetID,
           _datasetName AS Dataset,
           public.try_cast((xpath('//DTARef_MassErrorStats/PSM_Source_Job/text()', _resultsXML))[1]::text, 0) AS PSM_Source_Job;

    ---------------------------------------------------
    -- Now extract out the Measurement information
    ---------------------------------------------------

    INSERT INTO Tmp_Measurements (Name, ValueText)
    SELECT XmlQ.Name, XmlQ.ValueText
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _resultsXML AS rooted_xml
             ) Src,
             XMLTABLE('//DTARef_MassErrorStats/Measurements/Measurement'
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
    FROM ( SELECT Name,
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

    INSERT INTO Tmp_KnownMetrics ( Dataset_ID,
                                   Mass_Error_PPM,
                                   Mass_Error_PPM_Refined
                                 )
    SELECT _datasetID,
           ct."MassErrorPPM",
           ct."MassErrorPPM_Refined"
    FROM crosstab(
       'SELECT 1 AS RowID,
               Name,
               Value
        FROM Tmp_Measurements
        ORDER BY 1,2',
       $$SELECT unnest('{MassErrorPPM, MassErrorPPM_Refined}'::text[])$$
       ) AS ct (RowID int,
                "MassErrorPPM" float8, "MassErrorPPM_Refined" float8);

    If _infoOnly Then
        -----------------------------------------------
        -- Preview the data, then exit
        -----------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-80s %-14s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Dataset_Name',
                            'PSM_Source_Job'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   Dataset_Name,
                   PSM_Source_Job
            FROM Tmp_DatasetInfo
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Dataset_Name,
                                _previewData.PSM_Source_Job
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';

        _formatSpecifier := '%-25s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Name',
                            'ValueText',
                            'Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------------',
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

        _formatSpecifier := '%-10s %-14s %-22s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Mass_Error_PPM',
                            'Mass_Error_PPM_Refined'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------',
                                     '----------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   Mass_Error_PPM,
                   Mass_Error_PPM_Refined
            FROM Tmp_KnownMetrics
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Mass_Error_PPM,
                                _previewData.Mass_Error_PPM_Refined
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

    MERGE INTO t_dataset_qc AS Target
    USING ( SELECT DI.dataset_id,
                   DI.psm_source_job,
                   M.mass_error_ppm,
                   M.mass_error_ppm_refined
            FROM Tmp_KnownMetrics M INNER JOIN
                 Tmp_DatasetInfo DI ON M.dataset_id = DI.dataset_id
          ) AS Source
    ON (Target.dataset_id = Source.dataset_id)
    WHEN MATCHED THEN
        UPDATE SET
            mass_error_ppm = Source.mass_error_ppm,
            mass_error_ppm_refined = Source.mass_error_ppm_refined,
            psm_source_job = Coalesce(Target.PSM_Source_Job, Source.PSM_Source_Job)
    WHEN NOT MATCHED THEN
        INSERT (Dataset_ID,
                psm_source_job,
                mass_error_ppm,
                mass_error_ppm_refined)
        VALUES (Source.Dataset_ID,
                Source.PSM_Source_Job,
                Source.mass_error_ppm,
                Source.mass_error_ppm_refined);

    _message := 'DTARefinery Mass Error stats successfully stored';

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    If Coalesce(_datasetName, '') = '' Then
        _usageMessage := format('Dataset ID: %s', _datasetID);
    Else
        _usageMessage := format('Dataset: %s', _datasetName);
    End If;

    If Not _infoOnly Then
        CALL post_usage_log_entry ('store_dta_ref_mass_error_stats', _usageMessage);
    End If;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_Measurements;
    DROP TABLE Tmp_KnownMetrics;
END
$_$;


ALTER PROCEDURE public.store_dta_ref_mass_error_stats(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE store_dta_ref_mass_error_stats(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.store_dta_ref_mass_error_stats(IN _datasetid integer, IN _resultsxml xml, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'StoreDTARefMassErrorStats';


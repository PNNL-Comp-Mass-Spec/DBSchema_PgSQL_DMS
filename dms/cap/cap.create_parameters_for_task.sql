--
-- Name: create_parameters_for_task(integer, text, integer, text, text, text, text, integer, text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.create_parameters_for_task(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) RETURNS xml
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Format parameters for given capture task job as XML
**
**  Arguments:
**    _job                      Job number
**    _dataset                  Dataset name
**    _datasetid                Dataset ID
**    _scriptname               Capture task script
**    _storageserver            Storage server
**    _instrument               Instrument
**    _instrumentclass          Instrument class
**    _maxsimultaneouscaptures  Maximum simultaneous capture tasks
**    _capturesubdirectory      Capture subdirectory
**
**  Example Usage:
**      SELECT Src::text FROM cap.create_parameters_for_task(5273219, 'ABF_Rt_HH_B112_CP_M_d7_r2_46_LC', '1016835', 'DatasetCapture', 'proto-4', 'Agilent_QQQ_04', 'Agilent_TOF_V2', 1, '') Src
**
**  Example Results:
**      <Param Section="DatasetQC" Name="ComputeOverallQualityScores" Value="True" />
**      <Param Section="DatasetQC" Name="CreateDatasetInfoFile" Value="True" />
**      <Param Section="DatasetQC" Name="LCMS2DOverviewPlotDivisor" Value="10" />
**      <Param Section="DatasetQC" Name="LCMS2DPlotMaxPointsToPlot" Value="200000" />
**      <Param Section="JobParameters" Name="Created" Value="2022-03-28 11:04:47" />
**      <Param Section="JobParameters" Name="Dataset" Value="ABF_Rt_HH_B112_CP_M_d7_r2_46_LC" />
**      <Param Section="JobParameters" Name="Dataset_ID" Value="1016835" />
**      <Param Section="JobParameters" Name="Dataset_Type" Value="HMS" />
**      <Param Section="JobParameters" Name="Instrument_File_Hash" Value="64d1747df782f82d909c18ed5df07fecba97b999" />
**      <Param Section="JobParameters" Name="Instrument_Name" Value="Agilent_QQQ_04" />
**      <Param Section="JobParameters" Name="TransferDirectoryPath" Value="\\proto-4\DMS3_Xfer\" />
**
**  Auth:   grk
**  Date:   09/05/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/31/2013 mem - Added parameter _scriptName
**                         - Added support for script 'MyEMSLDatasetPush'
**          07/11/2013 mem - Added support for script 'MyEMSLDatasetPushRecursive'
**          09/28/2022 mem - Ported to PostgreSQL
**          04/02/2023 mem - Rename procedure and functions
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _xmlParameters xml;
BEGIN

    CREATE TEMP TABLE Tmp_Task_Parameters (
        Job int,
        Section text,
        Name text,
        Value text
    );

    ---------------------------------------------------
    -- Get capture task job parameters from main database
    ---------------------------------------------------

    INSERT INTO Tmp_Task_Parameters (Job, Section, Name, Value)
    SELECT Job, Section, Name, Value
    FROM cap.get_task_param_table(_job, _dataset, _datasetID, _storageServer, _instrument, _instrumentClass, _maxSimultaneousCaptures, _captureSubdirectory);

    If _scriptName In ('MyEMSLDatasetPush', 'MyEMSLDatasetPushRecursive') Then
        INSERT INTO Tmp_Task_Parameters (Job, Section, Name, Value)
        Values (_job, 'JobParameters', 'PushDatasetToMyEMSL', 'True');
    End If;

    If _scriptName = 'MyEMSLDatasetPushRecursive' Then
        INSERT INTO Tmp_Task_Parameters (Job, Section, Name, Value)
        Values (_job, 'JobParameters', 'PushDatasetRecurse', 'True');
    End If;

    ---------------------------------------------------
    -- Convert the capture task job parameters to XML
    ---------------------------------------------------

    SELECT xml_item
    INTO _xmlParameters
    FROM ( SELECT
             XMLAGG(XMLELEMENT(
                    NAME "Param",
                    XMLATTRIBUTES(
                        section As "Section",
                        name As "Name",
                        value As "Value"))
                    ORDER BY section, name
                   ) AS xml_item
           FROM Tmp_Task_Parameters
        ) AS LookupQ;

    DROP TABLE Tmp_Task_Parameters;

    RETURN _xmlParameters;
END
$$;


ALTER FUNCTION cap.create_parameters_for_task(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) OWNER TO d3l243;

--
-- Name: FUNCTION create_parameters_for_task(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.create_parameters_for_task(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) IS 'CreateParametersForTask or CreateParametersForJob';


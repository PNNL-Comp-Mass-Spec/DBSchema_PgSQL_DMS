--
-- Name: create_parameters_for_job(integer, text, integer, text, text, text, text, integer, text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.create_parameters_for_job(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) RETURNS xml
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Format parameters for given capture task job as XML
**
**  Auth:   grk
**  Date:   09/05/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          05/31/2013 mem - Added parameter _scriptName
**                         - Added support for script 'MyEMSLDatasetPush'
**          07/11/2013 mem - Added support for script 'MyEMSLDatasetPushRecursive'
**          09/28/2022 mem - Ported to PostgreSQL
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
    -- Note that the calling procedure must have already created temporary table Tmp_Jobs
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Task_Parameters (Job, Section, Name, Value)
    SELECT Job, Section, Name, Value
    FROM cap.get_task_param_table(_job, _dataset, _datasetID, _storageServer, _instrument, _instrumentClass, _maxSimultaneousCaptures, _captureSubdirectory);

    If _scriptName IN ('MyEMSLDatasetPush', 'MyEMSLDatasetPushRecursive') Then
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
    --
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


ALTER FUNCTION cap.create_parameters_for_job(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) OWNER TO d3l243;

--
-- Name: FUNCTION create_parameters_for_job(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.create_parameters_for_job(_job integer, _dataset text, _datasetid integer, _scriptname text, _storageserver text, _instrument text, _instrumentclass text, _maxsimultaneouscaptures integer, _capturesubdirectory text) IS 'CreateParametersForJob';


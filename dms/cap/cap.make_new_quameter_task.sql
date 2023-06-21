--
-- Name: make_new_quameter_task(text, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_new_quameter_task(IN _datasetname text, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a new Quameter capture task job for the specified dataset
**
**  Arguments:
**    _datasetName      Dataset name
**    _infoOnly         True to preview the capture task job that would be created
**
**  Auth:   mem
**  Date:   02/22/2013 mem - Initial version
**          06/20/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _jobID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName := Trim(Coalesce(_datasetName, ''));
    _infoOnly := Coalesce(_infoOnly, false);

    If _datasetName = '' Then
        _message := 'Dataset name not defined';
        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate this dataset and determine its Dataset_ID
    ---------------------------------------------------

    SELECT Dataset_ID
    INTO _datasetID
    FROM public.t_dataset
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _message := format('Dataset not found, unable to continue: %s', _datasetName);
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure a pending or running DatasetQuality capture task job doesn't already exist
    ---------------------------------------------------

    SELECT TS.Job
    INTO _jobID
    FROM cap.t_task_steps TS
         INNER JOIN cap.t_tasks T
           ON TS.Job = T.Job
    WHERE T.Dataset_ID = _datasetID AND
          TS.Tool = 'DatasetQuality' AND
          TS.State IN (1, 2, 4);

    If FOUND Then
        _message := format('Existing pending/running DatasetQuality job step already exists: job %s for %s', _jobID, _datasetName);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create new Quameter capture task job for the specified dataset
    ---------------------------------------------------

    If _infoOnly Then
        _message := format('Would create a new Quameter job for dataset ID %s: %s', _datasetID, _datasetName);
    Else

        INSERT INTO cap.t_tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT 'Quameter' AS Script,
               _datasetName AS Dataset,
               _datasetID AS Dataset_ID,
               '' AS Results_Folder_Name,
               'Created manually using make_new_quameter_task' AS Comment
        RETURNING job
        INTO _jobID;

        _message := format('Created Quameter capture task job %s for dataset %s', _jobID, _datasetName);

    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;
END
$$;


ALTER PROCEDURE cap.make_new_quameter_task(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_new_quameter_task(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_new_quameter_task(IN _datasetname text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'MakeNewQuameterTask or MakeNewQuameterJob';


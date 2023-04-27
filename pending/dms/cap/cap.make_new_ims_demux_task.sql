--
CREATE OR REPLACE PROCEDURE cap.make_new_ims_demux_task
(
    _datasetName text,
    _infoOnly boolean = false,
    INOUT _message text = '',
    INOUT _returnCode text = '',
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a new IMSDemultiplex capture task job for the specified dataset
**      This would typically be used to repeat the demultiplexing of a dataset
**
**  Arguments:
**    _infoOnly   True to preview the capture task job that would be created
**
**  Auth:   mem
**  Date:   08/29/2012 - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _jobID int;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _message := '';
    _returnCode := '';

    If _datasetName Is Null Then
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
        _message := 'Dataset not found: ' || _datasetName || '; unable to continue';
        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure a pending or running IMSDemultiplex capture task job doesn't already exist
    ---------------------------------------------------
    --
    _jobID := 0;

    SELECT TS.Job
    INTO _jobID
    FROM cap.t_task_steps TS INNER JOIN
         cap.t_tasks T ON TS.Job = T.Job
    WHERE (T.Dataset_ID = _datasetID) AND (TS.Tool = 'IMSDemultiplex') AND (TS.State IN (1, 2, 4))

    If _jobID > 0 Then
        _message := 'Existing pending/running capture task job already exists for ' || _datasetName || '; task ' || _jobID::text;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create new IMSDemultiplex capture task job for the specified dataset
    ---------------------------------------------------
    --
    If _infoOnly Then
        _message := format('Would create a new IMSDemultiplex job for dataset ID %s: %s', _datasetID, _datasetName);
    Else

        INSERT INTO cap.t_tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT
            'IMSDemultiplex' AS Script,
            _datasetName AS Dataset,
            _datasetID AS Dataset_ID,
            '' AS Results_Folder_Name,
            'Created manually using make_new_imsdemux_job' AS Comment
        RETURNING job
        INTO _jobID;

        _message := format('Created IMSDemultiplex capture task job %s for dataset %s', _jobID, _datasetName);

    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;
END
$$;

COMMENT ON PROCEDURE cap.make_new_ims_demux_task IS 'MakeNewIMSDemuxJob';

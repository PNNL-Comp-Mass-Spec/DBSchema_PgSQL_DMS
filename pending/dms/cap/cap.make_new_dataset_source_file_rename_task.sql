--
CREATE OR REPLACE PROCEDURE cap.make_new_dataset_source_file_rename_task
(
    _datasetName text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a new dataset source file rename capture task job for the specified dataset
**
**  Arguments:
**    _datasetName      Dataset name
**    _infoOnly         True to preview the capture task job that would be created
**
**  Auth:   mem
**  Date:   03/06/2012 mem - Initial version
**          09/09/2022 mem - Fix typo in message
**          12/15/2023 mem - Ported to PostgreSQL
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

    _infoOnly := Coalesce(_infoOnly, false);

    If _datasetName Is Null Then
        _message := 'Dataset name not defined';
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
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
        _message := format('Dataset not found: %s; unable to continue', _datasetName);
        _returnCode := 'U5202';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure a pending source file rename capture task job doesn't already exist
    ---------------------------------------------------

    SELECT Job
    INTO _jobID
    FROM cap.t_tasks
    WHERE Script = 'SourceFileRename' AND
          t_tasks.Dataset_ID = _datasetID AND
          State < 3;

    If FOUND Then
        _message := format('Existing pending SourceFileRename capture task job already exists for %s; task %s', _datasetName, _jobID);

        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create new SourceFileRename capture task job for specified dataset
    ---------------------------------------------------

    If _infoOnly Then
        _message := format('Would create a new SourceFileRename job for dataset ID %s: %s', _datasetID, _datasetName);
    Else

        INSERT INTO cap.t_tasks (Script, Dataset, Dataset_ID, Results_Folder_Name, Comment)
        SELECT
            'SourceFileRename' AS Script,
            _datasetName AS Dataset,
            _datasetID AS Dataset_ID,
            NULL AS Results_Folder_Name,
            'Created manually using make_new_dataset_source_file_rename_task' AS Comment
        RETURNING job
        INTO _jobID;

        _message := format('Created SourceFileRename capture task job %s for dataset %s', _jobID, _datasetName);

    End If;

    If _message <> '' Then
        RAISE INFO '%', _message;
    End If;
END
$$;

COMMENT ON PROCEDURE cap.make_new_dataset_source_file_rename_task IS 'MakeNewDatasetSourceFileRenameTask or MakeNewDatasetSourceFileRenameJob';

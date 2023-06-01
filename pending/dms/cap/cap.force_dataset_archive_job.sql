--
-- ToDo: Continue here
--
CREATE OR REPLACE PROCEDURE cap.force_dataset_archive_job
(
    _job int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates DatasetArchive capture task job in broker for given
**      broker DatasetCapture task
**
**  Auth:   grk
**  Date:   01/22/2010
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _taskInfo record;
    _hit int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Find capture task job
    ---------------------------------------------------
    --
    --
    SELECT
        Script,
        State,
        Dataset,
        Dataset_ID
    INTO _taskInfo
    FROM cap.t_tasks
    WHERE Job = _job;

    If Not FOUND Then
        _message := 'Target capture task job not found in t_tasks';
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is there another DatasetArchive capture task job
    -- for this dataset already in broker?
    ---------------------------------------------------
    --
    --

    If Exists (SELECT * FROM cap.t_tasks WHERE Dataset_ID = _datasetID AND Script = 'DatasetArchive') Then
        _message := format('A DatasetArchive capture task job for dataset "%s" already exists', _dataset);
        _returnCode := 'U5202';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create dataset archive entry in DMS
    ---------------------------------------------------
    --
    CALL public.add_archive_dataset (_taskInfo.DatasetID, _message => _message, _returnCode => _returnCode);

    If Coalesce(_returnCode, '') <> '' Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create DatasetArchive capture task job
    ---------------------------------------------------
    --
    INSERT INTO t_tasks (
        Script,
        Dataset,
        Dataset_ID,
        Comment
    ) VALUES (
        'DatasetArchive',
        _taskInfo.Dataset,
        _taskInfo.Dataset_ID,
        'Created by ForceDatasetArchiveJob'
    )

END
$$;

COMMENT ON PROCEDURE cap.force_dataset_archive_job IS 'ForceDatasetArchiveJob';

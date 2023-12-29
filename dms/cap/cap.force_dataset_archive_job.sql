--
-- Name: force_dataset_archive_job(integer, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.force_dataset_archive_job(IN _job integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create a DatasetArchive capture task job in cap.t_tasks for given DatasetCapture task
**
**  Arguments:
**    _job          Capture task job to lookup dataset info in cap.t_tasks
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   01/22/2010
**          06/05/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
    _dataset text;
    _existingJob int;
    _newJob int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Find capture task job (the script for the job does not matter)
    ---------------------------------------------------

    SELECT Dataset,
           Dataset_ID
    INTO _dataset, _datasetID
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
    -- for this dataset already in cap.t_tasks?
    ---------------------------------------------------

    SELECT job
    INTO _existingJob
    FROM cap.t_tasks
    WHERE Dataset_ID = _datasetID AND Script = 'DatasetArchive';

    If FOUND Then
        _message := format('A DatasetArchive capture task job for dataset "%s" already exists: job %s', _dataset, _existingJob);
        _returnCode := 'U5202';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create dataset archive entry in public.t_dataset_archive
    ---------------------------------------------------

    CALL public.add_archive_dataset (
                    _datasetID,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    If Coalesce(_returnCode, '') <> '' Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Create DatasetArchive capture task job
    ---------------------------------------------------

    INSERT INTO t_tasks ( Script,
                          Dataset,
                          Dataset_ID,
                          Comment
    ) VALUES (
        'DatasetArchive',
        _dataset,
        _datasetID,
        'Created by ForceDatasetArchiveJob'
    )
    RETURNING job
    INTO _newJob;

    _message := format('Created DatasetArchive capture task job %s for dataset %s', _newJob, _dataset);
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE cap.force_dataset_archive_job(IN _job integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE force_dataset_archive_job(IN _job integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.force_dataset_archive_job(IN _job integer, INOUT _message text, INOUT _returncode text) IS 'ForceDatasetArchiveJob';


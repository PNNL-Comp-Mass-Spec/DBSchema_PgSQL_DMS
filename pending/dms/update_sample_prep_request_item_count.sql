--
CREATE OR REPLACE PROCEDURE public.update_sample_prep_request_item_count
(
    _samplePrepRequestID int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates data package item count
**
**  Auth:   grk
**  Date:
**          07/05/2013 grk - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _biomaterialItemCount int := 0;
    _sampleSubmissionItemCount int := 0;
    _materialContainersItemCount int := 0;
    _experimentGroupItemCount int := 0;
    _experimentItemCount int := 0;
    _hpLCRunsItemCount int := 0;
    _dataPackagesItemCount int := 0;
    _datasetItemCount int := 0;
    _requestedRunItemCount int := 0;
    _totalItemCount int := 0;
BEGIN

    SELECT COUNT(prep_request_item_id)
    INTO _biomaterialItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'biomaterial';

    SELECT COUNT(prep_request_item_id)
    INTO _sampleSubmissionItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'sample_submission';

    SELECT COUNT(prep_request_item_id)
    INTO _materialContainersItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'material_container';

    SELECT COUNT(prep_request_item_id)
    INTO _experimentGroupItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'experiment_group';

    SELECT COUNT(prep_request_item_id)
    INTO _experimentItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'experiment';

    SELECT COUNT(prep_request_item_id)
    INTO _hpLCRunsItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'prep_lc_run';

    SELECT COUNT(prep_request_item_id)
    INTO _datasetItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'dataset';

    SELECT COUNT(prep_request_item_id)
    INTO _requestedRunItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID AND item_type = 'requested_run';

    SELECT COUNT(prep_request_item_id)
    INTO _totalItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_item_id = _samplePrepRequestID;


    UPDATE t_sample_prep_request
    SET
--        Last_Modified = CURRENT_TIMESTAMP,
        biomaterial_item_count = _biomaterialItemCount,
        sample_submission_item_count = _sampleSubmissionItemCount,
        material_containers_item_count = _materialContainersItemCount,
        experiment_group_item_count = _experimentGroupItemCount,
        experiment_item_count = _experimentItemCount,
        hplc_runs_item_count = _hpLCRunsItemCount,
        requested_run_item_count =     _requestedRunItemCount,
        dataset_item_count = _datasetItemCount,
        total_item_count = _totalItemCount
    WHERE t_sample_prep_request.prep_request_id = _samplePrepRequestID;

END
$$;

COMMENT ON PROCEDURE public.update_sample_prep_request_item_count IS 'UpdateSamplePrepRequestItemCount';

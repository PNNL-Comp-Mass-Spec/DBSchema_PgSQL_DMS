--
-- Name: update_sample_prep_request_item_count(integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_sample_prep_request_item_count(IN _samplepreprequestid integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update sample prep request item counts in t_sample_prep_request for the given prep request
**
**      Source data comes from table t_sample_prep_request_items,
**      which is populated by procedure update_sample_prep_request_items
**
**  Arguments:
**    _samplePrepRequestID      Sample prep request ID
**
**  Auth:   grk
**  Date:
**          07/05/2013 grk - Initial release
**          10/19/2023 mem - No longer populate column sample_submission_item_count since t_sample_prep_request_items does not track sample_submission items
**                           (sample submission items are associated with a campaign and container, but not a sample prep request)
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _biomaterialItemCount int;
    _materialContainersItemCount int;
    _experimentGroupItemCount int;
    _experimentItemCount int;
    _hpLCRunsItemCount int;
    _dataPackagesItemCount int;
    _datasetItemCount int;
    _requestedRunItemCount int;
    _totalItemCount int;
BEGIN

    SELECT COUNT(prep_request_id)
    INTO _biomaterialItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'biomaterial';

    SELECT COUNT(prep_request_id)
    INTO _materialContainersItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'material_container';

    SELECT COUNT(prep_request_id)
    INTO _experimentGroupItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'experiment_group';

    SELECT COUNT(prep_request_id)
    INTO _experimentItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'experiment';

    SELECT COUNT(prep_request_id)
    INTO _hpLCRunsItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'prep_lc_run';

    SELECT COUNT(prep_request_id)
    INTO _datasetItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'dataset';

    SELECT COUNT(prep_request_id)
    INTO _requestedRunItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID AND item_type = 'requested_run';

    SELECT COUNT(prep_request_id)
    INTO _totalItemCount
    FROM t_sample_prep_request_items
    WHERE prep_request_id = _samplePrepRequestID;

    UPDATE t_sample_prep_request
    SET biomaterial_item_count = _biomaterialItemCount,
        material_containers_item_count = _materialContainersItemCount,
        experiment_group_item_count = _experimentGroupItemCount,
        experiment_item_count = _experimentItemCount,
        hplc_runs_item_count = _hpLCRunsItemCount,
        requested_run_item_count =     _requestedRunItemCount,
        dataset_item_count = _datasetItemCount,
        total_item_count = _totalItemCount
        -- Leave Last_Modified unchanged
    WHERE t_sample_prep_request.prep_request_id = _samplePrepRequestID;

END
$$;


ALTER PROCEDURE public.update_sample_prep_request_item_count(IN _samplepreprequestid integer) OWNER TO d3l243;

--
-- Name: PROCEDURE update_sample_prep_request_item_count(IN _samplepreprequestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_sample_prep_request_item_count(IN _samplepreprequestid integer) IS 'UpdateSamplePrepRequestItemCount';


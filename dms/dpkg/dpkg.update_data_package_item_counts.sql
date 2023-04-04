--
-- Name: update_data_package_item_counts(integer); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_item_counts(IN _packageid integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates the entity count fields in t_data_package
**
**  Auth:   mem
**  Date:   06/09/2009 mem - Code ported from procedure UpdateDataPackageItems
**          06/10/2009 mem - Updated to support item counts of zero
**          06/10/2009 grk - Added update for total count
**          12/31/2013 mem - Added support for EUS Proposals
**          04/04/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobCount int := 0;
    _datasetCount int := 0;
    _proposalCount int := 0;
    _experimentCount int := 0;
    _biomaterialCount int := 0;
BEGIN
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _packageID := Coalesce(_packageID, -1);

    ---------------------------------------------------
    -- Determine the new item counts for this data package
    ---------------------------------------------------
    --
    SELECT COUNT(*)
    INTO _jobCount
    FROM dpkg.t_data_package_analysis_jobs
    WHERE data_pkg_id = _packageID;

    SELECT COUNT(*)
    INTO _datasetCount
    FROM dpkg.t_data_package_datasets
    WHERE data_pkg_id = _packageID;

    SELECT COUNT(*)
    INTO _proposalCount
    FROM dpkg.t_data_package_eus_proposals
    WHERE data_pkg_id = _packageID;

    SELECT COUNT(*)
    INTO _experimentCount
    FROM dpkg.t_data_package_experiments
    WHERE data_pkg_id = _packageID;

    SELECT COUNT(*)
    INTO _biomaterialCount
    FROM dpkg.t_data_package_biomaterial
    WHERE data_pkg_id = _packageID;

    ---------------------------------------------------
    -- Update the item counts for this data package
    ---------------------------------------------------
    --
    UPDATE dpkg.t_data_package
    SET analysis_job_item_count = _jobCount,
        dataset_item_count = _datasetCount,
        eus_proposal_item_count = _proposalCount,
        experiment_item_count = _experimentCount,
        biomaterial_item_count = _biomaterialCount,
        total_item_count = _jobCount + _datasetCount + _experimentCount + _biomaterialCount        -- Exclude EUS proposals from this total
    WHERE data_pkg_id = _packageID;
END
$$;


ALTER PROCEDURE dpkg.update_data_package_item_counts(IN _packageid integer) OWNER TO d3l243;

--
-- Name: PROCEDURE update_data_package_item_counts(IN _packageid integer); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_data_package_item_counts(IN _packageid integer) IS 'UpdateDataPackageItemCounts';


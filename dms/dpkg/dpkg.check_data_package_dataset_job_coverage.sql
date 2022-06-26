--
-- Name: check_data_package_dataset_job_coverage(integer, public.citext, public.citext); Type: FUNCTION; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE FUNCTION dpkg.check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext) RETURNS TABLE(dataset public.citext, job_count integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      When _mode is 'PackageJobCount', returns a table of dataset job coverage
**      For the other two modes, returns a table that lists datasets with missing jobs, either in the data package or in DMS
**
**  Arguments:
**    _packageID    Data package ID
**    _tool         Tool to check
**    _mode         Type of data to return
**                    'NoPackageJobs'   will return the dataset names that do not have an analysis job in the data package for the given tool (the job_count column will be null)
**                    'NoDMSJobs'       will return the dataset names that do not have any DMS job for the given tool (the job_count column will be null)
**                    'PackageJobCount' will return all of the datasets in the data package, plus a count of the number of jobs for the given tool for each dataset
**
**  Auth:   grk
**  Date:   05/22/2010
**          04/25/2018 mem - Now joining T_Data_Package_Datasets and T_Data_Package_Analysis_Jobs on Dataset_ID
**          06/25/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    If Not _mode In ('NoPackageJobs', 'NoDMSJobs', 'PackageJobCount') Then
        RETURN QUERY
        SELECT format('Invalid mode "%s"; should be ''NoPackageJobs'', ''NoDMSJobs'', or ''PackageJobCount''', _mode)::citext,
               NULL::int;

        Return;
    End If;

    -- Package datasets with no package jobs for given tool
    --
    If _mode = 'NoPackageJobs' Then
        RETURN QUERY
        SELECT TD.dataset,
               NULL::int AS job_count
        FROM dpkg.t_data_package_datasets AS TD
             LEFT OUTER JOIN dpkg.t_data_package_analysis_jobs AS TA
               ON TD.dataset = TA.dataset AND
                  TD.data_pkg_id = TA.data_pkg_id AND
                  TA.tool = _tool
        WHERE TD.data_pkg_id = _packageID AND TA.job is null;
    End If;

    -- Package datasets with no DMS jobs for given tool
    --
    If _mode = 'NoDMSJobs' Then
        RETURN QUERY
        SELECT TD.dataset,
               NULL::int AS job_count
        FROM dpkg.t_data_package_datasets AS TD
        WHERE TD.data_pkg_id = _packageID AND
              NOT EXISTS (  SELECT J.dataset_id
                            FROM public.t_analysis_job AS J
                                 INNER JOIN public.t_analysis_tool Tool
                                   ON J.analysis_tool_id = Tool.analysis_tool_id AND
                                      Tool.analysis_tool = _tool
                            WHERE J.dataset_id = TD.dataset_id
                         );
    End If;

    -- For each dataset, return the number of jobs for the given tool in the data package
    --
    If _mode = 'PackageJobCount' Then
        RETURN QUERY
        SELECT TD.Dataset,
               SUM(CASE WHEN TJ.Job IS NULL THEN 0 ELSE 1 END)::int AS job_count
        FROM dpkg.t_data_package_datasets AS TD
             LEFT OUTER JOIN dpkg.t_data_package_analysis_jobs AS TJ
               ON TD.dataset_id = TJ.dataset_id AND
                  TD.data_pkg_id = TJ.data_pkg_id AND
                  TJ.tool = _tool
        WHERE TD.data_pkg_id = _packageID
        GROUP BY TD.dataset;
    End If;
END
$$;


ALTER FUNCTION dpkg.check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext) IS 'CheckDataPackageDatasetJobCoverage';


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
**      For the other two modes, returns a table that lists datasets with missing jobs, either in the data package or in public.t_analysis_job
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
**          05/22/2023 mem - Capitalize reserved word
**          09/28/2023 mem - Obtain dataset names from t_dataset and tool names from t_analysis_tool
**
*****************************************************/
BEGIN
    _mode := Trim(Coalesce(_mode, ''));

    If Not _mode In ('NoPackageJobs', 'NoDMSJobs', 'PackageJobCount') Then
        RETURN QUERY
        SELECT format('Invalid mode "%s"; should be ''NoPackageJobs'', ''NoDMSJobs'', or ''PackageJobCount''', _mode)::citext,
               NULL::int;

        RETURN;
    End If;

    -- Package datasets with no package jobs for given tool

    If _mode = 'NoPackageJobs' Then
        RETURN QUERY
        SELECT DS.dataset,
               NULL::int AS job_count
        FROM dpkg.t_data_package_datasets AS DPD
             INNER JOIN public.t_dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN dpkg.t_data_package_analysis_jobs AS DPJ
                             INNER JOIN public.t_analysis_job AJ
                               ON AJ.job = DPJ.job
                             INNER JOIN public.t_analysis_tool T
                               ON AJ.analysis_tool_id = T.analysis_tool_id AND
                                  T.analysis_tool = _tool
               ON DPD.dataset_id = DPJ.dataset_id AND
                  DPD.data_pkg_id = DPJ.data_pkg_id
        WHERE DPD.data_pkg_id = _packageID AND
              DPJ.job IS NULL;
    End If;

    -- Package datasets with no DMS jobs for given tool

    If _mode = 'NoDMSJobs' Then
        RETURN QUERY
        SELECT DS.dataset,
               NULL::int AS job_count
        FROM dpkg.t_data_package_datasets AS DPD
             INNER JOIN public.t_dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
        WHERE DPD.data_pkg_id = _packageID AND
              NOT EXISTS ( SELECT J.dataset_id
                           FROM public.t_analysis_job AS J
                                INNER JOIN public.t_analysis_tool Tool
                                  ON J.analysis_tool_id = Tool.analysis_tool_id AND
                                     Tool.analysis_tool = _tool
                           WHERE J.dataset_id = DPD.dataset_id
                         );
    End If;

    -- For each dataset, return the number of jobs for the given tool in the data package

    If _mode = 'PackageJobCount' Then
        RETURN QUERY
        SELECT DS.Dataset,
               SUM(CASE WHEN DPJ.Job IS NULL THEN 0 ELSE 1 END)::int AS job_count
        FROM dpkg.t_data_package_datasets AS DPD
             INNER JOIN public.t_dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN dpkg.t_data_package_analysis_jobs AS DPJ
                             INNER JOIN public.t_analysis_job AJ
                               ON AJ.job = DPJ.job
                             INNER JOIN public.t_analysis_tool T
                               ON AJ.analysis_tool_id = T.analysis_tool_id AND
                                  T.analysis_tool = _tool
               ON DPD.dataset_id = DPJ.dataset_id AND
                  DPD.data_pkg_id = DPJ.data_pkg_id
        WHERE DPD.data_pkg_id = _packageID
        GROUP BY DS.dataset;
    End If;
END
$$;


ALTER FUNCTION dpkg.check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON FUNCTION dpkg.check_data_package_dataset_job_coverage(_packageid integer, _tool public.citext, _mode public.citext) IS 'CheckDataPackageDatasetJobCoverage';


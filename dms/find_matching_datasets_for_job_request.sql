--
-- Name: find_matching_datasets_for_job_request(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.find_matching_datasets_for_job_request(_requestid integer) RETURNS TABLE(dataset public.citext, jobs integer, new integer, busy integer, complete integer, failed integer, holding integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return list of datasets for given analysis job request,
**      showing how many jobs exist for each that match the parameters of the request
**      (regardless of whether or not the job is linked to the request)
**
**  Auth:   grk
**  Date:   01/08/2008 grk - Initial release
**          02/11/2009 mem - Updated to allow for OrgDBName to not be 'na' when using protein collection lists
**          06/17/2009 mem - Updated to ignore OrganismName when using protein collection lists
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          06/09/2017 mem - Add support for state 13 (inactive)
**          06/30/2022 mem - Rename parameter file argument
**          07/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobRequestInfo record;
BEGIN

    If _requestID Is Null Then
        RAISE INFO 'Analysis job request ID is null';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get job parameters and list of datasets from request
    ---------------------------------------------------

    SELECT AJR.datasets AS DatasetList,
           AJR.analysis_tool AS ToolName,
           AJR.param_file_name AS ParamFileName,
           AJR.settings_file_name AS SettingsFileName,
           Org.organism AS OrganismName,
           AJR.organism_db_name AS OrganismDBName,
           AJR.protein_collection_list AS ProteinCollectionList,
           AJR.protein_options_list AS ProteinOptionsList
    INTO _jobRequestInfo
    FROM t_analysis_job_request AJR
         INNER JOIN t_organisms Org
           ON AJR.organism_id = Org.organism_id
    WHERE AJR.request_id = _requestID;

    If Not FOUND Then
        RAISE INFO 'Analysis job request not found: %', _requestID;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Populate temporary tables with matching datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestDatasets (
        dataset citext
    );

    CREATE TEMP TABLE Tmp_MatchingJobDatasets (
        Dataset citext,
        Jobs int,
        New int,
        Busy int,
        Complete int,
        Failed int,
        Holding int
    );

    INSERT INTO Tmp_RequestDatasets(dataset)
    SELECT value
    FROM public.parse_delimited_list(_jobRequestInfo.DatasetList);

    ---------------------------------------------------
    -- Get list of datasets that have jobs that match job parameters from the request
    ---------------------------------------------------

    INSERT INTO Tmp_MatchingJobDatasets(dataset, Jobs, New, Busy, Complete, Failed, Holding)
    SELECT DS.dataset,
           COUNT(AJ.job) AS Jobs,
           SUM(CASE WHEN AJ.job_state_id IN (1)                           THEN 1 ELSE 0 END) AS New,
           SUM(CASE WHEN AJ.job_state_id IN (2, 3, 9, 10, 11, 16, 17)     THEN 1 ELSE 0 END) AS Busy,
           SUM(CASE WHEN AJ.job_state_id IN (4, 14)                       THEN 1 ELSE 0 END) AS Complete,
           SUM(CASE WHEN AJ.job_state_id IN (5, 6, 7, 12, 13, 15, 18, 99) THEN 1 ELSE 0 END) AS Failed,
           SUM(CASE WHEN AJ.job_state_id IN (8)                           THEN 1 ELSE 0 END) AS Holding
    FROM t_dataset DS
         INNER JOIN t_analysis_job AJ
           ON AJ.dataset_id = DS.dataset_id
         INNER JOIN t_analysis_tool AJT
           ON AJ.analysis_tool_id = AJT.analysis_tool_id
         INNER JOIN t_organisms Org
           ON AJ.organism_id = Org.organism_id
         -- INNER JOIN t_analysis_job_state AJS ON AJ.job_state_id = AJS.job_state_id
         INNER JOIN Tmp_RequestDatasets RD
           ON RD.dataset = DS.dataset
    WHERE AJT.analysis_tool = _jobRequestInfo.ToolName AND
          AJ.param_file_name = _jobRequestInfo.ParamFileName AND
          AJ.settings_file_name = _jobRequestInfo.SettingsFileName AND
          (
            ( _jobRequestInfo.ProteinCollectionList = 'na' AND
              AJ.organism_db_name = _jobRequestInfo.OrganismDBName AND
              Org.organism = Coalesce(_jobRequestInfo.OrganismName, Org.organism)
            )
            OR
            ( _jobRequestInfo.ProteinCollectionList <> 'na' AND
              AJ.protein_collection_list = Coalesce(_jobRequestInfo.ProteinCollectionList, AJ.protein_collection_list) AND
              AJ.protein_options_list = Coalesce(_jobRequestInfo.ProteinOptionsList, AJ.protein_options_list)
            )
          )
    GROUP BY DS.dataset;

    ---------------------------------------------------
    -- Output
    ---------------------------------------------------

    RETURN QUERY
    SELECT M.Dataset,
           M.Jobs,
           M.New,
           M.Busy,
           M.Complete,
           M.Failed,
           M.Holding
    FROM Tmp_MatchingJobDatasets M
    UNION
    SELECT RD.Dataset,
           0 AS Jobs,
           0 AS New,
           0 AS Busy,
           0 AS Complete,
           0 AS Failed,
           0 AS Holding
    FROM Tmp_RequestDatasets RD
    WHERE NOT RD.Dataset IN ( SELECT M.dataset
                              FROM Tmp_MatchingJobDatasets M);

    DROP TABLE Tmp_RequestDatasets;
    DROP TABLE Tmp_MatchingJobDatasets;
END
$$;


ALTER FUNCTION public.find_matching_datasets_for_job_request(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION find_matching_datasets_for_job_request(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.find_matching_datasets_for_job_request(_requestid integer) IS 'FindMatchingDatasetsForJobRequest';


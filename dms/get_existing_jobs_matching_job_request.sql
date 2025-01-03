--
-- Name: get_existing_jobs_matching_job_request(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_existing_jobs_matching_job_request(_requestid integer) RETURNS TABLE(job integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of existing jobs for the given analysis job request,
**      searching for the jobs using the analysis tool name, parameter file name, and
**      settings file name specified by the analysis request.
**
**      For Peptide_Hit tools, also uses organism DB file name, organism name,
**      protein collection list, and protein options list
**
**  Arguments:
**     _requestID   Analysis job request ID
**
**  Auth:   grk
**  Date:   12/06/2005 grk - Initial release
**          03/28/2006 grk - Added protein collection fields
**          08/30/2006 grk - Fixed selection logic to handle auto-generated fasta file names https://prismtrac.pnl.gov/trac/ticket/218
**          01/26/2007 mem - Now getting organism name from T_Organisms (Ticket #368)
**          10/11/2007 mem - Expanded protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**          03/27/2009 mem - Updated Where clause logic for Peptide_Hit jobs to ignore organism name when using a Protein Collection List
**          05/03/2012 mem - Now comparing the special processing field
**          09/25/2012 mem - Expanded _organismDBName to varchar(128)
**          07/30/2019 mem - Get dataset ID from T_Analysis_Job_Request_Datasets
**          07/31/2019 mem - Remove unused table from query join list
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          06/16/2024 mem - Ignore case when finding existing jobs for the job request
**          01/02/2025 mem - Add support for data package based job requests
**
*****************************************************/
DECLARE
    _requestInfo record;
    _resultType citext;
BEGIN

    -- Lookup the entries for _requestID in t_analysis_job_request

    SELECT AJR.analysis_tool,
           AJR.param_file_name,
           AJR.settings_file_name,
           AJR.organism_db_name,
           Org.organism,
           AJR.protein_collection_list,
           AJR.protein_options_list,
           AJR.special_processing,
           AJR.data_pkg_id
    INTO _requestInfo
    FROM t_analysis_job_request AJR
         INNER JOIN t_organisms Org
           ON AJR.organism_id = Org.organism_id
    WHERE AJR.request_id = _requestID;

    CREATE TEMP TABLE Tmp_Jobs (
        Job int PRIMARY KEY NOT NULL
    );

    If FOUND Then

        -- Lookup the ResultType for the analysis tool

        SELECT result_type
        INTO _resultType
        FROM t_analysis_tool
        WHERE analysis_tool = _requestInfo.analysis_tool;

        _resultType := Coalesce(_resultType, 'Unknown');

        -- When looking for existing jobs, if the analysis tool is not a Peptide_Hit tool,
        -- we ignore OrganismDBName, Organism Name, Protein Collection List, and Protein Options List

        -- If the tool is a Peptide_Hit tool, we only consider Organism Name when searching
        -- against a legacy Fasta file (i.e. when the Protein Collection List is 'na')

        If Coalesce(_requestInfo.data_pkg_id, 0) > 1 Then
            -- Data package based job request
            INSERT INTO Tmp_Jobs (Job)
            SELECT DISTINCT AJ.job
            FROM t_dataset DS
                 INNER JOIN t_analysis_job AJ
                   ON AJ.dataset_id = DS.dataset_id
                 INNER JOIN t_analysis_tool AJT
                   ON AJ.analysis_tool_id = AJT.analysis_tool_id
                 INNER JOIN t_organisms Org
                   ON AJ.organism_id = Org.organism_id
            WHERE DS.dataset SIMILAR TO 'DataPackage[_]' || _requestInfo.data_pkg_id::text || '[_]%' AND
                  AJT.analysis_tool = _requestInfo.analysis_tool::citext AND
                  AJ.param_file_name = _requestInfo.param_file_name::citext AND
                  AJ.settings_file_name = _requestInfo.settings_file_name::citext AND
                  Coalesce(AJ.special_processing, '') = Coalesce(_requestInfo.special_processing::citext, '') AND
                  (_resultType NOT LIKE '%Peptide_Hit%' OR
                   _resultType LIKE '%Peptide_Hit%' AND
                   (
                       (_requestInfo.protein_collection_list <> 'na' AND
                        AJ.protein_collection_list = _requestInfo.protein_collection_list::citext AND
                        AJ.protein_options_list = _requestInfo.protein_options_list::citext
                       ) OR
                       (_requestInfo.protein_collection_list = 'na' AND
                        AJ.protein_collection_list = _requestInfo.protein_collection_list::citext AND
                        AJ.organism_db_name = _requestInfo.organism_db_name::citext AND
                        Org.organism = _requestInfo.organism::citext
                       )
                   )
                  )
            GROUP BY AJ.job
            ORDER BY AJ.job;
        Else
            -- Dataset based job request
            INSERT INTO Tmp_Jobs (Job)
            SELECT DISTINCT AJ.job
            FROM (SELECT dataset_id
                  FROM t_analysis_job_request_datasets
                  WHERE request_id = _requestID
                 ) DSList
                 INNER JOIN t_analysis_job AJ
                   ON AJ.dataset_id = DSList.dataset_id
                 INNER JOIN t_analysis_tool AJT
                   ON AJ.analysis_tool_id = AJT.analysis_tool_id
                 INNER JOIN t_organisms Org
                   ON AJ.organism_id = Org.organism_id
            WHERE AJT.analysis_tool = _requestInfo.analysis_tool::citext AND
                  AJ.param_file_name = _requestInfo.param_file_name::citext AND
                  AJ.settings_file_name = _requestInfo.settings_file_name::citext AND
                  Coalesce(AJ.special_processing, '') = Coalesce(_requestInfo.special_processing::citext, '') AND
                  (_resultType NOT LIKE '%Peptide_Hit%' OR
                   _resultType LIKE '%Peptide_Hit%' AND
                   (
                       (_requestInfo.protein_collection_list <> 'na' AND
                        AJ.protein_collection_list = _requestInfo.protein_collection_list::citext AND
                        AJ.protein_options_list = _requestInfo.protein_options_list::citext
                       ) OR
                       (_requestInfo.protein_collection_list = 'na' AND
                        AJ.protein_collection_list = _requestInfo.protein_collection_list::citext AND
                        AJ.organism_db_name = _requestInfo.organism_db_name::citext AND
                        Org.organism = _requestInfo.organism::citext
                       )
                   )
                  )
            GROUP BY AJ.job
            ORDER BY AJ.job;
        End If;
    End If;

    RETURN QUERY
    SELECT Src.Job
    FROM Tmp_Jobs Src;

    DROP TABLE Tmp_Jobs;
END
$$;


ALTER FUNCTION public.get_existing_jobs_matching_job_request(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_existing_jobs_matching_job_request(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_existing_jobs_matching_job_request(_requestid integer) IS 'GetExistingJobsMatchingJobRequest';


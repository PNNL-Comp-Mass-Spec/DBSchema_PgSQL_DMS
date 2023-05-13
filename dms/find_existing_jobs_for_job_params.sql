--
-- Name: find_existing_jobs_for_job_params(text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.find_existing_jobs_for_job_params(_datasetlist text, _toolname text, _paramfilename text, _settingsfilename text, _organismdbname text, _organismname text, _protcollnamelist text, _protcolloptionslist text) RETURNS TABLE(job integer, state public.citext, dataset public.citext, created timestamp without time zone, start timestamp without time zone, finish timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      For the given dataset(s), return a table of existing analysis jobs
**      that match the specified tool name, parameter file name, etc.
**
**  Auth:   grk
**  Date:   12/07/2005
**          04/04/2006 grk - increased sized of param file name
**          03/28/2006 grk - added protein collection fields
**          04/07/2006 grk - eliminated job to request map table
**          01/02/2009 grk - added dataset to output rowset
**          02/27/2009 mem - Expanded _comment to varchar(512)
**          03/27/2009 mem - Updated Where clause logic for Peptide_Hit jobs to ignore organism name when using a Protein Collection List
**                         - Expanded _datasetList to varchar(6000)
**          09/18/2009 mem - Switched to using dbo.MakeTableFromList to populate Tmp_Datasets
**                         - Now checking for invalid dataset names
**          09/18/2009 grk - Cleaned up unused parameters
**          05/06/2010 mem - Expanded _settingsFileName to varchar(255)
**          09/25/2012 mem - Expanded _organismDBName and _organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**          11/28/2022 mem - Ported to PostgreSQL
**          05/05/2023 mem - Change table alias name
**          05/12/2023 mem - Rename variables
**
*****************************************************/
DECLARE
    _unknownCount int := 0;
    _datasetName text;
    _organismID int;
    _analysisToolID int;
    _resultType citext;
    _message text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetList := Trim(Coalesce(_datasetList, ''));
    _toolName := Trim(Coalesce(_toolName, ''));
    _paramFileName := Trim(Coalesce(_paramFileName, ''));
    _settingsFileName := Trim(Coalesce(_settingsFileName, ''));
    _organismDBName := Trim(Coalesce(_organismDBName, ''));
    _organismName := Trim(Coalesce(_organismName, ''));
    _protCollNameList := Trim(Coalesce(_protCollNameList, ''));
    _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, ''));

    ---------------------------------------------------
    -- Temporary table to hold dataset list
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Datasets (
        dataset citext,
        ID int NULL
    );

    ---------------------------------------------------
    -- Convert dataset list to table entries
    ---------------------------------------------------

    INSERT INTO Tmp_Datasets (dataset)
    SELECT DISTINCT Value
    FROM public.parse_delimited_list(_datasetList)
    ORDER BY Value;

    ---------------------------------------------------
    -- Get dataset IDs for the datasets in Tmp_Datasets
    ---------------------------------------------------

    UPDATE Tmp_Datasets
    SET ID = t_dataset.dataset_id
    FROM t_dataset
    WHERE t_dataset.dataset = Tmp_Datasets.dataset;

    ---------------------------------------------------
    -- Check for any unknown datasets
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _unknownCount
    FROM Tmp_Datasets
    WHERE ID Is Null;

    If _unknownCount > 0 Then
        If _unknownCount = 1 Then
            SELECT DS.Dataset
            INTO _datasetName
            FROM Tmp_Datasets DS
            WHERE ID Is Null;

            _message := format('Error: "%s" is not a known dataset', _datasetName);
        Else
            _message := format('Error: %s dataset names are invalid', _unknownCount);
        End If;

        RAISE WARNING '%', _message;

        RETURN QUERY
        SELECT 0 AS Job,
               'Error'::citext AS State,
               _message::citext AS Dataset,
               null::timestamp AS Created,
               null::timestamp AS Start,
               null::timestamp AS Finish;

        DROP TABLE Tmp_Datasets;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Convert organism name to ID
    ---------------------------------------------------

    _organismID := get_organism_id(_organismName);

    ---------------------------------------------------
    -- Convert tool name to ID
    ---------------------------------------------------

    _analysisToolID := get_analysis_tool_id (_toolName);

    ---------------------------------------------------
    -- Look for existing jobs
    ---------------------------------------------------

    -- Lookup the ResultType for _toolName
    --
    SELECT Coalesce(result_type, 'Unknown')
    INTO _resultType
    FROM  t_analysis_tool
    WHERE analysis_tool = _toolName;

    If Not FOUND Then
        _resultType := 'Unknown';
    End If;

    -- When looking for existing jobs, if the analysis tool is not a Peptide_Hit tool,
    -- we ignore OrganismDBName, Organism Name, Protein Collection List, and Protein Options List
    --
    -- If the tool is a Peptide_Hit tool, we only consider Organism Name when searching
    -- against a legacy Fasta file (i.e. when the Protein Collection List is 'na')

    RETURN QUERY
    SELECT AJ.job AS Job,
           AJS.job_state AS State,
           DS.dataset AS Dataset,
           AJ.created AS Created,
           AJ.start AS Start,
           AJ.finish AS Finish
    FROM Tmp_Datasets
         INNER JOIN t_dataset DS
           ON Tmp_Datasets.ID = DS.dataset_id
         INNER JOIN t_analysis_job AJ
           ON AJ.dataset_id = DS.dataset_id
         INNER JOIN t_analysis_tool AJT
           ON AJ.analysis_tool_id = AJT.analysis_tool_id
         INNER JOIN t_organisms Org
           ON AJ.organism_id = Org.organism_id
         INNER JOIN t_analysis_job_state AJS
           ON AJ.job_state_id = AJS.job_state_id
    WHERE AJT.analysis_tool = _toolName::citext AND
          AJ.param_file_name = _paramFileName::citext AND
          AJ.settings_file_name = _settingsFileName::citext AND
          (_resultType NOT LIKE '%Peptide_Hit%' OR
           _resultType LIKE '%Peptide_Hit%' AND
           (
             (_protCollNameList::citext <> 'na'::citext AND
              AJ.protein_collection_list = _protCollNameList::citext AND
              AJ.protein_options_list = _protCollOptionsList::citext
             ) OR
             (_protCollNameList::citext = 'na'::citext AND
              AJ.protein_collection_list = _protCollNameList::citext AND
              AJ.organism_db_name = _organismDBName::citext AND
              Org.organism = _organismName::citext
             )
           )
          )
    ORDER BY AJ.job;

    If Not FOUND Then
        RAISE INFO 'Jobs not found for the specified datasets and tool %, filtering on:', _toolName;
        RAISE INFO '  Parameter file: %', _paramFileName;
        RAISE INFO '  Settings file: %', _settingsFileName;
        RAISE INFO '  Result type: %', _resultType;
        RAISE INFO '  Protein collection list: %', _protCollNameList;
        RAISE INFO '  Protein options: %', _protCollOptionsList;
        RAISE INFO '  Organism DB: %', _organismDBName;
        RAISE INFO '  Organism: %', _organismName;
    End If;

    DROP TABLE Tmp_Datasets;
END
$$;


ALTER FUNCTION public.find_existing_jobs_for_job_params(_datasetlist text, _toolname text, _paramfilename text, _settingsfilename text, _organismdbname text, _organismname text, _protcollnamelist text, _protcolloptionslist text) OWNER TO d3l243;

--
-- Name: FUNCTION find_existing_jobs_for_job_params(_datasetlist text, _toolname text, _paramfilename text, _settingsfilename text, _organismdbname text, _organismname text, _protcollnamelist text, _protcolloptionslist text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.find_existing_jobs_for_job_params(_datasetlist text, _toolname text, _paramfilename text, _settingsfilename text, _organismdbname text, _organismname text, _protcollnamelist text, _protcolloptionslist text) IS 'FindExistingJobsForJobParams';


--
-- Name: get_psm_job_defaults(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_psm_job_defaults(_datasets text) RETURNS TABLE(datasets public.citext, metadata public.citext, tool_name public.citext, job_type_name public.citext, job_type_desc public.citext, dyn_met_ox_enabled integer, stat_cys_alk_enabled integer, dyn_sty_phos_enabled integer, organism_name public.citext, prot_coll_name_list public.citext, prot_coll_options_list public.citext, error_message public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parses the list of datasets to create a table of stats and to suggest
**      default search settings for creating an analysis job to search MS/MS data (PSM search)
**
**  Arguments:
**    _datasets             Comma-separated list of dataset names
**
**  Description of data columns returned by this function:
**    datasets                  Alphabetized list of dataset names (duplicate datasets are consolidated)
**    metadata                  Table of metadata with columns separated by colons and rows separated by vertical bars
**    tool_name                 Tool name
**    job_type_name             Job type name
**    job_type_desc             Job type description
**    dyn_met_ox_enabled        1 if dynamic Met Oxidation should be enabled, otherwise 0
**    stat_cys_alk_enabled      1 if static Cys Alkylation should be enabled, otherwise 0
**    dyn_sty_phos_enabled      1 if dynamic STY Phosphorylation should be enabled, otherwise 0
**    organism_name             Organism name
**    prot_coll_name_list       Protein collection list
**    prot_coll_options_list    Protein collection options
**    error_message             Empty string if no problems, error message if an issue
**
**  Example usage:
**    SELECT * FROM public.get_psm_job_defaults('QC_Mam_23_01_Run01_FAIMS_Merry_02June23_WBEH-23-05-13');
**
**  Example results:
**    Datasets:                 QC_Mam_23_01_Run01_FAIMS_Merry_02June23_WBEH-23-05-13
**    Metadata:                 Metadata:Description:Datasets|HMS-HCD-HMSn:High res MS with high res HCD MSn:1|Alkylated:Sample (experiment) marked as alkylated in DMS:1|Labeling:none:1|Enzyme:Trypsin:1|
**    Tool_name:                MSGFPlus_MzML
**    Job_type_name:            High Res MS1
**    Job_type_desc:            Data acquired with high resolution MS1 spectra, typically an Orbitrap or LTQ-FT
**    Dyn_met_ox_enabled:       1
**    Stat_cys_alk_enabled:     1
**    Dyn_sty_phos_enabled:     0
**    Organism_name:            Mus_musculus
**    Prot_coll_name_list:      M_musculus_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov
**    Prot_coll_options_list:   seq_direction=decoy
**
**  Auth:   mem
**  Date:   11/14/2012 mem - Initial version
**          11/20/2012 mem - Added 3 new parameters: organism name, protein collection name, and protein collection options
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Now passing _autoRemoveNotReleasedDatasets to validate_analysis_job_request_datasets
**          09/03/2013 mem - Added iTRAQ8
**          04/23/2015 mem - Now passing _toolName to validate_analysis_job_request_datasets
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/18/2016 mem - Added TMT6 and TMT10
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Exclude logging some try/catch errors
**          12/06/2017 mem - Set _allowNewDatasets to true when calling validate_analysis_job_request_datasets
**          06/04/2018 mem - Change default tool to MSGFPlus_MzML
**          01/28/2020 mem - Use '%TMT1%' instead of '%TMT10' so we can match TMT10 and TMT11
**          09/10/2020 mem - Add job types 'TMT Zero' and 'TMT 16-plex'
**          08/02/2023 mem - Ported to PostgreSQL
**          09/01/2023 mem - Change column Dataset_Rating_ID to smallint in temp table
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/11/2023 mem - Remove unnecessary _trimWhitespace argument when calling validate_na_parameter
**
*****************************************************/
DECLARE
    _metadata citext;
    _toolName citext;
    _jobTypeName citext;
    _jobTypeDesc citext;
    _dynMetOxEnabled int;
    _statCysAlkEnabled int;
    _dynSTYPhosEnabled int;
    _organismName citext;
    _protCollNameList text;
    _protCollOptionsList citext;

    _collectionCountAdded int;
    _message text;
    _returncode text;

    _addon text;
    _topDatasetType citext := '';
    _topLabeling citext := '';
    _datasetCount int := 0;
    _datasetCountAlkylated int := 0;
    _datasetCountPhospho int := 0;
    _organismCount int := 0;
    _logErrors boolean := false;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returncode := '';

    ---------------------------------------------------
    -- Initialize the output parameters
    ---------------------------------------------------

    _metadata := '';
    _toolName := 'MSGFPlus_MzML';
    _jobTypeName := '';
    _jobTypeDesc := '';
    _dynMetOxEnabled := 0;
    _statCysAlkEnabled := 0;
    _dynSTYPhosEnabled := 0;
    _organismName := '';
    _protCollNameList := '';
    _protCollOptionsList := '';

    ---------------------------------------------------
    -- Dataset list shouldn't be empty
    ---------------------------------------------------

    If Coalesce(_datasets, '') = '' Then
        _message := 'Dataset list is empty';

        RETURN QUERY
        SELECT ''::citext As datasets,
               ''::citext As metadata,
               ''::citext As tool_name,
               ''::citext As job_type_name,
               ''::citext As job_type_desc,
               0          As dyn_met_ox_enabled,
               0          As stat_cys_alk_enabled,
               0          As dyn_sty_phos_enabled,
               ''::citext As organism_name,
               ''::citext As prot_coll_name_list,
               ''::citext As prot_coll_options_list,
               _message::citext As error_message;

        RETURN;
    End If;

    _logErrors := true;

    ---------------------------------------------------
    -- Create temporary table to hold list of datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_Name citext,
        Dataset_ID int NULL,
        Instrument_Class text NULL,
        Dataset_State_ID int NULL,
        Archive_State_ID int NULL,
        Dataset_Type text NULL,
        Dataset_Rating_ID smallint NULL
    );

    CREATE INDEX IX_Tmp_DatasetInfo_DatasetID ON Tmp_DatasetInfo (Dataset_ID);

    ---------------------------------------------------
    -- Create several additional temporary tables
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetTypeStats (
        Dataset_Type text,
        Description text,
        DatasetCount int
    );

    CREATE TEMP TABLE Tmp_DatasetLabelingStats (
        Labeling text,
        DatasetCount int
    );

    CREATE TEMP TABLE Tmp_Organisms (
        OrganismName text,
        DatasetCount int
    );

    ---------------------------------------------------
    -- Populate Tmp_DatasetInfo using the dataset list
    -- Remove any duplicates that may be present
    ---------------------------------------------------

    INSERT INTO Tmp_DatasetInfo ( Dataset_Name )
    SELECT DISTINCT Value
    FROM public.parse_delimited_list ( _datasets );

    ---------------------------------------------------
    -- Validate the datasets in Tmp_DatasetInfo
    ---------------------------------------------------

    CALL public.validate_analysis_job_request_datasets (
                    _autoRemoveNotReleasedDatasets => true,
                    _toolName                      => _toolName,
                    _allowNewDatasets              => true,
                    _message                       => _message,         -- Output
                    _returnCode                    => _returnCode);     -- Output

    If _returnCode <> '' Then

        RETURN QUERY
        SELECT ''::citext As datasets,
               ''::citext As metadata,
               ''::citext As tool_name,
               ''::citext As job_type_name,
               ''::citext As job_type_desc,
               0          As dyn_met_ox_enabled,
               0          As stat_cys_alk_enabled,
               0          As dyn_sty_phos_enabled,
               ''::citext As organism_name,
               ''::citext As prot_coll_name_list,
               ''::citext As prot_coll_options_list,
               _message::citext As error_message;

        DROP TABLE Tmp_DatasetInfo;
        DROP TABLE Tmp_DatasetTypeStats;
        DROP TABLE Tmp_DatasetLabelingStats;
        DROP TABLE Tmp_Organisms;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Regenerate the dataset list, sorting by dataset name
    ---------------------------------------------------

    SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
    INTO _datasets
    FROM Tmp_DatasetInfo;

    ---------------------------------------------------
    -- Populate a temporary table with dataset type stats
    ---------------------------------------------------

    INSERT INTO Tmp_DatasetTypeStats (Dataset_Type, Description, DatasetCount)
    SELECT DSType.Dataset_Type, DSType.Description, COUNT(DSInfo.dataset_id) AS DatasetCount
    FROM Tmp_DatasetInfo DSInfo
         INNER JOIN t_dataset_type_name DSType
           ON DSInfo.Dataset_Type = DSType.Dataset_Type
    GROUP BY DSType.Dataset_Type, DSType.Description
    ORDER BY DSType.Dataset_Type;

    SELECT Dataset_Type
    INTO _topDatasetType
    FROM Tmp_DatasetTypeStats
    ORDER BY DatasetCount Desc
    LIMIT 1;

    ---------------------------------------------------
    -- Populate a temporary table with labeling stats
    ---------------------------------------------------

    INSERT INTO Tmp_DatasetLabelingStats (Labeling, DatasetCount)
    SELECT E.labelling, COUNT(DSInfo.dataset_id) AS DatasetCount
    FROM Tmp_DatasetInfo DSInfo
         INNER JOIN t_dataset DS
           ON DSInfo.dataset_id = DS.dataset_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
    GROUP BY E.labelling
    ORDER BY E.labelling;

    SELECT Labeling
    INTO _topLabeling
    FROM Tmp_DatasetLabelingStats
    ORDER BY DatasetCount Desc
    LIMIT 1;

    ---------------------------------------------------
    -- Populate a temporary table with the organism(s) for the datasets
    ---------------------------------------------------

    INSERT INTO Tmp_Organisms (OrganismName, DatasetCount)
    SELECT O.organism, COUNT(DSInfo.dataset_id) AS DatasetCount
    FROM Tmp_DatasetInfo DSInfo
         INNER JOIN t_dataset DS
           ON DSInfo.dataset_id = DS.dataset_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_organisms O
           ON E.organism_id = O.organism_id
    GROUP BY O.organism
    ORDER BY O.organism;

    SELECT OrganismName
    INTO _organismName
    FROM Tmp_Organisms
    ORDER BY DatasetCount Desc
    LIMIT 1;

    _protCollNameList := '';
    _protCollOptionsList := 'seq_direction=decoy';

    -- Lookup the default protein collection name (if defined)
    --
    SELECT organism_db_name
    INTO _protCollNameList
    FROM t_organisms
    WHERE organism = _organismName AND Coalesce(organism_db_name, 'na') <> 'na';

    If char_length(_protCollNameList) > 0 And public.validate_na_parameter(_protCollNameList) <> 'na' Then

        -- Append the default contaminant collections
        CALL public.validate_protein_collection_list_for_datasets (
                            _datasets,
                            _protCollNameList     => _protCollNameList,     -- Output
                            _collectionCountAdded => _collectionCountAdded, -- Output
                            _message              => _message,              -- Output
                            _returncode           => _returnCode,           -- Output
                            _showDebug            => false);

    End If;

    ---------------------------------------------------
    -- Populate _metadata
    ---------------------------------------------------

    -- Header row
    --
    _metadata := 'Metadata:Description:Datasets|';

    -- Dataset Type stats
    --
    SELECT string_agg(format('%s:%s:%s', Dataset_Type, Description, DatasetCount), '|' ORDER BY Dataset_Type)
    INTO _addon
    FROM Tmp_DatasetTypeStats;

    _metadata := format('%s%s|', _metadata, _addon);

    -- Alkylation
    --
    SELECT COUNT(DSInfo.dataset_id),
           SUM(CASE WHEN alkylation = 'Y' THEN 1 ELSE 0 END)
    INTO _datasetCount, _datasetCountAlkylated
    FROM Tmp_DatasetInfo DSInfo
         INNER JOIN t_dataset DS
           ON DSInfo.dataset_id = DS.dataset_id
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id;

    _metadata := format('%sAlkylated:Sample (experiment) marked As alkylated in DMS:%s|', _metadata, _datasetCountAlkylated);

    -- Labeling
    --
    SELECT string_agg(format('Labeling:%s:%s', Labeling, DatasetCount), '|' ORDER BY Labeling)
    INTO _addon
    FROM Tmp_DatasetLabelingStats;

    _metadata := format('%s%s|', _metadata, _addon);

    -- Enzyme
    --
    SELECT string_agg(format('Enzyme:%s:%s', CountQ.enzyme_name, CountQ.Datasets), '|' ORDER BY CountQ.enzyme_name)
    INTO _addon
    FROM (  SELECT Enz.enzyme_name, COUNT(DSInfo.dataset_id) As Datasets
            FROM Tmp_DatasetInfo DSInfo
                 INNER JOIN t_dataset DS
                   ON DSInfo.dataset_id = DS.dataset_id
                 INNER JOIN t_experiments E
                   ON DS.exp_id = E.exp_id
                 INNER JOIN t_enzymes Enz
                   ON E.enzyme_id = Enz.enzyme_id
            GROUP BY Enz.enzyme_name
        ) CountQ;

    _metadata := format('%s%s|', _metadata, _addon);

    -- Display the organism names if datasets from multiple organisms are present
    --
    If _organismCount > 1 Then
        SELECT string_agg(format('Organism:%s:%s', OrganismName, DatasetCount), '|' ORDER BY OrganismName)
        INTO _addon
        FROM Tmp_Organisms;

        _metadata := format('%s%s|', _metadata, _addon);
    End If;

    -- Look for phosphorylation
    --
    SELECT COUNT(DSInfo.dataset_id)
    INTO _datasetCountPhospho
    FROM Tmp_DatasetInfo DSInfo
    WHERE DSInfo.Dataset_Name LIKE '%Phospho%' Or
          DSInfo.Dataset_Name LIKE '%NiNTA%';

    ---------------------------------------------------
    -- Define the default options using the stats on the datasets
    ---------------------------------------------------

    _jobTypeName := '';

    If _jobTypeName = '' And _topLabeling = 'iTRAQ8' And _topDatasetType Like '%HCD%' Then
        _jobTypeName := 'iTRAQ 8-plex';
    End If;

    If _jobTypeName = '' And _topLabeling = 'iTRAQ' And _topDatasetType Like '%HCD%' Then
        _jobTypeName := 'iTRAQ 4-plex';
    End If;

    If _jobTypeName = '' And _topLabeling = 'TMT16' And _topDatasetType Like '%HCD%' Then
        _jobTypeName := 'TMT 16-plex';
    End If;

    If _jobTypeName = '' And _topLabeling In ('TMT6', 'TMT10', 'TMT11') And _topDatasetType Like '%HCD%' Then
        _jobTypeName := 'TMT 6-plex';
    End If;

    If _jobTypeName = '' And _topLabeling = 'TMT0' And _topDatasetType Like '%HCD%' Then
        _jobTypeName := 'TMT Zero';
    End If;

    If _jobTypeName = '' And _topDatasetType Like 'MS-%MSn' Then
        _jobTypeName := 'Low Res MS1';
    End If;

    If _jobTypeName = '' And _topDatasetType Like '%HMS-%MSn' Then
        _jobTypeName := 'High Res MS1';
    End If;

    If _datasetCountPhospho > _datasetCount * 0.85 Then
        _dynSTYPhosEnabled := 1;
        _dynMetOxEnabled := 0;
    Else
        _dynSTYPhosEnabled := 0;
        _dynMetOxEnabled := 1;
    End If;

    If _datasetCountAlkylated > _datasetCount * 0.85 Then
        _statCysAlkEnabled := 1;
    Else
        _statCysAlkEnabled := 0;
    End If;

    -- Lookup the description for _jobTypeName
    --
    SELECT JT.job_type_description
    INTO _jobTypeDesc
    FROM t_default_psm_job_types JT
    WHERE JT.job_type_name = _jobTypeName;

    _jobTypeDesc := Trim(Coalesce(_jobTypeDesc, ''));

    RETURN QUERY
    SELECT _datasets::citext         As datasets,
           _metadata                 As metadata,
           _toolName                 As tool_name,
           _jobTypeName              As job_type_name,
           _jobTypeDesc              As job_type_desc,
           _dynMetOxEnabled          As dyn_met_ox_enabled,
           _statCysAlkEnabled        As stat_cys_alk_enabled,
           _dynSTYPhosEnabled        As dyn_sty_phos_enabled,
           _organismName             As organism_name,
           _protCollNameList::citext As prot_coll_name_list,
           _protCollOptionsList      As prot_coll_options_list,
           ''::citext                As error_message;

    DROP TABLE Tmp_DatasetInfo;
    DROP TABLE Tmp_DatasetTypeStats;
    DROP TABLE Tmp_DatasetLabelingStats;
    DROP TABLE Tmp_Organisms;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

    If _logErrors Then
        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);
    Else
        _message := _exceptionMessage;
    End If;

    If Coalesce(_returnCode, '') = '' Then
        _returnCode := _sqlState;
    End If;

    If Position(_returnCode In _message) = 0 Then
        _message := format('%s (%s)', _message, _returnCode);
    End If;

    RETURN QUERY
    SELECT _datasets::citext As datasets,
           ''::citext As metadata,
           ''::citext As tool_name,
           ''::citext As job_type_name,
           ''::citext As job_type_desc,
           0          As dyn_met_ox_enabled,
           0          As stat_cys_alk_enabled,
           0          As dyn_sty_phos_enabled,
           ''::citext As organism_name,
           ''::citext As prot_coll_name_list,
           ''::citext As prot_coll_options_list,
           _message::citext As error_message;


    DROP TABLE IF EXISTS Tmp_DatasetInfo;
    DROP TABLE IF EXISTS Tmp_DatasetTypeStats;
    DROP TABLE IF EXISTS Tmp_DatasetLabelingStats;
    DROP TABLE IF EXISTS Tmp_Organisms;
END
$$;


ALTER FUNCTION public.get_psm_job_defaults(_datasets text) OWNER TO d3l243;

--
-- Name: FUNCTION get_psm_job_defaults(_datasets text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_psm_job_defaults(_datasets text) IS 'GetPSMJobDefaults';


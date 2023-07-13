--
CREATE OR REPLACE PROCEDURE public.get_psm_job_defaults
(
    INOUT _datasets text,
    INOUT _metadata text,
    INOUT _toolName text,
    INOUT _jobTypeName text,
    INOUT _jobTypeDesc text,
    INOUT _dynMetOxEnabled int,
    INOUT _statCysAlkEnabled int,
    INOUT _dynSTYPhosEnabled int,
    INOUT _organismName text,
    INOUT _protCollNameList text,
    INOUT _protCollOptionsList text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Parses the list of datasets to create a table of stats and to suggest
**      default search settings for creating an analysis job to search MS/MS data (PSM search)
**
**  Arguments:
**    _datasets             Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
**    _metadata             Output parameter; table of metadata with columns separated by colons and rows separated by vertical bars
**    _toolName             Output parameter; tool name
**    _jobTypeName          Output parameter; job type name
**    _jobTypeDesc          Output parameter; job type description
**    _dynMetOxEnabled      Output parameter; 1 if dynamic Met Oxidation should be enabled, otherwise 0
**    _statCysAlkEnabled    Output parameter; 1 if static Cys Alkylation should be enabled, otherwise 0
**    _dynSTYPhosEnabled    Output parameter; 1 if dynamic STY Phosphorylation should be enabled, otherwise 0
**    _organismName         Output parameter; organism
**    _protCollNameList     Output parameter; protein collections
**    _protCollOptionsList  Output parameter; protein collection options
**
**  Example usage:
**    CALL get_psm_job_defaults ('QC_Mam_23_01_Run01_FAIMS_Merry_02June23_WBEH-23-05-13',
**                               _metadata,              -- Output
**                               _toolName,              -- Output
**                               _jobTypeName,           -- Output
**                               _jobTypeDesc,           -- Output
**                               _dynMetOxEnabled,       -- Output
**                               _statCysAlkEnabled,     -- Output
**                               _dynSTYPhosEnabled,     -- Output
**                               _organismName,          -- Output
**                               _protCollNameList,      -- Output
**                               _protCollOptionsList,   -- Output
**                               _message,               -- Output
**                               _returnCode);           -- Output
**
**    Output values:
**      _metadata = 'Metadata:Description:Datasets|HMS-HCD-HMSn:High res MS with high res HCD MSn:1|Alkylated:Sample (experiment) marked as alkylated in DMS:1|Labeling:none:1|Enzyme:Trypsin:1|'
**      _toolName = 'MSGFPlus_MzML'
**      _jobTypeName = 'High Res MS1'
**      _jobTypeDesc = 'Data acquired with high resolution MS1 spectra, typically an Orbitrap or LTQ-FT'
**      _dynMetOxEnabled = '1'
**      _statCysAlkEnabled = '1'
**      _dynSTYPhosEnabled = '0'
**      _organismName = 'Mus_musculus'
**      _protCollNameList = 'M_musculus_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov'
**      _protCollOptionsList = 'seq_direction=decoy	'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _result int := 0;
    _list text;
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
    _returnCode := '';

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
        RAISE EXCEPTION 'Dataset list is empty';
    End If;

    _logErrors := true;

    ---------------------------------------------------
    -- Create temporary table to hold list of datasets
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetInfo (
        Dataset_Name citext,
        Dataset_ID int NULL,
        Instrument_class text NULL,
        Dataset_State_ID int NULL,
        Archive_State_ID int NULL,
        Dataset_Type text NULL,
        Dataset_rating int NULL
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
    SELECT DISTINCT Item
    FROM public.parse_delimited_list ( _datasets );

    ---------------------------------------------------
    -- Validate the datasets in Tmp_DatasetInfo
    ---------------------------------------------------

    CALL validate_analysis_job_request_datasets (
                _message => _message,                   -- Output
                _autoRemoveNotReleasedDatasets => true,
                _toolName => _toolName,
                _allowNewDatasets => true);

    If _returnCode <> '' Then
        _logErrors := false;
        RAISE EXCEPTION _message;
    End If;

    ---------------------------------------------------
    -- Regenerate the dataset list, sorting by dataset name
    ---------------------------------------------------

    SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name;)
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

    If char_length(_protCollNameList) > 0 And public.validate_na_parameter(_protCollNameList, 1) <> 'na' Then

        -- Append the default contaminant collections
        CALL validate_protein_collection_list_for_datasets (
                            _datasets,
                            _protCollNameList => _protCollNameList,     -- Output
                            _showDebug => true);

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

    _metadata := format('%sAlkylated:Sample (experiment) marked As alkylated in DMS:%s|', _metadata, datasetCountAlkylated);

    -- Labeling
    --
    SELECT string_agg(format('Labeling:%s:%s', Labeling, DatasetCount), '|' ORDER BY Labeling)
    INTO _addon
    FROM Tmp_DatasetLabelingStats;

    _metadata := format('%s%s|', _metadata, _addon);

    -- Enzyme
    --
    SELECT string_agg('Enzyme:%s:%s', CountQ.enzyme_name, CountQ.Datasets, '|' ORDER BY CountQ.enzyme_name)
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
        ) CountQ
    ORDER BY;

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

    If _jobTypeName = '' And _topLabeling IN ('TMT6', 'TMT10', 'TMT11') And _topDatasetType Like '%HCD%' Then
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
    SELECT job_type_description
    INTO _jobTypeDesc
    FROM t_default_psm_job_types
    WHERE job_type_name = _jobTypeName;

    _jobTypeDesc := Coalesce(_jobTypeDesc, '');

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

    DROP TABLE IF EXISTS Tmp_DatasetInfo;
    DROP TABLE IF EXISTS Tmp_DatasetTypeStats;
    DROP TABLE IF EXISTS Tmp_DatasetLabelingStats;
    DROP TABLE IF EXISTS Tmp_Organisms;
END
$$;

COMMENT ON PROCEDURE public.get_psm_job_defaults IS 'GetPSMJobDefaults';

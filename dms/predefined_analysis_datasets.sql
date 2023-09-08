--
-- Name: predefined_analysis_datasets(integer, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.predefined_analysis_datasets(_ruleid integer, _infoonly boolean DEFAULT false, _previewsql boolean DEFAULT false, _populatetemptable boolean DEFAULT false) RETURNS TABLE(dataset public.citext, dataset_id integer, instrument_class public.citext, instrument public.citext, campaign public.citext, experiment public.citext, organism public.citext, experiment_labelling public.citext, experiment_comment public.citext, dataset_comment public.citext, dataset_type public.citext, dataset_rating_id smallint, dataset_rating public.citext, separation_type public.citext, analysis_tool public.citext, parameter_file public.citext, settings_file public.citext, protein_collections public.citext, legacy_fasta public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Shows datasets that satisfy a given predefined analysis rule
**
**  Arguments:
**    _ruleID              Predefined analysis rule ID
**    _infoOnly            When true, shows the criteria for the predefine rule, and shows the number of matching datasets (in the Dataset_ID and Settings_File columns of the output table)
**    _previewSql          When true, show queries that would be used
**    _populateTempTable   When true, populates table T_Tmp_PredefinedAnalysisDatasets with the results (creates the table if it does not yet exist)
**
**  Usage:
**      SELECT * FROM predefined_analysis_datasets(300, _infoonly => true);
**      SELECT * FROM predefined_analysis_datasets(300, _infoonly => false, _previewSQL => true)
**      SELECT * FROM predefined_analysis_datasets(300, _infoonly => false)
**
**  Auth:   grk
**  Date:   06/22/2005
**          03/03/2006 mem - Fixed bug involving evaluation of _datasetNameCriteria
**          08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**          09/04/2009 mem - Added DatasetType filter
**                         - Added parameters _infoOnly and _previewSql
**          05/03/2012 mem - Added parameter _populateTempTable
**          07/26/2016 mem - Now include Dataset Rating
**          08/04/2016 mem - Fix column name for dataset Rating ID
**          03/17/2017 mem - Include job, parameter file, settings file, etc. for the predefines that would run for the matching datasets
**          04/21/2017 mem - Add AD_instrumentNameCriteria
**          06/30/2022 mem - Rename parameter file argument
**          05/26/2023 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          07/11/2023 mem - Use COUNT(id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _predefineInfo record;
    _s text;
    _sqlWhere text;
    _datasetCount int;
    _datasetDateMin timestamp;
    _datasetDateMax timestamp;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ruleID            := Coalesce(_ruleID, 0);
    _infoOnly          := Coalesce(_infoOnly, false);
    _previewSql        := Coalesce(_previewSql, false);
    _populateTempTable := Coalesce(_populateTempTable, false);

    If _populateTempTable And Not _previewSql Then
        DROP TABLE IF EXISTS T_Tmp_PredefinedAnalysisDatasets;
    End If;

    SELECT Coalesce(instrument_class_criteria, '') AS InstrumentClassCriteria,
           Coalesce(campaign_name_criteria,    '') AS CampaignNameCriteria,
           Coalesce(experiment_name_criteria,  '') AS ExperimentNameCriteria,
           Coalesce(instrument_name_criteria,  '') AS InstrumentNameCriteria,
           Coalesce(instrument_excl_criteria,  '') AS InstrumentExclCriteria,
           Coalesce(organism_name_criteria,    '') AS OrganismNameCriteria,
           Coalesce(labelling_incl_criteria,   '') AS LabellingInclCriteria,
           Coalesce(labelling_excl_criteria,   '') AS LabellingExclCriteria,
           Coalesce(dataset_name_criteria,     '') AS DatasetNameCriteria,
           Coalesce(dataset_type_criteria,     '') AS DatasetTypeCriteria,
           Coalesce(exp_comment_criteria,      '') AS ExpCommentCriteria,
           Coalesce(separation_type_criteria,  '') AS SeparationTypeCriteria,
           Coalesce(campaign_excl_criteria,    '') AS CampaignExclCriteria,
           Coalesce(experiment_excl_criteria,  '') AS ExperimentExclCriteria,
           Coalesce(dataset_excl_criteria,     '') AS DatasetExclCriteria,
           Coalesce(analysis_tool_name,        '') AS AnalysisToolName,
           Coalesce(param_file_name,           '') AS ParamFileName,
           Coalesce(settings_file_name,        '') AS SettingsFileName,
           Coalesce(protein_collection_list,   '') AS ProteinCollectionList,
           Coalesce(organism_db_name,          '') AS OrganismDBName
    INTO _predefineInfo
    FROM t_predefined_analysis
    WHERE predefine_id = _ruleID;

/*
    RAISE INFO 'InstrumentClass: %',   _predefineInfo.InstrumentClassCriteria;
    RAISE INFO 'CampaignName: %',      _predefineInfo.CampaignNameCriteria;
    RAISE INFO 'Experiment: %',        _predefineInfo.ExperimentNameCriteria;
    RAISE INFO 'InstrumentName: %',    _predefineInfo.InstrumentNameCriteria;
    RAISE INFO 'InstrumentExcl: %',    _predefineInfo.InstrumentExclCriteria;
    RAISE INFO 'OrganismName: %',      _predefineInfo.OrganismNameCriteria;
    RAISE INFO 'LabellingIncl: %',     _predefineInfo.LabellingInclCriteria;
    RAISE INFO 'LabellingExcl: %',     _predefineInfo.LabellingExclCriteria;
    RAISE INFO 'DatasetName: %',       _predefineInfo.DatasetNameCriteria;
    RAISE INFO 'DatasetType: %',       _predefineInfo.DatasetTypeCriteria;
    RAISE INFO 'ExperimentComment: %', _predefineInfo.ExpCommentCriteria;
    RAISE INFO 'SeparationType: %',    _predefineInfo.SeparationTypeCriteria;
    RAISE INFO 'CampaignExcl: %',      _predefineInfo.CampaignExclCriteria;
    RAISE INFO 'ExperimentExcl: %',    _predefineInfo.ExperimentExclCriteria;
    RAISE INFO 'DatasetExcl: %',       _predefineInfo.DatasetExclCriteria;
*/

    _sqlWhere := ' WHERE true';

    If _predefineInfo.InstrumentClassCriteria <> '' Then
        _sqlWhere := format('%s AND (Instrument_Class SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.InstrumentClassCriteria);
    End If;

    If _predefineInfo.InstrumentNameCriteria <> '' Then
        _sqlWhere := format('%s AND (Instrument SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.InstrumentNameCriteria);
    End If;

    If _predefineInfo.InstrumentExclCriteria <> '' Then
        _sqlWhere := format('%s AND (NOT Instrument SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.InstrumentExclCriteria);
    End If;

    If _predefineInfo.CampaignNameCriteria <> '' Then
        _sqlWhere := format('%s AND (Campaign SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.CampaignNameCriteria);
    End If;

    If _predefineInfo.ExperimentNameCriteria <> '' Then
        _sqlWhere := format('%s AND (Experiment SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.ExperimentNameCriteria);
    End If;

    If _predefineInfo.LabellingInclCriteria <> '' Then
        _sqlWhere := format('%s AND (Experiment_Labelling SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.LabellingInclCriteria);
    End If;

    If _predefineInfo.LabellingExclCriteria <> '' Then
        _sqlWhere := format('%s AND (NOT Experiment_Labelling SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.LabellingExclCriteria);
    End If;

    If _predefineInfo.SeparationTypeCriteria <> '' Then
        _sqlWhere := format('%s AND (Separation_Type SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.SeparationTypeCriteria);
    End If;

    If _predefineInfo.CampaignExclCriteria <> '' Then
        _sqlWhere := format('%s AND (NOT Campaign SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.CampaignExclCriteria);
    End If;

    If _predefineInfo.ExperimentExclCriteria <> '' Then
        _sqlWhere := format('%s AND (NOT Experiment SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.ExperimentExclCriteria);
    End If;

    If _predefineInfo.DatasetExclCriteria <> '' Then
        _sqlWhere := format('%s AND (NOT Dataset SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.DatasetExclCriteria);
    End If;

    If _predefineInfo.OrganismNameCriteria <> '' Then
        _sqlWhere := format('%s AND (Organism SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.OrganismNameCriteria);
    End If;

    If _predefineInfo.DatasetNameCriteria <> '' Then
        _sqlWhere := format('%s AND (Dataset SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.DatasetNameCriteria);
    End If;

    If _predefineInfo.DatasetTypeCriteria <> '' Then
        _sqlWhere := format('%s AND (Dataset_Type SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.DatasetTypeCriteria);
    End If;

    If _predefineInfo.ExpCommentCriteria <> '' Then
        _sqlWhere := format('%s AND (Experiment_Comment SIMILAR TO ''%s'')', _sqlWhere, _predefineInfo.ExpCommentCriteria);
    End If;

    _s := '';

    If _infoOnly Then

        _s := ' SELECT COUNT(ID) AS DatasetCount,'
                     ' MIN(DS_Date) AS Dataset_Date_Min,'
                     ' MAX(DS_Date) AS Dataset_Date_Max'
              ' FROM V_Predefined_Analysis_Dataset_Info' ||
              _sqlWhere;

        If _previewSql Then
            RAISE INFO '%', _s;
            RETURN;
        End If;

        EXECUTE _s
        INTO _datasetCount, _datasetDateMin, _datasetDateMax;

        RETURN QUERY
        SELECT format('%s%s',
                      _predefineInfo.DatasetNameCriteria,
                      Case When _predefineInfo.DatasetExclCriteria = ''
                           Then ''
                           Else format(' (Exclude "%s")', _predefineInfo.DatasetExclCriteria)
                      End)::citext AS Dataset,
               _datasetCount As Dataset_ID,
               _predefineInfo.InstrumentClassCriteria::citext AS Instrument_Class,
               format('%s%s',
                      _predefineInfo.InstrumentNameCriteria,
                      Case When _predefineInfo.InstrumentExclCriteria = ''
                           Then ''
                           Else format(' (Exclude "%s")', _predefineInfo.InstrumentExclCriteria)
                      End)::citext AS Instrument,
               format('%s%s',
                      _predefineInfo.CampaignNameCriteria,
                      Case When _predefineInfo.CampaignExclCriteria = ''
                           Then ''
                           Else format(' (Exclude "%s")', _predefineInfo.CampaignExclCriteria)
                      End)::citext AS Campaign,
               format('%s%s',
                      _predefineInfo.ExperimentNameCriteria,
                      Case When _predefineInfo.ExperimentExclCriteria = ''
                           Then ''
                           Else format(' (Exclude "%s")', _predefineInfo.ExperimentExclCriteria)
                      End)::citext AS Experiment,
               _predefineInfo.OrganismNameCriteria::citext AS Organism,
                format('%s%s',
                      _predefineInfo.LabellingInclCriteria,
                      Case When _predefineInfo.LabellingExclCriteria = ''
                           Then ''
                           Else format(' (Exclude "%s")', _predefineInfo.LabellingExclCriteria)
                      End)::citext AS Experiment_Labelling,
               _predefineInfo.ExpCommentCriteria::citext AS Experiment_Comment,
               ''::citext AS Dataset_Comment,
               _predefineInfo.DatasetTypeCriteria::citext AS Dataset_Type,
               0::smallint AS Dataset_Rating_ID,
               ''::citext AS Dataset_Rating,
               _predefineInfo.SeparationTypeCriteria::citext AS Separation_Type,
               ''::citext AS Analysis_Tool,
               format('Predefine rule %s', _ruleID)::citext AS Parameter_File,
               format('Matching datasets: %s', _datasetCount)::citext AS Settings_File,
               format('Oldest dataset date: %s', public.timestamp_text(_datasetDateMin))::citext AS Protein_Collections,
               format('Newest dataset date: %s', public.timestamp_text(_datasetDateMax))::citext AS Legacy_FASTA;

        RETURN;
    End If;

    _s := ' SELECT Dataset, ID,'
               ' Instrument_Class, Instrument,'
               ' Campaign, Experiment, Organism,'
               ' Experiment_Labelling, Experiment_Comment,'
               ' Dataset_Comment, Dataset_Type,'
               ' Rating As Dataset_Rating_ID, Rating_Name AS Dataset_Rating,'
               ' Separation_Type,'                                                              ||
        format(' ''%s''::citext AS Tool,',                _predefineInfo.AnalysisToolName)      ||
        format(' ''%s''::citext AS Parameter_File,',      _predefineInfo.ParamFileName)         ||
        format(' ''%s''::citext AS Settings_File,',       _predefineInfo.SettingsFileName)      ||
        format(' ''%s''::citext AS Protein_Collections,', _predefineInfo.ProteinCollectionList) ||
        format(' ''%s''::citext AS Legacy_FASTA',         _predefineInfo.OrganismDBName)        ||
          ' FROM V_Predefined_Analysis_Dataset_Info'                                            ||
          _sqlWhere                                                                             ||
          ' ORDER BY ID DESC';

    If _previewSql Then
        RAISE INFO '%', _s;
    Else
        RETURN QUERY
        EXECUTE _s;
    End If;

    If _populateTempTable Then

        _s := format('CREATE TABLE T_Tmp_PredefinedAnalysisDatasets AS%s', _s);

        If _previewSql Then
            RAISE INFO '%', _s;
            RETURN;
        End If;

        RAISE INFO 'Populating table T_Tmp_PredefinedAnalysisDatasets';

        EXECUTE _s;

        CREATE INDEX IX_T_Tmp_PredefinedAnalysisDatasets_Dataset_ID ON T_Tmp_PredefinedAnalysisDatasets (ID);
    End If;

END;
$$;


ALTER FUNCTION public.predefined_analysis_datasets(_ruleid integer, _infoonly boolean, _previewsql boolean, _populatetemptable boolean) OWNER TO d3l243;

--
-- Name: FUNCTION predefined_analysis_datasets(_ruleid integer, _infoonly boolean, _previewsql boolean, _populatetemptable boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.predefined_analysis_datasets(_ruleid integer, _infoonly boolean, _previewsql boolean, _populatetemptable boolean) IS 'PredefinedAnalysisDatasets';


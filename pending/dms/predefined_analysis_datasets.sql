--
CREATE OR REPLACE FUNCTION public.predefined_analysis_datasets
(
    _ruleID int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _previewSql boolean = false,
    _populateTempTable boolean = false
)
RETURNS TABLE (
    Dataset citext,
    Dataset_ID int,
    Instrument_Class citext,
    Instrument citext,
    Campaign citext,
    Experiment citext,
    Organism citext,
    Experiment_Labelling citext,
    Experiment_Comment citext,
    Dataset_Comment citext,
    Dataset_Type citext,
    Dataset_Rating_ID, int,
    Dataset_Rating citext,
    Separation_Type citext,
    Analysis_Tool citext,
    Parameter_File citextv
    Settings_File citext,
    Protein_Collections citext,
    Legacy_FASTA citext
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Shows datasets that satisfy a given predefined analysis rule
**
**  Arguments:
**    _infoOnly            When true, returns the count of the number of datasets, not the actual datasets
**    _populateTempTable   When true, populates table T_Tmp_PredefinedAnalysisDatasets with the results
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _predefineInfo record;
    _s text;
    _sqlWhere text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _ruleID := Coalesce(_ruleID, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _previewSql := Coalesce(_previewSql, false);
    _populateTempTable := Coalesce(_populateTempTable, false);

    If _populateTempTable Then
        DROP TABLE IF EXISTS T_Tmp_PredefinedAnalysisDatasets;
    End If;

    SELECT
        instrument_class_criteria As InstrumentClassCriteria,
        campaign_name_criteria As CampaignNameCriteria,
        experiment_name_criteria As ExperimentNameCriteria,
        instrument_name_criteria As InstrumentNameCriteria,
        instrument_excl_criteria As InstrumentExclCriteria,
        organism_name_criteria As OrganismNameCriteria,
        labelling_incl_criteria As LabellingInclCriteria,
        labelling_excl_criteria As LabellingExclCriteria,
        dataset_name_criteria As DatasetNameCriteria,
        dataset_type_criteria As DatasetTypeCriteria,
        exp_comment_criteria As ExpCommentCriteria,
        separation_type_criteria As SeparationTypeCriteria,
        campaign_excl_criteria As CampaignExclCriteria,
        experiment_excl_criteria As ExperimentExclCriteria,
        dataset_excl_criteria As DatasetExclCriteria,
        analysis_tool_name As AnalysisToolName,
        param_file_name As ParamFileName,
        settings_file_name As SettingsFileName,
        protein_collection_list As ProteinCollectionList,
        organism_db_name As OrganismDBName
    INTO _predefineInfo
    FROM t_predefined_analysis
    WHERE predefine_id = _ruleID;

/*
    RAISE INFO '%', 'InstrumentClass: ' || _predefineInfo.InstrumentClassCriteria;
    RAISE INFO '%', 'CampaignName: ' || _predefineInfo.CampaignNameCriteria;
    RAISE INFO '%', 'Experiment: ' || _predefineInfo.ExperimentNameCriteria;
    RAISE INFO '%', 'InstrumentName: ' || _predefineInfo.InstrumentNameCriteria;
    RAISE INFO '%', 'InstrumentExcl: ' || _predefineInfo.InstrumentExclCriteria;
    RAISE INFO '%', 'OrganismName: ' || _predefineInfo.OrganismNameCriteria;
    RAISE INFO '%', 'LabellingIncl: ' || _predefineInfo.LabellingInclCriteria;
    RAISE INFO '%', 'LabellingExcl: ' || _predefineInfo.LabellingExclCriteria;
    RAISE INFO '%', 'DatasetName: ' || _predefineInfo.DatasetNameCriteria;
    RAISE INFO '%', 'DatasetType: ' || _predefineInfo.DatasetTypeCriteria;
    RAISE INFO '%', 'ExperimentComment: ' || _predefineInfo.ExpCommentCriteria;
    RAISE INFO '%', 'SeparationType: ' || _predefineInfo.SeparationTypeCriteria;
    RAISE INFO '%', 'CampaignExcl: ' || _predefineInfo.CampaignExclCriteria;
    RAISE INFO '%', 'ExperimentExcl: ' || _predefineInfo.ExperimentExclCriteria;
    RAISE INFO '%', 'DatasetExcl: ' || _predefineInfo.DatasetExclCriteria;
*/

    _sqlWhere := 'WHERE true';

    If _predefineInfo.InstrumentClassCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (InstrumentClass LIKE ''' || _predefineInfo.InstrumentClassCriteria || ''')';
    End If;

    If _predefineInfo.InstrumentNameCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Instrument LIKE ''' || _predefineInfo.InstrumentNameCriteria || ''')';
    End If;

    If _predefineInfo.InstrumentExclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (NOT Instrument LIKE ''' || _predefineInfo.InstrumentExclCriteria || ''')';
    End If;

    If _predefineInfo.CampaignNameCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Campaign LIKE ''' || _predefineInfo.CampaignNameCriteria || ''')';
    End If;

    If _predefineInfo.ExperimentNameCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Experiment LIKE ''' || _predefineInfo.ExperimentNameCriteria || ''')';
    End If;

    If _predefineInfo.LabellingInclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Experiment_Labelling LIKE ''' || _predefineInfo.LabellingInclCriteria || ''')';
    End If;

    If _predefineInfo.LabellingExclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (NOT Experiment_Labelling LIKE ''' || _predefineInfo.LabellingExclCriteria || ''')';
    End If;

    If _predefineInfo.SeparationTypeCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Separation_Type LIKE ''' || _predefineInfo.SeparationTypeCriteria || ''')';
    End If;

    If _predefineInfo.CampaignExclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (NOT Campaign LIKE ''' || _predefineInfo.CampaignExclCriteria || ''')';
    End If;

    If _predefineInfo.ExperimentExclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (NOT Experiment LIKE ''' || _predefineInfo.ExperimentExclCriteria || ''')';
    End If;

    If _predefineInfo.DatasetExclCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (NOT Dataset LIKE ''' || _predefineInfo.DatasetExclCriteria || ''')';
    End If;

    If _predefineInfo.OrganismNameCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Organism LIKE ''' || _predefineInfo.OrganismNameCriteria || ''')';
    End If;

    If _predefineInfo.DatasetNameCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Dataset LIKE ''' || _predefineInfo.DatasetNameCriteria || ''')';
    End If;

    If _predefineInfo.DatasetTypeCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Dataset_Type LIKE ''' || _predefineInfo.DatasetTypeCriteria || ''')';
    End If;

    If _predefineInfo.ExpCommentCriteria <> '' Then
        _sqlWhere := _sqlWhere || ' AND (Experiment_Comment LIKE ''' || _predefineInfo.ExpCommentCriteria || ''')';
    End If;

    _s := '';

    If _infoOnly Then
        _s :=       ' SELECT ' || _ruleID::text || ' AS RuleID,';
        _s := _s ||          ' COUNT(*) AS DatasetCount,';
        _s := _s ||          ' MIN(DS_Date) AS Dataset_Date_Min, MAX(DS_Date) AS Dataset_Date_Max, ';

        _s := _s ||          ' ''' || _predefineInfo.InstrumentClassCriteria || ''' AS InstrumentClassCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.InstrumentNameCriteria ||  ''' AS InstrumentNameCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.InstrumentExclCriteria ||  ''' AS InstrumentExclCriteria,';

        _s := _s ||          ' ''' || _predefineInfo.CampaignNameCriteria ||   ''' AS CampaignNameCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.CampaignExclCriteria ||   ''' AS CampaignExclCriteria,';

        _s := _s ||          ' ''' || _predefineInfo.ExperimentNameCriteria || ''' AS ExperimentNameCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.ExperimentExclCriteria || ''' AS ExperimentExclCriteria,';

        _s := _s ||          ' ''' || _predefineInfo.OrganismNameCriteria ||   ''' AS OrganismNameCriteria,';

        _s := _s ||          ' ''' || _predefineInfo.DatasetNameCriteria ||    ''' AS DatasetNameCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.DatasetExclCriteria ||    ''' AS DatasetExclCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.DatasetTypeCriteria ||    ''' AS DatasetTypeCriteria,';

        _s := _s ||          ' ''' || _predefineInfo.ExpCommentCriteria ||     ''' AS ExpCommentCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.LabellingInclCriteria ||  ''' AS LabellingInclCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.LabellingExclCriteria ||  ''' AS LabellingExclCriteria,';
        _s := _s ||          ' ''' || _predefineInfo.SeparationTypeCriteria || ''' AS SeparationTypeCriteria';

        _s := _s || ' FROM V_Predefined_Analysis_Dataset_Info';
        _s := _s || ' ' || _sqlWhere;

        FOR _previewInfo IN
            EXECUTE _s;
        LOOP
            RAISE INFO '%', format('Rule %s, %s datasets, date range %s to %s', _previewInfo.RuleID, _previewInfo.DatasetCount, _previewInfo.Dataset_Date_Min, _previewInfo.Dataset_Date_Max);

            -- ToDo: Show the other info stored in _predefineInfo
        END LOOP;

        RETURN;
    End If;


    _s :=       ' SELECT Dataset, ID,';
    _s := _s ||        ' InstrumentClass, Instrument,';
    _s := _s ||        ' Campaign, Experiment, Organism,';
    _s := _s ||        ' Experiment_Labelling, Experiment_Comment,';
    _s := _s ||        ' Dataset_Comment, Dataset_Type,';
    _s := _s ||        ' Rating As Dataset_Rating_ID, Rating_Name AS Dataset_Rating,';
    _s := _s ||        ' Separation_Type,';
    _s := _s ||        ' ''' || _predefineInfo.AnalysisToolName || ''' AS Tool,';
    _s := _s ||        ' ''' || _predefineInfo.ParamFileName || ''' AS Parameter_File,';
    _s := _s ||        ' ''' || _predefineInfo.SettingsFileName || ''' AS Settings_File,';
    _s := _s ||        ' ''' || _predefineInfo.ProteinCollectionList || ''' AS Protein_Collections,';
    _s := _s ||        ' ''' || _predefineInfo.OrganismDBName || ''' AS Legacy_FASTA';
    _s := _s || ' FROM V_Predefined_Analysis_Dataset_Info';
    _s := _s || ' ' || _sqlWhere;
    _s := _s || ' ORDER BY ID DESC';

    If _previewSQL Then
        RAISE INFO '%', _s;
        RETURN;
    End If;

    RETURN QUERY
    EXECUTE _s;

    If _populateTempTable Then
        RAISE INFO 'Populating table T_Tmp_PredefinedAnalysisDatasets';

        _s := 'CREATE TABLE T_Tmp_PredefinedAnalysisDatasets AS ' || _s;

        EXECUTE _s;

        CREATE INDEX IX_T_Tmp_PredefinedAnalysisDatasets_Dataset_ID ON T_Tmp_PredefinedAnalysisDatasets (ID);
    End If;

END;
$$;

COMMENT ON PROCEDURE public.predefined_analysis_datasets IS 'PredefinedAnalysisDatasets';

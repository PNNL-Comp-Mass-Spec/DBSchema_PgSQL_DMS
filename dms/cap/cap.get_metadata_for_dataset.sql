--
-- Name: get_metadata_for_dataset(text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_metadata_for_dataset(_datasetname text) RETURNS TABLE(section text, name text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a table with metadata for the given dataset
**
**  Auth:   grk
**  Date:   10/29/2009 grk - Initial release
**          11/03/2009 dac - Corrected name of dataset number column in global metadata
**          06/12/2018 mem - Now including Experiment_Labelling, Reporter_MZ_Min, and Reporter_MZ_Max
**          05/04/2020 mem - Add fields LC_Cart_Name, LC_Cart_Config, and LC_Column
**                         - Store dates in ODBC canonical style: yyyy-MM-dd hh:mm:ss
**          07/28/2020 mem - Add Dataset_ID
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          09/30/2022 mem - Ported to PostgreSQL
**          02/08/2023 mem - Switch from PRN to Username
**          02/27/2023 mem - Capitalize XML element names
**          05/29/2023 mem - Use format() for string concatenation
**          07/23/2023 mem - Use new alias names for table
**
*****************************************************/
DECLARE
    _stepParamSectionName text := 'Meta';
    _datasetInfo record;
BEGIN
    ---------------------------------------------------
    -- Return "global" metadata
    ---------------------------------------------------

    RETURN QUERY
    SELECT _stepParamSectionName, 'Meta_Investigation', 'Proteomics'
    UNION
    SELECT _stepParamSectionName, 'Meta_Instrument_Type', 'Mass spectrometer'
    UNION
    SELECT _stepParamSectionName, 'Meta_Dataset_Name', _datasetName;

    ---------------------------------------------------
    -- Obtain metadata for the dataset
    ---------------------------------------------------

    SELECT DS.created AS DatasetCreated,
           DS.dataset_id AS DatasetID,
           InstName.instrument AS Instrument,
           Coalesce(DS.comment, '') AS DatasetComment,
           DS.separation_type AS SeparationType,                        -- DS_sec_sep
           LCCart.Cart_Name AS LcCartName,
           Coalesce(CartConfig.Cart_Config_Name, '') AS LcCartConfig,
           LCCol.lc_column AS LcColumn,
           Coalesce(DS.well, 'na') AS DatasetWell,
           E.experiment AS Experiment,
           E.researcher_username AS ExperimentResearcherUsername,
           Org.organism AS ExperimentOrganism,
           Coalesce(E.comment, '') AS ExperimentComment,
           Coalesce(E.sample_concentration, 'na') AS ExperimentSampleConc,
           E.labelling AS ExperimentLabelling,
           Coalesce(E.reason, '') AS ExperimentReason,
           Coalesce(E.lab_notebook_ref, '') AS ExperimentLabNotebook,
           Coalesce(CEC.biomaterial_list, '') AS BiomaterialList,       -- Cell_Culture_List
           Coalesce(L.Reporter_Mz_Min, 0) AS LabellingReporterMzMin,
           Coalesce(L.Reporter_Mz_Max, 0) AS LabellingReporterMzMax,
           C.campaign AS Campaign,
           C.project AS CampaignProject,
           Coalesce(C.comment, '') AS CampaignComment,
           C.created AS CampaignCreated
    INTO _datasetInfo
    FROM T_Dataset DS
         INNER JOIN T_Experiments E
           ON DS.Exp_ID = E.Exp_ID
         INNER JOIN T_Campaign C
           ON E.campaign_id = C.Campaign_ID
         INNER JOIN T_Dataset_State_Name DSN
           ON DS.dataset_state_id = DSN.Dataset_state_ID
         INNER JOIN T_Instrument_Name InstName
           ON DS.instrument_id = InstName.Instrument_ID
         INNER JOIN T_Storage_Path SPath
           ON DS.storage_path_ID = SPath.storage_path_ID
         INNER JOIN T_Dataset_Type_Name DTN
           ON DS.dataset_type_ID = DTN.dataset_type_ID
         INNER JOIN T_Organisms Org
           ON E.organism_id = Org.organism_id
         INNER JOIN T_Sample_Labelling L
           ON E.labelling = L.Label
         LEFT OUTER JOIN T_LC_Column AS LCCol
          ON DS.lc_column_ID = LCCol.lc_column_ID
         LEFT OUTER JOIN T_Cached_Experiment_Components CEC
           ON E.Exp_ID = CEC.Exp_ID
         LEFT OUTER JOIN T_LC_Cart AS LCCart
                         INNER JOIN T_Requested_Run AS RR
                           ON LCCart.cart_id = RR.cart_id
           ON DS.Dataset_ID = RR.Dataset_ID
         LEFT OUTER JOIN T_LC_Cart_Configuration AS CartConfig
           ON DS.Cart_Config_ID = CartConfig.Cart_Config_ID
    WHERE DS.Dataset = _datasetName;

    If Not FOUND Then
        RETURN QUERY
        SELECT _stepParamSectionName, 'Error', 'Dataset not found in t_dataset';

        RAISE WARNING 'Dataset not found: %', _datasetName;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Return primary metadata for the dataset
    ---------------------------------------------------

    RETURN QUERY
    SELECT _stepParamSectionName, 'Meta_Dataset_Created', timestamp_text(_datasetInfo.DatasetCreated)         UNION
    SELECT _stepParamSectionName, 'Meta_Dataset_ID', _datasetInfo.DatasetId::text                             UNION
    SELECT _stepParamSectionName, 'Meta_Instrument_Name', _datasetInfo.Instrument                             UNION
    SELECT _stepParamSectionName, 'Meta_Dataset_Comment', _datasetInfo.DatasetComment                         UNION
    SELECT _stepParamSectionName, 'Meta_Dataset_Sec_Sep', _datasetInfo.SeparationType                         UNION
    SELECT _stepParamSectionName, 'Meta_LC_Cart_Name', _datasetInfo.LcCartName                                UNION
    SELECT _stepParamSectionName, 'Meta_LC_Cart_Config', _datasetInfo.LcCartConfig                            UNION
    SELECT _stepParamSectionName, 'Meta_LC_Column', _datasetInfo.LcColumn                                     UNION
    SELECT _stepParamSectionName, 'Meta_Dataset_Well_Number', _datasetInfo.DatasetWell                        UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Name', _datasetInfo.Experiment                             UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Researcher_Username', _datasetInfo.ExperimentResearcherUsername UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Reason', _datasetInfo.ExperimentReason                     UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Biomaterial', _datasetInfo.BiomaterialList                 UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Organism_Name', _datasetInfo.ExperimentOrganism            UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Comment', _datasetInfo.ExperimentComment                   UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Sample_Concentration', _datasetInfo.ExperimentSampleConc   UNION
    SELECT _stepParamSectionName, 'Meta_Experiment_Sample_Labelling', _datasetInfo.ExperimentLabelling ;

    If _datasetInfo.LabellingReporterMzMin > 0 Then
        RETURN QUERY
        SELECT _stepParamSectionName, 'Meta_Experiment_Labelling_Reporter_Mz_Min', _datasetInfo.LabellingReporterMzMin::text UNION
        SELECT _stepParamSectionName, 'Meta_Experiment_Labelling_Reporter_Mz_Max', _datasetInfo.LabellingReporterMzMax::text;
    End If;

    RETURN QUERY
    SELECT _stepParamSectionName, 'Meta_Experiment_Lab_Notebook_Ref', _datasetInfo.ExperimentLabNotebook     UNION
    SELECT _stepParamSectionName, 'Meta_Campaign_Name', _datasetInfo.Campaign                                UNION
    SELECT _stepParamSectionName, 'Meta_Campaign_Project_Name', _datasetInfo.CampaignProject                 UNION
    SELECT _stepParamSectionName, 'Meta_Campaign_Comment', _datasetInfo.CampaignComment                      UNION
    SELECT _stepParamSectionName, 'Meta_Campaign_Created', timestamp_text(_datasetInfo.CampaignCreated);

    ---------------------------------------------------
    -- Return auxiliary metadata for the dataset's experiment
    ---------------------------------------------------

    RETURN QUERY
    SELECT _stepParamSectionName AS Section,
           (format('Meta_Aux_Info:%s:%s.%s.%s', M.Target, M.Category, M.Subcategory, M.Item))::text AS Name,
           M.Value::text
    FROM cap.V_DMS_Get_Experiment_Metadata M
    WHERE Experiment = _datasetInfo.Experiment
    ORDER BY Name;

END
$$;


ALTER FUNCTION cap.get_metadata_for_dataset(_datasetname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_metadata_for_dataset(_datasetname text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_metadata_for_dataset(_datasetname text) IS 'GetMetadataForDataset';


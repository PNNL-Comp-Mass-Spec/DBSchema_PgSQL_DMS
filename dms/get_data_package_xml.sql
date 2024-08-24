--
-- Name: get_data_package_xml(integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_data_package_xml(_datapackageid integer, _options text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get XML description of data package contents
**
**  Arguments:
**    _dataPackageID    Data package ID
**    _options          Comma separated list of items to include: 'Parameters', 'Experiments', 'Datasets', 'Jobs', 'Paths', or 'All'
**
**  Returns:
**      XML, as text
**
**  Example output (excerpt)
**    <data_package>
**    <general>
**    <package id="3793" name="QC_Shew_16_01-15f" description="Data package for testing MaxQuant" owner="D3L243" team="Public" state="Active"/>
**    </general>
**    <experiments>
**    <experiment experiment_id="166519" experiment="QC_Shew_16_01" organism="Shewanella_oneidensis_MR-1" campaign="QC-Shew-Standard" created="2016-02-17T09:09:31"/>
**    </experiments>
**    <datasets>
**    <dataset dataset_id="534700" dataset="QC_Shew_16_01-15f_08_4Nov16_Tiger_16-02-14"  experiment_id="166519" instrument="VOrbiETD02" created="2016-11-05T00:23:27" package_comment="MaxQuant Experiment QC_Shew_16_01a"/>
**    <dataset dataset_id="535990" dataset="QC_Shew_16_01-15f_09_15Nov16_Tiger_16-02-15" experiment_id="166519" instrument="VOrbiETD02" created="2016-11-16T06:08:46" package_comment="MaxQuant Experiment QC_Shew_16_01a"/>
**    <dataset dataset_id="535995" dataset="QC_Shew_16_01-15f_10_15Nov16_Tiger_16-02-14" experiment_id="166519" instrument="VOrbiETD02" created="2016-11-16T08:25:46" package_comment="MaxQuant Experiment QC_Shew_16_01b"/>
**    </datasets>
**    <jobs>
**    </jobs>
**    <paths>
**    <data_package_path share_path="\\protoapps\DataPkgs\Public\2021\3793_QC_Shew_16_01_15f" storage_path_relative="Public\2021\3793_QC_Shew_16_01_15f"/>
**    <dataset_path dataset_id="534700" dataset_folder_path="\\proto-4\VOrbiETD02\2016_4\QC_Shew_16_01-15f_08_4Nov16_Tiger_16-02-14"/>
**    <dataset_path dataset_id="535990" dataset_folder_path="\\proto-4\VOrbiETD02\2016_4\QC_Shew_16_01-15f_09_15Nov16_Tiger_16-02-15"/>
**    <dataset_path dataset_id="535995" dataset_folder_path="\\proto-4\VOrbiETD02\2016_4\QC_Shew_16_01-15f_10_15Nov16_Tiger_16-02-14"/>
**    </paths>
**    </data_package>
**
**  Auth:   grk
**  Date:   04/25/2012
**          05/06/2012 grk - Added support for experiments
**          06/18/2022 mem - Ported to PostgreSQL
**          11/15/2022 mem - Use new column name
**          04/27/2023 mem - Use boolean for data type name
**          05/30/2023 mem - Use format() for string concatenation
**          08/17/2023 mem - Use renamed column data_pkg_id in views V_Data_Package_Analysis_Jobs_Export, V_Data_Package_Dataset_Export, and V_Data_Package_Experiments_Export
**                         - Coalesce null values to empty strings
**                         - Indent XML
**          09/11/2023 mem - Adjust capitalization of keywords
**          01/04/2024 mem - Remove unnecessary parentheses
**          01/21/2024 mem - Change data type of argument _options to text
**          02/19/2024 mem - Query tables directly instead of using views
**          08/23/2024 mem - Switch from V_Data_Package_Export to V_Data_Package_Paths
**
*****************************************************/
DECLARE
    _includeAll boolean;
    _result text;
    _newline text := chr(10);
    _paramXML xml;
    _experimentXML xml;
    _datasetXML xml;
    _jobXML xml;
    _dpPathXML xml;
    _dsPathXML xml;
    _jobPathXML xml;
BEGIN

    _options := Trim(Coalesce(_options, ''));

    If _options::citext IN ('', 'All') THEN
        _includeAll = true;
    Else
        _includeAll = false;
    End If;

    _result := format('<data_package>%s', _newline);

    ---------------------------------------------------
    -- Data Package Parameters
    ---------------------------------------------------

    If _includeAll Or Position(Lower('Parameters') In Lower(_options)) > 0 Then
        _result := format('%s  <general>%s', _result, _newline);

        -- Note: if LookupQ returns multiple rows, use XMLFOREST to wrap the <package></package> items in <packages></packages>
        -- SELECT XMLFOREST(LookupQ.xml_item AS packages)

        SELECT xml_item
        INTO _paramXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME package,
                       XMLATTRIBUTES(
                           DP.data_pkg_id AS id,
                           DP.package_name AS name,
                           DP.description,
                           DP.owner_username AS owner,
                           DP.path_team AS team,
                           DP.state,
                           DP.package_type,
                           Coalesce(DP.requester, '') AS requester,
                           DP.total_item_count AS total,
                           DP.analysis_job_item_count AS jobs,
                           DP.dataset_item_count AS datasets,
                           DP.experiment_item_count AS experiments,
                           DP.biomaterial_item_count AS biomaterial,
                           DP.created::date::text AS created))
                      ) AS xml_item
              FROM dpkg.t_data_package AS DP
              WHERE DP.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        _result := format('%s    %s%s  %s%s',
                            _result,
                            Coalesce(_paramXML::text, ''), _newline,
                            '</general>', _newline);
    End If;

    ---------------------------------------------------
    -- Experiment Details
    ---------------------------------------------------

    If _includeAll Or Position(Lower('Experiments') In Lower(_options)) > 0 Then
        _result := format('%s  <experiments>%s', _result, _newline);

        SELECT xml_item
        INTO _experimentXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME experiment,
                       XMLATTRIBUTES(
                           DPE.experiment_id,
                           EX.experiment,
                           Org.organism,
                           C.campaign,
                           EX.created,
                           Coalesce(EX.reason, '') AS reason,
                           Coalesce(DPE.package_comment, '') AS package_comment))
                      ) AS xml_item
              FROM dpkg.t_data_package_experiments AS DPE
                   INNER JOIN t_experiments EX ON DPE.Experiment_ID = EX.exp_id
                   INNER JOIN t_campaign C ON C.campaign_id = EX.campaign_id
                   INNER JOIN public.t_organisms Org ON Org.organism_id = EX.organism_id
              WHERE DPE.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        If Coalesce(_experimentXML::text, '') = '' Then
            _result := format('%s  %s%s',
                                _result,
                                '</experiments>', _newline);
        Else
            _result := format('%s    %s%s  %s%s',
                                _result,
                                _experimentXML, _newline,
                                '</experiments>', _newline);
        End If;

    End If;

    ---------------------------------------------------
    -- Dataset Details
    ---------------------------------------------------

    If _includeAll Or Position(Lower('Datasets') In Lower(_options)) > 0 Then
        _result := format('%s  <datasets>%s', _result, _newline);

        SELECT xml_item
        INTO _datasetXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME dataset,
                       XMLATTRIBUTES(
                           DS.dataset_id,
                           DS.dataset,
                           -- EX.experiment,
                           DS.exp_id AS Experiment_ID,
                           InstName.instrument,
                           DS.created,
                           Coalesce(DPD.package_comment, '') AS package_comment))
                      ) AS xml_item
              FROM dpkg.t_data_package_datasets AS DPD
                   INNER JOIN t_dataset AS DS ON DS.Dataset_ID = DPD.Dataset_ID
                   INNER JOIN t_instrument_name InstName ON DS.instrument_id = InstName.instrument_id
              WHERE DPD.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        If Coalesce(_datasetXML::text, '') = '' Then
            _result := format('%s  %s%s',
                                _result,
                                '</datasets>', _newline);
        Else
            _result := format('%s    %s%s  %s%s',
                                _result,
                                _datasetXML, _newline,
                                '</datasets>', _newline);
        End If;

    End If;

    ---------------------------------------------------
    -- Job Details
    ---------------------------------------------------

    If _includeAll Or Position(Lower('Jobs') In Lower(_options)) > 0 Then
        _result := format('%s  <jobs>%s', _result, _newline);

        SELECT xml_item
        INTO _jobXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME job,
                       XMLATTRIBUTES(
                           DPJ.job,
                           AJ.dataset_id,
                           T.analysis_tool AS tool,
                           AJ.param_file_name AS parameter_file,
                           AJ.settings_file_name AS settings_file,
                           Coalesce(AJ.protein_collection_list, '') AS protein_collection_list,
                           Coalesce(AJ.protein_options_list, '') AS protein_options,
                           Coalesce(AJ.comment, '') AS comment,
                           Coalesce(AJS.job_state, '') AS state,
                           Coalesce(DPJ.package_comment, '') AS package_comment))
                      ) AS xml_item
              FROM dpkg.t_data_package_analysis_jobs AS DPJ
                   INNER JOIN t_analysis_job AJ ON DPJ.job = AJ.job
                   INNER JOIN t_analysis_tool T ON AJ.analysis_tool_id = T.analysis_tool_id
                   INNER JOIN t_analysis_job_state AJS ON AJ.job_state_id = AJS.job_state_id
              WHERE DPJ.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        If Coalesce(_jobXML::text, '') = '' Then
            _result := format('%s  %s%s',
                                _result,
                                '</jobs>', _newline);
        Else
            _result := format('%s    %s%s  %s%s',
                                _result,
                                _jobXML, _newline,
                                '</jobs>', _newline);
        End If;

    End If;

    ---------------------------------------------------
    -- Storage Paths
    ---------------------------------------------------

    If _includeAll Or Position(Lower('Paths') In Lower(_options)) > 0 Then
        _result := format('%s  <paths>%s', _result, _newline);

        ---------------------------------------------------
        -- Data package path
        ---------------------------------------------------

        SELECT xml_item
        INTO _dpPathXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME data_package_path,
                       XMLATTRIBUTES(
                           dpp.share_path,
                           dpp.storage_path_relative))
                      ) AS xml_item
              FROM dpkg.V_Data_Package_Paths dpp
              WHERE dpp.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        _result := format('%s    %s%s', _result, Coalesce(_dpPathXML::text, ''), _newline);

        ---------------------------------------------------
        -- Dataset paths
        ---------------------------------------------------

        SELECT xml_item
        INTO _dsPathXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME dataset_path,
                       XMLATTRIBUTES(
                           DS.dataset_id,
                           DFP.dataset_folder_path,
                           DFP.archive_folder_path,
                           DFP.myemsl_path_flag,
                           DFP.dataset_url))
                      ) AS xml_item
              FROM dpkg.t_data_package_datasets AS DPD
                   INNER JOIN t_dataset AS DS ON DS.Dataset_ID = DPD.Dataset_ID
                   INNER JOIN t_cached_dataset_folder_paths AS DFP ON DFP.dataset_id = DS.Dataset_ID
              WHERE DPD.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        If Coalesce(_dsPathXML::text, '') <> '' Then
           _result := format('%s    %s%s', _result, _dsPathXML, _newline);
        End If;

        ---------------------------------------------------
        -- Job paths
        ---------------------------------------------------

        SELECT xml_item
        INTO _jobPathXML
        FROM (SELECT
                XMLAGG(XMLELEMENT(
                       NAME job_path,
                       XMLATTRIBUTES(
                           DPJ.job,
                           DFP.dataset_folder_path || '\' || AJ.results_folder_name AS folder_path,
                           DFP.archive_folder_path || '\' || AJ.results_folder_name AS archive_path,
                           DFP.myemsl_path_flag    || '\' || AJ.results_folder_name AS myemsl_path))
                      ) AS xml_item
              FROM dpkg.t_data_package_analysis_jobs AS DPJ
                   INNER JOIN t_analysis_job AJ ON DPJ.job = AJ.job
                   INNER JOIN t_dataset AS DS ON DS.dataset_id = DPJ.dataset_id
                   INNER JOIN t_cached_dataset_folder_paths AS DFP ON DFP.dataset_id = DS.Dataset_ID
              WHERE DPJ.data_pkg_id = _dataPackageID
            ) AS LookupQ;

        If Coalesce(_jobPathXML::text, '') = '' Then
            _result := format('%s  %s%s',
                                _result,
                                '</paths>', _newline);
        Else
            _result := format('%s    %s%s  %s%s',
                                _result,
                                _jobPathXML, _newline,
                                '</paths>', _newline);
        End If;

    End If;

    _result := format('%s</data_package>%s', _result, _newline);

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_data_package_xml(_datapackageid integer, _options text) OWNER TO d3l243;

--
-- Name: FUNCTION get_data_package_xml(_datapackageid integer, _options text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_data_package_xml(_datapackageid integer, _options text) IS 'GetDataPackageXML';


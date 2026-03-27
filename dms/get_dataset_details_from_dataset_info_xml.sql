--
-- Name: get_dataset_details_from_dataset_info_xml(xml, text, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.get_dataset_details_from_dataset_info_xml(IN _datasetinfoxml xml, IN _rootelement text DEFAULT 'DatasetInfo'::text, INOUT _datasetid integer DEFAULT 0, INOUT _datasetname text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Extract the dataset name from _datasetInfoXML
**      If _datasetID is non-zero, validates the dataset ID vs. the dataset name
**      Otherwise, updates _datasetID based on the dataset name defined in the XML
**
**      This procedure is used by procedures update_dataset_file_info_xml, update_dataset_device_info_xml, and update_dataset_nom_stats_xml
**
**  Typical XML file contents for dataset info XML files (with _rootElement = 'DatasetInfo')
**      <DatasetInfo>
**        <Dataset>QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08</Dataset>
**        ...
**      </DatasetInfo>
**
**  Typical XML file contents for natural organic matter stats XML files (with _rootElement = 'NOMStats')
**      <NOMStats>
**        <Dataset>QC_SRFAII_25_01_D_WEOM_r2_54_1_31253</Dataset>
**        <metrics>
**      ...
**        </metrics>
**      </NOMStats>
**
**  Arguments:
**    _datasetInfoXML   Dataset info, in XML format
**    _rootElement      Root element name
**    _datasetID        Input/output: dataset ID
**    _datasetName      Output: dataset name
**    _message          Error message, or an empty string if no error
**    _returnCode       '' if no error, otherwise an error code
**
**  Auth:   mem
**  Date:   02/29/2020 mem - Initial version
**          10/21/2022 mem - Ported to PostgreSQL
**          05/31/2023 mem - Combine string literals
**          06/13/2023 mem - Show a warning if _datasetInfoXML is null
**          12/08/2023 mem - Select a single column when using If Not Exists()
**          01/20/2024 mem - Ignore case when resolving dataset name to ID
**          03/26/2026 mem - Add parameter _rootElement
**
*****************************************************/
DECLARE
    _xpath text;
    _datasetIDCheck int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _rootElement := Coalesce(_rootElement, 'DatasetInfo');
    _datasetID   := Coalesce(_datasetID, 0);
    _datasetName := '';

    If Trim(_rootElement) = '' Then
        _rootElement = 'DatasetInfo';
    End If;

    If _datasetInfoXML Is Null Then
        _message := '_datasetInfoXML is null; unable to continue';
        RAISE WARNING '%', _message;

        _returnCode := 'U5200';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Parse out the dataset name from _datasetInfoXML
    -- If this parse fails, there is no point in continuing
    --
    -- Note that "text()" means to return the text inside the <Dataset></Dataset> node
    -- [1] is used to select the first match (there should only be one matching node, but xpath() returns an array)
    ---------------------------------------------------

    -- Construct the XPath to extract the dataset name
    --   When _rootElement is 'DatasetInfo', use '//DatasetInfo/Dataset/text()'
    --   When _rootElement is 'NOMStats'   , use '//NOMStats/Dataset/text()'

    _xpath = '//' || _rootElement || '/Dataset/text()';
    _datasetName := (xpath(_xpath, _datasetInfoXML))[1]::text;

    If Coalesce(_datasetName, '') = '' Then
        _message := format('XML in _datasetInfoXML is not in the expected form for DatasetID %s in procedure get_dataset_details_from_dataset_info_xml; could not match /DatasetInfo/Dataset',
                           _datasetID);

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Update or Validate Dataset_ID
    ---------------------------------------------------

    If _datasetId = 0 Then
        SELECT DS.dataset_id
        INTO _datasetID
        FROM t_dataset DS
        WHERE DS.dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Dataset "%s" not found in table t_dataset by procedure get_dataset_details_from_dataset_info_xml', _datasetName);
            _returnCode := 'U5202';
            RETURN;
        End If;
    Else
        -- _datasetID is non-zero

        -- Validate that _datasetID exists in t_dataset
        If Not Exists (SELECT dataset_id FROM t_dataset WHERE dataset_id = _datasetID) Then
            _message := format('Dataset ID %s not found in table t_dataset by procedure get_dataset_details_from_dataset_info_xml', _datasetID);
            _returnCode := 'U5203';
            RETURN;
        End If;

        SELECT DS.dataset_id
        INTO _datasetIDCheck
        FROM t_dataset DS
        WHERE DS.dataset = _datasetName::citext;

        If Not FOUND Then
            _message := format('Dataset "%s" not found in table t_dataset by procedure get_dataset_details_from_dataset_info_xml', _datasetName);
            _returnCode := 'U5204';
            RETURN;
        End If;

        If _datasetIDCheck <> _datasetID Then
            _message := format('Dataset ID values for dataset %s do not match; expecting %s but procedure param _datasetID is %s',
                                _datasetName, _datasetIDCheck, _datasetID);

            _returnCode := 'U5205';
            RETURN;
        End If;
    End If;
END
$$;


ALTER PROCEDURE public.get_dataset_details_from_dataset_info_xml(IN _datasetinfoxml xml, IN _rootelement text, INOUT _datasetid integer, INOUT _datasetname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


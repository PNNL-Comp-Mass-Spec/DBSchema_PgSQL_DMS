--
-- Name: update_dms_file_info_xml(integer, boolean, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_dms_file_info_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Calls public.update_dataset_file_info_xml() for the specified DatasetID
**
**      Procedure public.update_dataset_file_info_xml uses data in cap.t_dataset_info_xml
**      to populate several dataset info tables
**
**      Table                       Columns / Description
**      -----                       ---------------------
**      public.T_Dataset            Acq_Time_Start, Acq_Time_End, Scan_Count, File_Size_Bytes, File_Info_Last_Modified
**      public.T_Dataset_Info       Scan_Count_MS, Scan_Count_MSn, Elution_Time_Max, Scan_Types, Scan_Count_DIA, etc.
**      public.T_Dataset_ScanTypes  Scan_Type, Scan_Count, Scan_Filter
**      public.T_Dataset_Files      File_Path, File_Size_Bytes, File_Hash, File_Size_Rank
**
**  Arguments:
**    _datasetID                    Dataset ID
**    _deleteFromTableOnSuccess     When true, delete from cap.t_dataset_info_xml if successfully stored in the dataset tables
**    _message                      Output message
**    _returnCode                   Return code; will be 'U5360' if this dataset is a duplicate to another dataset (based on T_Dataset_Files)
**    _infoOnly                     When true, preview udpates
**
**  Auth:   mem
**  Date:   09/01/2010 mem - Initial Version
**          06/13/2018 mem - Add comment regarding duplicate datasets
**          08/09/2018 mem - Set Ignore to true when the return code from public.update_dataset_file_info_xml is 53600 (aka 'U5360')
**          06/14/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetInfoXML xml;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------

    _deleteFromTableOnSuccess := Coalesce(_deleteFromTableOnSuccess, true);
    _infoOnly := Coalesce(_infoOnly, false);

    SELECT ds_info_xml
    INTO _datasetInfoXML
    FROM cap.t_dataset_info_xml
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        RAISE WARNING 'Dataset ID % not found in cap.t_dataset_info_xml', _datasetID;
        RETURN;
    End If;

    If _datasetInfoXML Is Null Then
        RAISE WARNING 'Dataset info XML is null for Dataset ID % in cap.t_dataset_info_xml', _datasetID;
        RETURN;
    End If;

    If _infoOnly Then
        RAISE INFO 'Call public.update_dataset_file_info_xml for DatasetID %', _datasetID;
    End If;

    -- Note that procedure public.update_dataset_file_info_xml will set _returnCode to 'U5360'
    -- if this dataset is a duplicate of another dataset (based on T_Dataset_Files)

    CALL public.update_dataset_file_info_xml (
                    _datasetID,
                    _datasetInfoXML,
                    _message => _message,           -- Output
                    _returnCode => _returnCode,     -- Output
                    _infoOnly => _infoOnly);

    If _returnCode = ''      And Not _infoOnly And _deleteFromTableOnSuccess Then
        DELETE FROM cap.t_dataset_info_xml
        WHERE dataset_id = _datasetID;
    End If;

    If _returnCode = 'U5360' And Not _infoOnly And _deleteFromTableOnSuccess Then
        UPDATE cap.t_dataset_info_xml
        SET ignore = true
        WHERE dataset_id = _datasetID;
    End If;

END
$$;


ALTER PROCEDURE cap.update_dms_file_info_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dms_file_info_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_dms_file_info_xml(IN _datasetid integer, IN _deletefromtableonsuccess boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'UpdateDMSFileInfoXML';


--
CREATE OR REPLACE PROCEDURE public.update_dataset_device_info_xml
(
    _datasetID int = 0,
    _datasetInfoXML xml,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _skipValidation boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds (or updates) information about the device (or devices) for a dataset
**      Adds new devices to T_Dataset_Device as necessary
**
**      Device information is provided via XML, using the same format as recognized by update_dataset_file_info_xml, for example:
**
**      <DatasetInfo>
**        <Dataset>Sample_Name_W_F20</Dataset>
**        <ScanTypes>
**          <ScanType ScanCount="17060" ScanFilterText="FTMS + p NSI Full ms">HMS</ScanType>
**          <ScanType ScanCount="61336" ScanFilterText="FTMS + p NSI d Full ms2 0_hcd32.00">HCD-HMSn</ScanType>
**        </ScanTypes>
**        <AcquisitionInfo>
**          <ScanCount>78396</ScanCount>
**          <ScanCountMS>17060</ScanCountMS>
**          <ScanCountMSn>61336</ScanCountMSn>
**          <Elution_Time_Max>210.00</Elution_Time_Max>
**          <AcqTimeMinutes>210.00</AcqTimeMinutes>
**          <StartTime>2019-12-29 08:28:22 PM</StartTime>
**          <EndTime>2019-12-29 11:58:22 PM</EndTime>
**          <FileSizeBytes>3555625312</FileSizeBytes>
**          <InstrumentFiles>
**            <InstrumentFile Hash="4677d34d0f02999f5bddd01fc30b6941f64841da" HashType="SHA1" Size="3555625312">Sample_Name_W_F20.raw</InstrumentFile>
**          </InstrumentFiles>
**          <DeviceList>
**            <Device Type="MS" Number="1" Name="Q Exactive HF-X Orbitrap" Model="Q Exactive HF-X Orbitrap"
**                    SerialNumber="Exactive Series slot #6000" SoftwareVersion="2.9-290033/2.9.0.2926">
**              Mass Spectrometer
**            </Device>
**            <Device Type="Analog" Number="1" Name="Dionex.PumpNCS3500RS" Model="NCS-3500RS"
**                    SerialNumber="8140000" SoftwareVersion="">
**              Analog device #1
**            </Device>
**          </DeviceList>
**        </AcquisitionInfo>
**        ...
**      </DatasetInfo>
**
**  Arguments:
**    _datasetID        If this value is 0, will determine the dataset ID using the contents of _deviceInfoXML by looking for <Dataset>DatasetName</Dataset>
**    _datasetInfoXML   Dataset info, in XML format
**    _skipValidation   When true, if _datasetID is non-zero, skip calling Get_Dataset_Details_From_Dataset_Info_XML
**
**  Auth:   mem
**  Date:   03/01/2020 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _datasetName text;
    _datasetIDCheck int;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Create a temp table to hold the data
    -----------------------------------------------------------
    CREATE TEMP TABLE Tmp_DatasetDevicesTable (
        Device_Type text,
        Device_Number_Text text,
        Device_Number int Null,
        Device_Name text,
        Device_Model text,
        Device_Serial_Number text,
        Device_Software_Version text,
        Device_Description text,
        Device_ID Int null
    );

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _skipValidation := Coalesce(_skipValidation, false);

    If _datasetID > 0 And Not _skipValidation Then
        ---------------------------------------------------
        -- Examine the XML to determine the dataset name and update or validate _datasetID
        ---------------------------------------------------
        --
        CALL get_dataset_details_from_dataset_info_xml (
            _datasetInfoXML,
            _datasetID => _datasetID,       -- Input/Output
            _datasetName => _datasetName,   -- Output
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            DROP TABLE Tmp_DatasetDevicesTable;
            RETURN;
        End If;

        If _datasetID = 0 Then
            _message := 'Procedure get_dataset_details_from_dataset_info_xml was unable to determine the dataset ID value';

            DROP TABLE Tmp_DatasetDevicesTable;
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Parse the contents of _datasetInfoXML to populate Tmp_DatasetDevicesTable
    -- Skip the StartTime and EndTime values for now since they might have invalid dates
    ---------------------------------------------------
    --

    INSERT INTO Tmp_DatasetDevicesTable (
        Device_Type,
        Device_Number_Text,
        Device_Name,
        Device_Model,
        Device_Serial_Number,
        Device_Software_Version,
        Device_Description
    )
    SELECT XmlQ.Device_Type, XmlQ.Device_Number_Text,
           XmlQ.Device_Name, XmlQ.Device_Model, XmlQ.Device_Serial_Number,
           XmlQ.Device_Software_Version, XmlQ.Device_Description
    FROM (
        SELECT xmltable.*
        FROM ( SELECT _datasetInfoXML As rooted_xml
             ) Src,
             XMLTABLE('//DatasetInfo/AcquisitionInfo/DeviceList/Device'
                      PASSING Src.rooted_xml
                      COLUMNS Device_Type citext PATH '@Type',
                              Device_Number_Text citext PATH '@Number',
                              Device_Name citext PATH '@Name',
                              Device_Model citext PATH '@Model',
                              Device_Serial_Number citext PATH '@SerialNumber',
                              Device_Software_Version citext PATH '@SoftwareVersion',
                              Device_Description citext PATH '.')
         ) XmlQ
    WHERE Not XmlQ.Device_Type IS NULL;

    -- Populate the Device_Number column
    UPDATE Tmp_DatasetDevicesTable
    SET Device_Number = public.try_cast(Device_Number_Text, null::int);

    ---------------------------------------------------
    -- Look for matching devices in t_dataset_device
    ---------------------------------------------------

    UPDATE Tmp_DatasetDevicesTable DD
    SET Device_ID = DD.Device_ID
    FROM t_dataset_device DD
    WHERE DD.device_type = Src.device_type AND
          DD.device_name = Src.device_name AND
          DD.device_model = Src.device_model AND
          DD.serial_number = Src.Device_Serial_Number AND
          DD.software_version = Src.Device_Software_Version;

    If _infoOnly Then
        -- ToDo: Show this using Raise Info

        -- Preview new devices
        SELECT 'New device' As Info_Message,
               Src.device_type,
               Src.device_number,
               Src.device_name,
               Src.device_model,
               Src.Device_Serial_Number,
               Src.Device_Software_Version,
               Src.device_description
        FROM Tmp_DatasetDevicesTable Src
        WHERE Src.device_id IS NULL
        UNION
        SELECT format('Existing device, ID %s', DD.device_id) AS Info_Message,
               DD.device_type,
               DD.device_number,
               DD.device_name,
               DD.device_model,
               DD.serial_number,
               DD.software_version,
               DD.device_description
        FROM Tmp_DatasetDevicesTable Src
             INNER JOIN t_dataset_device DD
               ON Src.device_id = DD.device_id

        RETURN;
    End If;

    ---------------------------------------------------
    -- Add new devices
    ---------------------------------------------------
    --
    INSERT INTO t_dataset_device (
        device_type, device_number,
        device_name, device_model,
        serial_number, software_version,
        device_description )
    SELECT Src.device_type,
           Src.device_number,
           Src.device_name,
           Src.device_model,
           Src.Device_Serial_Number,
           Src.Device_Software_Version,
           Src.device_description
    FROM Tmp_DatasetDevicesTable Src
    WHERE Src.device_id IS NULL
    ORDER BY Src.device_type DESC, Src.device_number;

    ---------------------------------------------------
    -- Look, again for matching devices in t_dataset_device
    ---------------------------------------------------

    UPDATE Tmp_DatasetDevicesTable Target
    SET Device_ID = DD.Device_ID
    FROM t_dataset_device DD
    WHERE DD.device_type = Target.device_type AND
          DD.device_name = Target.device_name AND
          DD.device_model = Target.device_model AND
          DD.serial_number = Target.Device_Serial_Number AND
          DD.software_version = Target.Device_Software_Version;

    ---------------------------------------------------
    -- Add/update t_dataset_device_map
    ---------------------------------------------------

    -- Remove any existing froms from t_dataset_device_map
    DELETE FROM t_dataset_device_map
    WHERE dataset_id = _datasetID;

    INSERT INTO t_dataset_device_map( dataset_id, device_id )
    SELECT DISTINCT _datasetID,
                    Src.device_id
    FROM Tmp_DatasetDevicesTable Src
    WHERE NOT Src.device_id IS NULL;

    If char_length(_message) > 0 AND _infoOnly Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.update_dataset_device_info_xml IS 'UpdateDatasetDeviceInfoXML';

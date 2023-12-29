--
-- Name: add_new_dataset(text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_new_dataset(IN _xmldoc text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _logdebugmessages boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new dataset entry to DMS database using metadata in the given XML
**
**      This procedure is called by the Data Import Manager (DIM) while processing dataset trigger files
**      This procedure extracts the metadata from the XML then calls add_update_dataset()
**
**      Example XML:
**
**        <Dataset>
**          <Parameter Name="Dataset Name" Value="QC_Mam_19_01_a-HiRes_16Oct22_Rage_Rep-22-09-02" />
**          <Parameter Name="Experiment Name" Value="QC_Mam_19_01" />
**          <Parameter Name="Instrument Name" Value="Lumos03" />
**          <Parameter Name="Capture Share Name" Value="" />
**          <Parameter Name="Capture Subdirectory" Value="" />
**          <Parameter Name="Separation Type" Value="LC-Waters-Formic_2hr" />
**          <Parameter Name="LC Cart Name" Value="Rage" />
**          <Parameter Name="LC Cart Config" Value="Rage_RepSil_20cmx75umx200nlmin_CPTAC3" />
**          <Parameter Name="LC Column" Value="REP-22-08-08" />
**          <Parameter Name="Dataset Type" Value="HMS-HCD-MSn" />
**          <Parameter Name="Operator (PRN)" Value="Weitz, Karl K" />
**          <Parameter Name="DS Creator (PRN)" Value="DMSWebUser"/>
**          <Parameter Name="Work Package" Value="none" />
**          <Parameter Name="Comment" Value="" />
**          <Parameter Name="Interest Rating" Value="Released" />
**          <Parameter Name="Request" Value="0" />
**          <Parameter Name="EMSL Proposal ID" Value="" />
**          <Parameter Name="EMSL Usage Type" Value="MAINTENANCE" />
**          <Parameter Name="EMSL Users List" Value="" />
**          <Parameter Name="Run Start" Value="10/16/2022 11:31:36" />
**          <Parameter Name="Run Finish" Value="10/16/2022 14:08:30" />
**        </Dataset>
**
**        This procedure also supports
**          <Parameter Name="Username" Value="Weitz, Karl K" />
**          <Parameter Name="DS Creator" Value="Weitz, Karl K" />
**
**  Arguments:
**    _xmlDoc               Metadata for the new dataset
**    _mode                 Processing mode: 'add', 'parse_only', 'update', 'bad', 'check_add', 'check_update'
**    _message              Output message
**    _returnCode           Return code
**    _logDebugMessages     When true, log debug messages to t_log_entries
**
**  Auth:   grk
**  Date:   05/04/2007 grk - Ticket #434
**          10/02/2007 grk - Automatically release QC datasets (http://prismtrac.pnl.gov/trac/ticket/540)
**          10/02/2007 mem - Updated to query T_Dataset_Rating_Name for rating 5=Released
**          10/16/2007 mem - Added support for the 'DS Creator (PRN)' field
**          01/02/2008 mem - Now setting the rating to 'Released' for datasets that start with 'Blank' (Ticket #593)
**          02/13/2008 mem - Increased size of _datasetName to varchar(128) (Ticket #602)
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          09/09/2010 mem - Now always looking up the request number associated with the new dataset
**          03/04/2011 mem - Now validating that _runFinish is not a future date
**          03/07/2011 mem - Now auto-defining experiment name if empty for QC_Shew and Blank datasets
**                         - Now auto-defining EMSL usage type to Maintenance for QC_Shew and Blank datasets
**          05/12/2011 mem - Now excluding Blank%-bad datasets when auto-setting rating to 'Released'
**          01/25/2013 mem - Now converting _xmlDoc to an XML variable instead of using sp_xml_preparedocument and OpenXML
**          11/15/2013 mem - Now scrubbing "Buzzard:" out of the comment if there is no other text
**          06/20/2014 mem - Now removing "Buzzard:" from the end of the comment
**          12/18/2014 mem - Replaced QC_Shew_1[0-9] with QC_Shew[_-][0-9][0-9]
**          03/25/2015 mem - Now also checking the dataset's experiment name against get_dataset_priority() to see if we should auto-release the dataset
**          05/29/2015 mem - Added support for 'Capture Subfolder'
**          06/22/2015 mem - Now ignoring 'Capture Subfolder' if it is an absolute path to a local drive (e.g. D:\ProteomicsData)
**          11/21/2016 mem - Added parameter _logDebugMessages
**          02/23/2017 mem - Added support for 'LC Cart Config'
**          08/18/2017 mem - Change _captureSubfolder to '' if it is the same as _datasetName
**          06/13/2019 mem - Leave the dataset rating as 'Not Released', 'No Data (Blank/Bad)', or 'No Interest' for QC datasets
**          07/02/2019 mem - Add support for parameter 'Work Package' in the XML file
**          09/04/2020 mem - Rename variable and match both 'Capture Subfolder' and 'Capture Subdirectory' in _xmlDoc
**          10/10/2020 mem - Rename variables
**          12/17/2020 mem - Ignore _captureSubfolder if it is an absolute path to a network share (e.g. \\proto-2\External_Orbitrap_Xfer)
**          05/26/2021 mem - Expand _message to varchar(1024)
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          11/25/2022 mem - Rename variable and use new parameter name when calling add_update_dataset
**          02/27/2023 mem - Show parsed values when mode is 'check_add' or 'check_update'
**          12/14/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetId int;
    _existingRequestID int;
    _internalStandards text;
    _addUpdateTimeStamp timestamp;
    _runStartDate timestamp;
    _runFinishDate timestamp;
    _xml xml;
    _logMessage text;

    _datasetName            text := '';
    _experimentName         text := '';
    _instrumentName         text := '';
    _captureSubdirectory    text := '';
    _separationType         text := '';
    _lcCartName             text := '';
    _lcCartConfig           text := '';
    _lcColumnName           text := '';
    _wellplateName          text := '';
    _wellNumber             text := '';
    _datasetType            text := '';
    _operatorUsername       text := '';
    _comment                text := '';
    _interestRating         text := '';     -- Dataset rating name (tracked by column dataset_rating in t_dataset_rating_name)
    _requestID              int  := 0 ;     -- Requested run ID; this might get updated by add_update_dataset
    _workPackage            text := '';
    _emslUsageType          text := '';
    _emslProposalID         text := '';
    _emslUsersList          text := '';
    _runStart               text := '';
    _runFinish              text := '';
    _datasetCreatorUsername text := '';     -- Username of the person that created the dataset; it is typically only present in trigger files created due to a dataset manually being created by a user

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

BEGIN
    _message := '';
    _returnCode := '';

    _logDebugMessages := Coalesce(_logDebugMessages, false);

    ---------------------------------------------------
    -- Convert _xmlDoc to XML
    ---------------------------------------------------

    _xml := public.try_cast(_xmlDoc, null::XML);

    If _xml Is Null Then
        _message := 'Could not convert dataset info from text to XML';
        RAISE WARNING '%', _message;

        _returnCode := 'U5234';
        RETURN;
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Create temporary table to hold list of parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Parameters (
        ParamName citext,
        ParamValue text
    );

    ---------------------------------------------------
    -- Populate parameter table from XML parameter description
    ---------------------------------------------------

    INSERT INTO Tmp_Parameters (ParamName, ParamValue)
    SELECT XmlQ.name, XmlQ.value
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _xml AS rooted_xml
                 ) Src,
                 XMLTABLE('//Dataset/Parameter'
                          PASSING Src.rooted_xml
                          COLUMNS name citext PATH '@Name',
                                  value citext PATH '@Value')
             ) XmlQ
    WHERE NOT XmlQ.name IS NULL;

    If _mode = 'parse_only' Then

        RAISE INFO '';

        _formatSpecifier := '%-25s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Name',
                            'Param_Value'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT ParamName AS Name,
                   ParamValue
            FROM Tmp_Parameters
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Name,
                                _previewData.ParamValue
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Parameters;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get arguments from parsed parameters
    ---------------------------------------------------

    SELECT Trim(ParamValue)
    INTO _datasetName
    FROM Tmp_Parameters
    WHERE ParamName = 'Dataset Name';

    SELECT Trim(ParamValue)
    INTO _experimentName
    FROM Tmp_Parameters
    WHERE ParamName = 'Experiment Name';

    SELECT Trim(ParamValue)
    INTO _instrumentName
    FROM Tmp_Parameters
    WHERE ParamName = 'Instrument Name';

    SELECT Trim(ParamValue)
    INTO _captureSubdirectory
    FROM Tmp_Parameters
    WHERE ParamName IN ('Capture Subfolder', 'Capture Subdirectory');

    SELECT Trim(ParamValue)
    INTO _separationType
    FROM Tmp_Parameters
    WHERE ParamName = 'Separation Type';

    SELECT Trim(ParamValue)
    INTO _lcCartName
    FROM Tmp_Parameters
    WHERE ParamName = 'LC Cart Name';

    SELECT Trim(ParamValue)
    INTO _lcCartConfig
    FROM Tmp_Parameters
    WHERE ParamName = 'LC Cart Config';

    SELECT Trim(ParamValue)
    INTO _lcColumnName
    FROM Tmp_Parameters
    WHERE ParamName = 'LC Column';

    SELECT Trim(ParamValue)
    INTO _wellplateName
    FROM Tmp_Parameters
    WHERE ParamName IN ('Wellplate Number', 'Wellplate Name');

    SELECT Trim(ParamValue)
    INTO _wellNumber
    FROM Tmp_Parameters
    WHERE ParamName = 'Well Number';

    SELECT Trim(ParamValue)
    INTO _datasetType
    FROM Tmp_Parameters
    WHERE ParamName = 'Dataset Type';

    SELECT Trim(ParamValue)
    INTO _operatorUsername
    FROM Tmp_Parameters
    WHERE ParamName IN ('Operator (PRN)', 'Operator (Username)');

    SELECT Trim(ParamValue)
    INTO _comment
    FROM Tmp_Parameters
    WHERE ParamName = 'Comment';

    SELECT Trim(ParamValue)
    INTO _interestRating
    FROM Tmp_Parameters
    WHERE ParamName = 'Interest Rating';

    SELECT Trim(ParamValue)
    INTO _requestID
    FROM Tmp_Parameters
    WHERE ParamName = 'Request';

    SELECT Trim(ParamValue)
    INTO _workPackage
    FROM Tmp_Parameters
    WHERE ParamName = 'Work Package';

    SELECT Trim(ParamValue)
    INTO _emslUsageType
    FROM Tmp_Parameters
    WHERE ParamName = 'EMSL Usage Type';

    SELECT Trim(ParamValue)
    INTO _emslProposalID
    FROM Tmp_Parameters
    WHERE ParamName = 'EMSL Proposal ID';

    SELECT Trim(ParamValue)
    INTO _emslUsersList
    FROM Tmp_Parameters
    WHERE ParamName = 'EMSL Users List';

    SELECT Trim(ParamValue)
    INTO _runStart
    FROM Tmp_Parameters
    WHERE ParamName = 'Run Start';

    SELECT Trim(ParamValue)
    INTO _runFinish
    FROM Tmp_Parameters
    WHERE ParamName = 'Run Finish';

    SELECT Trim(ParamValue)
    INTO _datasetCreatorUsername
    FROM Tmp_Parameters
    WHERE ParamName IN ('DS Creator (PRN)', 'DS Creator (Username)');

    ---------------------------------------------------
    -- Check for QC or Blank datasets
    ---------------------------------------------------

    If public.get_dataset_priority(_datasetName) > 0 Or
       public.get_dataset_priority(_experimentName) > 0 Or
       (_datasetName ILike 'Blank%' And Not _datasetName ILike '%-bad')
    Then
        If Not _interestRating::citext In ('Not Released', 'No Interest') And _interestRating Not ILike 'No Data%' Then

            -- Auto set interest rating to 5 ('Released')

            SELECT dataset_rating
            INTO _interestRating
            FROM t_dataset_rating_name
            WHERE dataset_rating_id = 5;

            If Not FOUND Then
                _logMessage := 'Dataset Rating ID 5 should be "Released", but ID 5 was not found in t_dataset_rating_name';
                RAISE WARNING '%', _logMessage;

                CALL post_log_entry ('Error', _logMessage, 'Add_New_Dataset');

                _interestRating := 'Released';
            End If;

        End If;
    End If;

    ---------------------------------------------------
    -- Possibly auto-define the experiment
    ---------------------------------------------------

    If _experimentName = '' Then
        If _datasetName ILike 'Blank%' Then
            _experimentName := 'Blank';
        ElsIf _datasetName::citext SIMILAR TO 'QC_Shew[_-][0-9][0-9][_-][0-9][0-9]%' Then
            _experimentName := Substring(_datasetName, 1, 13);
        ElsIf _datasetName::citext SIMILAR TO 'QC_Mam[_-][0-9][0-9][_-][0-9][0-9]%' Then
            _experimentName := Substring(_datasetName, 1, 12);
        End If;
    End If;

    ---------------------------------------------------
    -- Possibly auto-define the _emslUsageType
    ---------------------------------------------------

    If _emslUsageType = '' Then
        If _datasetName ILike 'Blank%' Or _datasetName ILike 'QC_Shew%' Or _datasetName ILike 'QC_Mam%' Then
            _emslUsageType := 'MAINTENANCE';
        End If;
    End If;

    ---------------------------------------------------
    -- Establish default parameters
    ---------------------------------------------------

    _internalStandards  := 'none';
    _addUpdateTimeStamp := CURRENT_TIMESTAMP;

    ---------------------------------------------------
    -- Check for the comment ending in "Buzzard:"
    ---------------------------------------------------

    If _comment ILike '%Buzzard:' Then
        _comment := Substring(_comment, 1, char_length(_comment) - 8);
    End If;

    If _captureSubdirectory::citext SIMILAR TO '[A-Z]:\%' Or _captureSubdirectory Like '\\\\%' Then
        _message := format('Capture subfolder is not a relative path for dataset %s; ignoring %s',
                            _datasetName, _captureSubdirectory);

        CALL post_log_entry ('Error', _message, 'Add_New_Dataset');

        _captureSubdirectory := '';
    End If;

    If _captureSubdirectory::citext = _datasetName::citext Then
        _message := format('Capture subfolder is identical to the dataset name for %s; changing to an empty string', _datasetName);

        -- Post this message to the log every 3 days
        If Not Exists (
           SELECT entry_id
           FROM t_log_entries
           WHERE message LIKE 'Capture subfolder is identical to the dataset name%' AND
                 Entered > CURRENT_TIMESTAMP - INTERVAL '3 days' )
        Then
            CALL post_log_entry ('Debug', _message, 'Add_New_Dataset');
        End If;

        _captureSubdirectory := '';
    End If;

    ---------------------------------------------------
    -- Create new dataset
    ---------------------------------------------------

    CALL public.add_update_dataset (
            _datasetName           => _datasetName,
            _experimentName        => _experimentName,
            _operatorUsername      => _operatorUsername,
            _instrumentName        => _instrumentName,
            _msType                => _datasetType,
            _lcColumnName          => _lcColumnName,
            _wellplateName         => _wellplateName,
            _wellNumber            => _wellNumber,
            _secSep                => _separationType,
            _internalStandards     => _internalStandards,
            _comment               => _comment,
            _rating                => _interestRating,
            _lcCartName            => _lcCartName,
            _eusProposalID         => _emslProposalID,
            _eusUsageType          => _emslUsageType,
            _eusUsersList          => _emslUsersList,
            _requestID             => _requestID,
            _workPackage           => _workPackage,
            _mode                  => _mode,
            _callingUser           => session_user,
            _aggregationJobDataset => false,
            _captureSubfolder      => _captureSubdirectory,
            _lcCartConfig          => _lcCartConfig,
            _logDebugMessages      => _logDebugMessages,
            _message               => _message,      -- Output
            _returnCode            => _returnCode    -- Output
           );

    If _returnCode <> '' Then
        -- Uncomment to log the XML to T_Log_Entries
        --
        /*
        If _mode = 'add' Then
            _logMessage := format('Error adding new dataset: %s; %s', _message, _xmlDoc);

            CALL post_log_entry ('Error', _logMessage, 'Add_New_Dataset');
        End If;
        */

        RAISE INFO '';
        RAISE WARNING '%', _message;

        DROP TABLE Tmp_Parameters;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Trap 'check' modes here
    ---------------------------------------------------

    If _mode = 'check_add' Or _mode = 'check_update' Then

        -- Show the parsed values

        RAISE INFO '';
        RAISE INFO 'Dataset Name:         %', _datasetName;
        RAISE INFO 'Experiment Name:      %', _experimentName;
        RAISE INFO 'Instrument Name:      %', _instrumentName;
        RAISE INFO 'Capture Subdirectory: %', _captureSubdirectory;
        RAISE INFO 'Separation Type:      %', _separationType;
        RAISE INFO 'LC Cart Name:         %', _lcCartName;
        RAISE INFO 'LC Cart Config:       %', _lcCartConfig;
        RAISE INFO 'LC Column:            %', _lcColumnName;
        RAISE INFO 'Wellplate Name:       %', _wellplateName;
        RAISE INFO 'WellNumber:           %', _wellNumber;
        RAISE INFO 'Dataset Type:         %', _datasetType;
        RAISE INFO 'Operator Username:    %', _operatorUsername;
        RAISE INFO 'Comment:              %', _comment;
        RAISE INFO 'Interest Rating:      %', _interestRating;
        RAISE INFO 'Request ID:           %', _requestID;
        RAISE INFO 'Work Package:         %', _workPackage;
        RAISE INFO 'EMSL UsageType:       %', _emslUsageType;
        RAISE INFO 'EMSL Proposal ID:     %', _emslProposalID;
        RAISE INFO 'EMSL Users List:      %', _emslUsersList;
        RAISE INFO 'Run Start:            %', _runStart;
        RAISE INFO 'Run Finish:           %', _runFinish;
        RAISE INFO 'DS Creator Username:  %', _datasetCreatorUsername;

        DROP TABLE Tmp_Parameters;
        RETURN;
    End If;

    ---------------------------------------------------
    -- It's possible that _requestID got updated by add_update_dataset
    -- Lookup the current value
    ---------------------------------------------------

    -- Use dataset name to lookup the dataset ID

    SELECT dataset_id
    INTO _datasetId
    FROM t_dataset
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _message := format('Could not resolve dataset ID for dataset %s', _datasetName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5235';
        DROP TABLE Tmp_Parameters;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Find request run associated with the dataset
    ---------------------------------------------------

    SELECT request_id
    INTO _existingRequestID
    FROM t_requested_run
    WHERE dataset_id = _datasetId;

    If FOUND Then
        _requestID := _existingRequestID;
    End If;

    If _datasetCreatorUsername <> '' Then

        ---------------------------------------------------
        -- Update t_event_log to reflect _datasetCreatorUsername creating this dataset
        ---------------------------------------------------

        UPDATE t_event_log
        SET entered_by = format('%s; via %s', _datasetCreatorUsername, entered_by)
        WHERE Target_ID = _datasetId AND
              Target_State = 1 AND
              Target_Type = 4 AND
              Entered Between _addUpdateTimeStamp AND _addUpdateTimeStamp + INTERVAL '1 minute';

    End If;

    ---------------------------------------------------
    -- Update the associated requested run with run start/finish values
    ---------------------------------------------------

    If Coalesce(_requestID, 0) <> 0 Then

        If _runStart <> '' Then
            _runStartDate := public.try_cast(_runStart, null::timestamp);
        Else
            _runStartDate := Null;
        End If;

        If _runFinish <> '' Then
            _runFinishDate := public.try_cast(_runFinish, null::timestamp);
        Else
            _runFinishDate := Null;
        End If;

        If Not _runStartDate Is Null and Not _runFinishDate Is Null Then
            -- Check whether the _runFinishDate value is more than 24 hours from now
            -- If it is, update it to match _runStartDate
            If extract(epoch FROM _runFinishDate - CURRENT_TIMESTAMP) / 3600 > 24 Then
                _runFinishDate := _runStartDate;
            End If;
        End If;

        UPDATE t_requested_run
        SET request_run_start = _runStartDate,
            request_run_finish = _runFinishDate
        WHERE request_id = _requestID;

    End If;

    DROP TABLE Tmp_Parameters;
END
$$;


ALTER PROCEDURE public.add_new_dataset(IN _xmldoc text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _logdebugmessages boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_new_dataset(IN _xmldoc text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _logdebugmessages boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_new_dataset(IN _xmldoc text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _logdebugmessages boolean) IS 'AddNewDataset';


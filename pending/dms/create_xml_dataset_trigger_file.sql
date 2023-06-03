--
-- ToDo:
--      Update this procedure to make an entry in a table that is monitored by a new manager tool,
--      which will then create the XML trigger file
--
CREATE OR REPLACE PROCEDURE public.create_xml_dataset_trigger_file
(
    _datasetName       text,
    _experimentName    text,
    _instrumentName    text,
    _separationType    text,
    _lcCartName        text,
    _lcColumn          text,
    _wellplateName     text,
    _wellNumber        text,
    _datasetType       text,
    _operatorUsername  text,
    _dsCreatorUsername text,
    _comment           text,
    _interestRating    text,
    _request           int,
    _workPackage       text = '',
    _emslUsageType     text = '',
    _emslProposalID    text = '',
    _emslUsersList     text = '',
    _runStart          text,
    _runFinish         text,
    _captureSubfolder  text,
    _lcCartConfig      text,
    INOUT _message      text,
    INOUT _returnCode   text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**  Desc:
**      Creates an XML dataset trigger file to deposit into a directory
**      where the DIM will pick it up, validate the dataset file(s) are available,
**      and submit back to DMS
**
**  Arguments:
**    _datasetName       Dataset name
**    _experimentName    Experiment Name
**    _instrumentName    Instrument Name
**    _separationType    Separation Type
**    _lcCartName        LC Cart Name
**    _lcColumn          LC Column Name
**    _wellplateName     Wellplate
**    _wellNumber        Well Number
**    _datasetType       Dataset Type
**    _operatorUsername  Operator Username
**    _dsCreatorUsername Dataset Creator Username
**    _comment           Comment
**    _interestRating    Interest Rating
**    _request           Requested Run ID
**    _emslUsageType     EUS Usage Type
**    _emslProposalID    EUS Proposal ID
**    _emslUsersList     EUS Users List
**
**  Auth:   jds
**  Date:   10/03/2007 jds - Initial version
**          04/26/2010 grk - Widened _datasetName to 128 characters
**          02/03/2011 mem - Now calling XML_Quote_Check() to replace double quotes with &quot;
**          07/31/2012 mem - Now using Combine_Paths to build the output file path
**          05/08/2013 mem - Removed Coalesce() checks since XML_Quote_Check() now changes Nulls to empty strings
**          06/23/2015 mem - Added _captureSubfolder
**          02/23/2017 mem - Added _lcCartConfig
**          03/15/2017 mem - Log an error if _triggerFolderPath does not exist
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          07/02/2019 mem - Add parameter _workPackage
**          11/25/2022 mem - Rename parameter to _wellplate
**          02/27/2023 mem - Look for '..\' at the start of _captureSubfolder
**                         - Use new XML element names
**          05/12/2023 bcg - Fix extra double quote bug on the XML 'Capture Share Name' line
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _fso int;
    _hr int;
    _src text, _desc text;
    _result int;
    _triggerFolderPath text;
    _filePath text;
    _captureShareName text;
    _captureSubdirectory text;
    _charPos int;
    _xmlLine text;
    _tmpXmlLine text;
    _newLine text;
    _ts int;
    _property text;
    _return text;
BEGIN
    _message := '';
    _returnCode := '';

    If _request Is Null Then
        _returnCode := 'U5201';
        _message := 'Request is null, cannot create trigger file';
        RETURN;
    End If;

    _logErrors := true;

    SELECT server
    INTO _triggerFolderPath
    FROM t_misc_paths
    WHERE path_function = 'DIMTriggerFileDir'

    _filePath := public.combine_paths(_triggerFolderPath, format('man_%s.xml', _datasetName));

    -- Create a filesystem object
    CALL _hr => sp_oacreate 'Scripting.FileSystemObject', _fso OUT
    If _hr <> 0 Then
        CALL sp_oaget_error_info _fso, _src OUT, _desc OUT
        SELECT hr=_hr::varbinary(4), Source=_src, Description=_desc
        _message := 'Error creating FileSystemObject, cannot create trigger file';
        RETURN;
    End If;

    -- Make sure _triggerFolderPath exists
    CALL _hr => sp_oamethod  _fso, 'FolderExists', _result OUT, _triggerFolderPath
    If _hr <> 0 Then
        CALL load_get_oaerror_message _fso, _hr, _message OUT
        _returnCode := 'U5202';

        If Coalesce(_message, '') = '' Then
            _message := format('Error verifying that the trigger folder exists at %s', Coalesce(_triggerFolderPath, '??'));
        End If;

        goto DestroyFSO
    End If;

    If _result = 0 Then
        _returnCode := 'U5203';
        _message := format('Trigger folder not found at %s; update t_misc_paths', Coalesce(_triggerFolderPath, '??'));

        goto DestroyFSO
    End If;

    _xmlLine := '';

    _captureSubfolder := Coalesce(_captureSubfolder, '');
    _lcCartConfig := Coalesce(_lcCartConfig, '');

    _message := '';
    _returnCode := '';

    -- Look for '..\' at the start of _captureSubfolder
    --
    If _captureSubfolder Similar To '..\\%\\%' Then
        -- Find the second backslash
        _charPos := 4 + Position('\' In substring(_captureSubfolder, 4));

        If _charPos > 4 Then
            _captureShareName    := Substring(_captureSubfolder, 4, _charPos - 4);
            _captureSubdirectory := Substring(_captureSubfolder, _charPos + 1, 250);
        Else
            _captureShareName := '';
            _captureSubdirectory := _captureSubfolder;
        End If;
    Else
        _captureShareName := '';
        _captureSubdirectory := _captureSubfolder;
    End If


    ---------------------------------------------------
    -- Create XML dataset trigger file lines
    -- Be sure to replace double quote characters with &quot; to avoid mal-formed XML
    -- In reality, only the comment should have double-quote characters, but we'll check all text fields just to be safe
    -- Note that xml_quote_check will also change Null values to empty strings
    ---------------------------------------------------
    --

    _newLine := format('%s%s', chr(13) || chr(10));

    --XML Header
    _tmpXmlLine := format('<?xml version="1.0" ?>%s', _newLine);

    _tmpXmlLine := format('%s<Dataset>%s', _tmpXmlLine, _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Dataset Name" Value="%s" />%s',          _tmpXmlLine, xml_quote_check(_datasetName),         _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Experiment Name" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_experimentName),      _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Instrument Name" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_instrumentName),      _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Capture Share Name" Value="%s" />%s',    _tmpXmlLine, xml_quote_check(_captureShareName),    _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Capture Subdirectory" Value="%s" />%s',  _tmpXmlLine, xml_quote_check(_captureSubdirectory), _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Separation Type" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_separationType),      _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="LC Cart Name" Value="%s" />%s',          _tmpXmlLine, xml_quote_check(_lcCartName),          _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="LC Cart Config" Value="%s" />%s',        _tmpXmlLine, xml_quote_check(_lcCartConfig),        _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="LC Column" Value="%s" />%s',             _tmpXmlLine, xml_quote_check(_lcColumn),            _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Wellplate Name" Value="%s" />%s',        _tmpXmlLine, xml_quote_check(_wellplateName),       _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Well Number" Value="%s" />%s',           _tmpXmlLine, xml_quote_check(_wellNumber),          _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Dataset Type" Value="%s" />%s',          _tmpXmlLine, xml_quote_check(_datasetType),         _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Operator (Username)" Value="%s" />%s',   _tmpXmlLine, xml_quote_check(_operatorUsername),    _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="DS Creator (Username)" Value="%s" />%s', _tmpXmlLine, xml_quote_check(_dsCreatorUsername),   _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Work Package" Value="%s" />%s',          _tmpXmlLine, xml_quote_check(_workPackage),         _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Comment" Value="%s" />%s',               _tmpXmlLine, xml_quote_check(_comment),             _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Interest Rating" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_interestRating),      _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Request" Value="%s" />%s',               _tmpXmlLine, _request,                              _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="EMSL Proposal ID" Value="%s" />%s',      _tmpXmlLine, xml_quote_check(_emslProposalID),      _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="EMSL Usage Type" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_emslUsageType),       _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="EMSL Users List" Value="%s" />%s',       _tmpXmlLine, xml_quote_check(_emslUsersList),       _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Run Start" Value="%s" />%s',             _tmpXmlLine, xml_quote_check(_runStart),            _newLine);
    _tmpXmlLine := format('%s  <Parameter Name="Run Finish" Value="%s" />%s',            _tmpXmlLine, xml_quote_check(_runFinish),           _newLine);

    --Close XML file
    _tmpXmlLine := format('%s</Dataset>%s', _tmpXmlLine, _newLine);

    ---------------------------------------------------
    -- Write XML dataset trigger file
    ---------------------------------------------------

    -- See if file already exists
    --
    CALL _hr => sp_oamethod  _fso, 'FileExists', _result OUT, _filePath
    If _hr <> 0 Then
        CALL load_get_oaerror_message _fso, _hr, _message OUT
        _returnCode := 'U5204';
        If Coalesce(_message, '') = '' Then
            _message := format('Error looking for an existing trigger file at %s', Coalesce(_filePath, '??'));
        End If;
        goto DestroyFSO
    End If;

    If _result = 1 Then
        _logErrors := false;
        _message := format('Trigger file already exists (%s).  Enter a different dataset name', _filePath);
        _returnCode := 'U5205';

        goto DestroyFSO
    End If;

    -- Open the text file for appending (1- ForReading, 2 - ForWriting, 8 - ForAppending)
    CALL _hr => sp_oamethod _fso, 'OpenTextFile', _ts OUT, _filePath, 8, true
    If _hr <> 0 Then
        CALL sp_oaget_error_info _fso, _src OUT, _desc OUT
        SELECT hr=_hr::varbinary(4), Source=_src, Description=_desc
        _returnCode := 'U5206';

        If Coalesce(_message, '') = '' Then
            _message := format('Error creating the trigger file at %s', Coalesce(_filePath, '??'));
        End If;

        goto DestroyFSO
    End If;

    -- Call the write method of the text stream to write the trigger file
    CALL _hr => sp_oamethod _ts, 'WriteLine', NULL, _tmpXmlLine
    If _hr <> 0 Then
        CALL sp_oaget_error_info _fso, _src OUT, _desc OUT
        SELECT hr=_hr::varbinary(4), Source=_src, Description=_desc
        _returnCode := 'U5207';

        If Coalesce(_message, '') = '' Then
            _message := format('Error writing to the trigger file at %s', Coalesce(_filePath, '??'));
        End If;

        goto DestroyFSO
    End If;

    -- Close the text stream
    CALL _hr => sp_oamethod _ts, 'Close', NULL
    If _hr <> 0 Then
        CALL sp_oaget_error_info _fso, _src OUT, _desc OUT
        SELECT hr=_hr::varbinary(4), Source=_src, Description=_desc
        _returnCode := 'U5208';

        If Coalesce(_message, '') = '' Then
            _message := format('Error closing the trigger file at %s', Coalesce(_filePath, '??'));
        End If;

        goto DestroyFSO
    End If;

    RETURN;

    -----------------------------------------------
    -- Clean up file system object
    -----------------------------------------------

DestroyFSO:
    -- Destroy the FileSystemObject object.
    --
    CALL _hr => sp_oadestroy _fso
    If _hr <> 0 Then
        CALL load_get_oaerror_message _fso, _hr, _message OUT
        _returnCode := 'U5209';
        _message := 'Error destroying FileSystemObject';
        RETURN;
    End If;

    -----------------------------------------------
    -- Exit
    -----------------------------------------------

    If _returnCode <> '' Then
        If Coalesce(_message, '') = '' Then
            _message := format('Error code %s in Create_XML_Dataset_Trigger_File', _returnCode);
        End If;

        If _logErrors Then
            CALL post_log_entry ('Error', _message, 'Create_XML_Dataset_Trigger_File');
        End If;
    End If;

END
$$;

COMMENT ON PROCEDURE public.create_xml_dataset_trigger_file IS 'CreateXmlDatasetTriggerFile';

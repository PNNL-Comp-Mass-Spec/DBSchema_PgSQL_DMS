--
CREATE OR REPLACE PROCEDURE pc.add_output_file_archive_entry
(
    _proteinCollectionID int,
    _crc32Authentication text,
    _fileModificationDate datetime,
    _fileSize bigint,
    _proteinCount int default 0,
    _archivedFileType text,
    _creationOptions text,
    _proteinCollectionString text,
    _collectionStringHash text,
    INOUT _archivedFilePath text default '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**    Adds a new entry to T_Archived_Output_Files
**
**  Arguments:
**    _proteinCollectionID          Protein collection ID
**    _crc32Authentication          CRC32 authentication hash
**    _fileModificationDate         File modification time
**    _fileSize                     File size (bytes)
**    _proteinCount                 Protein count
**    _archivedFileType             Archived file type
**    _creationOptions              Creation options
**    _proteinCollectionString      Protein collection list
**    _collectionStringHash         SHA-1 hash of the protein collection list and creation options (separated by a forward slash)
**
**  Returns:
**    _returnCode will have the archived file ID of the file added to T_Archived_Output_Files if no errors
**    _returnCode will be '0' if an error
**
**  Auth:   kja
**  Date:   03/10/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _skipOutputTableAdd int;
    _archivedFileTypeID int;
    _outputSequenceTypeID int;
    _archivedFileState text;
    _archivedFileStateID int;

    _optionItem text
    _equalsPosition int;

    _optionKeyword text;
    _optionKeywordID int;
    _optionValue text;
    _optionValueID int;
BEGIN
    _message := '';
    _returnCode := '';

    _archiveFileID := 0;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _archivedFilePath := Trim(Coalesce(_archivedFilePath ''));

    -- Is the hash the right length?

    If char_length(_crc32Authentication) <> 8 Then
        _message := 'Authentication hash must be 8 alphanumeric characters in length (0-9, A-F)';
        RAISE WARNING '%', _message;

        _returnCode := '0';
        RETURN;
    End If;

    -- Does this hash code already exist?

    SELECT Archived_File_ID
    INTO _archiveFileID
    FROM V_Archived_Output_Files
    WHERE Authentication_Hash = _crc32Authentication;

    If Not FOUND Then
        _archiveFileID := 0;
    End If;

    -- Does the protein collection exist?

    If Not Exists ( SELECT *
                    FROM pc.t_protein_collections
                    WHERE protein_collection_id = _proteinCollectionID)
    Then
        _message := format('Protein collection ID not found in T_Protein_Collections: %s', _proteinCollectionID);
        RAISE WARNING '%', _message;

        _returnCode := '0';
        RETURN;
    End If;

    -- Is the archive path length valid?

    If _archivedFilePath = '' Then
         _message := 'Argument _archivedFilePath is an empty string';
        RAISE WARNING '%', _message;

        _returnCode := '0';
        RETURN;
    End If;

-- Check for existence of output file type in pc.t_archived_file_types

    SELECT archived_file_type_id
    INTO _archivedFileTypeID
    FROM pc.t_archived_file_types
    WHERE file_type_name = _archivedFileType

    If Not FOUND Then
        _message := format('Invalid archived file type; %s not found in t_archived_file_types', _archivedFileType);
        RAISE WARNING '%', _message;

        _returnCode := '0';
        RETURN;
    End If;

    -- Determine the state of the entry based on provided data

    If Exists ( SELECT archived_file_id
                FROM pc.t_archived_output_file_collections_xref
                WHERE protein_collection_id = _proteinCollectionID)
    Then
        _archivedFileState := 'modified';
    Else
        _archivedFileState := 'original';
    End If;

    SELECT archived_file_state_id
    INTO _archivedFileStateID
    FROM pc.t_archived_file_states
    WHERE archived_file_state = _archivedFileState;

    ---------------------------------------------------
    -- Make the initial entry
    ---------------------------------------------------

    If _archiveFileID = 0 Then

        INSERT INTO pc.t_archived_output_files (
            archived_file_type_id,
            archived_file_state_id,
            archived_file_path,
            authentication_hash,
            archived_file_creation_date,
            file_modification_date,
            creation_options,
            filesize,
            protein_count,
            protein_collection_list,
            collection_list_hex_hash
        ) VALUES (
            _archivedFileTypeID,
            _archivedFileStateID,
            _archivedFilePath,
            _crc32Authentication,
            CURRENT_TIMESTAMP,
            _fileModificationDate,
            _creationOptions,
            _fileSize,
            _proteinCount,
            _proteinCollectionString,
            _collectionStringHash)
        RETURNING archived_file_id
        INTO _archiveFileID;

        _archivedFilePath := REPLACE(_archivedFilePath, '00000', RIGHT(format('000000%s', archived_file_id), 6));

        UPDATE pc.t_archived_output_files
        SET archived_file_path = _archivedFilePath
        WHERE archived_file_id = _archiveFileID;

        ---------------------------------------------------
        -- Parse and Store Creation Options
        ---------------------------------------------------

        _tmpOptionKeyword := '';
        _tmpOptionValue := '';

        _tmpOptionString := '';

        For _optionItem IN
            SELECT value
            FROM public.parse_delimited_list(_creationOptions, ',')
        LOOP
            _equalsPosition := Position('=' in _optionItem);

            If _equalsPosition = 0 Then
                _message := format('Equals sign missing from creation option "%"', _optionItem);
                RAISE WARNING '%', _message;

                ROLLBACK;

                _returnCode = '0'
                RETURN;
            End If;

             If _equalsPosition = 1 Or _equalsPosition = char_length(_optionItem) Then
                _message := format('Equals sign at invalid location in creation option "%"', _optionItem);
                RAISE WARNING '%', _message;

                ROLLBACK;

                _returnCode = '0'
                RETURN;
            End If;

            _optionKeyword := Trim(Substring(_optionItem, 1, _equalsPosition - 1));
            _optionValue   := Trim(Substring(_optionItem, _equalsPosition + 1));

            SELECT keyword_id
            INTO _optionKeywordID
            FROM pc.t_creation_option_keywords
            WHERE keyword = _optionKeyword;

            If Not FOUND Then
                _message := format('Keyword: "%s" not found in t_creation_option_keywords', _optionKeyword);
                RAISE WARNING '%', _message;

                ROLLBACK;

                _returnCode = '0'
                RETURN;
            End If;

            SELECT value_id
            INTO _optionValueID
            FROM pc.t_creation_option_values
            WHERE value_string = _optionValue;

            If Not FOUND Then
                _message := format('Value: "%s" not found in t_creation_option_values', _optionValue);
                RAISE WARNING '%', _message;
            Else
                INSERT INTO pc.t_archived_file_creation_options (
                    keyword_id,
                    value_id,
                    archived_file_id
                ) VALUES (
                    _optionKeywordID,
                    _optionValueID,
                    _archiveFileID);

            End If;

        END LOOP;

        INSERT INTO pc.t_archived_output_file_collections_xref (
            archived_file_id,
            protein_collection_id
        ) VALUES (
            _archiveFileID,
            _proteinCollectionID);

    End If;

    _returnCode := _archiveFileID::text;
END
$$;

COMMENT ON PROCEDURE pc.add_output_file_archive_entry IS 'AddOutputFileArchiveEntry';

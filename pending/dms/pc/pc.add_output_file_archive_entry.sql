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
**  Desc:   Adds a new entry to the T_Archived_Output_Files
**
**  Return values: Archived_File_ID (nonzero) : success, otherwise, error code
**
**
**
**  Auth:   kja
**  Date:   03/10/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _archiveEntryID int;
    _skipOutputTableAdd int;
    _archivedFileTypeID int;
    _outputSequenceTypeID int;
    _archivedFileState text;
    _archivedFileStateID int;
    _transName text;
    _tmpOptionKeyword text;
    _tmpOptionKeywordID int;
    _tmpOptionValue text;
    _tmpOptionValueID int;
    _tmpOptionString text;
    _tmpEqualsPosition int;
    _tmpStartPosition int;
    _tmpEndPosition int;
    _tmpCommaPosition int;
BEGIN
    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

-- is the hash the right length?

    if char_length(_crc32Authentication) <> 8 Then
        _myError := -51000;
        _msg := 'Authentication hash must be 8 alphanumeric characters in length (0-9, A-F)';
        RAISERROR (_msg, 10, 1)
    End If;

-- does this hash code already exist?

    _archiveEntryID := 0;

    SELECT Archived_File_ID INTO _archiveEntryID
        FROM V_Archived_Output_Files
        WHERE (Authentication_Hash = _crc32Authentication)

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myError <> 0 Then
        _msg := 'Database retrieval error during hash duplication check';
        RAISERROR (_msg, 10, 1)
        _message := _msg;
        return _myError
    End If;

--    if _myRowCount > 0
--    begin

--        set _myError = -51009
--        set _msg = 'SHA-1 Authentication Hash already exists for this collection'
--        RAISERROR (_msg, 10, 1)
--        return _myError
--    end

-- Does this protein collection even exist?

    SELECT ID FROM V_Collection_Picker
     WHERE (ID = _proteinCollectionID)

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myRowCount = 0 Then
        _myError := -51001;
        _msg := 'Collection does not exist';
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;

-- Is the archive path length valid?

    if char_length(_archivedFilePath) < 1 Then
        _myError := -51002;
        _msg := 'No archive path specified!';
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;

-- Check for existence of output file type in pc.t_archived_file_types

    SELECT archived_file_type_id  INTO _archivedFileTypeID
        FROM pc.t_archived_file_types
        WHERE file_type_name = _archivedFileType

    if _archivedFileTypeID < 1 Then
        _myError := -51003;
        _msg := 'archived_file_type does not exist';
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;

/*-- Check for existence of sequence type in pc.t_output_sequence_types

    SELECT output_sequence_type_id  INTO _outputSequenceTypeID
        FROM pc.t_output_sequence_types
        WHERE output_sequence_type = _outputSequenceType

    if _outputSequenceTypeID < 1 Then
        _myError := -51003;
        _msg := 'output_sequence_type does not exist';
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;
*/

-- Does this path already exist?

--    SELECT archived_file_id
--        FROM pc.t_archived_output_files
--        WHERE (archived_file_path = _archivedFilePath)
--
--    SELECT _myError = @@error, _myRowCount = @@rowcount
--
--    if _myError <> 0
--    begin
--        set _msg = 'Database retrieval error during archive path duplication check'
--        RAISERROR (_msg, 10, 1)
--        set _message = _msg
--        return _myError
--    end
--
--    if _myRowCount <> 0
--    begin
--        set _myError = -51010
--        set _msg = 'An archived file already exists at this location'
--        RAISERROR (_msg, 10, 1)
--        return _myError
--    end
--

--    if _myError <> 0
--    begin
--        set _message = _msg
--        return _myError
--    end

-- Determine the state of the entry based on provided data

    SELECT archived_file_id
    FROM pc.t_archived_output_file_collections_xref
    WHERE protein_collection_id = _proteinCollectionID

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    if _myError <> 0 Then
        _msg := 'Database retrieval error';
        RAISERROR (_msg, 10, 1)
        _message := _msg;
        return _myError
    End If;

    if _myRowCount = 0 Then
        _archivedFileState := 'original';
    End If;

    if _myRowCount > 0 Then
        _archivedFileState := 'modified';
    End If;

    SELECT archived_file_state_id INTO _archivedFileStateID
    FROM pc.t_archived_file_states
    WHERE archived_file_state = _archivedFileState

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    _transName := 'AddOutputFileArchiveEntry';
    begin transaction _transName

    ---------------------------------------------------
    -- Make the initial entry with what we have
    ---------------------------------------------------

    if _archiveEntryID = 0 Then

/*    INSERT INTO pc.t_archived_output_files (
        archived_file_type_id,
        archived_file_state_id,
        Output_Sequence_Type_ID,
        archived_file_path,
        Creation_Options_String,
        SHA1Authentication,
        archived_file_creation_date,
        file_modification_date,
        filesize
    ) VALUES (
        _archivedFileTypeID,
        _archivedFileStateID,
        _outputSequenceTypeID,
        _archivedFilePath,
        _creationOptions,
        _sha1Authentication,
        CURRENT_TIMESTAMP,
        _fileModificationDate,
        _fileSize)
*/
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
    INTO _archiveEntryID;

    _archivedFilePath := REPLACE(_archivedFilePath, '00000', RIGHT('000000' || archived_file_id::text, 6));

    UPDATE pc.t_archived_output_files
    SET archived_file_path = _archivedFilePath
    WHERE archived_file_id = _archiveEntryID

    ---------------------------------------------------
    -- Parse and Store Creation Options
    ---------------------------------------------------

    _tmpOptionKeyword := '';
    _tmpOptionValue := '';

    _tmpOptionString := '';

    _tmpEqualsPosition := 0;
    _tmpStartPosition := 0;
    _tmpEndPosition := 0;
    _tmpCommaPosition := 0;

    _tmpCommaPosition := position(',' in _creationOptions);
    if _tmpCommaPosition = 0 Then
        _tmpCommaPosition := char_length(_creationOptions);
    End If;

        WHILE(_tmpCommaPosition < char_length(_creationOptions))
        begin
            _tmpCommaPosition := position(',', _creationOptions in _tmpStartPosition);
            if _tmpCommaPosition = 0 Then
                _tmpCommaPosition := char_length(_creationOptions) + 1;
            End If;
            _tmpEndPosition := _tmpCommaPosition - _tmpStartPosition;
            _tmpOptionString := LTRIM(SUBSTRING(_creationOptions, _tmpStartPosition, _tmpCommaPosition));
            _tmpEqualsPosition := position('=' in _tmpOptionString);

            _tmpOptionKeyword := LEFT(_tmpOptionString, _tmpEqualsPosition - 1);
            _tmpOptionValue := RIGHT(_tmpOptionString, char_length(_tmpOptionString) - _tmpEqualsPosition);

            SELECT keyword_id INTO _tmpOptionKeywordID
            FROM pc.t_creation_option_keywords
            WHERE keyword = _tmpOptionKeyword

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            if _myError > 0 Then
                _msg := 'Database retrieval error during keyword validity check';
                _message := _msg;
                return _myError
            End If;

            if _myRowCount = 0 Then
                _msg := 'Keyword: "' || _tmpOptionKeyword || '" not located';
                _message := _msg;
                return -50011
            End If;

            if _myError = 0 and _myRowCount > 0 Then
                SELECT value_id INTO _tmpOptionValueID
                FROM pc.t_creation_option_values
                WHERE value_string = _tmpOptionValue

                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                if _myError > 0 Then
                    _msg := 'Database retrieval error during value validity check';
                    _message := _msg;
                End If;

                if _myRowCount = 0 Then
                    _msg := 'Value: "' || _tmpOptionValue || '" not located';
                    _message := _msg;
                End If;

                if _myError = 0 and _myRowCount > 0 Then
                INSERT INTO pc.t_archived_file_creation_options (
                    keyword_id,
                    value_id,
                    archived_file_id
                ) VALUES (
                    _tmpOptionKeywordID,
                    _tmpOptionValueID,
                    _archiveEntryID)

                End If;

                if _myError <> 0 Then
                    rollback transaction _transName
                    _msg := 'Insert operation failed: Creation Options';
                    RAISERROR (_msg, 10, 1)
                    _message := _msg;
                    return -51007
                End If;

            End If;

            _tmpStartPosition := _tmpCommaPosition + 1;
        End If;

        INSERT INTO pc.t_archived_output_file_collections_xref (
            archived_file_id,
            protein_collection_id
        ) VALUES (
            _archiveEntryID,
            _proteinCollectionID)

        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        if _myError <> 0 Then
            rollback transaction _transName
            _msg := 'Insert operation failed: Archive File Member Entry for "' || _proteinCollectionID || '"';
            RAISERROR (_msg, 10, 1)
            _message := _msg;
            return -51011
        End If;
    end

    commit transaction _transName

    return _archiveEntryID
END
$$;

COMMENT ON PROCEDURE pc.add_output_file_archive_entry IS 'AddOutputFileArchiveEntry';

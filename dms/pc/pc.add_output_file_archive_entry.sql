--
-- Name: add_output_file_archive_entry(integer, text, timestamp without time zone, bigint, integer, text, text, text, text, boolean, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_output_file_archive_entry(IN _proteincollectionid integer, IN _crc32authentication text, IN _filemodificationdate timestamp without time zone, IN _filesize bigint, IN _proteincount integer DEFAULT 0, IN _archivedfiletype text DEFAULT 'static'::text, IN _creationoptions text DEFAULT ''::text, IN _proteincollectionstring text DEFAULT ''::text, IN _collectionstringhash text DEFAULT ''::text, IN _showdebug boolean DEFAULT false, INOUT _archivedfilepath text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds a new entry to pc.t_archived_output_files
**
**  Arguments:
**    _proteinCollectionID          Protein collection ID (of the first protein collection, if combining multiple protein collections)
**    _crc32Authentication          CRC32 authentication hash (hash of the bytes in the file)
**    _fileModificationDate         File modification timestamp
**    _fileSize                     File size, in bytes
**    _proteinCount                 Protein count
**    _archivedFileType             Archived file type ('static' if a single protein collection; 'dynamic' if a combination of multiple protein collections)
**    _creationOptions              Creation options (e.g. 'seq_direction=forward,filetype=fasta')
**    _proteinCollectionString      Protein collection list (comma-separated list of protein collection names)
**    _collectionStringHash         SHA-1 hash of the protein collection list and creation options (separated by a forward slash)
**                                  For example, 'H_sapiens_UniProt_SPROT_2023-03-01,Tryp_Pig_Bov/seq_direction=forward,filetype=fasta' has SHA-1 hash '11822db6bbfc1cb23c0a728a0b53c3b9d97db1f5'
**    _showDebug                    When true, show debug messages
**    _archivedFilePath             Input/Output: archived file path
**
**  This procedure updates the filename to replace 00000 with the file ID in t_archived_output_files (padded using '000000')
**  For example,  '\\gigasax\DMS_FASTA_File_Archive\Dynamic\Forward\ID_00000_C1CEE570.fasta'
**  is changed to '\\gigasax\DMS_FASTA_File_Archive\Dynamic\Forward\ID_004226_C1CEE570.fasta'
**
**  Returns:
**    _returnCode will have the archived file ID of the file added to pc.t_archived_output_files if no errors
**    _returnCode will be '0' if an error
**
**  Auth:   kja
**  Date:   03/10/2006
**          08/18/2023 mem - When checking for an existing row in pc.t_archived_output_files, use both _crc32Authentication and _collectionStringHash
**                         - Update the file ID in _archivedFilePath even if an existing entry is found in T_Archived_Output_Files
**                         - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _archiveFileID int;
    _archivedFileTypeID int;
    _archivedFileState citext;
    _archivedFileStateID int;

    _optionItem text;
    _equalsPosition int;

    _optionKeyword citext;
    _optionKeywordID int;
    _optionValue citext;
    _optionValueID int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _proteinCollectionID     := Coalesce(_proteinCollectionID, 0);
    _crc32Authentication     := Coalesce(_crc32Authentication, '');

    _fileSize                := Coalesce(_fileSize, 0);
    _proteinCount            := Coalesce(_proteinCount, 0);
    _archivedFileType        := Coalesce(_archivedFileType, '');
    _creationOptions         := Coalesce(_creationOptions, '');
    _proteinCollectionString := Coalesce(_proteinCollectionString, '');
    _collectionStringHash    := Coalesce(_collectionStringHash, '');
    _showDebug               := Coalesce(_showDebug, false);
    _archivedFilePath        := Trim(Coalesce(_archivedFilePath, ''));

    If _showDebug Then
        RAISE INFO '';
    End If;

    -- Is the hash the right length?

    If char_length(_crc32Authentication) <> 8 Then
        _message := 'CRC-32 authentication hash must be 8 alphanumeric characters in length (0-9, A-F)';
        RAISE WARNING '%', _message;

        _returnCode := '0';
        RETURN;
    End If;

    -- Does this hash code already exist?

    SELECT Archived_File_ID
    INTO _archiveFileID
    FROM pc.t_archived_output_files
    WHERE authentication_hash = _crc32Authentication::citext AND
          collection_list_hex_hash = _collectionStringHash::citext
    ORDER BY archived_file_id DESC
    LIMIT 1;

    If Not FOUND Then
        _archiveFileID := 0;
    End If;

    -- Does the protein collection exist?

    If Not Exists ( SELECT protein_collection_id FROM pc.t_protein_collections WHERE protein_collection_id = _proteinCollectionID) Then
        _message := format('Protein collection ID not found in pc.t_protein_collections: %s', _proteinCollectionID);
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
    WHERE file_type_name = _archivedFileType::citext;

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

    If _showDebug Then
        RAISE INFO 'Archived file state: %', _archivedFileState;
    End If;

    SELECT archived_file_state_id
    INTO _archivedFileStateID
    FROM pc.t_archived_file_states
    WHERE archived_file_state = _archivedFileState;

    If _archiveFileID > 0 Then
        If _showDebug Then
            RAISE INFO 'Matched archive_file_id % for CRC32 hash % and collection name hash %',
                        _archiveFileID, _crc32Authentication, _collectionStringHash;
        End If;

        _archivedFilePath := REPLACE(_archivedFilePath, '00000', RIGHT(format('000000%s', _archiveFileID), 6));
    Else
        ---------------------------------------------------
        -- Make the initial entry
        ---------------------------------------------------

        If _showDebug Then
            RAISE INFO 'Adding new row to pc.t_archived_output_files for CRC32 hash % and collection name hash %',
                            _crc32Authentication, _collectionStringHash;
        End If;

        INSERT INTO pc.t_archived_output_files (
            archived_file_type_id,
            archived_file_state_id,
            archived_file_path,
            authentication_hash,
            archived_file_creation_date,
            file_modification_date,
            creation_options,
            file_size_bytes,
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

        _archivedFilePath := REPLACE(_archivedFilePath, '00000', RIGHT(format('000000%s', _archiveFileID), 6));

        UPDATE pc.t_archived_output_files
        SET archived_file_path = _archivedFilePath
        WHERE archived_file_id = _archiveFileID;

        ---------------------------------------------------
        -- Parse and Store Creation Options
        ---------------------------------------------------

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
                If _showDebug Then
                    RAISE INFO 'Adding creation option %=% to pc.t_archived_file_creation_options for %=%',
                                    _optionKeywordID, _optionValueID, _optionKeyword, _optionValue;
                End If;

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


ALTER PROCEDURE pc.add_output_file_archive_entry(IN _proteincollectionid integer, IN _crc32authentication text, IN _filemodificationdate timestamp without time zone, IN _filesize bigint, IN _proteincount integer, IN _archivedfiletype text, IN _creationoptions text, IN _proteincollectionstring text, IN _collectionstringhash text, IN _showdebug boolean, INOUT _archivedfilepath text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_output_file_archive_entry(IN _proteincollectionid integer, IN _crc32authentication text, IN _filemodificationdate timestamp without time zone, IN _filesize bigint, IN _proteincount integer, IN _archivedfiletype text, IN _creationoptions text, IN _proteincollectionstring text, IN _collectionstringhash text, IN _showdebug boolean, INOUT _archivedfilepath text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_output_file_archive_entry(IN _proteincollectionid integer, IN _crc32authentication text, IN _filemodificationdate timestamp without time zone, IN _filesize bigint, IN _proteincount integer, IN _archivedfiletype text, IN _creationoptions text, IN _proteincollectionstring text, IN _collectionstringhash text, IN _showdebug boolean, INOUT _archivedfilepath text, INOUT _message text, INOUT _returncode text) IS 'AddOutputFileArchiveEntry';


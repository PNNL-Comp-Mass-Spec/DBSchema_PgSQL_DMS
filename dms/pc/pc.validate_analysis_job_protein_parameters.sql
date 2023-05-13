--
-- Name: validate_analysis_job_protein_parameters(text, text, text, text, text, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.validate_analysis_job_protein_parameters(IN _organismname text, IN _ownerprn text, IN _organismdbfilename text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**    Validate the combination of organism DB file
**    (FASTA) file name, protein collection list,
**    and protein options list.
**
**    The protein collection list and protein options
**    list should be returned in canonical format.
**
**  Auth:   04/04/2006 grk
**  Date:   04/11/2006 kja
**          06/06/2006 mem - Updated Creation Options List logic to allow wider range of _protCollOptionsList values
**          06/08/2006 mem - Added call to StandardizeProteinCollectionList to validate the order of _protCollNameList
**          06/26/2006 mem - Updated to ignore _organismDBFileName If _protCollNameList is <> 'na'
**          10/04/2007 mem - Expanded _protCollNameList from varchar(512) to varchar(max)
**                           Expanded _organismName from varchar(64) to varchar(128)
**          01/12/2012 mem - Updated error message for error -50001
**          05/15/2012 mem - Updated error message for error -50001
**          09/25/2012 mem - Expanded _organismDBFileName to varchar(128)
**          06/24/2013 mem - Now removing duplicate protein collection names in _protCollNameList
**          05/11/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _legacyNameExists int;
    _organismID int;
    _legacyFileID int;
    _cleanCollNameList text;
    _collectionName citext;
    _extensionPosition int;
    _collectionID int;
    _entryID int;
    _isEncrypted int;
    _isAuthorized int;
    _optionKeyword citext;
    _optionKeywordID int;
    _optionValue citext;
    _optionValueToUse text;
    _keywordFound boolean;
    _optionString citext;
    _equalsPosition int;
    _cleanOptions text;
    _optionItem record;
BEGIN
    _message := '';
    _returnCode := '';

    -- Check for Null values
    _organismDBFileName := Trim(Coalesce(_organismDBFileName, ''));
    _protCollNameList := Trim(Coalesce(_protCollNameList, ''));
    _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, ''));

    _legacyNameExists := 0;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If char_length(_organismName) < 1 Then
        _message := 'Org DB validation failure: Organism Name cannot be blank';
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If char_length(_organismDBFileName) < 1 AND char_length(_protCollNameList) > 0 Then
        _organismDBFileName := 'na';
        -- No error needed, just fix it
    End If;

    If char_length(_protCollNameList) < 1 AND char_length(_organismDBFileName) > 0 AND _organismDBFileName::citext <> 'na' Then
        _protCollNameList := 'na';
        -- No error needed, just fix it
    End If;

    If (char_length(_organismDBFileName) = 0 AND char_length(_protCollNameList) = 0) OR (_organismDBFileName::citext = 'na' AND _protCollNameList::citext = 'na') Then
        _message := 'Org DB validation failure: Protein collection list and Legacy Fasta (OrgDBName) name cannot both be blank (or "na")';
        _returnCode := 'U5202';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _protCollNameList::citext <> 'na' AND char_length(_protCollNameList) > 0 Then
        -- No error needed, just fix it
        _organismDBFileName := 'na';
    End If;

    ---------------------------------------------------
    -- Check Validity of Organism Name
    ---------------------------------------------------

    SELECT ID
    INTO _organismID
    FROM V_Organism_Picker
    WHERE Short_Name = _organismName::citext;

    If Not FOUND Then
        _message := 'Organism "' || _organismName || '" does not exist (Protein_Sequences.V_Organism_Picker)';
        _returnCode := 'U5203';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check Validity of Legacy FASTA filename
    ---------------------------------------------------

    If _organismDBFileName::citext <> 'na' AND _protCollNameList::citext = 'na' Then
        If RIGHT(_organismDBFileName, 6)::citext <> '.fasta' Then
            _organismDBFileName := _organismDBFileName || '.fasta';
        End If;

        SELECT ID
        INTO _legacyFileID
        FROM V_Legacy_Static_File_Locations
        WHERE FileName = _organismDBFileName;

        If Not FOUND Then
            _message := 'FASTA file "' || _organismDBFileName || '" does not exist (Protein_Sequences.V_Legacy_Static_File_Locations)';
            _returnCode := 'U5204';

            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Check Validity of Protein Collection Name List
    ---------------------------------------------------

    If _protCollNameList::citext = 'na' Then
        RETURN;
    End If;


    CREATE TEMP TABLE Tmp_ProteinCollectionList (
        Collection_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Collection_Name text
    );

    INSERT INTO Tmp_ProteinCollectionList (Collection_Name)
    SELECT DISTINCT Trim(Value)
    FROM public.parse_delimited_list(_protCollNameList, ',');

    _cleanCollNameList := '';

    _entryID := 0;

    WHILE true
    LOOP
        If _entryID > 0 Then
            _cleanCollNameList := _cleanCollNameList || ',';
        End If;

        SELECT Collection_ID, Collection_Name
        INTO _entryID, _collectionName
        FROM Tmp_ProteinCollectionList
        WHERE Collection_ID > _entryID
        ORDER BY Collection_ID
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        _extensionPosition := position('.fasta' in _collectionName);

        If _extensionPosition > 0 Then
            _collectionName := SUBSTRING(_collectionName, 0, _extensionPosition);
        End If;

        SELECT contents_encrypted
        INTO _isEncrypted
        FROM pc.t_protein_collections
        WHERE collection_name = _collectionName;

        If Not FOUND Then
            _message := format('"%s" is not a valid protein collection name', _collectionName);
            _returnCode := 'U5205';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_ProteinCollectionList;
            RETURN;
        End If;

        If _isEncrypted > 0 Then

            SELECT authorization_id
            FROM pc.t_encrypted_collection_authorizations
            WHERE login_name LIKE '%' || _ownerPRN || '%' AND
                    protein_collection_id = _collectionID;

            If Not FOUND Then
                _message := format('%s is not authorized for the encrypted collection "%s"', _ownerPRN, _collectionName);
                _returnCode := 'U5206';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_ProteinCollectionList;
                RETURN;
            End If;

        End If;

        _cleanCollNameList := _cleanCollNameList || _collectionName;
    END LOOP;

    ---------------------------------------------------
    -- Order the protein collections in a standardized order
    ---------------------------------------------------

    _protCollNameList := pc.standardize_protein_collection_list(_cleanCollNameList);

    ---------------------------------------------------
    -- Check Validity of Creation Options List
    ---------------------------------------------------

    _cleanOptions := '';

    If _protCollOptionsList = '' Or _protCollOptionsList::citext = 'na' Then
        _protCollOptionsList := 'na';

        DROP TABLE Tmp_ProteinCollectionList;
        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_OptionTable (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Option_Entry text,
        Keyword_ID int NULL,
        Keyword citext NULL,
        Value text NULL
    );

    INSERT INTO Tmp_OptionTable (Option_Entry)
    SELECT DISTINCT Trim(Value)
    FROM public.parse_delimited_list(_protCollOptionsList, ',');

    _entryID := 0;

    WHILE true
    LOOP
        SELECT Entry_ID, Option_Entry
        INTO _entryID, _optionString
        FROM Tmp_OptionTable
        WHERE Entry_ID > _entryID
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        If Coalesce(_optionString, '') = '' Then
            RAISE WARNING 'Option item % is null or empty', _entryID;
            CONTINUE;
        End If;

        _equalsPosition := position('=' in _optionString);

        If _equalsPosition = 0 Then
            If _optionString <> 'na' Then
                _message := 'Keyword: "' || _optionString || '" not followed by an equals sign';
                _returnCode := 'U5207';
                RAISE WARNING '%', _message;

                DROP TABLE Tmp_ProteinCollectionList;
                DROP TABLE Tmp_OptionTable;
                RETURN;
            End If;

            CONTINUE;
        End If;

        If _equalsPosition = 1 OR _equalsPosition = char_length(_optionString) Then

            -- Keyword starts or ends with an equals sign
            _message := format('Keyword: "%s"', _optionString);

            If _equalsPosition = 1 Then
                _message := _message || ' starts with an equals sign';
            Else
                _message := _message || ' ends with an equals sign';
            End If;

            _returnCode := 'U5208';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_ProteinCollectionList;
            DROP TABLE Tmp_OptionTable;
            RETURN;
        End If;

        _optionKeyword    := TRIM(substring(_optionString, 1, _equalsPosition - 1));
        _optionValue      := TRIM(substring(_optionString, _equalsPosition + 1));

        -- Auto-update seq_direction 'reverse' to 'reversed'
        If _optionKeyword = 'seq_direction' AND _optionValue = 'reverse' Then
            _optionValue := 'reversed';
        End If;

        -- Look for _optionKeyword in pc.t_creation_option_keywords
        SELECT keyword_id
        INTO _optionKeywordID
        FROM pc.t_creation_option_keywords
        WHERE keyword = _optionKeyword;

        If Not FOUND Then
            _message := format('"%s" is not a valid keyword; protein options list: %s',
                            Coalesce(_optionKeyword, '??'), _protCollOptionsList);
            _returnCode := 'U5209';
            RAISE WARNING '%', _message;

            DROP TABLE Tmp_ProteinCollectionList;
            DROP TABLE Tmp_OptionTable;
            RETURN;
        End If;

        UPDATE Tmp_OptionTable
        SET Keyword_ID = _optionKeywordID,
            Keyword = _optionKeyword,
            Value = _optionValue
        WHERE entry_ID = _entryID;

    END LOOP;

    -- Step through collected Keyword/Value Pairs and validate the values

    FOR _optionItem IN
        SELECT keyword,
               default_value AS DefaultValue,
               is_required AS IsRequired
        FROM pc.t_creation_option_keywords
        ORDER BY keyword_id
    LOOP
        -- Check Specified Value Existence
        SELECT Value
        INTO _optionValue
        FROM Tmp_OptionTable
        WHERE Keyword = _optionItem.Keyword;

        If FOUND Then
            _keywordFound := true;

            -- Validate _optionValue against pc.t_creation_option_values
            SELECT OptValues.value_string
            INTO _optionValueToUse
            FROM pc.t_creation_option_values OptValues INNER JOIN
                 pc.t_creation_option_keywords OptKeywords ON OptValues.keyword_id = OptKeywords.keyword_id
            WHERE OptKeywords.keyword = _optionItem.Keyword AND
                  OptValues.value_string = _optionValue;

            If FOUND Then
                If char_length(_cleanOptions) > 0 Then
                    _cleanOptions := _cleanOptions || ',';
                End If;

                _cleanOptions := format('%s%s=%s', _cleanOptions, _optionItem.Keyword, _optionValueToUse);
            Else
                If _optionItem.IsRequired > 0 Then
                    RAISE WARNING 'Option "%" has an invalid value of "%"; using default value "%" instead', _optionItem.Keyword, _optionValue, _optionItem.DefaultValue;
                    _keywordFound := false;
                Else
                    RAISE WARNING 'Option "%" has an invalid value of "%"; ignoring', _optionItem.Keyword, _optionValue;
                End If;

            End If;

        Else
            If _optionItem.IsRequired > 0 Then
                RAISE INFO 'Options list does not include required keyword "%"; adding it with the default value "%"', _optionItem.Keyword, _optionItem.DefaultValue;
            End If;

            _keywordFound := false;
        End If;

        If Not _keywordFound AND _optionItem.IsRequired > 0 Then
            If char_length(_cleanOptions) > 0 Then
                _cleanOptions := _cleanOptions || ',';
            End If;

            _cleanOptions := format('%s%s=%s', _cleanOptions, _optionItem.Keyword, _optionItem.DefaultValue);
        End If;

    END LOOP;

    _protCollOptionsList := _cleanOptions;

    DROP TABLE Tmp_ProteinCollectionList;
    DROP TABLE Tmp_OptionTable;

END
$$;


ALTER PROCEDURE pc.validate_analysis_job_protein_parameters(IN _organismname text, IN _ownerprn text, IN _organismdbfilename text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_analysis_job_protein_parameters(IN _organismname text, IN _ownerprn text, IN _organismdbfilename text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.validate_analysis_job_protein_parameters(IN _organismname text, IN _ownerprn text, IN _organismdbfilename text, INOUT _protcollnamelist text, INOUT _protcolloptionslist text, INOUT _message text, INOUT _returncode text) IS 'ValidateAnalysisJobProteinParameters';


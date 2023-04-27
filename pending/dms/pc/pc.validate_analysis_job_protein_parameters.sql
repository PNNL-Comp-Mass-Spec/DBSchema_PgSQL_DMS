--
CREATE OR REPLACE PROCEDURE pc.validate_analysis_job_protein_parameters
(
    _organismName text,
    _ownerPRN text,
    _organismDBFileName text,
    INOUT _protCollNameList text,
    INOUT _protCollOptionsList text,
    INOUT _message text
)
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
**  original argument specs: grk
**  Date:   04/04/2006
**          12/15/2023 mem - Ported to PostgreSQL
**
**  Auth:   kja
**  Date:   04/11/2006
**          06/06/2006 mem - Updated Creation Options List logic to allow wider range of _protCollOptionsList values
**          06/08/2006 mem - Added call to StandardizeProteinCollectionList to validate the order of _protCollNameList
**          06/26/2006 mem - Updated to ignore _organismDBFileName If _protCollNameList is <> 'na'
**          10/04/2007 mem - Expanded _protCollNameList from varchar(512) to varchar(max)
**                           Expanded _organismName from varchar(64) to varchar(128)
**          01/12/2012 mem - Updated error message for error -50001
**          05/15/2012 mem - Updated error message for error -50001
**          09/25/2012 mem - Expanded _organismDBFileName to varchar(128)
**          06/24/2013 mem - Now removing duplicate protein collection names in _protCollNameList

**  Error Return Codes:
**      (-50001) = both values cannot be blank or 'na'
**      (-50002) = ambiguous combination of legacy name and protein collection
**                  (different values for each)
**      (-50010) = General database retrieval error
**      (-50011) = Lookup keyword or value not valid
**      (-50020) = Encrypted collection authorization failure
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _msg text;
    _legacyNameExists int;
    _organismID int;
    _legacyFileID int;
    _collListTable table(Collection_ID int Identity(1,1), Collection_Name text);
    _cleanCollNameList text;
    _tmpCollName text;
    _tmpExtPosition int;
    _tmpCollectionID int;
    _loopCounter int := 0;
    _itemCounter int := 0;
    _isEncrypted int;
    _isAuthorized int;
    _tmpCommaPosition int := 0;
    _tmpStartPosition int := 0;
    _tmpOptionKeyword text;
    _tmpOptionKeywordID int;
    _tmpOptionValueID int;
    _tmpOptionValue text;
    _keywordDefaultValue text;
    _keywordIsReqd int;
    _tmpOptionString text;
    _tmpOptionTable table(Keyword_ID int, Keyword text, Value text);
    _tmpEqualsPosition int;
    _cleanOptionString text;
    _protCollOptionsListLength int;
    _keywordID int;
    _continue int;
BEGIN
    _message := '';

    -- Check for Null values
    _organismDBFileName := Trim(Coalesce(_organismDBFileName, ''));
    _protCollNameList := Trim(Coalesce(_protCollNameList, ''));
    _protCollOptionsList := Trim(Coalesce(_protCollOptionsList, ''));

    _legacyNameExists := 0;

    /****************************************************************
    -- catch empty fields
    ****************************************************************/

    If char_length(_organismName) < 1 Then
        _msg := 'Org DB validation failure: Organism Name cannot be blank';
        _myError := -50001;
        RAISERROR(_msg, 10, 1)
    End If;

    If char_length(_organismDBFileName) < 1 and char_length(_protCollNameList) > 0 Then
        _organismDBFileName := 'na';
        -- No error needed, just fix it
    End If;

    If char_length(_protCollNameList) < 1 and char_length(_organismDBFileName) > 0 and _organismDBFileName <> 'na' Then
        _protCollNameList := 'na';
        -- No error needed, just fix it
    End If;

    If (char_length(_organismDBFileName) = 0 and char_length(_protCollNameList) = 0) OR (_organismDBFileName = 'na' AND _protCollNameList = 'na') Then
        _msg := 'Org DB validation failure: Protein collection list and Legacy Fasta (OrgDBName) name cannot both be blank (or "na")';
        _myError := -50001;
        RAISERROR(_msg, 10 ,1)
    End If;

    If _protCollNameList <> 'na' AND char_length(_protCollNameList) > 0 Then
        _organismDBFileName := 'na';
        -- No error needed, just fix it
    End If;

    If _myError <> 0 Then
        _message := _msg;
        return _myError
    End If;

    /****************************************************************
    ** Check Validity of Organism Name
    ****************************************************************/

    SELECT ID INTO _organismID
    FROM V_Organism_Picker
    WHERE Short_Name = _organismName

    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myError <> 0 Then
        _msg := 'Database retrieval error during organism name check (Protein_Sequences.V_Organism_Picker)';
        _myError := -50010;
        _message := _msg;
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;

    If _myRowCount < 1 Then
        _msg := 'Organism "' || _organismName || '" does not exist (Protein_Sequences.V_Organism_Picker)';
        _myError := -50011;
        _message := _msg;
        RAISERROR (_msg, 10, 1)
        return _myError
    End If;

    /****************************************************************
    ** Check Validity of Legacy FASTA filename
    ****************************************************************/

    If _organismDBFileName <> 'na' AND _protCollNameList = 'na' Then
    -- <a1>
        If RIGHT(_organismDBFileName, 6) <> '.fasta' Then
            _organismDBFileName := _organismDBFileName || '.fasta';
        End If;

        SELECT ID INTO _legacyFileID
        FROM V_Legacy_Static_File_Locations
        WHERE FileName = _organismDBFileName

        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myError <> 0 Then
            _msg := 'Database retrieval error during Organsim DB Filename check (Protein_Sequences.V_Legacy_Static_File_Locations)';
            _myError := -50010;
            _message := _msg;
            RAISERROR (_msg, 10, 1)
            return _myError
        End If;

        If _myRowCount < 1 Then
            _msg := 'FASTA file "' || _organismDBFileName || '" does not exist (Protein_Sequences.V_Legacy_Static_File_Locations)';
            _myError := -50011;
            _message := _msg;
            RAISERROR (_msg, 10, 1)
            return _myError
        End If;
    End If; -- </a1>

    /****************************************************************
    ** Check Validity of Protein Collection Name List
    ****************************************************************/
    If _protCollNameList <> 'na' Then
    -- <a2>

        INSERT INTO _collListTable (Collection_Name)
        SELECT DISTINCT Trim(Value)
        FROM public.parse_delimited_list(_protCollNameList, ',')

        _cleanCollNameList := '';

        SELECT COUNT(*) INTO _loopCounter
        FROM _collListTable

        While _loopCounter > 0 Loop
            If _itemCounter > 0 Then
                _cleanCollNameList := _cleanCollNameList || ',';
            End If;
            _loopCounter := _loopCounter - 1;
            _itemCounter := _itemCounter + 1;

            SELECT Collection_Name INTO _tmpCollName
            FROM _collListTable
            WHERE Collection_ID = _itemCounter

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _tmpExtPosition := position('.fasta' in _tmpCollName);
            If _tmpExtPosition > 0 Then
                _tmpCollName := SUBSTRING(_tmpCollName, 0, _tmpExtPosition);
            End If;

            SELECT contents_encrypted
            INTO _isEncrypted
            FROM pc.t_protein_collections
            WHERE collection_name = _tmpCollName

            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myError <> 0 Then
                _msg := 'Database retrieval error during collection name check (Protein_Sequences.t_protein_collections)';
                _message := _msg;
                RAISERROR (_msg, 10, 1)
                return _myError
            End If;

            If _myRowCount = 0 Then
                _msg := '"' || _tmpCollName || '" was not found in the Protein Collection List';
                _message := _msg;
                RAISERROR (_msg, 10, 1)
                return -50001
            End If;

            If _isEncrypted > 0 Then
            -- <c2>
                SELECT authorization_id
                FROM pc.t_encrypted_collection_authorizations
                WHERE login_name LIKE '%' || _ownerPRN || '%' AND
                        protein_collection_id = _tmpCollectionID

                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myRowCount = 0 Then
                    _msg := _ownerPRN || ' is not authorized for the encrypted collection "' || _tmpCollName || '"';
                    _message := _msg;
                    RAISERROR (_msg, 10, 1)
                    return -50020
                End If;

            End If; -- </c2>

            _cleanCollNameList := _cleanCollNameList + _tmpCollName;
        End Loop; -- </b2>

        /****************************************************************
        ** Copy the data from _cleanCollNameList to _protCollNameList and
        ** validate the order of the entries
        ****************************************************************/

        _protCollNameList := _cleanCollNameList;

        Call _protCollNameList => _protCollNameList OUTPUT, _message => _message OUTPUT

        /****************************************************************
        ** Check Validity of Creation Options List
        ****************************************************************/

        _cleanOptionString := '';

        _protCollOptionsListLength := char_length(_protCollOptionsList);

        If _protCollOptionsListLength = 0 Then
            _protCollOptionsList := 'na';
            _protCollOptionsListLength := char_length(_protCollOptionsList);
        End If;

        _tmpCommaPosition := position(',' in _protCollOptionsList);
        If _tmpCommaPosition = 0 Then
            _tmpCommaPosition := _protCollOptionsListLength;
        End If;

        While (_tmpCommaPosition <= _protCollOptionsListLength) Loop
            _tmpCommaPosition := position(',', _protCollOptionsList in _tmpStartPosition);
            If _tmpCommaPosition = 0 Then
                _tmpCommaPosition := _protCollOptionsListLength + 1;
            End If;

            If _tmpCommaPosition > _tmpStartPosition Then
            -- <c3>
                _tmpOptionString := LTRIM(SUBSTRING(_protCollOptionsList, _tmpStartPosition, _tmpCommaPosition - _tmpStartPosition));
                _tmpEqualsPosition := position('=' in _tmpOptionString);

                If _tmpEqualsPosition = 0 Then
                    If _tmpOptionString <> 'na' Then
                        _msg := 'Keyword: "' || _tmpOptionString || '" not followed by an equals sign';
                        _message := _msg;
                        return -50011
                    End If;
                Else
                -- <d3>
                    _tmpOptionKeyword := LEFT(_tmpOptionString, _tmpEqualsPosition - 1);
                    _tmpOptionValue := RIGHT(_tmpOptionString, char_length(_tmpOptionString) - _tmpEqualsPosition);

                    -- Auto-update seq_direction 'reverse' to 'reversed'
                    If _tmpOptionKeyword = 'seq_direction' and _tmpOptionValue = 'reverse' Then
                        _tmpOptionValue := 'reversed';
                    End If;

                    -- Look for _tmpOptionKeyword in pc.t_creation_option_keywords
                    SELECT keyword_id INTO _tmpOptionKeywordID
                    FROM pc.t_creation_option_keywords
                    WHERE keyword = _tmpOptionKeyword

                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    If _myError = 0 and _myRowCount > 0 Then
                        INSERT INTO _tmpOptionTable (Keyword_ID, Keyword, Value)
                        VALUES (_tmpOptionKeywordID, _tmpOptionKeyword, _tmpOptionValue)
                    End If;

                    If _myError > 0 Then
                        _msg := 'Database retrieval error during keyword validity check';
                        _message := _msg;
                        return _myError
                    End If;

                    If _myRowCount = 0 Then
                        _msg := 'Keyword: "' || _tmpOptionKeyword || '" not located';
                        _message := _msg;
                        return -50011
                    End If;
                End If; -- </d3>
            End If; -- </c3>

            _tmpStartPosition := _tmpCommaPosition + 1;
        End Loop; -- </b3>

        -- Cruise through collected Keyword/Value Pairs and check for validity
        _keywordID := 0;

        _continue := 1;
        While _continue = 1 Loop
            -- This While loop can probably be converted to a For loop; for example:
            --    For _itemName In
            --        SELECT item_name
            --        FROM TmpSourceTable
            --        ORDER BY entry_id
            --    Loop
            --        ...
            --    End Loop

            -- Moved to bottom of query: TOP 1
            SELECT    TOP 1
                    _keywordID = keyword_id,
                    _tmpOptionKeyword = keyword,
                    _keywordDefaultValue = default_value,
                    _keywordIsReqd = is_required
            FROM pc.t_creation_option_keywords
            WHERE keyword_id > _keywordID
            ORDER BY keyword_id
            LIMIT 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount = 0 Then
                _continue := 0;
            Else
            -- <c4>
                If char_length(_cleanOptionString) > 0 Then
                    _cleanOptionString := _cleanOptionString || ',';
                End If;

                --Check Specified Value Existence
                SELECT Value INTO _tmpOptionValue
                FROM _tmpOptionTable
                WHERE Keyword = _tmpOptionKeyword
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _myError = 0 and _myRowCount > 0 Then
                -- <d4>
                    -- Validate _tmpOptionValue against pc.t_creation_option_values
                    SELECT OptValues.value_string INTO _tmpOptionValue
                    FROM pc.t_creation_option_values OptValues INNER JOIN
                            pc.t_creation_option_keywords OptKeywords ON OptValues.keyword_id = OptKeywords.keyword_id
                    WHERE OptKeywords.keyword = _tmpOptionKeyword AND
                            OptValues.value_string = _tmpOptionValue
                    --
                    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                    If _myError = 0 and _myRowCount > 0 Then
                        _cleanOptionString := _cleanOptionString + _tmpOptionKeyword || '=' || _tmpOptionValue;
                    End If;

                End If;-- </d4>

                If _myError <> 0 Then
                    _msg := 'Database retrieval error during keyword validity check';
                    _message := _msg;
                    return _myError
                End If;

                If _myRowCount = 0 and _keywordIsReqd > 0 Then
                    _cleanOptionString := _cleanOptionString + _tmpOptionKeyword || '=' || _keywordDefaultValue;
                End If;

            End If; -- </c4>
        End Loop; -- <b4>

        _protCollOptionsList := _cleanOptionString;
    End If; -- </a2>

    return _myError

END
$$;

COMMENT ON PROCEDURE pc.validate_analysis_job_protein_parameters IS 'ValidateAnalysisJobProteinParameters';

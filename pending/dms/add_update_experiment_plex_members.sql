--
CREATE OR REPLACE PROCEDURE public.add_update_experiment_plex_members
(
    INOUT _plexExperimentIdOrName text,
    _plexMembers text,
    _expIdChannel1 text = '',
    _expIdChannel2 text = '',
    _expIdChannel3 text = '',
    _expIdChannel4 text = '',
    _expIdChannel5 text = '',
    _expIdChannel6 text = '',
    _expIdChannel7 text = '',
    _expIdChannel8 text = '',
    _expIdChannel9 text = '',
    _expIdChannel10 text = '',
    _expIdChannel11 text = '',
    _expIdChannel12 text = '',
    _expIdChannel13 text = '',
    _expIdChannel14 text = '',
    _expIdChannel15 text = '',
    _expIdChannel16 text = '',
    _expIdChannel17 text = '',
    _expIdChannel18 text = '',
    _channelType1 text = '',
    _channelType2 text = '',
    _channelType3 text = '',
    _channelType4 text = '',
    _channelType5 text = '',
    _channelType6 text = '',
    _channelType7 text = '',
    _channelType8 text = '',
    _channelType9 text = '',
    _channelType10 text = '',
    _channelType11 text = '',
    _channelType12 text = '',
    _channelType13 text = '',
    _channelType14 text = '',
    _channelType15 text = '',
    _channelType16 text = '',
    _channelType17 text = '',
    _channelType18 text = '',
    _comment1 text = '',
    _comment2 text = '',
    _comment3 text = '',
    _comment4 text = '',
    _comment5 text = '',
    _comment6 text = '',
    _comment7 text = '',
    _comment8 text = '',
    _comment9 text = '',
    _comment10 text = '',
    _comment11 text = '',
    _comment12 text = '',
    _comment13 text = '',
    _comment14 text = '',
    _comment15 text = '',
    _comment16 text = '',
    _comment17 text = '',
    _comment18 text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or updates existing experiment plex members in t_experiment_plex_members
**      Can either provide data via _plexMembers or via channel-specific parameters
**
**      _plexMembers is a table listing Experiment ID values by channel or by tag
**      Supported header names: Channel, Tag, Tag_Name, Exp_ID, Experiment, Channel_Type, Comment
**
**      If the header row is missing from the table, will attempt to auto-determine the channel
**      The first two columns are required; Channel Type and Comment are optional
**
** Example 1:
**     Channel, Exp_ID, Channel Type, Comment
**     1, 212457, Normal,
**     2, 212458, Normal,
**     3, 212458, Normal,
**     4, 212459, Normal, Optionally define a comment
**     5, 212460, Normal,
**     6, 212461, Normal,
**     7, 212462, Normal,
**     8, 212463, Normal,
**     9, 212464, Normal,
**     10, 212465, Normal,
**     11, 212466, Reference, This is a pooled reference
**
**
** Example 2:
**     Tag, Exp_ID, Channel Type, Comment
**     126, 212457, Normal,
**     127N, 212458, Normal,
**     127C, 212458, Normal,
**     128N, 212459, Normal, Optionally define a comment
**     128C, 212460
**     129N, 212461
**     129C, 212462
**     130N, 212463, Normal,
**     130C, 212464, Normal,
**     131N, 212465
**     131C, 212466, Reference, This is a pooled reference
**
** Example 3:
**     Tag, Experiment, Channel Type, Comment
**     126, CPTAC_UCEC_Ref, Reference,
**     127N, CPTAC_UCEC_C3N-00858, Normal, Aliquot: CPT007832 0004
**     127C, CPTAC_UCEC_C3N-00858, Normal, Aliquot: CPT007836 0001
**     128N, CPTAC_UCEC_C3L-01252, Normal, Aliquot: CPT008062 0001
**     128C, CPTAC_UCEC_C3L-01252, Normal, Aliquot: CPT008061 0003
**     129N, CPTAC_UCEC_C3L-00947, Normal, Aliquot: CPT002742 0003
**     129C, CPTAC_UCEC_C3L-00947, Normal, Aliquot: CPT002743 0001
**     130N, CPTAC_UCEC_C3N-00734, Normal, Aliquot: CPT002603 0004
**     130C, CPTAC_UCEC_C3L-01248, Normal, Aliquot: CPT008030 0003
**     131, CPTAC_UCEC_C3N-00850, Normal, Aliquot: CPT002781 0003
**
**  Arguments:
**    _plexExperimentIdOrName   Input/output parameter; used by the experiment_plex_members page family when copying an entry and changing the plex Exp_ID.  Accepts name or ID as input, but the output is always ID
**    _plexMembers              Table of Channel to Exp_ID mapping (see above for examples)
**    _expIdChannel 1 ... 18    Channel experiment: Experiment ID, Experiment Name, or ExpID:ExperimentName
**    _channelType  1 ... 18    Channel type: Normal, Reference, or Empty
**    _comment      1 ... 18    Channel domment
**    _mode                     Mode: 'add', 'update', 'check_add', 'check_update', or 'preview'
**    _message                  Output message
**    _returnCode               Return code
**    _callingUser              Calling user username
**
**  Auth:   mem
**  Date:   11/19/2018 mem - Initial version
**          11/28/2018 mem - Allow the second column in the plex table to have experiment names instead of IDs
**                         - Make _expIdChannel and _channelType parameters optional
**                         - Add _comment parameters
**          11/29/2018 mem - Call Alter_Entered_By_User
**          11/30/2018 mem - Make _plexExperimentId an output parameter
**          09/04/2019 mem - If the plex experiment is a parent experiment of an experiment group, copy plex info to the members (fractions) of the experiment group
**          09/06/2019 mem - When updating a plex experiment that is a parent experiment of an experiment group, also update the members (fractions) of the experiment group
**          03/02/2020 mem - Update to support TMT 16 by adding channels 12-16
**          08/04/2021 mem - Rename _plexExperimentId to _plexExperimentIdOrName
**          11/09/2021 mem - Update _mode to support 'preview'
**          04/18/2022 mem - Update to support TMT 18 by adding channels 17 and 18
**          04/20/2022 mem - Fix typo in variable names
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchCount int := 0;
    _msg text;
    _logErrors boolean := false;
    _plexExperimentId int;
    _experimentLabel text;
    _expectedChannelCount int := 0;
    _actualChannelCount int := 0;
    _entryID int;
    _parseColData false;
    _value text;
    _charIndex int;
    _plexExperimentName text := '';
    _currentPlexExperimentId Int;
    _targetPlexExperimentCount int := 0;
    _targetAddCount int := 0;
    _targetUpdateCount int := 0;
    _updatedRows int;
    _actionMessage text;
    _expIdList text := '';
    _firstLineParsed boolean := false;
    _headersDefined boolean := false;
    _channelColNum int := 0;
    _tagColNum int := 0;
    _experimentIdColNum int := 0;
    _channelTypeColNum int := 0;
    _commentColNum int := 0;
    _channelNum int;
    _channelText text;
    _tagName text;
    _experimentId int;
    _experimentIdOrName text;
    _channelTypeId int;
    _channelTypeName text;
    _plexMemberComment text;
    _invalidExperimentCount int := 0;
    _validValues text;
    _logMessage text;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If _plexExperimentIdOrName Is Null Then
            RAISE EXCEPTION 'plexExperimentIdOrName cannot be null';
        End If;

        _plexExperimentId := public.try_cast(_plexExperimentIdOrName, null::int);

        If _plexExperimentId Is Null Then
            -- Assume _plexExperimentIdOrName is an experiment name
            SELECT exp_id
            INTO _plexExperimentId
            FROM t_experiments
            WHERE experiment = _plexExperimentIdOrName;

            If Not FOUND Then
                _message := format('Invalid Experiment Name: %s', _plexExperimentIdOrName);
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        -- Assure that _plexExperimentIdOrName has Experiment ID
        _plexExperimentIdOrName := _plexExperimentId;

        _plexMembers := Trim(Coalesce(_plexMembers, ''));
        _mode        := Trim(Lower(Coalesce(_mode, 'check_add')));
        _callingUser := Trim(Coalesce(_callingUser, ''));

        ---------------------------------------------------
        -- Lookup the label associated with _plexExperimentId
        ---------------------------------------------------

        SELECT Trim(labelling)
        INTO _experimentLabel
        FROM t_experiments
        WHERE exp_id = _plexExperimentId

        If Not FOUND Then
            _message := format('Invalid Plex Experiment ID %s', _plexExperimentIdOrName);
            RAISE EXCEPTION '%', _message;
        End If;

        If _experimentLabel::citext In ('Unknown', 'None') Then
            _message := format('Plex Experiment ID %s needs to have its isobaric label properly defined (as TMT10, TMT11, iTRAQ, etc.); it is currently %s',
                                _plexExperimentIdOrName, _experimentLabel);

            RAISE EXCEPTION '%', _message;
        End If;

        SELECT COUNT(channel)
        INTO _expectedChannelCount
        FROM t_sample_labelling_reporter_ions
        WHERE label = _experimentLabel;

        ---------------------------------------------------
        -- Create a temporary table to track the mapping info
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Experiment_Plex_Members (
            Channel int NOT NULL,
            Exp_ID int NOT NULL,
            Channel_Type_ID int NOT NULL,
            Comment text NULL,
            ValidExperiment int NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_Experiment_Plex_Members On Tmp_Experiment_Plex_Members (Channel);

        CREATE TEMP TABLE Tmp_DatabaseUpdates (
            ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Message text NOT NULL
        );

        CREATE UNIQUE INDEX IX_Tmp_DatabaseUpdates On Tmp_DatabaseUpdates (ID);

        ---------------------------------------------------
        -- Parse _plexMembers
        ---------------------------------------------------

        If char_length(_plexMembers) > 0 Then
            -- Split _plexMembers on newline characters

            CREATE TEMP TABLE Tmp_RowData (Entry_ID int, Value text);

            CREATE TEMP TABLE Tmp_ColData (Entry_ID int, Value text);

            INSERT INTO Tmp_RowData( Entry_ID, Value)
            SELECT Entry_ID, Value
            FROM public.parse_delimited_list_ordered(_plexMembers, chr(10), 0);

            _entryID := 0;

            FOR _value IN
                SELECT Value
                FROM Tmp_RowData
                ORDER BY Entry_ID
            LOOP
                DELETE FROM Tmp_ColData;

                -- Note that public.parse_delimited_list_ordered will replace tabs with commas

                INSERT INTO Tmp_ColData( Entry_ID, Value)
                SELECT Entry_ID, Value
                FROM public.parse_delimited_list_ordered(_value, ',', 4);

                If FOUND Then
                    _parseColData := true;
                Else
                    _parseColData := false;
                End If;

                If _parseColData And Not _firstLineParsed Then

                    SELECT Entry_ID
                    INTO _channelColNum
                    FROM Tmp_ColData
                    WHERE Value::citext In ('Channel', 'Channel Number')
                    ORDER BY Entry_ID
                    LIMIT 1;

                    If FOUND Then
                        _headersDefined := true;
                    Else
                        SELECT Entry_ID
                        INTO _tagColNum
                        FROM Tmp_ColData
                        WHERE Value::citext In ('Tag', 'Tag_Name', 'Tag Name', 'Masic_Name', 'Masic Name')
                        ORDER BY Entry_ID
                        LIMIT 1;

                        If FOUND Then
                            _headersDefined := true;
                        End If;
                    End If;

                    SELECT Entry_ID
                    INTO _experimentIdColNum
                    FROM Tmp_ColData
                    WHERE Value::citext In ('Exp_ID', 'Exp ID', 'Experiment_ID', 'Experiment ID', 'Experiment', 'Exp_ID_or_Name', 'Name')
                    ORDER BY Entry_ID
                    LIMIT 1;

                    If FOUND Then
                        _headersDefined := true;
                    End If;

                    SELECT Entry_ID
                    INTO _channelTypeColNum
                    FROM Tmp_ColData
                    WHERE Value::citext In ('Channel_Type', 'Channel Type')
                    ORDER BY Entry_ID
                    LIMIT 1;

                    If FOUND Then
                        _headersDefined := true;
                    End If;

                    SELECT Entry_ID
                    INTO _commentColNum
                    FROM Tmp_ColData
                    WHERE Value Like 'Comment%'
                    ORDER BY Entry_ID
                    LIMIT 1;

                    If FOUND Then
                        _headersDefined := true;
                    End If;

                    If _headersDefined Then
                        If _channelColNum = 0 And _tagColNum = 0 Then
                            RAISE EXCEPTION 'Plex Members table must have column header Channel or Tag';
                        End If;

                        If _experimentIdColNum = 0 Then
                            RAISE EXCEPTION 'Plex Members table must have column header Exp_ID or Experiment';
                        End If;

                        DELETE FROM Tmp_ColData
                    Else
                        RAISE EXCEPTION 'Plex Members table must start with a row of header names, for example: Tag, Exp_ID, Channel Type, Comment';
                    End If;

                    _firstLineParsed := true;
                    _parseColData := false;
                End If;

                If _parseColData Then

                    _channelNum := 0;
                    _channelText := '';
                    _tagName := '';
                    _experimentId := 0;
                    _experimentIdOrName := '';
                    _channelTypeId := 0;
                    _channelTypeName := '';
                    _plexMemberComment := '';

                    If _channelColNum > 0 Then
                        SELECT Value
                        INTO _channelText
                        FROM Tmp_ColData
                        WHERE Entry_ID = _channelColNum
                    End If;

                    If _tagColNum > 0 Then
                        SELECT Value
                        INTO _tagName
                        FROM Tmp_ColData
                        WHERE Entry_ID = _tagColNum
                    End If;

                    SELECT Value
                    INTO _experimentIdOrName
                    FROM Tmp_ColData
                    WHERE Entry_ID = _experimentIdColNum

                    If _channelTypeColNum > 0 Then
                        SELECT Value
                        INTO _channelTypeName
                        FROM Tmp_ColData
                        WHERE Entry_ID = _channelTypeColNum
                    End If;

                    If _commentColNum > 0 Then
                        SELECT Value
                        INTO _plexMemberComment
                        FROM Tmp_ColData
                        WHERE Entry_ID = _commentColNum
                    End If;

                    If char_length(_channelText) > 0 Then
                        _channelNum := public.try_cast(_channelText, null::int);

                        If _channelNum Is Null Then
                            _message := format('Could not convert channel number %s to an integer in row %s of the Plex Members table',
                                                _channelText, _entryID);
                            RAISE EXCEPTION '%', _message;
                        End If;
                    Else
                        If char_length(_tagName) > 0 Then
                            If _experimentLabel = 'TMT10' And _tagName = '131' Then
                                _tagName := '131N';
                            End If;

                            _channelNum := Null;

                            SELECT channel
                            INTO _channelNum
                            FROM t_sample_labelling_reporter_ions
                            WHERE label = _experimentLabel And (tag_name = _tagName Or masic_name = _tagName)
                            LIMIT 1;

                            If Not FOUND Then
                                _message := format('Could not determine the channel number for tag %s and label %s; see https://dms2.pnl.gov/sample_label_reporter_ions/report/%s',
                                                   _tagName, _experimentLabel, _experimentLabel);

                                RAISE EXCEPTION '%', _message;
                            End If;
                        End If;
                    End If;

                    _experimentId := public.try_cast(_experimentIdOrName, null::int);

                    If _experimentId Is Null Then
                        -- Not an integer; is it a valid experiment name?
                        SELECT exp_id
                        INTO _experimentId
                        FROM t_experiments
                        WHERE experiment = _experimentIdOrName;

                        Not FOUND Then
                            If _tagName = '' Then
                                _message := format('Experiment not found for channel %s', _channelNum);
                            Else
                                _message := format('Experiment not found for tag %s', _tagName);
                            End If;

                            _message := format('%s (specify an experiment ID or name): %s (see row %s of the Plex Members table)',
                                               _experimentIdOrName, _entryID);

                            RAISE EXCEPTION '%', _message;
                        End If;
                    End If;

                    If char_length(_channelTypeName) > 0 Then
                        SELECT channel_type_id
                        INTO _channelTypeId
                        FROM t_experiment_plex_channel_type_name
                        WHERE channel_type_name = _channelTypeName;

                        If Not FOUND Then
                            _message := format('Invalid channel type %s in row %s of the Plex Members table; valid values: ', _channelTypeName, _entryID);

                            SELECT string_agg(channel_type_name, ', ' ORDER BY channel_type_name)
                            INTO _validValues
                            FROM t_experiment_plex_channel_type_name;

                            _message := format('%s%s', _message, _validValues);

                            RAISE EXCEPTION '%', _message;
                        End If;
                    Else
                        -- Default to type 'Normal'
                        _channelTypeId := 1;
                    End If;

                    If Coalesce(_channelNum, 0) > 0 And Coalesce(_experimentId, 0) > 0 Then
                        If Exists (SELECT Channel FROM Tmp_Experiment_Plex_Members WHERE Channel = _channelNum) Then
                            _message := format('Plex Members table has duplicate entries for channel %s', _channelNum);

                            If _tagName <> '' Then
                                _message := format('%s (tag %s)', _message, _tagName);
                            End If;

                            RAISE EXCEPTION '%', _message;
                        Else
                            INSERT INTO Tmp_Experiment_Plex_Members (Channel, Exp_ID, Channel_Type_ID, Comment, ValidExperiment)
                            VALUES (_channelNum, _experimentId, _channelTypeId, _plexMemberComment, 0);
                        End If;
                    End If;

                End If;

            END LOOP;
        End If;

        ---------------------------------------------------
        -- Check whether we even need to parse the individual parameters
        ---------------------------------------------------

        SELECT COUNT(Channel)
        INTO _actualChannelCount
        FROM Tmp_Experiment_Plex_Members;

        If Coalesce(_expectedChannelCount, 0) = 0 Or _actualChannelCount < _expectedChannelCount Then
            -- Step through the _expIdChannel and _channelType fields to define info for channels not defined in the Plex Members table

            CREATE TEMP TABLE Tmp_Experiment_Plex_Members_From_Params (
                Channel int NOT NULL,
                ExperimentInfo text NULL,
                ChannelType text NULL,
                Comment text NULL
            );

            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (1,  _expIdChannel1,  _channelType1,  _comment1);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (2,  _expIdChannel2,  _channelType2,  _comment2);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (3,  _expIdChannel3,  _channelType3,  _comment3);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (4,  _expIdChannel4,  _channelType4,  _comment4);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (5,  _expIdChannel5,  _channelType5,  _comment5);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (6,  _expIdChannel6,  _channelType6,  _comment6);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (7,  _expIdChannel7,  _channelType7,  _comment7);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (8,  _expIdChannel8,  _channelType8,  _comment8);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (9,  _expIdChannel9,  _channelType9,  _comment9);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (10, _expIdChannel10, _channelType10, _comment10);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (11, _expIdChannel11, _channelType11, _comment11);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (12, _expIdChannel12, _channelType12, _comment12);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (13, _expIdChannel13, _channelType13, _comment13);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (14, _expIdChannel14, _channelType14, _comment14);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (15, _expIdChannel15, _channelType15, _comment15);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (16, _expIdChannel16, _channelType16, _comment16);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (17, _expIdChannel17, _channelType17, _comment17);
            INSERT INTO Tmp_Experiment_Plex_Members_From_Params VALUES (18, _expIdChannel18, _channelType18, _comment18);

            _channelNum := 1;

            WHILE _channelNum <= 18
            LOOP
                If Not Exists (SELECT Channel FROM Tmp_Experiment_Plex_Members WHERE Channel = _channelNum) Then

                    SELECT Trim(Coalesce(ExperimentInfo, '')),
                           Trim(Coalesce(ChannelType, '')),
                           Trim(Coalesce(Comment, ''))
                    INTO _experimentIdOrName, _channelTypeName, _plexMemberComment
                    FROM Tmp_Experiment_Plex_Members_From_Params
                    WHERE Channel = _channelNum;

                    _experimentId := 0;

                    If char_length(_experimentIdOrName) > 0 Then

                        -- ExperimentIdText can have Experiment ID, or Experiment Name, or both, separated by a colon, comma, space, or tab
                        -- First assure that the delimiter (if present) is a colon
                        _experimentIdOrName := Replace(_experimentIdOrName, ',', ':');
                        _experimentIdOrName := Replace(_experimentIdOrName, chr(9), ':');
                        _experimentIdOrName := Replace(_experimentIdOrName, ' ', ':');

                        -- Look for a colon
                        _charIndex := Position(':' In _experimentIdOrName);
                        If _charIndex > 1 Then
                            _experimentId := public.try_cast(Substring(_experimentIdOrName, 1, _charIndex-1), null::int);

                            If _experimentId Is Null Then
                                _message := format('Could not parse out the experiment ID from %s for channel %s',
                                                    Substring(_experimentIdOrName, 1, _charIndex-1), _channelNum);
                                RAISE EXCEPTION '%', _message;
                            End If;

                        Else
                            -- No colon (or the first character is a colon)
                            -- First try to match experiment ID
                            _experimentId := public.try_cast(_experimentIdOrName, null::int);

                            If _experimentId Is Null Then
                                -- No match; try to match experiment name
                                SELECT exp_id
                                INTO _experimentId
                                FROM t_experiments
                                WHERE experiment = _experimentIdOrName
                                --
                                GET DIAGNOSTICS _matchCount = ROW_COUNT;

                                If _matchCount = 0 Then
                                    _message := format('Experiment not found for channel %s: %s', _channelNum, _experimentIdOrName);
                                    RAISE EXCEPTION '%', _message;
                                End If;
                            End If;
                        End If;

                        If char_length(_channelTypeName) = 0 Then
                            _channelTypeId := 1;
                        Else
                            SELECT channel_type_id
                            INTO _channelTypeId
                            FROM t_experiment_plex_channel_type_name
                            WHERE channel_type_name = _channelTypeName;

                            If Not FOUND Then
                                _message := format('Invalid channel type %s for channel %s; valid values: ',
                                                   _channelTypeName, _channelNum);

                                SELECT string_agg(channel_type_name, ', ' ORDER BY channel_type_name)
                                INTO _validValues
                                FROM t_experiment_plex_channel_type_name;

                                _message := format('%s%s', _message, _validValues);

                                RAISE EXCEPTION '%', _message;
                            End If;
                        End If;

                        If Coalesce(_experimentId, 0) > 0 Then
                            INSERT INTO Tmp_Experiment_Plex_Members (Channel, Exp_ID, Channel_Type_ID, Comment, ValidExperiment)
                            VALUES (_channelNum, _experimentId, _channelTypeId, _plexMemberComment, 0)
                        End If;

                    End If;

                End If;

                _channelNum := _channelNum + 1;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Update the cached actual chanel count
        ---------------------------------------------------

        SELECT COUNT(Channel)
        INTO _actualChannelCount
        FROM Tmp_Experiment_Plex_Members;

        ---------------------------------------------------
        -- Validate experiment IDs in Tmp_Experiment_Plex_Members
        ---------------------------------------------------

        UPDATE Tmp_Experiment_Plex_Members PlexMembers
        SET ValidExperiment = 1
        FROM t_experiments E
        WHERE PlexMembers.exp_id = E.exp_id;

        SELECT COUNT(ValidExperiment)
        INTO _invalidExperimentCount
        FROM Tmp_Experiment_Plex_Members
        WHERE ValidExperiment = 0;

        If Coalesce(_invalidExperimentCount, 0) > 0 Then
            If _invalidExperimentCount = 1 Then
                SELECT format('Invalid Experiment ID: %s', Exp_ID)
                INTO _message
                FROM Tmp_Experiment_Plex_Members
                WHERE ValidExperiment = 0;
            Else
                _message := 'Invalid Experiment IDs: ';

                SELECT string_agg(Exp_ID::text, ',' ORDER BY Exp_ID)
                INTO _message
                FROM Tmp_Experiment_Plex_Members
                WHERE ValidExperiment = 0;

                _message := format('Invalid Experiment IDs: %s', _message);
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add, update, or preview mode
        ---------------------------------------------------

        If _mode In ('add', 'update', 'preview') Then

            ---------------------------------------------------
            -- Create a temporary table to hold the experiment IDs that will be updated with the plex info in Tmp_Experiment_Plex_Members
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_ExperimentsToUpdate (plexExperimentId int Not Null);

            CREATE INDEX IX_Tmp_ExperimentsToUpdate On Tmp_ExperimentsToUpdate (plexExperimentId);

            INSERT INTO Tmp_ExperimentsToUpdate (plexExperimentId )
            VALUES (_plexExperimentId);

            ---------------------------------------------------
            -- Check whether this experiment is the parent experiment of any experiment groups
            -- An experiment can be the parent experiment for more than one group, for example
            -- StudyName4_TB_Plex11 could be the parent experiment for group ID 6846, with members:
            --   StudyName4_TB_Plex11_G_f01
            --   StudyName4_TB_Plex11_G_f02
            --   StudyName4_TB_Plex11_G_f03
            --   StudyName4_TB_Plex11_G_f04
            -- and also the parent experiment for group ID 6847 with members:
            --   StudyName4_TB_Plex11_P_f01
            --   StudyName4_TB_Plex11_P_f02
            --   StudyName4_TB_Plex11_P_f03
            --   StudyName4_TB_Plex11_P_f04
            ---------------------------------------------------

            If Exists (SELECT group_id FROM t_experiment_groups WHERE parent_exp_id = _plexExperimentId) Then
                ---------------------------------------------------
                -- Add experiments that are associated with parent experiment _plexExperimentId
                -- Assure that the parent experiment is not the 'Placeholder' experiment
                ---------------------------------------------------

                INSERT INTO Tmp_ExperimentsToUpdate ( plexExperimentId )
                SELECT DISTINCT EGM.exp_id
                FROM t_experiment_groups EG
                     INNER JOIN t_experiment_group_members EGM
                       ON EGM.group_id = EG.group_id
                     INNER JOIN t_experiments E
                       ON EG.parent_exp_id = E.exp_id
                WHERE EG.parent_exp_id = _plexExperimentId AND
                      E.experiment <> 'Placeholder';
            End If;

            ---------------------------------------------------
            -- Process each experiment in Tmp_ExperimentsToUpdate
            --
            -- We're processing the experiments one at a time so that we can
            -- delete rows in the target table that aren't in the source table
            ---------------------------------------------------

            _currentPlexExperimentId := 0;

            FOR _currentPlexExperimentId IN
                SELECT plexExperimentId
                FROM Tmp_ExperimentsToUpdate
                WHERE plexExperimentId > _currentPlexExperimentId
                ORDER BY plexExperimentId
            LOOP
                If _expIdList = '' Then
                    _expIdList := _currentPlexExperimentId;
                Else
                    _expIdList := format('%s, %s', _expIdList, _currentPlexExperimentId);
                End If;

                If _mode = 'preview' Then
                    _updatedRows := 0;

                    SELECT COUNT(t.plex_exp_id)
                    INTO _updatedRows
                    FROM t_experiment_plex_members t
                         INNER JOIN Tmp_Experiment_Plex_Members s
                           ON t.channel = s.channel
                    WHERE t.plex_exp_id = _currentPlexExperimentId

                    If _updatedRows = _actualChannelCount Then
                        _actionMessage := format('Would update %s channels for Exp_ID %s', _updatedRows, _currentPlexExperimentId);
                    ElsIf _updatedRows = 0
                        _actionMessage := format('Would add %s channels for Exp_ID %s', _actualChannelCount, _currentPlexExperimentId);
                    Else
                        _actionMessage := format('Would add/update %s channels for Exp_ID %s', _actualChannelCount, _currentPlexExperimentId);
                    End If;

                    INSERT INTO Tmp_DatabaseUpdates (Message)
                    VALUES (_actionMessage);

                Else

                    MERGE INTO t_experiment_plex_members AS t
                    USING ( SELECT channel, exp_id, channel_type_id, Comment
                            FROM Tmp_Experiment_Plex_Members
                          ) AS s
                    ON (t.channel = s.channel AND t.plex_exp_id = _currentPlexExperimentId)
                    WHEN MATCHED AND
                         (t.exp_id <> s.exp_id OR
                          t.channel_type_id <> s.channel_type_id OR
                          t.comment IS DISTINCT FROM s.comment) THEN
                        UPDATE SET
                            exp_id = s.exp_id,
                            channel_type_id = s.channel_type_id,
                            comment = s.comment
                    WHEN NOT MATCHED THEN
                        INSERT (plex_exp_id,
                                channel,
                                exp_id,
                                Channel_Type_ID,
                                Comment)
                        VALUES (_currentPlexExperimentId,
                                s.channel,
                                s.exp_id,
                                s.channel_type_id,
                                s.Comment);

                    -- Delete rows in the target table that aren't in the source table
                    DELETE FROM t_experiment_plex_members
                    WHERE t.plex_exp_id = _currentPlexExperimentId AND
                          NOT t.channel IN (SELECT channel FROM Tmp_Experiment_Plex_Members);

                    If char_length(_callingUser) > 0 Then
                        -- Call public.alter_entered_by_user to alter the entered_by field in t_experiment_plex_members_history
                        --
                        CALL public.alter_entered_by_user ('public', 't_experiment_plex_members_history', 'plex_exp_id', _currentPlexExperimentId, _callingUser, _message => _alterEnteredByMessage);
                    End If;
                End If;

            END LOOP;

            If _mode = 'add' Then
                If _expIdList Like '%,%' Then
                    _message := format('Defined experiment plex members for Exp_IDs: %s', _expIdList);
                Else
                    _message := format('Defined experiment plex members for Plex Exp ID %s', _plexExperimentIdOrName);
                End If;
            ElsIf _mode = 'preview'
                SELECT COUNT(*)
                INTO _targetPlexExperimentCount
                FROM Tmp_DatabaseUpdates;

                SELECT COUNT(*)
                INTO _targetAddCount
                FROM Tmp_DatabaseUpdates
                WHERE Message Like 'Would add %';

                SELECT COUNT(*)
                INTO _targetUpdateCount
                FROM Tmp_DatabaseUpdates
                WHERE Message like 'Would update %';

                SELECT Message
                INTO _message
                FROM Tmp_DatabaseUpdates
                ORDER BY ID
                LIMIT 1;

                If _targetPlexExperimentCount > 1 Then

                    If _targetAddCount = _targetPlexExperimentCount Then
                        -- Adding plex members for all of the target experiments
                        _message := format('Would add %s channels for Exp_IDs %s', _actualChannelCount, _expIdList);
                    ElsIf _targetUpdateCount = _targetPlexExperimentCount
                        -- Updating plex members for all of the target experiments
                        _message := format('Would update %s channels for Exp_IDs %s', _updatedRows, _expIdList);
                    Else
                        -- Mix of adding and updating plex members

                        -- Append the message for the next 6 experiments

                        _entryId := 2;
                        While _entryID <= _targetPlexExperimentCount And _entryID <= 7
                        LOOP
                            SELECT Message
                            INTO _msg
                            FROM Tmp_DatabaseUpdates
                            WHERE ID = _entryID

                            _message := format('%s, %s', _message, Replace(_msg, 'Would', 'would'));

                            _entryID := _entryID + 1;
                        END LOOP;

                        If _targetPlexExperimentCount > 7 Then
                            SELECT Message
                            INTO _msg
                            FROM Tmp_DatabaseUpdates
                            ORDER BY ID DESC
                            LIMIT 1;

                            _message := format('%s ... %s', _message, Replace(_msg, 'Would', 'would'));
                        End If;
                    End If;
                End If;
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Plex Exp ID %s', _exceptionMessage, _plexExperimentIdOrName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_Experiment_Plex_Members;
    DROP TABLE IF EXISTS Tmp_DatabaseUpdates;
    DROP TABLE IF EXISTS Tmp_RowData;
    DROP TABLE IF EXISTS Tmp_ColData;
    DROP TABLE IF EXISTS Tmp_Experiment_Plex_Members_From_Params;
    DROP TABLE IF EXISTS Tmp_ExperimentsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.add_update_experiment_plex_members IS 'AddUpdateExperimentPlexMembers';

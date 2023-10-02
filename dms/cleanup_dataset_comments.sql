--
-- Name: cleanup_dataset_comments(text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.cleanup_dataset_comments(IN _datasetids text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove error messages from dataset comments, provided the dataset state is Complete or Inactive
**
**  Auth:   mem
**  Date:   12/16/2017 mem - Initial version
**          01/02/2018 mem - Check for 'Authentication failure' and "Error: NeedToAbortProcessing"
**          06/16/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _unknownIDs text;
    _matchCount int;
    _idsWrongState text := null;
    _datasetID int;
    _comment text;
    _matchIndex int;
    _messageText text;
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------

    _datasetIDs := Trim(Coalesce(_datasetIDs, ''));

    If _datasetIDs = '' Then
        _message := 'One or more dataset IDs is required';
        RAISE WARNING '%', _message;

         _returnCode := 'U5201';
        RETURN;
    End If;

    _infoOnly := Coalesce(_infoOnly, true);

    ----------------------------------------------------
    -- Create some Temporary Tables
    ----------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToUpdate (
        DatasetID int,
        InvalidID boolean,
        StateID int,
        ExistingComment text null,
        NewComment text null,
        UpdateRequired boolean null
    );

    CREATE INDEX IX_Tmp_DatasetsToUpdate_DatasetID ON Tmp_DatasetsToUpdate (DatasetID);

    CREATE TEMP TABLE Tmp_MessagesToRemove (
        MessageID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        MessageText text
    );

    -- Example errors to remove:
    --   Error while copying \\15TFTICR64\data\
    --   Error running OpenChrom
    --   Authentication failure: The user name or password is incorrect.
    --   Error: NeedToAbortProcessing

    INSERT INTO Tmp_MessagesToRemove (MessageText)
    VALUES ('Error while copying \\'),
           ('Error running OpenChrom'),
           ('Authentication failure'),
           ('Error: NeedToAbortProcessing');

    ----------------------------------------------------
    -- Find datasets to process
    ----------------------------------------------------

    INSERT INTO Tmp_DatasetsToUpdate (DatasetID, InvalidID, StateID, ExistingComment, NewComment)
    SELECT Src.Value,
           CASE WHEN DS.dataset_id IS NULL THEN true ELSE false END AS InvalidID,
           dataset_state_id,
           DS.comment,
           DS.comment
    FROM public.parse_delimited_integer_list(_datasetIDs) Src
         LEFT OUTER JOIN t_dataset DS
           ON Src.Value = DS.dataset_id;

    If Not FOUND Then
        _message := format('No valid integers were found: %s', _datasetIDs);

        RAISE INFO '';
        RAISE WARNING '%', _message;

        DROP TABLE Tmp_DatasetsToUpdate;
        DROP TABLE Tmp_MessagesToRemove;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Exists (Select * From Tmp_DatasetsToUpdate WHERE InvalidID) Then
        SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID)
        INTO _unknownIDs
        FROM Tmp_DatasetsToUpdate
        WHERE InvalidID;

        _matchCount := array_length(string_to_array(_unknownIDs, ','), 1);
        _message := format('Ignoring unknown Dataset %s: %s', public.check_plural(_matchCount, 'ID', 'IDs'), _unknownIDs);

        RAISE INFO '';
        RAISE INFO '%', _message;

        _message := '';
    End If;

    If Exists (SELECT * FROM Tmp_DatasetsToUpdate WHERE NOT InvalidID AND NOT StateID IN (3, 4)) Then
        SELECT string_agg(DatasetID::text, ', ' ORDER BY DatasetID)
        INTO _idsWrongState
        FROM Tmp_DatasetsToUpdate
        WHERE Not InvalidID AND NOT StateID IN (3, 4);

        _matchCount := array_length(string_to_array(_unknownIDs, ','), 1);
        _message := format('Ignoring Dataset %s not in state 3 or 4 (complete or inactive): %s', public.check_plural(_matchCount, 'ID', 'IDs'), _idsWrongState);
        RAISE INFO '%', _message;

        _message := '';
    End If;

    FOR _datasetID, _comment IN
        SELECT DatasetID, NewComment
        FROM Tmp_DatasetsToUpdate
        WHERE Not InvalidID AND
              StateID IN (3, 4)
        ORDER BY DatasetID
    LOOP

        FOR _messageText IN
            SELECT MessageText
            FROM Tmp_MessagesToRemove
            ORDER BY MessageID
        LOOP
            _matchIndex := Position(Lower(format('; %s', _messageText)) In Lower(_comment));

            If _matchIndex = 0 Then
                _matchIndex := Position(Lower(_messageText) In Lower(_comment));
            End If;

            If _matchIndex = 1 Then
                _comment := '';
            End If;

            If _matchIndex > 1 Then
                -- Match found at the end; remove the error message but keep the initial part of the comment
                _comment := Trim(Substring(_comment, 1, _matchIndex - 1));
            End If;

            UPDATE Tmp_DatasetsToUpdate
            SET NewComment = _comment
            WHERE DatasetID = _datasetID;

        END LOOP;
    END LOOP;

    UPDATE Tmp_DatasetsToUpdate
    SET UpdateRequired = CASE
                             WHEN ExistingComment IS DISTINCT FROM NewComment THEN true
                             ELSE false
                         END;

    If _infoOnly Then
        RAISE INFO '';

        _formatSpecifier := '%-12s %-5s %-80s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'State',
                            'New Comment',
                            'Old Comment'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '-----',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT DatasetID,
                   InvalidID,
                   StateID,
                   ExistingComment,
                   NewComment,
                   UpdateRequired
            FROM Tmp_DatasetsToUpdate
            ORDER BY DatasetID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.DatasetID,
                                _previewData.StateID,
                                CASE WHEN _previewData.InvalidID
                                     THEN 'Invalid dataset ID'
                                     ELSE  _previewData.NewComment
                                END,
                                CASE WHEN _previewData.UpdateRequired
                                     THEN _previewData.ExistingComment
                                     ELSE 'comment not changed'
                                END
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        UPDATE t_dataset Target
        SET comment = NewComment
        FROM Tmp_DatasetsToUpdate Src
        WHERE Src.UpdateRequired AND
              Target.Dataset_ID = Src.DatasetID AND
              Not Src.InvalidID AND
              Target.dataset_state_id IN (3, 4);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Removed error messages from the comment field of %s %s', _updateCount, public.check_plural(_updateCount, 'dataset', 'datasets'));
            RAISE INFO '%', _message;
        End If;
    End If;

    DROP TABLE Tmp_DatasetsToUpdate;
    DROP TABLE Tmp_MessagesToRemove;
END
$$;


ALTER PROCEDURE public.cleanup_dataset_comments(IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE cleanup_dataset_comments(IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.cleanup_dataset_comments(IN _datasetids text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'CleanupDatasetComments';


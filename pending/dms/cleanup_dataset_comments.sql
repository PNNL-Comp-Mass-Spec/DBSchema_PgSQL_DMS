--
CREATE OR REPLACE PROCEDURE public.cleanup_dataset_comments
(
    _datasetIDs text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = true
)
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _unknownIDs text := null;
    _idsWrongState text := null;
    _datasetID int;
    _comment text;
    _matchIndex int;
    _messageID int;
    _messageText text;
    _updateCount int;
BEGIN
    _message := '';
    _returnCode:= '';

    ----------------------------------------------------
    -- Validate the inputs
    ----------------------------------------------------

    _datasetIDs := Coalesce(_datasetIDs, '');

    If _datasetIDs = '' Then
        _message := 'One or more dataset IDs is required';
        RAISE INFO '%', _message;

         _returnCode := 'U5201';
        RETURN;
    End If;

    _infoOnly := Coalesce(_infoOnly, true);

    ----------------------------------------------------
    -- Create some Temporary Tables
    ----------------------------------------------------

    CREATE TEMP TABLE Tmp_DatasetsToUpdate (
        DatasetID int,
        InvalidID int,
        StateID int,
        ExistingComment text null,
        NewComment text null,
        UpdateRequired boolean null
    );

    CREATE INDEX IX_Tmp_DatasetsToUpdate_DatasetID ON Tmp_DatasetsToUpdate (DatasetID)

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
           ('Error: NeedToAbortProcessing')

    ----------------------------------------------------
    -- Find datasets to process
    ----------------------------------------------------
    --

    INSERT Tmp_DatasetsToUpdate (DatasetID, InvalidID, StateID, ExistingComment, NewComment)
    SELECT Src.Value,
           CASE WHEN DS.dataset_id IS NULL THEN 1 ELSE 0 END AS InvalidID,
           dataset_state_id,
           ExistingComment = DS.comment,
           NewComment = DS.comment
    FROM public.parse_delimited_integer_list ( _datasetIDs, ',' ) Src
         LEFT OUTER JOIN t_dataset DS
           ON Src.Value = DS.dataset_id;

    If Not FOUND Then
        _message := 'No valid integers were found: ' || _datasetIDs;
        RAISE WARNING '%', _message;
        _returnCode := 'U5201';

        DROP TABLE Tmp_DatasetsToUpdate;
        DROP TABLE Tmp_MessagesToRemove;
        RETURN;
    End If;

    If Exists (Select * From Tmp_DatasetsToUpdate WHERE InvalidID > 0) Then
        SELECT string_agg(DatasetID::text, ', ')
        INTO _unknownIDs
        FROM Tmp_DatasetsToUpdate
        WHERE InvalidID > 0;

        _message := 'Ignoring unknown DatasetIDs: ' || _unknownIDs;
        RAISE INFO '%', _message;

        _message := '';
    End If;

    If Exists (Select * From Tmp_DatasetsToUpdate WHERE InvalidID = 0 AND NOT StateID IN (3,4) ) Then
        SELECT string_agg(DatasetID::text, ', ')
        INTO _idsWrongState
        FROM Tmp_DatasetsToUpdate
        WHERE InvalidID = 0 AND NOT StateID IN (3,4);

        _message := 'Ignoring Datasets not in state 3 or 4 (complete or inactive): ' || _idsWrongState;
        RAISE INFO '%', _message;

        _message := '';
    End If;

    FOR _datasetID, _comment IN
        SELECT DatasetID, NewComment
        FROM Tmp_DatasetsToUpdate
        WHERE InvalidID = 0 AND
              StateID IN (3, 4)
        ORDER BY DatasetID
    LOOP

        FOR _messageText IN
            SELECT MessageText
            FROM Tmp_MessagesToRemove
            WHERE MessageID > _messageID
            ORDER BY MessageID
        LOOP
            _matchIndex := Position('; ' || _messageText In _comment);

            If _matchIndex = 0 Then
                _matchIndex := Position(_messageText In _comment);
            End If;

            If _matchIndex = 1 Then
                _comment := '';
            End If;

            If _matchIndex > 1 Then
                -- Match found at the end; remove the error message but keep the initial part of the comment
                _comment := RTrim(Substring(_comment, 1, _matchIndex - 1));
            End If;

            UPDATE Tmp_DatasetsToUpdate
            SET NewComment = _comment
            WHERE DatasetID = _datasetID;

        END LOOP;
    END LOOP;

    UPDATE Tmp_DatasetsToUpdate
    SET UpdateRequired = CASE
                             WHEN Coalesce(ExistingComment, '') <> Coalesce(NewComment, '') THEN true
                             ELSE false
                         END;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT *
        FROM Tmp_DatasetsToUpdate
        ORDER BY DatasetID;

    Else
        UPDATE t_dataset
        SET comment = NewComment
        FROM Tmp_DatasetsToUpdate
        WHERE Src.UpdateRequired AND
              Target.Dataset_ID = Src.DatasetID
              InvalidID = 0 AND
              StateID IN (3, 4);
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

COMMENT ON PROCEDURE public.cleanup_dataset_comments IS 'CleanupDatasetComments';

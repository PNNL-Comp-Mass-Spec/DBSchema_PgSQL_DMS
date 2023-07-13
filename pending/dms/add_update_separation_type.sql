--
CREATE OR REPLACE PROCEDURE public.add_update_separation_type
(
    _id int,
    _sepTypeName text,
    _sepGroupName text,
    _comment text,
    _sampleType text,
    _state text = 'Active',
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
**      Adds new or edits existing T_Secondary_Sep entry
**
**  Arguments:
**    _state   Active or Inactive
**    _mode    or 'update'
**
**  Auth:   bcg
**  Date:   12/19/2019 bcg - Initial release
**          08/11/2021 mem - Determine the next ID to use when adding a new separation type
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _debugMsg text := '';
    _nextID Int;
    _stateInt integer := 0;
    _badCh text;
    _sampleTypeID integer := 0;
    _existingName text := '';
    _oldState integer := 0;
    _ignoreDatasetChecks int := 0;
    _conflictID int := 0;
    _datasetCount int;
    _maxDatasetID int;
    _datasetDescription text;
    _datasetName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _id := Coalesce(_id, 0);
    _sepTypeName := Coalesce(_sepTypeName, '');
    _state := Coalesce(_state, 'Active');
    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _state = '' Then
        _state := 'Active';
    End If;

    ---------------------------------------------------
    -- Validate _state
    ---------------------------------------------------

    If Not _state::citext IN ('Active', 'Inactive') Then
        _message := format('Separation type state must be Active or Inactive; %s is not allowed', _state);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Convert text state to integer
    ---------------------------------------------------

    If _state = 'Active' Then
        _stateint := 1;
    Else
        _stateint := 0;
    End If;

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    _badCh := public.validate_chars(_sepTypeName, '');

    If _badCh <> '' Then
        If _badCh = 'space' Then
            _message := 'Separation Type name may not contain spaces';
        Else
            _message := format('Separation Type name may not contain the character(s) "%s"', _badCh);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If char_length(_sepTypeName) < 6 Then
        _message := format('Separation Type name must be at least 6 characters in length; currently %s characters', char_length(_sepTypeName));
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate the sample type and get the ID
    ---------------------------------------------------

    SELECT sample_type_id
    INTO _sampleTypeID
    FROM t_secondary_sep_sample_type
    WHERE name = _sampleType;

    If Not FOUND Then
        _message := 'No matching sample type could be found in the database';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Lookup the current name and state

        SELECT separation_type,
                active
        INTO _existingName, _oldState
        FROM t_secondary_sep
        WHERE separation_type_id = _id;

        If Not FOUND Then
            _message := 'No entry could be found in database for update';
            RAISE WARNING '%', _message;

            _returnCode := 'U5205';
            RETURN;
        End If;

        If _sepTypeName <> _existingName Then

            SELECT separation_type_id
            INTO _conflictID
            FROM t_secondary_sep
            WHERE separation_type = _sepTypeName;

            If FOUND Then
                _message := format('Cannot rename separation type from %s to %s because the new name is already in use by ID %s',
                                    _existingName, _sepTypeName, _conflictID);
                RAISE WARNING '%', _message;

                _returnCode := 'U5206';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Only allow updating the state of Separation Type items that are associated with a dataset
        ---------------------------------------------------

        If _ignoreDatasetChecks = 0 And Exists (Select * FROM t_dataset Where separation_type = _sepTypeName) Then

            SELECT COUNT(dataset_id),
                   MAX(dataset_id)
            INTO _datasetCount, _maxDatasetID
            FROM t_dataset
            WHERE separation_type = _id;

            SELECT dataset
            INTO _datasetName
            FROM t_dataset
            WHERE dataset_id = _maxDatasetID;

            If _datasetCount = 1 Then
                _datasetDescription := format('dataset %s', _datasetName);
            Else
                _datasetDescription := format('%s datasets', _datasetCount);
            End If;

            If _stateInt <> _oldState Then
                UPDATE t_secondary_sep
                SET active = _stateInt
                WHERE separation_type_id = _id;

                _message := format('Updated state to %s; any other changes were ignored because this separation type is associated with %s', _state, _datasetDescription);

                RETURN;
            End If;

            _message := format('Separation Type ID %s is associated with %s, most recently %s; contact a DMS admin to update the configuration',
                                _id, _datasetDescription, _datasetName);

            RAISE WARNING '%', _message;

            _returnCode := 'U5207';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Validate that the LC Cart Config name is unique when creating a new entry
    ---------------------------------------------------

    If _mode = 'add' Then
        If Exists (Select * FROM t_secondary_sep Where separation_type = _sepTypeName) Then
            _message := format('Separation Type already exists; cannot add a new separation type named %s', _sepTypeName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5208';
            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        SELECT MAX(separation_type_id) + 1
        INTO _nextID
        FROM t_secondary_sep;

        INSERT INTO t_secondary_sep( separation_type,
                                     separation_type_id,
                                     separation_group,
                                     comment,
                                     sample_type_id,
                                     active,
                                     created )
        VALUES (
            _sepTypeName,
            _nextID,
            _sepGroupName,
            _comment,
            _sampleTypeID,
            _stateInt,
            CURRENT_TIMESTAMP
        )

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_secondary_sep
        SET separation_type = _sepTypeName,
            separation_group = _sepGroupName,
            comment = _comment,
            sample_type_id = _sampleTypeID,
            active = _stateInt
        WHERE separation_type_id = _id

    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_separation_type IS 'AddUpdateSeparationType';

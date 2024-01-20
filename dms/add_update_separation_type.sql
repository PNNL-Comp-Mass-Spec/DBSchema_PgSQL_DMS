--
-- Name: add_update_separation_type(integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_separation_type(IN _id integer, IN _septypename text, IN _sepgroupname text, IN _comment text, IN _sampletype text, IN _state text DEFAULT 'Active'::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing separation type
**
**  Arguments:
**    _id               Separation type ID in t_secondary_sep
**    _sepTypeName      Separation type name
**    _sepGroupName     Parent separation group name
**    _comment          Separation type comment
**    _sampleType       Sample type name: 'Peptides', 'Proteins', 'Metabolites', 'Lipids', 'Glycans', or 'Unknown'
**    _state            State: 'Active' or 'Inactive'
**    _mode             Mode: 'add' or 'update'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user (unused by this procedure)
**
**  Auth:   bcg
**  Date:   12/19/2019 bcg - Initial version
**          08/11/2021 mem - Determine the next ID to use when adding a new separation type
**          01/18/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _debugMsg text := '';
    _nextID Int;
    _activeValue integer := 0;
    _badCh text;
    _matchedValue text;
    _sampleTypeID integer := 0;
    _existingName citext := '';
    _currentActiveValue integer := 0;
    _ignoreDatasetChecks boolean := false;
    _conflictID int := 0;
    _datasetCount int;
    _maxDatasetID int;
    _datasetDescription text;
    _datasetName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _id           := Coalesce(_id, 0);
    _sepTypeName  := Trim(Coalesce(_sepTypeName, ''));
    _sepGroupName := Trim(Coalesce(_sepGroupName, ''));
    _comment      := Trim(Coalesce(_comment, ''));
    _sampleType   := Trim(Coalesce(_sampleType, ''));
    _state        := Trim(Coalesce(_state, 'Active'));
    _mode         := Trim(Lower(Coalesce(_mode, '')));

    If _sepTypeName = '' Then
        _message := 'Separation type name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    If _sepGroupName = '' Then
        _message := 'Separation group name must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    SELECT separation_group
    INTO _matchedValue
    FROM t_separation_group
    WHERE separation_group = _sepGroupName::citext;

    If FOUND Then
        _sepGroupName := _matchedValue;
    Else
        _message := format('Invalid separation group: %s', _sepGroupName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _sampleType = '' Then
        _message := 'Sample type must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    If _state = '' Then
        _state := 'Active';
    End If;

    If Not _mode::citext In ('Add', 'Update') Then
        RAISE WARNING 'Mode is not "add" or "update"; no changes will be saved';
    End If;

    ---------------------------------------------------
    -- Validate _state
    ---------------------------------------------------

    If Not _state::citext In ('Active', 'Inactive') Then
        _message := format('Separation type state must be Active or Inactive; %s is not allowed', _state);
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Convert text state to integer
    ---------------------------------------------------

    If _state::citext = 'Active' Then
        _activeValue := 1;
    Else
        _activeValue := 0;
    End If;

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    _badCh := public.validate_chars(_sepTypeName, '');

    If _badCh <> '' Then
        If _badCh = '[space]' Then
            _message := 'Separation type name may not contain spaces';
        Else
            _message := format('Separation type name may not contain the character(s) "%s"', _badCh);
        End If;

        RAISE WARNING '%', _message;

        _returnCode := 'U5206';
        RETURN;
    End If;

    If char_length(_sepTypeName) < 6 Then
        _message := format('Separation type name must be at least 6 characters in length; currently %s characters', char_length(_sepTypeName));
        RAISE WARNING '%', _message;

        _returnCode := 'U5207';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate the sample type and get the ID
    ---------------------------------------------------

    SELECT sample_type_id
    INTO _sampleTypeID
    FROM t_secondary_sep_sample_type
    WHERE name = _sampleType::citext;

    If Not FOUND Then
        _message := format('Invalid sample type: "%s"', _sampleType);
        RAISE WARNING '%', _message;

        _returnCode := 'U5208';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If _mode = 'update' Then
        -- Lookup the current name and state

        SELECT separation_type, active
        INTO _existingName, _currentActiveValue
        FROM t_secondary_sep
        WHERE separation_type_id = _id;

        If Not FOUND Then
            _message := format('Cannot update: separation type ID %s does not exist', _id);
            RAISE WARNING '%', _message;

            _returnCode := 'U5209';
            RETURN;
        End If;

        If _existingName <> _sepTypeName::citext Then

            SELECT separation_type_id
            INTO _conflictID
            FROM t_secondary_sep
            WHERE separation_type = _sepTypeName::citext;

            If FOUND Then
                _message := format('Cannot rename separation type from %s to %s because the new name is already in use by ID %s',
                                    _existingName, _sepTypeName, _conflictID);
                RAISE WARNING '%', _message;

                _returnCode := 'U5210';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- If a separation type is associated with one or more datasets, only allow updating the state
        ---------------------------------------------------

        If Not _ignoreDatasetChecks And Exists (SELECT dataset_id FROM t_dataset WHERE separation_type = _existingName) Then

            SELECT COUNT(dataset_id),
                   MAX(dataset_id)
            INTO _datasetCount, _maxDatasetID
            FROM t_dataset
            WHERE separation_type = _existingName::citext;

            SELECT dataset
            INTO _datasetName
            FROM t_dataset
            WHERE dataset_id = _maxDatasetID;

            If _datasetCount = 1 Then
                _datasetDescription := format('dataset %s', _datasetName);
            Else
                _datasetDescription := format('%s datasets', _datasetCount);
            End If;

            If _activeValue <> _currentActiveValue Then
                UPDATE t_secondary_sep
                SET active = _activeValue
                WHERE separation_type_id = _id;

                _message := format('Updated state to %s; any other changes were ignored because this separation type is associated with %s', _state, _datasetDescription);

                RETURN;
            End If;

            If _datasetCount = 1 Then
                _message := format('Separation Type ID %s is associated with %s; only the state can be updated using the website. Contact a DMS admin to update other metadata',
                                   _id, _datasetDescription, _datasetName);
            Else
                _message := format('Separation Type ID %s is associated with %s; only the state can be updated using the website. Contact a DMS admin to update other metadata',
                                   _id, _datasetDescription, _datasetName);
            End If;

            RAISE WARNING '%', _message;

            _returnCode := 'U5211';
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Validate that the separation type name is unique when creating a new entry
    ---------------------------------------------------

    If _mode = 'add' Then
        If Exists (SELECT separation_type FROM t_secondary_sep WHERE separation_type = _sepTypeName::citext) Then
            _message := format('Separation type already exists; cannot add a new separation type named %s', _sepTypeName);
            RAISE WARNING '%', _message;

            _returnCode := 'U5212';
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

        INSERT INTO t_secondary_sep (
            separation_type,
            separation_type_id,
            separation_group,
            comment,
            sample_type_id,
            active,
            created
        ) VALUES (
            _sepTypeName,
            _nextID,
            _sepGroupName,
            _comment,
            _sampleTypeID,
            _activeValue,
            CURRENT_TIMESTAMP
        );

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE t_secondary_sep
        SET separation_type  = _sepTypeName,
            separation_group = _sepGroupName,
            comment          = _comment,
            sample_type_id   = _sampleTypeID,
            active           = _activeValue
        WHERE separation_type_id = _id;

        If _existingName <> _sepTypeName::citext Then
            _message := format('Renamed separation type to %s', _sepTypeName);
        End If;
    End If;

END
$$;


ALTER PROCEDURE public.add_update_separation_type(IN _id integer, IN _septypename text, IN _sepgroupname text, IN _comment text, IN _sampletype text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_separation_type(IN _id integer, IN _septypename text, IN _sepgroupname text, IN _comment text, IN _sampletype text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_separation_type(IN _id integer, IN _septypename text, IN _sepgroupname text, IN _comment text, IN _sampletype text, IN _state text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateSeparationType';


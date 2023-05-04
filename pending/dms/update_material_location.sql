--
CREATE OR REPLACE PROCEDURE public.update_material_location
(
    _locationTag text,
    _comment text,
    _status text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Change properties of a single material location item
**      Only allows updating the comment or the active/inactive state
**
**      Additionally, prevents updating entries where the container limit is 100 or more
**      since those are special locations (typically for staging samples)
**
**  Auth:   mem
**  Date:   08/27/2018 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _errorMessage text;
    _logErrors boolean := false;
    _logMessage text;
    _locationId int;
    _containerLimit int;
    _oldStatus text;
    _oldComment text;
    _activeContainers int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _locationTag := Trim(Coalesce(_locationTag, ''));
        _comment := Trim(Coalesce(_comment, ''));
        _status := Trim(Coalesce(_status, ''));

        If Coalesce(_callingUser, '') = '' Then
            _callingUser := get_user_login_without_domain('');
        End If;

        If char_length(_locationTag) < 1 Then
            RAISE EXCEPTION 'Location tag must be defined';
        End If;

        If Not _status::citext In ('Active', 'Inactive') Then
            RAISE EXCEPTION 'Status must be Active or Inactive';
        End If;

        -- Make sure _status is properly capitalized
        If _status = 'Active' Then
            _status := 'Active';
        End If;

        If _status = 'Inactive' Then
            _status := 'Inactive';
        End If;

        -----------------------------------------------------------
        -- Validate _locationTag and retrieve the current status
        -----------------------------------------------------------

        SELECT location_id,
               Coalesce(comment, ''),
               container_limit,
               status
        INTO _locationId, _oldComment, _containerLimit, _oldStatus
        FROM  t_material_locations
        WHERE location = _locationTag;

        If Not FOUND Then
            RAISE EXCEPTION 'Material location tag not found; contact a DMS admin to add new locations';
        End If;

        ---------------------------------------------------
        -- Do not allow updates to shared material locations
        ---------------------------------------------------

        If _containerLimit >= 100 Then
            _errorMessage := 'Cannot update the comment or active status of shared material location ' || _locationTag || '; contact a DMS admin for assistance';
            RAISE EXCEPTION '%', _errorMessage;
        End If;

        ---------------------------------------------------
        -- Do not allow a location to be made Inactive if it has active containers
        ---------------------------------------------------

        If _oldStatus = 'Active' And _status ='Inactive' Then

            SELECT COUNT(*)
            INTO _activeContainers
            FROM t_material_locations AS ML
                 INNER JOIN t_material_containers AS MC
                   ON ML.ID = MC.Location_ID
            WHERE ML.location_id = _locationId AND
                  MC.status = 'Active';
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _activeContainers > 0 Then
                _errorMessage := format('Location cannot be set to inactive because it has %s active %s',
                                        _activeContainers, public.check_plural(_activeContainers, 'container', 'containers'));

                RAISE EXCEPTION '%', _errorMessage;
            End If;
        End If;

        ---------------------------------------------------
        -- Update the data
        ---------------------------------------------------

        -- Enable error logging if an exception is caught
        _logErrors := true;

        If _status <> _oldStatus Then
            -- Update the status

            Update t_material_locations
            Set status = _status
            Where location_id = _locationId;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _logMessage := 'Material location status changed from ' || _oldStatus || ' to ' || _status ||
                              ' by ' || _callingUser || ' for material location ' || _locationTag

            Call post_log_entry ('Normal', _logMessage, 'UpdateMaterialLocation');

            _message := 'Set status to ' || _status;
        End If;

        If _oldComment <> _comment Then
            -- Update the comment

            Update t_material_locations
            Set comment = _comment
            Where location_id = _locationId;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _oldComment <> '' Then
                If _comment = '' Then
                    _logMessage := format('Material location comment "%s" removed by %s for material location %s',
                                            _oldComment, _callingUser, _locationTag);

                Else
                    _logMessage := format('Material location comment changed from "%s" to "%s" by %s for material location %s',
                                            _oldComment, _comment, _callingUser, _locationTag);
                End If;

                Call post_log_entry ('Normal', _logMessage, 'UpdateMaterialLocation');
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

            _logMessage := format('%s; Location tag %s', _exceptionMessage, _locationTag);

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

END
$$;

COMMENT ON PROCEDURE public.update_material_location IS 'UpdateMaterialLocation';
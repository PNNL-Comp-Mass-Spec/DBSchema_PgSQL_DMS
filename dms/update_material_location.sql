--
-- Name: update_material_location(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_material_location(IN _locationtag text, IN _comment text, IN _status text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update a single material location item
**
**      Only allows updating the comment and state ('Active' or 'Inactive')
**
**      Additionally, prevents updating entries where the container limit is 100 or more,
**      since those are special locations (typically for staging samples)
**
**  Arguments:
**    _locationTag      Location name, e.g. '1206B.1.1.5.1'
**    _comment          New comment for the location
**    _status           State: 'Active' or 'Inactive'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   mem
**  Date:   08/27/2018 mem - Initial version
**          03/05/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _errorMessage text;
    _logErrors boolean := false;
    _logMessage text;
    _locationId int;
    _containerLimit int;
    _oldStatus citext;
    _oldComment text;
    _activeContainers int := 0;

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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _locationTag := Trim(Coalesce(_locationTag, ''));
        _comment     := Trim(Coalesce(_comment, ''));
        _status      := Trim(Coalesce(_status, ''));
        _callingUser := Trim(Coalesce(_callingUser, ''));

        If _callingUser = '' Then
            _callingUser := public.get_user_login_without_domain('');
        End If;

        If _locationTag = '' Then
            RAISE EXCEPTION 'Location tag must be specified';
        End If;

        If Not _status::citext In ('Active', 'Inactive') Then
            RAISE EXCEPTION 'Status must be Active or Inactive';
        End If;

        -- Make sure _status is properly capitalized
        If _status::citext = 'Active' Then
            _status := 'Active';
        End If;

        If _status::citext = 'Inactive' Then
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
        FROM t_material_locations
        WHERE location = _locationTag::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Material location tag not found; contact a DMS admin to add new locations';
        End If;

        ---------------------------------------------------
        -- Do not allow updates to shared material locations
        ---------------------------------------------------

        If _containerLimit >= 100 Then
            _errorMessage := format('Cannot update the comment or active status of shared material location %s; contact a DMS admin for assistance', _locationTag);
            RAISE EXCEPTION '%', _errorMessage;
        End If;

        ---------------------------------------------------
        -- Do not allow a location to be made Inactive if it has active containers
        ---------------------------------------------------

        If _oldStatus = 'Active' And _status = 'Inactive' Then

            SELECT COUNT(ML.location_id)
            INTO _activeContainers
            FROM t_material_locations AS ML
                 INNER JOIN t_material_containers AS MC
                   ON ML.location_id = MC.location_id
            WHERE ML.location_id = _locationId AND
                  MC.status = 'Active';

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

        If _status IS DISTINCT FROM _oldStatus Then
            -- Update the status

            UPDATE t_material_locations
            SET status = _status
            WHERE location_id = _locationId;

            _logMessage := format('Material location status changed from %s to %s by %s for material location %s',
                                  _oldStatus, _status, _callingUser, _locationTag);

            CALL post_log_entry ('Normal', _logMessage, 'Update_Material_Location');

            _message := format('Set status to %s for location %s', _status, _locationTag);
        End If;

        If _oldComment IS DISTINCT FROM _comment Then
            -- Update the comment

            UPDATE t_material_locations
            SET comment = _comment
            WHERE location_id = _locationId;

            If _oldComment <> '' Then
                If _comment = '' Then
                    _logMessage := format('Material location comment "%s" removed by %s for material location %s',
                                          _oldComment, _callingUser, _locationTag);

                Else
                    _logMessage := format('Material location comment changed from "%s" to "%s" by %s for material location %s',
                                          _oldComment, _comment, _callingUser, _locationTag);
                End If;

                CALL post_log_entry ('Normal', _logMessage, 'Update_Material_Location');
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


ALTER PROCEDURE public.update_material_location(IN _locationtag text, IN _comment text, IN _status text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_material_location(IN _locationtag text, IN _comment text, IN _status text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_material_location(IN _locationtag text, IN _comment text, IN _status text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateMaterialLocation';


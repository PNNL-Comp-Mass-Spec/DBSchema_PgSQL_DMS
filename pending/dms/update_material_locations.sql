--
CREATE OR REPLACE PROCEDURE public.update_material_locations
(
    _locationList text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the given list of material locations
**
**      Example contents of _locationList:
**        <r n="80B.na.na.na.na" i="425" a="Status" v="Active" />
**        <r n="80B.2.na.na.na" i="439" a="Status" v="Active" />
**        <r n="80B.3.3.na.na" i="558" a="Status" v="Active" />
**
**        ('n' is location name and 'i' is location_id, though this procedure ignores location_id)
**
**  Arguments:
**    _locationList     Information on material locations to update
**    _infoOnly         When true, preview the changes that would be made
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Calling user username
**
**  Auth:   grk
**  Date:   06/02/2013 grk - Initial version
**          06/03/2013 grk - Added action attribute to XML
**          06/06/2013 grk - Added code to update status
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _xml AS xml;
    _usageMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        If Coalesce(_callingUser, '') = '' Then
            _callingUser := public.get_user_login_without_domain('');
        End If;

        _infoOnly := Coalesce(_infoOnly, false);

        -----------------------------------------------------------
        -- Temp table to hold location info
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_LocationInfo (
            Location citext,      -- Location name, e.g., 2240B.2.na.na.na
            ID citext NULL,       -- Location ID (ignored)
            Action citext NULL,
            Value text NULL,
            Old_Value text NULL
        );

        -----------------------------------------------------------
        -- Convert _locationList to rooted XML
        -----------------------------------------------------------

        _xml := public.try_cast('<root>' || _locationList || '</root>', null::xml);

        If _xml Is Null Then
            _message := 'Location list is not valid XML';
            RAISE EXCEPTION '%', _message;
        End If;

        -----------------------------------------------------------
        -- Populate temp table with new parameters
        -----------------------------------------------------------

        INSERT INTO Tmp_LocationInfo (Location, ID, Action, Value)
        SELECT XmlQ.Location, XmlQ.ID, XmlQ.Action, XmlQ.Value
        FROM (
            SELECT xmltable.*
            FROM ( SELECT _xml As rooted_xml
                 ) Src,
                 XMLTABLE('//root/r'
                          PASSING Src.rooted_xml
                          COLUMNS Location citext PATH '@n',
                                  ID citext PATH '@i',
                                  Action citext PATH '@a',
                                  Value citext PATH '@v')
             ) XmlQ;

        -----------------------------------------------------------
        -- Get current status values
        -----------------------------------------------------------

        UPDATE Tmp_LocationInfo
        SET Old_Value = ML.status
        FROM t_material_locations AS ML
        WHERE ML.location = Tmp_LocationInfo.Location AND
              Tmp_LocationInfo.Action = 'status';

        -----------------------------------------------------------
        -- Update status values that have changed
        -----------------------------------------------------------

        If Not _infoOnly Then
            UPDATE t_material_locations
            SET status = Tmp_LocationInfo.Value
            FROM Tmp_LocationInfo
            WHERE t_material_locations.location = Tmp_LocationInfo.Location AND
                  Tmp_LocationInfo.Action = 'status' AND
                  NOT Tmp_LocationInfo.Value = Coalesce(Tmp_LocationInfo.Old_Value, '');

            DROP TABLE Tmp_LocationInfo;
            RETURN;
        End If;

        RAISE INFO '';

        _formatSpecifier := '%-11s %-25s %-25s %-10s %-15s %-80s %-25s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Location_ID',
                            'Freezer_Tag',
                            'Location',
                            'Status',
                            'Container_Limit',
                            'Comment',
                            'RFID_Hex_ID',
                            'Barcode'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------',
                                     '-------------------------',
                                     '-------------------------',
                                     '----------',
                                     '---------------',
                                     '--------------------------------------------------------------------------------',
                                     '-------------------------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT ML.Location_ID,
                   ML.Freezer_Tag,
                   ML.Location,
                   ML.Status,
                   ML.Container_Limit,
                   ML.Comment,
                   ML.RFID_Hex_ID,
                   ML.Barcode
            FROM t_material_locations ML
                 INNER JOIN Tmp_LocationInfo
                   ON ML.Location = Tmp_LocationInfo.Location
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Location_ID,
                                _previewData.Freezer_Tag,
                                _previewData.Location,
                                _previewData.Status,
                                _previewData.Container_Limit,
                                _previewData.Comment,
                                _previewData.RFID_Hex_ID,
                                _previewData.Barcode
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_LocationInfo;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_LocationInfo;
END
$$;

COMMENT ON PROCEDURE public.update_material_locations IS 'UpdateMaterialLocations';

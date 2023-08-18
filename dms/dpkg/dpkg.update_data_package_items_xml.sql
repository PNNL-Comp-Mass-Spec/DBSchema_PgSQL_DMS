--
-- Name: update_data_package_items_xml(text, text, text, integer, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text DEFAULT 'update'::text, IN _removeparents integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in _paramListXML according to the mode
**      This procedure is used by web page "Data Package Items List Report" (data_package_items/report)
**
**      Example contents of _paramListXML
**      <item pkg="194" type="Job" id="913603"></item><item pkg="194" type="Job" id="913604"></item>
**
**  Arguments:
**    _paramListXML     XML listing items to update for one or more data packages
**    _comment          Comment to use when the mode is 'add' or 'comment'
**    _mode             'add', 'update', 'comment', or 'delete'
**    _removeParents    When 1 and _mode is 'delete', remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**
**  Auth:   grk
**  Date:   06/10/2009 grk - Initial release
**          05/23/2010 grk - Factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/11/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          04/25/2018 mem - Assure that _removeParents is not null
**          08/17/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logUsage bool := false;
    _logMessage text;
    _xml xml;
    _removeParentItems boolean;

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

        _removeParents := Coalesce(_removeParents, 0);
        _removeParentItems := CASE WHEN _removeParents > 0 THEN true ELSE false END;

        -- Set this to true to log a debug message
        If _logUsage Then
            _logMessage := format('Mode: %s; RemoveParents: %s; %s',
                                _mode,
                                _removeParentItems,
                                Coalesce(_paramListXML, 'Error: _paramListXML is null'));

            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Data_Package_Items_XML', 'dpkg');
        End If;

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Biomaterial Name, or EUSProposal ID
        );

        _xml := try_cast(_paramListXML, null::xml);

        If _xml Is Null Then
            _message := format('Parameter _paramListXML does not have valid XML: %s', Coalesce(_paramListXML, 'Error: _paramListXML is null'));
            _returnCode := 'U5201';

            DROP TABLE Tmp_DataPackageItems;
            RETURN;
        End If;

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT XmlQ.Package, XmlQ.ItemType, XmlQ.Identifier
        FROM (
            SELECT xmltable.*
            FROM ( SELECT ('<items>' || _xml::text || '</items>')::xml as rooted_xml ) Src,
                 XMLTABLE('//items/item'
                          PASSING Src.rooted_xml
                          COLUMNS Package int PATH '@pkg',
                                  ItemType citext PATH '@type',
                                  Identifier citext PATH '@id')
             ) XmlQ;

        CALL dpkg.update_data_package_items_utility (
                                _comment,
                                _mode,
                                _removeParents => _removeParentItems,
                                _message => _message,           -- Output
                                _returnCode => _returnCode,     -- Output
                                _callingUser => _callingUser);

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := format('Unknown error calling update_data_package_items_utility (return code %s)', _returnCode);
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        DROP TABLE Tmp_DataPackageItems;

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

        DROP TABLE If Exists Tmp_DataPackageItems;
    END;

END
$$;


ALTER PROCEDURE dpkg.update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateDataPackageItemsXML';

--
-- Name: update_data_package_items_xml(text, text, text, integer, text, text, text, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text DEFAULT 'update'::text, IN _removeparents integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in _paramListXML according to the mode
**      This procedure is used by web page "Data Package Items List Report" (data_package_items/report)
**
**      Example contents of _paramListXML
**      <item pkg="194" type="Job" id="913603"></item><item pkg="194" type="Job" id="913604"></item>
**
**  Arguments:
**    _paramListXML     XML listing items to update for one or more data packages
**    _comment          Comment to use when the mode is 'add' or 'comment'
**    _mode             'add', 'update', 'comment', or 'delete'
**    _removeParents    When 1 and _mode is 'delete', remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**    _message          Output: status message
**    _returnCode       Output: return code
**    _callingUser      Username of the calling user
**    _infoOnly         When true, preview updates
**
**  Auth:   grk
**  Date:   06/10/2009 grk - Initial release
**          05/23/2010 grk - Factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/11/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          04/25/2018 mem - Assure that _removeParents is not null
**          08/17/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logUsage bool := false;
    _logMessage text;
    _xml xml;
    _removeParentItems boolean;

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

        _removeParents := Coalesce(_removeParents, 0);
        _removeParentItems := CASE WHEN _removeParents > 0 THEN true ELSE false END;

        -- Set this to true to log a debug message
        If _logUsage Then
            _logMessage := format('Mode: %s; RemoveParents: %s; %s',
                                _mode,
                                _removeParentItems,
                                Coalesce(_paramListXML, 'Error: _paramListXML is null'));

            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Data_Package_Items_XML', 'dpkg');
        End If;

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Biomaterial Name, or EUSProposal ID
        );

        _xml := try_cast(_paramListXML, null::xml);

        If _xml Is Null Then
            _message := format('Parameter _paramListXML does not have valid XML: %s', Coalesce(_paramListXML, 'Error: _paramListXML is null'));
            _returnCode := 'U5201';

            DROP TABLE Tmp_DataPackageItems;
            RETURN;
        End If;

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT XmlQ.Package, XmlQ.ItemType, XmlQ.Identifier
        FROM (
            SELECT xmltable.*
            FROM ( SELECT ('<items>' || _xml::text || '</items>')::xml as rooted_xml ) Src,
                 XMLTABLE('//items/item'
                          PASSING Src.rooted_xml
                          COLUMNS Package int PATH '@pkg',
                                  ItemType citext PATH '@type',
                                  Identifier citext PATH '@id')
             ) XmlQ;

        CALL dpkg.update_data_package_items_utility (
                                _comment,
                                _mode,
                                _removeParents => _removeParentItems,
                                _message => _message,           -- Output
                                _returnCode => _returnCode,     -- Output
                                _callingUser => _callingUser,
                                _infoOnly => _infoOnly);

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := format('Unknown error calling update_data_package_items_utility (return code %s)', _returnCode);
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        DROP TABLE Tmp_DataPackageItems;

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

        DROP TABLE If Exists Tmp_DataPackageItems;
    END;

END
$$;


ALTER PROCEDURE dpkg.update_data_package_items_xml(IN _paramlistxml text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;


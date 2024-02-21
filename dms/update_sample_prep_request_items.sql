--
-- Name: update_sample_prep_request_items(integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_sample_prep_request_items(IN _samplepreprequestid integer, IN _mode text DEFAULT 'update'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_sample_prep_request_items, which tracks cached DMS entities associated with the given sample prep request
**
**      This procedure is called by update_all_sample_prep_request_items for active sample prep requests
**      It is also called for closed sample prep requests where the state was changed within the last year
**
**  Arguments:
**    _samplePrepRequestID      Sample prep request ID
**    _mode                     Mode: 'update' or 'debug'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Auth:   grk
**  Date:   07/05/2013 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/08/2022 mem - Change Item_ID from text to integer
**                         - No longer clear the Created column for existing items
**          03/08/2023 mem - Use new column name Sample_Prep_Requests in T_Prep_LC_Run
**          10/19/2023 mem - No longer clear the status field
**                         - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

    _mode := Trim(Lower(Coalesce(_mode, '')));

    ---------------------------------------------------
    -- Test mode for debugging
    ---------------------------------------------------

    If _mode = 'test' Then
        _message := 'Test Mode';
        RETURN;
    End If;

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
        -- Staging table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_PrepRequestItems (
            Prep_Request_ID int,
            Item_ID int,
            Item_Name text,
            Item_Type text,
            Status text,
            Created timestamp,
            Marked text NOT NULL DEFAULT 'N'        -- All items are initially flagged with 'N', meaning not present in T_Sample_Prep_Request_Items; this is later changed to 'Y' or 'D'
        );

        ---------------------------------------------------
        -- Get items associated with sample prep request
        -- into staging table
        ---------------------------------------------------

        -- Biomaterial (unused by prep requests since April 2017, but still tracked)

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT SPR.prep_request_id,
               B.Biomaterial_ID AS Item_ID,
               TL.Item AS Item_Name,
               'biomaterial' AS Item_Type,
               B.Material_Active AS Status,
               B.Created AS Created
        FROM t_sample_prep_request SPR
             JOIN LATERAL (
               SELECT Value AS Item
               FROM public.parse_delimited_list(SPR.Biomaterial_List, ';')
             ) AS TL On true
             INNER JOIN t_biomaterial B
               ON B.Biomaterial_Name = TL.Item
        WHERE SPR.prep_request_id = _samplePrepRequestID;

        -- Experiments

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT SPR.prep_request_id,
               E.exp_id AS Item_ID,
               E.experiment AS Item_Name,
               'experiment' AS Item_Type,
               E.material_active AS Status,
               E.created AS Created
        FROM t_sample_prep_request SPR
             INNER JOIN t_experiments E
               ON SPR.prep_request_id = E.sample_prep_request_id
        WHERE SPR.prep_request_id = _samplePrepRequestID;

        -- Experiment groups

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT DISTINCT SPR.prep_request_id,
                        GM.group_id AS Item_ID,
                        G.description AS Item_Name,
                        'experiment_group' AS Item_Type,
                        G.group_type AS Status,
                        G.created AS Created
        FROM t_sample_prep_request SPR
             INNER JOIN t_experiments E
               ON SPR.prep_request_id = E.sample_prep_request_id
             INNER JOIN t_experiment_group_members GM
               ON E.exp_id = GM.exp_id
             INNER JOIN t_experiment_groups G
               ON GM.group_id = G.group_id
        WHERE SPR.prep_request_id = _samplePrepRequestID;

        -- Material containers

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT DISTINCT SPR.prep_request_id,
                        MC.container_id AS Item_ID,
                        MC.container AS Item_Name,
                        'material_container' AS Item_Type,
                        MC.status,
                        MC.created
        FROM t_sample_prep_request SPR
             INNER JOIN t_experiments E
               ON SPR.prep_request_id = E.sample_prep_request_id
             INNER JOIN t_material_containers MC
               ON E.container_id = MC.container_id
        WHERE SPR.prep_request_id = _samplePrepRequestID AND
              MC.container_id > 1;

        -- Requested runs

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT SPR.prep_request_id,
               RR.request_id AS Item_ID,
               RR.request_name AS Item_Name,
               'requested_run' AS Item_Type,
               RR.state_name AS Status,
               RR.created AS Created
        FROM t_sample_prep_request SPR
             INNER JOIN t_experiments E
               ON SPR.prep_request_id = E.sample_prep_request_id
             INNER JOIN t_requested_run RR
               ON E.exp_id = RR.exp_id
        WHERE SPR.prep_request_id = _samplePrepRequestID;

        -- Datasets

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT SPR.prep_request_id,
               DS.dataset_id AS Item_ID,
               DS.dataset AS Item_Name,
               'dataset' AS Item_Type,
               DSN.dataset_state AS Status,
               DS.created AS Created
        FROM t_sample_prep_request SPR
             INNER JOIN t_experiments E
               ON SPR.prep_request_id = E.sample_prep_request_id
             INNER JOIN t_dataset DS
               ON E.exp_id = DS.exp_id
             INNER JOIN t_dataset_state_name DSN
               ON DS.dataset_state_id = DSN.dataset_state_id
        WHERE SPR.prep_request_id = _samplePrepRequestID;

        -- HPLC Runs: Reference to sample prep request IDs in comma-separated list in text field

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, Item_Name, Item_Type, Status, Created)
        SELECT _samplePrepRequestID AS Prep_Request_ID,
               Item_ID,
               Item_Name,
               'prep_lc_run' AS Item_Type,
               '' AS Status,
               Created
        FROM ( SELECT LCRun.prep_run_id AS Item_ID,
                      LCRun.comment AS Item_Name,
                      TL.value AS SPR_ID,
                      LCRun.Created
               FROM t_prep_lc_run LCRun
                    INNER JOIN LATERAL public.parse_delimited_integer_list(LCRun.sample_prep_requests) AS TL ON true
               WHERE sample_prep_requests LIKE '%' || _samplePrepRequestID::text || '%'
             ) TX
        WHERE TX.SPR_ID = _samplePrepRequestID;

        ---------------------------------------------------
        -- Mark items for update that are already in database
        ---------------------------------------------------

        UPDATE Tmp_PrepRequestItems TPRI
        SET Marked = 'Y'
        FROM t_sample_prep_request_items I
        WHERE I.prep_request_id = TPRI.prep_request_id AND
              I.item_id         = TPRI.item_id AND
              I.item_type       = TPRI.item_type;

        ---------------------------------------------------
        -- Mark items that should be deleted from T_Sample_Prep_Request_Items
        ---------------------------------------------------

        INSERT INTO Tmp_PrepRequestItems (Prep_Request_ID, Item_ID, item_type, Marked)
        SELECT I.prep_request_id,
               I.item_id,
               I.item_type,
               'D' AS Marked
        FROM t_sample_prep_request_items I
        WHERE prep_request_id = _samplePrepRequestID
              AND NOT EXISTS ( SELECT 1
                               FROM Tmp_PrepRequestItems TPRI
                               WHERE I.prep_request_id = TPRI.prep_request_id AND
                                     I.item_id         = TPRI.item_id AND
                                     I.item_type       = TPRI.item_type );

        ---------------------------------------------------
        -- Update database
        ---------------------------------------------------

        If _mode = 'update' Then

            ---------------------------------------------------
            -- Add new items
            ---------------------------------------------------

            INSERT INTO t_sample_prep_request_items (
                prep_request_id,
                item_id,
                item_name,
                item_type,
                status,
                created
            )
            SELECT Prep_Request_ID,
                   Item_id,
                   Item_name,
                   Item_type,
                   Status,
                   Created
            FROM Tmp_PrepRequestItems
            WHERE Marked = 'N';

            ---------------------------------------------------
            -- Update the created date and status for existing items (if not correct)
            ---------------------------------------------------

            UPDATE t_sample_prep_request_items I
            SET created = TPRI.created,
                status = TPRI.Status
            FROM Tmp_PrepRequestItems TPRI
            WHERE I.prep_request_id = TPRI.prep_request_id AND
                  I.item_id         = TPRI.item_id AND
                  I.item_type       = TPRI.item_type AND
                  TPRI.marked       = 'Y' AND
                  ( I.created IS NULL AND NOT TPRI.created IS NULL OR I.created <> TPRI.created OR
                    I.status  IS NULL AND NOT TPRI.status  IS NULL OR I.status  <> TPRI.status);

            ---------------------------------------------------
            -- Delete extra items from table
            ---------------------------------------------------

            DELETE FROM t_sample_prep_request_items I
            WHERE EXISTS (SELECT 1
                          FROM Tmp_PrepRequestItems TPRI
                          WHERE I.prep_request_id = TPRI.prep_request_id AND
                                I.item_id         = TPRI.item_id         AND
                                I.item_type       = TPRI.item_type       AND
                                TPRI.Marked = 'D'
            );

            ---------------------------------------------------
            -- Update item counts in T_Sample_Prep_Request
            ---------------------------------------------------

            CALL public.update_sample_prep_request_item_count (_samplePrepRequestID);

        End If;

        If _mode = 'debug' Then

            RAISE INFO '';

            _formatSpecifier := '%-15s %-9s %-80s %-20s %-15s %-20s %-6s';

            _infoHead := format(_formatSpecifier,
                                'Prep_Request_ID',
                                'Item_ID',
                                'Item_Name',
                                'Item_Type',
                                'Status',
                                'Created',
                                'Marked'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '---------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------',
                                         '---------------',
                                         '--------------------',
                                         '------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Prep_Request_ID,
                       Item_ID,
                       Item_Name,
                       Item_Type,
                       Status,
                       public.timestamp_text(Created) AS Created,
                       Marked
                FROM Tmp_PrepRequestItems
                ORDER BY Marked, Item_Type, Item_Name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Prep_Request_ID,
                                    _previewData.Item_ID,
                                    _previewData.Item_Name,
                                    _previewData.Item_Type,
                                    _previewData.Status,
                                    _previewData.Created,
                                    _previewData.Marked
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        DROP TABLE Tmp_PrepRequestItems;
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

    DROP TABLE IF EXISTS Tmp_PrepRequestItems;
END
$$;


ALTER PROCEDURE public.update_sample_prep_request_items(IN _samplepreprequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_sample_prep_request_items(IN _samplepreprequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_sample_prep_request_items(IN _samplepreprequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateSamplePrepRequestItems';


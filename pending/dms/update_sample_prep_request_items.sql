--
CREATE OR REPLACE PROCEDURE public.update_sample_prep_request_items
(
    _samplePrepRequestID int,
    _mode text = 'update',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Automatically associates DMS entities with specified sample prep request
**
**  Arguments:
**    _mode   'update' or 'debug'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

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

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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
            ID int,
            Item_ID int,
            Item_Name text,
            Item_Type text,
            Status text,
            Created timestamp,
            Marked text NOT NULL DEFAULT 'N'        -- all items are initially marked as not being in the database
        )

        ---------------------------------------------------
        -- Get items associated with sample prep request
        -- into staging table
        ---------------------------------------------------

        -- Biomaterial
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT  SPR.prep_request_id,
                B.Biomaterial_ID AS Item_ID,
                TL.Item AS Item_Name,
                'biomaterial' AS Item_Type,
                B.Material_Active AS Status,
                B.Created AS Created
        FROM    t_sample_prep_request SPR
                -- Remove or update since skipped column: CROSS APPLY public.parse_delimited_list(SPR.Biomaterial_List, ';') TL
                INNER JOIN T_Biomaterial B ON B.Biomaterial_Name = TL.Item
        WHERE   SPR.prep_request_id = _samplePrepRequestID
                -- Remove or update since skipped column: AND SPR.Biomaterial_List <> '(none)'
                -- Remove or update since skipped column: AND SPR.Biomaterial_List <> ''

        -- Experiments
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT  SPR.prep_request_id,
                E.exp_id AS Item_ID,
                E.experiment AS Item_Name,
                'experiment' AS Item_Type,
                E.material_active AS Status,
                E.created AS Created
        FROM    t_sample_prep_request SPR
                INNER JOIN t_experiments E ON SPR.prep_request_id = E.sample_prep_request_id
        WHERE SPR.prep_request_id = _samplePrepRequestID

        -- Experiment groups
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT DISTINCT
                SPR.prep_request_id,
                GM.group_id AS Item_ID,
                G.description AS Item_Name,
                'experiment_group' AS Item_Type,
                G.group_type AS Status,
                G.created AS Created
        FROM    t_sample_prep_request SPR
                INNER JOIN t_experiments E ON SPR.prep_request_id = E.sample_prep_request_id
                INNER JOIN t_experiment_group_members GM ON E.exp_id = GM.exp_id
                INNER JOIN t_experiment_groups G ON GM.group_id = G.group_id
        WHERE SPR.prep_request_id = _samplePrepRequestID

        -- Material containers
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT  DISTINCT SPR.prep_request_id,
                MC.prep_request_id AS Item_ID,
                MC.container AS Item_Name,
                'material_container' AS Item_Type,
                MC.status,
                MC.created
        FROM    t_sample_prep_request SPR
                INNER JOIN t_experiments E ON SPR.prep_request_id = E.sample_prep_request_id
                INNER JOIN t_material_containers MC ON E.container_id = MC.prep_request_id
        WHERE SPR.prep_request_id = _samplePrepRequestID AND MC.prep_request_id > 1;

        -- Requested runs
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT  SPR.prep_request_id,
                RR.prep_request_id AS Item_ID,
                RR.request_name AS Item_Name,
                'requested_run' AS Item_Type,
                RR.state_name AS Status,
                RR.created AS Created
        FROM    t_sample_prep_request SPR
                INNER JOIN t_experiments E ON SPR.prep_request_id = E.sample_prep_request_id
                INNER JOIN t_requested_run RR ON E.exp_id = RR.exp_id
        WHERE SPR.prep_request_id = _samplePrepRequestID

        -- Datasets
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT  SPR.prep_request_id,
                DS.dataset_id AS Item_ID,
                DS.dataset AS Item_Name,
                'dataset' AS Item_Type,
                DSN.DSS_name AS Status,
                DS.created AS Created
        FROM    t_sample_prep_request SPR
                INNER JOIN t_experiments E ON SPR.prep_request_id = E.sample_prep_request_id
                INNER JOIN t_dataset DS ON E.exp_id = DS.exp_id
                INNER JOIN t_dataset_rating_name DSN ON DS.dataset_state_id = DSN.dataset_state_id
        WHERE SPR.prep_request_id = _samplePrepRequestID

        -- HPLC Runs - Reference to sample prep request IDs in comma delimited list in text field
        --
        INSERT INTO Tmp_PrepRequestItems (prep_request_id, Item_ID, Item_Name, Item_Type, Status, created)
        SELECT _samplePrepRequestID AS ID,
               Item_ID,
               Item_Name,
               'prep_lc_run' AS Item_Type,
               '' AS Status,
               created
        FROM ( SELECT LCRun.prep_run_id AS Item_ID,
                      LCRun.comment As Item_Name,
                      TL.value AS SPR_ID,
                      LCRun.created
               FROM t_prep_lc_run LCRun
                    INNER JOIN LATERAL public.parse_delimited_integer_list(LCRun.sample_prep_requests) As TL On true
               WHERE sample_prep_requests LIKE '%' || _samplePrepRequestID::text || '%'
             ) TX
        WHERE TX.SPR_ID = _samplePrepRequestID;

        ---------------------------------------------------
        -- Mark items for update that are already in database
        ---------------------------------------------------

        UPDATE Tmp_PrepRequestItems
        SET Marked = 'Y'
        FROM t_sample_prep_request_items I
        WHERE I.prep_request_item_id = Tmp_PrepRequestItems.prep_request_item_id AND
              I.item_id = Tmp_PrepRequestItems.item_id AND
              I.item_type = Tmp_PrepRequestItems.item_type;

        ---------------------------------------------------
        -- Mark items for delete that are already in database
        -- but are not in staging table
        ---------------------------------------------------

        INSERT INTO Tmp_PrepRequestItems (prep_request_item_id, item_id, item_type, Marked)
        SELECT  I.prep_request_item_id,
                I.item_id,
                I.item_type,
                'D' AS Marked
        FROM    t_sample_prep_request_items I
        WHERE   prep_request_item_id = _samplePrepRequestID
                AND NOT EXISTS ( SELECT *
                                 FROM   Tmp_PrepRequestItems
                                 WHERE  I.prep_request_item_id = Tmp_PrepRequestItems.prep_request_item_id AND
                                        I.item_id = Tmp_PrepRequestItems.item_id AND
                                        I.item_type = Tmp_PrepRequestItems.item_type );

        ---------------------------------------------------
        -- Update database
        ---------------------------------------------------
        If _mode = 'update' Then

            ---------------------------------------------------
            -- Insert unmarked items into table
            ---------------------------------------------------

            INSERT INTO t_sample_prep_request_items (
                prep_request_item_id,
                item_id,
                item_name,
                item_type,
                status,
                created
            )
            SELECT
                prep_request_item_id,
                item_id,
                item_name,
                item_type,
                status,
                created
            FROM    Tmp_PrepRequestItems
            WHERE   Marked = 'N';

            ---------------------------------------------------
            -- Clear the status of marked items
            ---------------------------------------------------

            UPDATE t_sample_prep_request_items
            SET Status = ''
            FROM Tmp_PrepRequestItems
            WHERE I.ID = Tmp_PrepRequestItems.ID AND
                  I.Item_ID = Tmp_PrepRequestItems.Item_ID AND
                  I.Item_Type = Tmp_PrepRequestItems.Item_Type AND
                  Tmp_PrepRequestItems.Marked = 'Y' And char_length(Coalesce(I.Status, '')) > 0;

            ---------------------------------------------------
            -- Update the Created date for marked items (if not correct)
            ---------------------------------------------------

            UPDATE t_sample_prep_request_items I
            SET created = Tmp_PrepRequestItems.created
            FROM Tmp_PrepRequestItems ITM
            WHERE I.ID = ITM.ID AND
                  I.Item_ID = ITM.Item_ID AND
                  I.Item_Type = ITM.Item_Type AND
                  ITM.Marked = 'Y' AND
                  ( I.Created Is Null And Not ITM.Created Is Null OR
                    I.Created <> ITM.Created);

            ---------------------------------------------------
            -- Delete marked items from database
            ---------------------------------------------------

            DELETE FROM t_sample_prep_request_items
            WHERE EXISTS (
            SELECT  *
            FROM    Tmp_PrepRequestItems
            WHERE   t_sample_prep_request_items.prep_request_item_id = Tmp_PrepRequestItems.prep_request_item_id
                    AND t_sample_prep_request_items.item_id = Tmp_PrepRequestItems.item_id
                    AND t_sample_prep_request_items.item_type = Tmp_PrepRequestItems.item_type
                    AND Tmp_PrepRequestItems.Marked = 'D'
            );

            ---------------------------------------------------
            -- Update item counts
            ---------------------------------------------------

            CALL update_sample_prep_request_item_count (_samplePrepRequestID);

        End If; --<update>

        ---------------------------------------------------
        --
        ---------------------------------------------------
        If _mode = 'debug' Then
            -- ToDo: Update this to use RAISE INFO
            SELECT *
            FROM Tmp_PrepRequestItems
            ORDER BY Marked;

            RETURN;
        End If;

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

COMMENT ON PROCEDURE public.update_sample_prep_request_items IS 'UpdateSamplePrepRequestItems';

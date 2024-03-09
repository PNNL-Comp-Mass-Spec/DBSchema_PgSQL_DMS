--
-- Name: request_dataset_create_task(text, boolean, integer, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.request_dataset_create_task(IN _processorname text, IN _infoonly boolean DEFAULT false, IN _taskcounttopreview integer DEFAULT 10, INOUT _entryid integer DEFAULT 0, INOUT _parameters text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return first available dataset creation task in T_Dataset_Create_Queue
**
**  Arguments:
**    _processorName        Name of the processor requesting a dataset creation task
**    _infoOnly             When 1, preview the dataset creation task that would be returned
**    _taskCountToPreview   The number of dataset creation tasks to preview when _infoOnly >= 1
**    _entryID              Output: Entry_ID assigned; 0 if no creation tasks are available
**    _parameters           Output: Dataset metadata (as XML)
**    _message              Status message
**    _returnCode           Return code
**
**  Return values:
**      0 for success, non-zero if an error
**
**  Example XML parameters returned in @parameters:
**      <root>
**        <dataset>SW_Test_Dataset_2023-10-24</dataset>
**        <experiment>QC_Mam_23_01</experiment>
**        <instrument>Exploris03</instrument>
**        <separation_type>LC-Dionex-Formic_100min</separation_type>
**        <lc_cart>Birch</lc_cart>
**        <lc_cart_config>Birch_BEH-1pt7</lc_cart_config>
**        <lc_column>WBEH-CoAnn-23-09-02</lc_column>
**        <wellplate></wellplate>
**        <well></well>
**        <dataset_type>HMS-HCD-HMSn</dataset_type>
**        <operator_username>D3L243</operator_username>
**        <ds_creator_username>D3L243</ds_creator_username>
**        <comment>Test comment</comment>
**        <interest_rating>Released</interest_rating>
**        <request>0</request>
**        <work_package>none</work_package>
**        <eus_usage_type>USER_ONSITE</eus_usage_type>
**        <eus_proposal_id>60328</eus_proposal_id>
**        <eus_users>35357</eus_users>
**        <capture_share_name></capture_share_name>
**        <capture_subdirectory></capture_subdirectory>
**        <command>add</command>
**      </root>
**
**  Auth:   mem
**          10/25/2023 mem - Initial version
**          10/27/2023 mem - Apply a row-level lock to t_dataset_create_queue using FOR UPDATE
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _taskAssigned boolean;
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

        ---------------------------------------------------
        -- Validate the inputs; clear the outputs
        ---------------------------------------------------

        _processorName      := Trim(Coalesce(_processorName, ''));
        _infoOnly           := Coalesce(_infoOnly, false);
        _taskCountToPreview := Coalesce(_taskCountToPreview, 10);
        _entryID            := 0;
        _parameters         := '';

        ---------------------------------------------------
        -- Get first available dataset creation task from t_dataset_create_queue
        ---------------------------------------------------

        SELECT entry_id
        INTO _entryID
        FROM t_dataset_create_queue
        WHERE state_id = 1
        ORDER BY entry_id
        LIMIT 1
        FOR UPDATE;         -- Lock the row to prevent other threads from selecting this task

        If FOUND Then
            _taskAssigned = true;
        Else
            _taskAssigned = false;
        End If;

        ---------------------------------------------------
        -- If a new dataset creation task was found (_entryID <> 0) and if _infoOnly is false,
        -- update the state to 2=In Progress
        ---------------------------------------------------

        If _taskAssigned AND Not _infoOnly Then

            UPDATE T_Dataset_Create_Queue
            SET State_ID = 2,
                Processor = _processorName,
                Start = CURRENT_TIMESTAMP,
                Finish = Null
            WHERE Entry_ID = _entryID;
        End If;

        If _taskAssigned Then

            ---------------------------------------------------
            -- A new dataset creation task was assigned; return parameters in XML format
            ---------------------------------------------------

            SELECT xml_item::text
            INTO _parameters
            FROM ( SELECT
                     XMLELEMENT(name "root",
                       XMLELEMENT(name "dataset", dataset),
                       XMLELEMENT(name "experiment", experiment),
                       XMLELEMENT(name "instrument", instrument),
                       XMLELEMENT(name "separation_type", separation_type),
                       XMLELEMENT(name "lc_cart", lc_cart),
                       XMLELEMENT(name "lc_cart_config", lc_cart_config),
                       XMLELEMENT(name "lc_column", lc_column),
                       XMLELEMENT(name "wellplate", wellplate),
                       XMLELEMENT(name "well", well),
                       XMLELEMENT(name "dataset_type", dataset_type),
                       XMLELEMENT(name "operator_username", operator_username),
                       XMLELEMENT(name "ds_creator_username", ds_creator_username),
                       XMLELEMENT(name "comment", comment),
                       XMLELEMENT(name "interest_rating", interest_rating),
                       XMLELEMENT(name "request", request),
                       XMLELEMENT(name "work_package", work_package),
                       XMLELEMENT(name "eus_usage_type", eus_usage_type),
                       XMLELEMENT(name "eus_proposal_id", eus_proposal_id),
                       XMLELEMENT(name "eus_users", eus_users),
                       XMLELEMENT(name "capture_share_name", capture_share_name),
                       XMLELEMENT(name "capture_subdirectory", capture_subdirectory),
                       XMLELEMENT(name "command", command)
                            ) AS xml_item
                   FROM public.t_dataset_create_queue
                   WHERE entry_id = _entryID
                ) AS LookupQ;

            If _infoOnly Then
                _message := format('Dataset creation task %s would be assigned to %s', _entryID, _processorName)p;
            End If;
        Else
            ---------------------------------------------------
            -- A new creation task was not found
            ---------------------------------------------------

            _message := 'No available dataset creation tasks';
        End If;

        ---------------------------------------------------
        -- Dump candidate tasks if in infoOnly mode
        ---------------------------------------------------

        If _infoOnly Then

            -- Preview the next _taskCountToPreview available dataset creation tasks

            RAISE INFO '';

            _formatSpecifier := '%-8s %-8s %-80s %-40s %-18s %-40s %-15s %-35s %-25s %-20s %-5s %-16s %-17s %-19s %-20s %-15s %-7s %-12s %-14s %-15s %-9s %-18s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Entry_ID',
                                'State_ID',
                                'Dataset',
                                'Experiment',
                                'Instrument',
                                'Separation_Type',
                                'LC_Cart',
                                'LC_Cart_Config',
                                'LC_Column',
                                'Wellplate',
                                'Well',
                                'Dataset_Type',
                                'Operator_Username',
                                'DS_Creator_Username',
                                'Comment',
                                'Interest_Rating',
                                'Request',
                                'Work_Package',
                                'EUS_Usage_Type',
                                'EUS_Proposal_ID',
                                'EUS_Users',
                                'Capture_Share_Name',
                                'Capture_Subdirectory'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------',
                                         '--------',
                                         '--------------------------------------------------------------------------------',
                                         '----------------------------------------',
                                         '------------------',
                                         '----------------------------------------',
                                         '---------------',
                                         '-----------------------------------',
                                         '-------------------------',
                                         '--------------------',
                                         '-----',
                                         '----------------',
                                         '-----------------',
                                         '-------------------',
                                         '--------------------',
                                         '---------------',
                                         '-------',
                                         '------------',
                                         '--------------',
                                         '---------------',
                                         '---------',
                                         '------------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Entry_ID,
                       State_ID,
                       Dataset,
                       Experiment,
                       Instrument,
                       Separation_Type,
                       LC_Cart,
                       LC_Cart_Config,
                       LC_Column,
                       Wellplate,
                       Well,
                       Dataset_Type,
                       Operator_Username,
                       DS_Creator_Username,
                       Comment,
                       Interest_Rating,
                       Request,
                       Work_Package,
                       EUS_Usage_Type,
                       EUS_Proposal_ID,
                       EUS_Users,
                       Capture_Share_Name,
                       Capture_Subdirectory
                FROM T_Dataset_Create_Queue
                WHERE State_ID = 1
                ORDER BY Entry_ID
                LIMIT _taskCountToPreview
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.State_ID,
                                    _previewData.Dataset,
                                    _previewData.Experiment,
                                    _previewData.Instrument,
                                    _previewData.Separation_Type,
                                    _previewData.LC_Cart,
                                    _previewData.LC_Cart_Config,
                                    _previewData.LC_Column,
                                    _previewData.Wellplate,
                                    _previewData.Well,
                                    _previewData.Dataset_Type,
                                    _previewData.Operator_Username,
                                    _previewData.DS_Creator_Username,
                                    _previewData.Comment,
                                    _previewData.Interest_Rating,
                                    _previewData.Request,
                                    _previewData.Work_Package,
                                    _previewData.EUS_Usage_Type,
                                    _previewData.EUS_Proposal_ID,
                                    _previewData.EUS_Users,
                                    _previewData.Capture_Share_Name,
                                    _previewData.Capture_Subdirectory
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('Error requesting a dataset creation task: %s', _exceptionMessage);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.request_dataset_create_task(IN _processorname text, IN _infoonly boolean, IN _taskcounttopreview integer, INOUT _entryid integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


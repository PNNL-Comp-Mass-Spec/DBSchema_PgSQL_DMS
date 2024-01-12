--
-- Name: add_update_data_analysis_request(text, text, text, text, text, text, text, integer, integer, text, text, text, text, text, integer, text, text, integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_data_analysis_request(IN _requestname text, IN _analysistype text, IN _requesterusername text, IN _description text, IN _analysisspecifications text, IN _comment text, IN _batchids text DEFAULT ''::text, IN _datapackageid integer DEFAULT NULL::integer, IN _experimentgroupid integer DEFAULT NULL::integer, IN _workpackage text DEFAULT ''::text, IN _requestedpersonnel text DEFAULT ''::text, IN _assignedpersonnel text DEFAULT ''::text, IN _priority text DEFAULT 'Normal'::text, IN _reasonforhighpriority text DEFAULT ''::text, IN _estimatedanalysistimedays integer DEFAULT 0, IN _state text DEFAULT 'New'::text, IN _statecomment text DEFAULT ''::text, INOUT _id integer DEFAULT 0, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing data analysis request
**
**      The analysis request must be associated with at least one of the following data containers:
**        - One or more requested run batches
**        - Data package
**        - Experiment group
**
**  Arguments:
**    _requestName                  Data analysis request name
**    _analysisType                 Analysis type: Proteomics, Metabolomics, or Lipidomics; see table t_data_analysis_request_type_name
**    _requesterUsername            Requester username
**    _description                  Description
**    _analysisSpecifications       Analysis specifications
**    _comment                      Comment
**    _batchIDs                     Comma-separated list of requested run batch IDs; null if not applicable
**    _dataPackageID                Data Package ID;     null if not applicable
**    _experimentGroupID            Experiment Group ID; null if not applicable
**    _workPackage                  Work package
**    _requestedPersonnel           Requested personnel; names should be in the form 'Last Name, First Name (Username)', but usernames are also supported
**    _assignedPersonnel            Assigned personnel;  names should be in the form 'Last Name, First Name (Username)', but usernames are also supported
**    _priority                     Priority (1 is the highest priority)
**    _reasonForHighPriority        Reason for high priority
**    _estimatedAnalysisTimeDays    Estimated analysis time, in days
**    _state                        State: 'New', 'On Hold', 'Analysis in Progress', or 'Closed'; see table t_data_analysis_request_state_name
**    _stateComment                 State comment
**    _id                           Input/output: data analysis request ID
**    _mode                         Mode: 'add', 'update', or 'previewadd', 'previewupdate'
**    _message                      Status message
**    _returnCode                   Return code
**    _callingUser                  Username of the calling user
**
**  Auth:   mem
**  Date:   03/22/2022 mem - Initial version
**          03/26/2022 mem - Replace parameter _batchID with _batchIDs
**                         - Add parameter _comment
**          08/08/2022 mem - Update State_Changed when the state changes
**          02/13/2023 bcg - Send the correct procedure name to ValidateRequestUsers
**          01/06/2024 mem - Ported to PostgreSQL
**          01/07/2024 mem - Update error message and remove unnecessary Begin/End block
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _insertCount int := 0;
    _msg text;
    _currentStateID int;
    _requestType text := 'Default';
    _logErrors boolean := false;
    _batchDescription text := '';
    _allowUpdateEstimatedAnalysisTime boolean := false;
    _batchDefined boolean := false;
    _dataPackageDefined boolean := false;
    _experimentGroupDefined boolean := false;
    _stateID int := 0;
    _campaign text;
    _organism  text;
    _datasetCount int := 0;
    _eusProposalID text;
    _containerID int;
    _preferredContainer text := '';
    _representativeBatchID int := null;
    _currentAssignedPersonnel text;
    _activationState int := 10;
    _activationStateName text;
    _currentEstimatedAnalysisTimeDays Int;
    _logMessage text;
    _alterEnteredByMessage text;

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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _requestName                := Trim(Coalesce(_requestName, ''));
        _analysisType               := Trim(Coalesce(_analysisType, ''));
        _requesterUsername          := Trim(Coalesce(_requesterUsername, ''));
        _description                := Trim(Coalesce(_description, ''));
        _analysisSpecifications     := Trim(Coalesce(_analysisSpecifications, ''));
        _comment                    := Trim(Coalesce(_comment, ''));
        _batchIDs                   := Trim(Coalesce(_batchIDs, ''));
        _dataPackageID              := Coalesce(_dataPackageID, 0);
        _experimentGroupID          := Coalesce(_experimentGroupID, 0);
        _workPackage                := Trim(Coalesce(_workPackage, ''));
        _requestedPersonnel         := Trim(Coalesce(_requestedPersonnel, ''));
        _assignedPersonnel          := Trim(Coalesce(_assignedPersonnel, 'na'));
        _priority                   := Trim(Coalesce(_priority, 'Normal'));
        _reasonForHighPriority      := Trim(Coalesce(_reasonForHighPriority, ''));
        _estimatedAnalysisTimeDays  := Coalesce(_estimatedAnalysisTimeDays, 1);
        _state                      := Trim(Coalesce(_state, ''));
        _stateComment               := Trim(Coalesce(_stateComment, ''));
        _id                         := Coalesce(_id, 0);
        _callingUser                := Trim(Coalesce(_callingUser, ''));

        _mode                       := Trim(Lower(Coalesce(_mode, '')));

        If _assignedPersonnel = '' Then
            _assignedPersonnel := 'na';
        End If;

        If _description = '' Then
            RAISE EXCEPTION 'The description field is required';
        End If;

        If _state::citext In ('New', 'Closed') Then
            -- Always clear state comment when the state is new or closed
            _stateComment := '';
        End If;

        If Exists ( SELECT U.username
                    FROM t_users U
                         INNER JOIN t_user_operations_permissions UOP
                           ON U.user_id = UOP.user_id
                         INNER JOIN t_user_operations UO
                           ON UOP.operation_id = UO.operation_id
                    WHERE U.Status = 'Active' AND
                          UO.operation = 'DMS_Data_Analysis_Request' AND
                          Username = _callingUser::citext
                  ) Then

              _allowUpdateEstimatedAnalysisTime := true;
        End If;

        ---------------------------------------------------
        -- Validate priority
        ---------------------------------------------------

        If Not _priority::citext In ('Normal', 'High') Then
            RAISE EXCEPTION 'Priority must be Normal or High';
        End If;

        If _priority::citext <> 'Normal' And _reasonForHighPriority = '' Then
            RAISE EXCEPTION 'Priority "%" requires justification reason to be provided', _priority;
        End If;

        ---------------------------------------------------
        -- Validate analysis type
        ---------------------------------------------------

        If Not Exists (SELECT analysis_type FROM t_data_analysis_request_type_name WHERE analysis_type = _analysisType::citext) Then
            RAISE EXCEPTION 'Invalid data analysis type: %', _analysisType;
        End If;

        ---------------------------------------------------
        -- Resolve Batch IDs, Data Package ID, and Experiment Group ID
        -- Require that at least one be valid
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_BatchIDs (
            Batch_ID Int Not Null
        );

        If _batchIDs <> '' Then
            INSERT INTO Tmp_BatchIDs (Batch_ID)
            SELECT Value
            FROM public.parse_delimited_integer_list(_batchIDs)
            WHERE Value <> 0;
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            If _insertCount = 0 Then
                If _batchIDs = '0' Then
                    RAISE EXCEPTION 'Invalid requested run batch ID; must be a positive integer, not zero';
                Else
                    RAISE EXCEPTION 'Invalid list of requested run batch IDs; integer not found: "%"', _batchIDs;
                End If;
            End If;

            If Not Exists (SELECT batch_id FROM t_requested_run_batches WHERE batch_id In (SELECT batch_id FROM Tmp_BatchIDs)) Then
                If _insertCount = 1 Then
                    _batchDescription := format('Invalid requested run batch ID: %s does not exist', _batchIDs);
                Else
                    _batchDescription := format('Batch ID list includes one or more invalid requested run batches: %s', _batchIDs);
                End If;

                RAISE EXCEPTION '%', _batchDescription;
            Else
                _batchDefined := true;

                If _insertCount = 1 Then
                    _batchDescription := format('batch %s', _batchIDs);
                Else
                    _batchDescription := format('batches %s', _batchIDs);
                End If;
            End If;
        End If;

        If _dataPackageID > 0 Then
            If Not Exists (SELECT ID FROM dpkg.V_Data_Package_Export WHERE ID = _dataPackageID) Then
                RAISE EXCEPTION 'Invalid data package ID: "%" does not exist', _dataPackageID;
            Else
                _dataPackageDefined := true;
            End If;
        End If;

        If _experimentGroupID > 0 Then
            If Not Exists (SELECT group_id FROM t_experiment_groups WHERE group_id = _experimentGroupID) Then
                RAISE EXCEPTION 'Invalid experiment group ID: "%" does not exist', _experimentGroupID;
            Else
                _experimentGroupDefined := true;
            End If;
        End If;

        If Not (_batchDefined Or _dataPackageDefined Or _experimentGroupDefined) Then
            RAISE EXCEPTION 'Must define a requested run batch, data package, and/or experiment group';
        End If;

        ---------------------------------------------------
        -- Force values of some properties for add mode
        ---------------------------------------------------

        If _mode Like '%add%' Then
            _state := 'New';
            _assignedPersonnel := 'na';
        End If;

        ---------------------------------------------------
        -- Validate requested and assigned personnel
        -- Names should be in the form 'Last Name, First Name (Username)', but usernames are also supported
        ---------------------------------------------------

        CALL public.validate_request_users (
                        _requestedPersonnel             => _requestedPersonnel,     -- Input/Output
                        _assignedPersonnel              => _assignedPersonnel,      -- Input/Output
                        _requireValidRequestedPersonnel => false,
                        _message                        => _message,                -- Output
                        _returnCode                     => _returnCode);            -- Output

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := 'Error validating the requested and assigned personnel';
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Convert state name to ID
        ---------------------------------------------------

        SELECT state_id
        INTO _stateID
        FROM  t_data_analysis_request_state_name
        WHERE state_name = _state::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid data analysis request state name: %', _state;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        If _batchDefined And _workPackage::citext In ('', 'na', 'none') Then
            -- Auto-define using requests in the batch(s)

            SELECT work_package
            INTO _workPackage
            FROM ( SELECT work_package AS Work_Package,
                          COUNT(RR.request_id) AS Requests
                   FROM t_requested_run RR
                        INNER JOIN Tmp_BatchIDs
                          ON RR.batch_id = Tmp_BatchIDs.batch_id
                   WHERE NOT Coalesce(work_package, '')::citext IN ('', 'na', 'none')
                   GROUP BY work_package ) StatsQ
            ORDER BY Requests DESC
            LIMIT 1;

            If FOUND And _mode Like 'preview%' Then
                RAISE INFO '';
                RAISE INFO 'Work package set to % based on requests in %', _workPackage, _batchDescription;
            End If;
        End If;

        CALL public.validate_wp (
                        _workPackage,
                        _allowNoneWP => false,
                        _message     => _msg,           -- Output
                        _returnCode  => _returnCode);   -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackage::citext And deactivated = 'Y') Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is deactivated', _workPackage));
        ElsIf Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackage::citext And charge_code_state = 0) Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is likely deactivated', _workPackage));
        End If;

        -- Make sure the work package is capitalized properly

        SELECT charge_code
        INTO _workPackage
        FROM t_charge_code
        WHERE charge_code = _workPackage::citext;

        ---------------------------------------------------
        -- Determine the number of datasets in the batch(s), data package,
        -- and/or experiment group for this data analysis request
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetCountsByContainerType (
            ContainerType text NOT NULL,
            ContainerID   Int NOT NULL,
            DatasetCount  int NOT NULL,
            SortWeight    int NOT NULL
        );

        If _batchDefined Then
            INSERT INTO Tmp_DatasetCountsByContainerType (
                ContainerType,
                ContainerID,
                SortWeight,
                DatasetCount
            )
            SELECT 'Batch', RR.batch_id, 2 AS SortWeight, COUNT(RR.request_id) AS DatasetCount
            FROM t_requested_run RR
                 INNER JOIN Tmp_BatchIDs
                   ON RR.batch_id = Tmp_BatchIDs.batch_id
            GROUP BY RR.batch_id;
        End If;

        If _dataPackageDefined Then
            INSERT INTO Tmp_DatasetCountsByContainerType (
                ContainerType,
                ContainerID,
                SortWeight,
                DatasetCount
            )
            SELECT 'Data Package', _dataPackageID, 1 AS SortWeight, COUNT(DISTINCT DS.Dataset_ID) AS DatasetCount
            FROM dpkg.V_Data_Package_Dataset_Export DataPkgDatasets
                 INNER JOIN t_dataset DS
                   ON DataPkgDatasets.dataset_id = DS.dataset_id
            WHERE DataPkgDatasets.Data_Package_ID = _dataPackageID;
        End If;

        If _experimentGroupDefined Then
            INSERT INTO Tmp_DatasetCountsByContainerType (
                ContainerType,
                ContainerID,
                SortWeight,
                DatasetCount
            )
            SELECT 'Experiment Group', _experimentGroupID, 3 As SortWeight, COUNT(DISTINCT DS.Dataset_ID) AS DatasetCount
            FROM t_experiment_group_members E
                 INNER JOIN t_dataset DS
                   ON E.exp_id = DS.exp_id
            WHERE E.group_id = _experimentGroupID;
        End If;

        ---------------------------------------------------
        -- Determine the representative campaign, organism, dataset count, and EUS_Proposal_ID
        -- Use the container type with the most datasets, sorting by SortWeight if ties
        ---------------------------------------------------

        SELECT ContainerType,
               ContainerID,
               DatasetCount
        INTO _preferredContainer, _containerID, _datasetCount
        FROM Tmp_DatasetCountsByContainerType
        WHERE DatasetCount > 0
        ORDER BY DatasetCount DESC, SortWeight
        LIMIT 1;

        If _mode Like 'preview%' Then

            RAISE INFO '';

            _formatSpecifier := '%-16s %-11s %-12s %-10s %-55s';

            _infoHead := format(_formatSpecifier,
                                'ContainerType',
                                'ContainerID',
                                'DatasetCount',
                                'SortWeight',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------------',
                                         '-----------',
                                         '------------',
                                         '----------',
                                         '-------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT ContainerType,
                       ContainerID,
                       DatasetCount,
                       SortWeight,
                       CASE WHEN ContainerType = _preferredContainer THEN 'Use for campaign, organism, and EUS proposal lookup' ELSE '' END As Comment
                FROM Tmp_DatasetCountsByContainerType
                ORDER BY DatasetCount DESC, SortWeight
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.ContainerType,
                                    _previewData.ContainerID,
                                    _previewData.DatasetCount,
                                    _previewData.SortWeight,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        If _preferredContainer = 'Batch' Then
            _representativeBatchID := _containerID;

            -- Use all batches for the dataset count
            SELECT COUNT(RR.dataset_id)
            INTO _datasetCount
            FROM t_requested_run RR
                 INNER JOIN Tmp_BatchIDs
                   ON RR.batch_id = Tmp_BatchIDs.batch_id;

            SELECT campaign
            INTO _campaign
            FROM ( SELECT C.campaign AS Campaign,
                          COUNT(E.exp_id) AS Experiments
                   FROM t_requested_run RR
                        INNER JOIN t_experiments E
                          ON RR.exp_id = E.exp_id
                        INNER JOIN t_campaign C
                          ON E.campaign_id = C.campaign_id
                   WHERE RR.batch_id = _representativeBatchID
                   GROUP BY C.campaign ) StatsQ
            ORDER BY StatsQ.Experiments DESC
            LIMIT 1;

            SELECT organism
            INTO _organism
            FROM ( SELECT Org.organism AS Organism,
                          COUNT(RR.request_id) AS Organisms
                   FROM t_requested_run RR
                        INNER JOIN t_experiments E
                          ON RR.exp_id = E.exp_id
                        INNER JOIN t_organisms Org
                          ON E.organism_id = Org.organism_id
                   WHERE RR.batch_id = _representativeBatchID
                   GROUP BY Org.organism ) StatsQ
            ORDER BY StatsQ.Organisms DESC
            LIMIT 1;

            SELECT eus_proposal_id
            INTO _eusProposalID
            FROM ( SELECT RR.eus_proposal_id AS EUS_Proposal_ID,
                          COUNT(RR.request_id) AS Requests
                   FROM t_requested_run RR
                   WHERE RR.batch_id = _representativeBatchID
                   GROUP BY RR.eus_proposal_id ) StatsQ
            ORDER BY StatsQ.Requests DESC
            LIMIT 1;

        ElsIf _preferredContainer = 'Data Package' Then
            SELECT campaign
            INTO _campaign
            FROM ( SELECT C.campaign AS Campaign,
                          COUNT(E.exp_id) AS Experiments
                   FROM dpkg.V_Data_Package_Dataset_Export DataPkgDatasets
                        INNER JOIN t_dataset DS
                          ON DataPkgDatasets.dataset_id = DS.dataset_id
                        INNER JOIN t_experiments E
                          ON DS.exp_id = E.exp_id
                        INNER JOIN t_campaign C
                          ON E.campaign_id = C.campaign_id
                   WHERE DataPkgDatasets.Data_Package_ID = _dataPackageID
                   GROUP BY C.campaign ) StatsQ
            ORDER BY StatsQ.Experiments DESC
            LIMIT 1;

            SELECT organism
            INTO _organism
            FROM ( SELECT Org.organism AS Organism,
                          COUNT(E.organism_id ) AS Organisms
                   FROM dpkg.V_Data_Package_Dataset_Export DataPkgDatasets
                        INNER JOIN t_dataset DS
                          ON DataPkgDatasets.dataset_id = DS.dataset_id
                        INNER JOIN t_experiments E
                          ON DS.exp_id = E.exp_id
                        INNER JOIN t_organisms Org
                          ON E.organism_id = Org.organism_id
                   WHERE DataPkgDatasets.Data_Package_ID = _dataPackageID
                   GROUP BY Org.organism ) StatsQ
            ORDER BY StatsQ.Organisms DESC
            LIMIT 1;

            SELECT eus_proposal_id
            INTO _eusProposalID
            FROM ( SELECT RR.eus_proposal_id AS EUS_Proposal_ID,
                          COUNT(RR.request_id) AS Requests
                   FROM dpkg.V_Data_Package_Dataset_Export DataPkgDatasets
                        INNER JOIN t_dataset DS
                          ON DataPkgDatasets.dataset_id = DS.dataset_id
                        INNER JOIN t_requested_run RR
                          ON DS.dataset_id = RR.dataset_id
                   WHERE DataPkgDatasets.Data_Package_ID = _dataPackageID
                   GROUP BY RR.eus_proposal_id ) StatsQ
            ORDER BY StatsQ.Requests DESC
            LIMIT 1;

        ElsIf _preferredContainer = 'Experiment Group' Then
            SELECT campaign
            INTO _campaign
            FROM ( SELECT C.campaign AS Campaign,
                          COUNT(E.exp_id) AS Experiments
                   FROM t_experiment_group_members EG
                        INNER JOIN t_experiments E
                          ON EG.exp_id = E.exp_id
                        INNER JOIN t_campaign C
                          ON E.campaign_id = C.campaign_id
                   WHERE EG.group_id = _experimentGroupID
                   GROUP BY C.campaign ) StatsQ
            ORDER BY StatsQ.Experiments DESC
            LIMIT 1;

            SELECT organism
            INTO _organism
            FROM ( SELECT Org.organism AS Organism,
                          COUNT(E.organism_id) AS Organisms
                   FROM t_experiment_group_members EG
                        INNER JOIN t_experiments E
                          ON EG.exp_id = E.exp_id
                        INNER JOIN t_organisms Org
                          ON E.organism_id = Org.organism_id
                   WHERE EG.group_id = _experimentGroupID
                   GROUP BY Org.organism ) StatsQ
            ORDER BY StatsQ.Organisms DESC
            LIMIT 1;

            SELECT eus_proposal_id
            INTO _eusProposalID
            FROM ( SELECT RR.eus_proposal_id AS EUS_Proposal_ID,
                          COUNT(RR.request_id) AS Requests
                   FROM t_experiment_group_members EG
                        INNER JOIN t_experiments E
                          ON EG.exp_id = E.exp_id
                        INNER JOIN t_dataset DS
                          ON E.exp_id = DS.dataset_id
                        INNER JOIN t_requested_run RR
                          ON DS.dataset_id = RR.dataset_id
                   WHERE EG.group_id = _experimentGroupID
                   GROUP BY RR.eus_proposal_id ) StatsQ
            ORDER BY StatsQ.Requests DESC
            LIMIT 1;

        Else
            If Coalesce(_preferredContainer, '') <> '' Then
                RAISE EXCEPTION 'Unrecognized preferred container type: %', _preferredContainer;
            Else
                -- There are no datasets associated with the batches, data packages, or experiment groups specified by the user
                -- This unusual for a data analysis request, but is allowed
            End If;
        End If;

        If _batchDefined And _representativeBatchID Is Null Then
            -- Either _preferredContainer is not 'Batch' or none of the batches has a requested run with a dataset

            SELECT batch_id
            INTO _representativeBatchID
            FROM ( SELECT RR.batch_id As Batch_ID,
                          COUNT(RR.request_id) AS Requests
                   FROM t_requested_run RR
                        INNER JOIN Tmp_BatchIDs
                          ON RR.batch_id = Tmp_BatchIDs.batch_id
                   GROUP BY RR.batch_id ) StatsQ
            ORDER BY Requests Desc
            LIMIT 1;

            If Not FOUND Then
                -- None of the batches has any requested runs
                -- This is highly unlikely, but possible

                SELECT Batch_ID
                INTO _representativeBatchID
                FROM Tmp_BatchIDs
                ORDER BY Batch_ID
                LIMIT 1;
            End If;
        End If;

        If _mode Like 'preview%' Then
            RAISE INFO '';
            RAISE INFO 'Campaign:        %', _campaign;
            RAISE INFO 'Organism:        %', _organism;
            RAISE INFO 'EUS Proposal ID: %', _eusProposalID;
            RAISE INFO 'Dataset Count:   %', _datasetCount;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode Like '%update%' Then

            SELECT state,
                   assigned_personnel
            INTO _currentStateID, _currentAssignedPersonnel
            FROM  t_data_analysis_request
            WHERE request_id = _id;

            -- Cannot update a non-existent entry
            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: request ID % does not exist', _id;
            End If;

            -- Limit who can make changes if in 'closed' state
            -- Users with permission 'DMS_Data_Analysis_Request' can update closed data analysis requests

            If _currentStateID = 4 And Not Exists (SELECT username FROM V_Data_Analysis_Request_User_Picklist WHERE username = _callingUser::citext) Then
                RAISE EXCEPTION 'Changes to entry are not allowed if it is in the "Closed" state';
            End If;

            -- Don't allow change to 'Analysis in Progress' unless someone has been assigned

            If _state::citext = 'Analysis in Progress' And (_assignedPersonnel In ('', 'na')) Then
                RAISE EXCEPTION 'Assigned personnel must be selected when the state is "Analysis in Progress"';
            End If;
        End If;

        If _mode Like '%add%' Then
            -- Make sure the work package is not inactive

            SELECT CCAS.activation_state,
                   CCAS.activation_state_name
            INTO _activationState, _activationStateName
            FROM t_charge_code CC
                 INNER JOIN t_charge_code_activation_state CCAS
                   ON CC.activation_state = CCAS.activation_state
            WHERE CC.charge_code = _workPackage::citext;

            If _activationState >= 3 Then
                RAISE EXCEPTION 'Cannot use inactive work package "%" for a new data analysis request', _workPackageNumber;
            End If;
        End If;

        ---------------------------------------------------
        -- Check for name collisions
        ---------------------------------------------------

        If _mode Like '%add%' Then
            If Exists (SELECT request_name FROM t_data_analysis_request WHERE request_name = _requestName::citext) Then
                RAISE EXCEPTION 'Cannot add: request "%" already exists', _requestName;
            End If;

        ElsIf Exists (SELECT request_name FROM t_data_analysis_request WHERE request_name = _requestName::citext AND request_id <> _id) Then
            RAISE EXCEPTION 'Cannot rename: request "%" already exists', _requestName;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            BEGIN

                INSERT INTO t_data_analysis_request (
                    request_name,
                    analysis_type,
                    requester_username,
                    description,
                    analysis_specifications,
                    comment,
                    representative_batch_id,
                    data_pkg_id,
                    exp_group_id,
                    work_package,
                    requested_personnel,
                    assigned_personnel,
                    priority,
                    reason_for_high_priority,
                    estimated_analysis_time_days,
                    state,
                    state_comment,
                    campaign,
                    organism,
                    eus_proposal_id,
                    dataset_count
                ) VALUES (
                    _requestName,
                    _analysisType,
                    _requesterUsername,
                    _description,
                    _analysisSpecifications,
                    _comment,
                    CASE WHEN _batchDefined           THEN _representativeBatchID ELSE Null END,
                    CASE WHEN _dataPackageDefined     THEN _dataPackageID         ELSE Null END,
                    CASE WHEN _experimentGroupDefined THEN _experimentGroupID     ELSE Null END,
                    _workPackage,
                    _requestedPersonnel,
                    _assignedPersonnel,
                    _priority,
                    _reasonForHighPriority,
                    CASE WHEN _allowUpdateEstimatedAnalysisTime THEN _estimatedAnalysisTimeDays ELSE 0 END,
                    _stateID,
                    _stateComment,
                    _campaign,
                    _organism,
                    _eusProposalID,
                    _datasetCount
                )
                RETURNING request_id
                INTO _id;

            END;

            -- If _callingUser is defined, update entered_by in t_data_analysis_request_updates
            If _callingUser <> '' Then
                CALL public.alter_entered_by_user ('public', 't_data_analysis_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'entered', _enteredByColumnName => 'entered_by', _message => _alterEnteredByMessage);
            End If;

            If _batchDefined Then
                INSERT INTO t_data_analysis_request_batch_ids (request_id, batch_id)
                SELECT _id, batch_id
                FROM Tmp_BatchIDs;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            SELECT estimated_analysis_time_days
            INTO _currentEstimatedAnalysisTimeDays
            FROM t_data_analysis_request
            WHERE request_id = _id;

            UPDATE t_data_analysis_request
            SET request_name                 = _requestName,
                analysis_type                = _analysisType,
                requester_username           = _requesterUsername,
                description                  = _description,
                analysis_specifications      = _analysisSpecifications,
                comment                      = _comment,
                representative_batch_id      = CASE WHEN _batchDefined           THEN _representativeBatchID ELSE Null END,
                data_pkg_id                  = CASE WHEN _dataPackageDefined     THEN _dataPackageID         ELSE Null END,
                exp_group_id                 = CASE WHEN _experimentGroupDefined THEN _experimentGroupID     ELSE Null END,
                work_package                 = _workPackage,
                requested_personnel          = _requestedPersonnel,
                assigned_personnel           = _assignedPersonnel,
                priority                     = _priority,
                reason_for_high_priority     = _reasonForHighPriority,
                estimated_analysis_time_days = CASE WHEN _allowUpdateEstimatedAnalysisTime THEN _estimatedAnalysisTimeDays
                                               ELSE Estimated_Analysis_Time_Days
                                               END,
                State                        = _stateID,
                State_Changed                = CASE WHEN _currentStateID = _stateID THEN State_Changed ELSE CURRENT_TIMESTAMP END,
                Closed                       = CASE WHEN _currentStateID <> 4 AND _stateID = 4 THEN CURRENT_TIMESTAMP ELSE Closed END,
                State_Comment                = _stateComment,
                Campaign                     = _campaign,
                Organism                     = _organism,
                EUS_Proposal_ID              = _eusProposalID,
                Dataset_Count                = _datasetCount
            WHERE request_id = _id;

            -- If _callingUser is defined, update entered_by in t_data_analysis_request_updates
            If _callingUser <> '' Then
                CALL public.alter_entered_by_user ('public', 't_data_analysis_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'entered', _enteredByColumnName => 'entered_by', _message => _alterEnteredByMessage);
            End If;

            If _currentEstimatedAnalysisTimeDays <> _estimatedAnalysisTimeDays And Not _allowUpdateEstimatedAnalysisTime Then
                _msg := 'Not updating estimated analysis time since user does not have permission';
                _message := public.append_to_text(_message, _msg);
            End If;

            If _batchDefined Then
                MERGE INTO t_data_analysis_request_batch_ids AS t
                USING ( SELECT _id As Request_ID, Batch_ID
                        FROM Tmp_BatchIDs
                      ) AS s
                ON (t.batch_id = s.batch_id AND t.request_id = s.request_id)
                WHEN NOT MATCHED THEN
                    INSERT (request_id, batch_id)
                    VALUES (s.request_id, s.batch_id);

                -- Delete rows in t_data_analysis_request_batch_ids where t.Request_ID = _id
                -- but the batch_id is not in Tmp_BatchIDs

                DELETE FROM t_data_analysis_request_batch_ids t
                WHERE t.request_id = _id AND
                      NOT t.batch_id IN (SELECT B.Batch_ID FROM Tmp_BatchIDs B);

            Else
                DELETE FROM t_data_analysis_request_batch_ids
                WHERE request_id = _id;
            End If;

        End If;

        DROP TABLE Tmp_BatchIDs;
        DROP TABLE Tmp_DatasetCountsByContainerType;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Request %s', _exceptionMessage, _requestName);

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

    DROP TABLE IF EXISTS Tmp_BatchIDs;
    DROP TABLE IF EXISTS Tmp_DatasetCountsByContainerType;
END
$$;


ALTER PROCEDURE public.add_update_data_analysis_request(IN _requestname text, IN _analysistype text, IN _requesterusername text, IN _description text, IN _analysisspecifications text, IN _comment text, IN _batchids text, IN _datapackageid integer, IN _experimentgroupid integer, IN _workpackage text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _priority text, IN _reasonforhighpriority text, IN _estimatedanalysistimedays integer, IN _state text, IN _statecomment text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_data_analysis_request(IN _requestname text, IN _analysistype text, IN _requesterusername text, IN _description text, IN _analysisspecifications text, IN _comment text, IN _batchids text, IN _datapackageid integer, IN _experimentgroupid integer, IN _workpackage text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _priority text, IN _reasonforhighpriority text, IN _estimatedanalysistimedays integer, IN _state text, IN _statecomment text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_data_analysis_request(IN _requestname text, IN _analysistype text, IN _requesterusername text, IN _description text, IN _analysisspecifications text, IN _comment text, IN _batchids text, IN _datapackageid integer, IN _experimentgroupid integer, IN _workpackage text, IN _requestedpersonnel text, IN _assignedpersonnel text, IN _priority text, IN _reasonforhighpriority text, IN _estimatedanalysistimedays integer, IN _state text, IN _statecomment text, INOUT _id integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateDataAnalysisRequest';


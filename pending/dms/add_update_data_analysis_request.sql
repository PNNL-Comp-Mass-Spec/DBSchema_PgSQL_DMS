--
CREATE OR REPLACE PROCEDURE public.add_update_data_analysis_request
(
    _requestName text,
    _analysisType text,
    _requesterUsername text,
    _description text,
    _analysisSpecifications text,
    _comment text,
    _batchIDs text = '',
    _dataPackageID int = null,
    _experimentGroupID int = null,
    _workPackage text,
    _requestedPersonnel text,
    _assignedPersonnel text,
    _priority text,
    _reasonForHighPriority text,
    _estimatedAnalysisTimeDays int,
    _state text,
    _stateComment text,
    INOUT _id int,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing Data Analysis Request
**
**      The analysis request must be associated with
**      at least one of the following data containers:
**        - One or more requested run batches
**        - Data package
**        - Experiment group
**
**  Arguments:
**    _batchIDs             Comma-separated list of Requested Run Batch IDs
**    _dataPackageID        Data Package ID; can be null
**    _experimentGroupID    Experiment Group ID; can be null
**    _state                New, On Hold, Analysis in Progress, or Closed
**    _id                   Input/output: Data Analysis Request ID
**    _mode                 'add', 'update', or 'previewadd', 'previewupdate'
**
**  Auth:   mem
**  Date:   03/22/2022 mem - Initial version
**          03/26/2022 mem - Replace parameter _batchID with _batchIDs
**                         - Add parameter _comment
**          08/08/2022 mem - Update State_Changed when the state changes
**          02/13/2023 bcg - Send the correct procedure name to ValidateRequestUsers
**          12/15/2023 mem - Ported to PostgreSQL
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
    _batchDefined int := 0;
    _dataPackageDefined int := 0;
    _experimentGroupDefined int := 0;
    _stateID int := 0;
    _allowNoneWP boolean := false;
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

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _estimatedAnalysisTimeDays := Coalesce(_estimatedAnalysisTimeDays, 1);

    _requestedPersonnel := Trim(Coalesce(_requestedPersonnel, ''));
    _assignedPersonnel := Trim(Coalesce(_assignedPersonnel, 'na'));

    If _assignedPersonnel = '' Then
        _assignedPersonnel := 'na';
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
        -- Validate input fields
        ---------------------------------------------------

        _analysisType := Coalesce(_analysisType, '');

        If char_length(Coalesce(_description, '')) < 1 Then
            RAISE EXCEPTION 'The description field is required';
        End If;

        If _state::citext In ('New', 'Closed') Then
            -- Always clear State Comment when the state is new or closed
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
                          Username = _callingUser
                  ) Then

              _allowUpdateEstimatedAnalysisTime := true;

        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Validate priority
        ---------------------------------------------------

        If _priority <> 'Normal' AND Coalesce(_reasonForHighPriority, '') = '' Then
            RAISE EXCEPTION 'Priority "%" requires justification reason to be provided', _priority;
        End If;

        If Not _priority::citext IN ('Normal', 'High') Then
            RAISE EXCEPTION 'Priority should be Normal or High';
        End If;

        ---------------------------------------------------
        -- Validate analysis type
        ---------------------------------------------------

        If NOT Exists (Select * From t_data_analysis_request_type_name Where analysis_type = _analysisType) Then
            RAISE EXCEPTION 'Invalid data analysis type: %', _analysisType;
        End If;

        ---------------------------------------------------
        -- Resolve Batch IDs, Data Package id, and Experiment Group ID
        -- Require that at least one be valid
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_BatchIDs (
            Batch_ID Int Not Null
        )

        _batchIDs := Trim(Coalesce(_batchIDs, ''));
        _dataPackageID := Coalesce(_dataPackageID, 0);
        _experimentGroupID := Coalesce(_experimentGroupID, 0);

        If char_length(_batchIDs) > 0 Then
            INSERT INTO Tmp_BatchIDs( Batch_ID )
            SELECT Value
            FROM public.parse_delimited_integer_list ( _batchIDs, ',' )
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

            If _insertCount = 1 Then
                _batchDescription := format('batch %s', _batchIDs);
            Else
                _batchDescription := format('batches %s', _batchIDs);
            End If;

            If Not Exists (Select * From t_requested_run_batches WHERE batch_id In (Select batch_id From Tmp_BatchIDs)) Then
                RAISE EXCEPTION 'Could not find entry in database for requested run %', _batchDescription;
            Else
                _batchDefined := 1;
            End If;
        End If;

        If _dataPackageID > 0 Then
            If Not Exists (Select * From dpkg.V_Data_Package_Export WHERE ID = _dataPackageID) Then
                RAISE EXCEPTION 'Could not find entry in database for data package ID "%"', _dataPackageID;
            Else
                _dataPackageDefined := 1;
            End If;
        End If;

        If _experimentGroupID > 0 Then
            If Not Exists (Select * From t_experiment_groups WHERE group_id = _experimentGroupID) Then
                RAISE EXCEPTION 'Could not find entry in database for experiment group ID "%"', _experimentGroupID;
            Else
                _experimentGroupDefined := 1;
            End If;
        End If;

        If _batchDefined = 0 And _dataPackageDefined = 0 And _experimentGroupDefined = 0 Then
            RAISE EXCEPTION 'Must define a requested run batch, data package, and/or experiment group';
        End If;

        ---------------------------------------------------
        -- Force values of some properties for add mode
        ---------------------------------------------------

        If _mode like '%add%' Then
            _state := 'New';
            _assignedPersonnel := 'na';
        End If;

        ---------------------------------------------------
        -- Validate requested and assigned personnel
        -- Names should be in the form 'Last Name, First Name (Username)'
        ---------------------------------------------------

        CALL validate_request_users (
                _requestName,
                'add_update_data_analysis_request',
                _requestedPersonnel => _requestedPersonnel,     -- Output
                _assignedPersonnel => _assignedPersonnel,       -- Output
                _requireValidRequestedPersonnel => false,
                _message => _message,                           -- Output
                _returnCode => _returnCode                      -- Output

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
        WHERE state_name = _state;

        If _stateID = 0 Then
            RAISE EXCEPTION 'No entry could be found in database for state "%"', _state;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        If _batchDefined > 0 And Coalesce(_workPackage, '')::citext In ('', 'na', 'none') Then
            -- Auto-define using requests in the batch(s)
            --
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
                RAISE INFO 'Set Work Package to % based on requests in %', _workPackage, _batchDescription;
            End If;
        End If;

        CALL validate_wp ( _workPackageNumber,
                           _allowNoneWP,
                           _message => _msg,
                           _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'validate_wp: %', _msg;
        End If;

        If Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackage And deactivated = 'Y') Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is deactivated', _workPackage),        _delimiter => '; ', _maxlength => 1024);
        ElsIf Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackage And charge_code_state = 0) Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is likely deactivated', _workPackage), _delimiter => '; ', _maxlength => 1024);
        End If;

        -- Make sure the Work Package is capitalized properly
        --
        SELECT charge_code
        INTO _workPackage
        FROM t_charge_code
        WHERE charge_code = _workPackage

        ---------------------------------------------------
        -- Determine the number of datasets in the batch(s), data package,
        -- and/or experiment group for this Data Analysis Request
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetCountsByContainerType (
            ContainerType text NOT NULL,
            ContainerID   Int Not Null,
            DatasetCount  int NOT Null,
            SortWeight    int NOT NULL,
        )

        If _batchDefined > 0 Then
            INSERT INTO Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
            SELECT 'Batch', RR.batch_id, 2 AS SortWeight, COUNT(RR.request_id) AS DatasetCount
            FROM t_requested_run RR
                 INNER JOIN Tmp_BatchIDs
                   ON RR.batch_id = Tmp_BatchIDs.batch_id
            GROUP BY RR.batch_id
        End If;

        If _dataPackageDefined > 0 Then
            INSERT INTO Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
            SELECT 'Data Package', _dataPackageID, 1 As SortWeight, COUNT(DISTINCT DS.Dataset_ID) AS DatasetCount
            FROM dpkg.V_Data_Package_Dataset_Export DataPkgDatasets
                 INNER JOIN t_dataset DS
                   ON DataPkgDatasets.dataset_id = DS.dataset_id
            WHERE DataPkgDatasets.Data_Package_ID = _dataPackageID
        End If;

        If _experimentGroupDefined > 0 Then
            INSERT INTO Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
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
            SELECT *, Case When ContainerType = _preferredContainer Then 'Use for campaign, organism, and EUS proposal lookup' Else '' End As Comment
            FROM Tmp_DatasetCountsByContainerType
            ORDER BY DatasetCount DESC, SortWeight
        End If;

        If _preferredContainer = 'Batch' Then
            _representativeBatchID := _containerID;

            -- Use all batches for the dataset count
            SELECT COUNT(RR.dataset_id)
            INTO _datasetCount
            FROM t_requested_run RR
                 INNER JOIN Tmp_BatchIDs
                   ON RR.batch_id = Tmp_BatchIDs.batch_id

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

        ElsIf _preferredContainer = 'Data Package'
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

        ElsIf _preferredContainer = 'Experiment Group'
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

        End If;

        If _batchDefined > 0 And _representativeBatchID Is Null Then
            -- Either _preferredContainer is not 'Batch' or none of the batches has a requested run with a dataset
            --
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
                --
                SELECT Batch_ID
                INTO _representativeBatchID
                FROM Tmp_BatchIDs
                ORDER BY Batch_ID
                LIMIT 1;

            End If;
        End If;

        If _mode Like 'preview%' Then
            RAISE INFO 'Campaign: %, Organism: %, EUS Proposal ID: %, Dataset Count: %', _campaign, _organism, _eusProposalID, _datasetCount;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode like '%update%' Then
            -- Cannot update a non-existent entry
            --
            _currentStateID := 0;
            --
            SELECT state,
                   assigned_personnel
            INTO _currentStateID, _currentAssignedPersonnel
            FROM  t_data_analysis_request
            WHERE request_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;

            -- Limit who can make changes if in 'closed' state
            --
            If _currentStateID = 4 AND NOT EXISTS (SELECT * FROM V_Data_Analysis_Request_User_Picklist WHERE username = _callingUser) Then
                RAISE EXCEPTION 'Changes to entry are not allowed if it is in the "Closed" state';
            End If;

            -- Don't allow change to 'Analysis in Progress' unless someone has been assigned
            --
            If _state = 'Analysis in Progress' AND ((_assignedPersonnel = '') OR (_assignedPersonnel = 'na')) Then
                RAISE EXCEPTION 'Assigned personnel must be selected when the state is "Analysis in Progress"';
            End If;
        End If;

        If _mode like '%add%' Then
            -- Make sure the work package is not inactive
            --

            SELECT CCAS.activation_state,
                   CCAS.activation_state_name
            INTO _activationState, _activationStateName
            FROM t_charge_code CC
                 INNER JOIN t_charge_code_activation_state CCAS
                   ON CC.activation_state = CCAS.activation_state
            WHERE (CC.charge_code = _workPackage)

            If _activationState >= 3 Then
                RAISE EXCEPTION 'Cannot use inactive Work Package "%" for a new Data Analysis Request', _workPackage;
            End If;
        End If;

        ---------------------------------------------------
        -- Check for name collisions
        ---------------------------------------------------

        If _mode like '%add%' Then
            If Exists (SELECT * FROM t_data_analysis_request WHERE request_name = _requestName) Then
                RAISE EXCEPTION 'Cannot add: Request "%" already in database', _requestName;
            End If;

        ElsIf EXISTS (SELECT * FROM t_data_analysis_request WHERE request_name = _requestName AND request_id <> _id) Then
            RAISE EXCEPTION 'Cannot rename: Request "%" already in database', _requestName;
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
                    Case When _batchDefined > 0 Then _representativeBatchID Else Null End,
                    Case When _dataPackageDefined > 0 Then _dataPackageID Else Null End,
                    Case When _experimentGroupDefined > 0 Then _experimentGroupID Else Null End,
                    _workPackage,
                    _requestedPersonnel,
                    _assignedPersonnel,
                    _priority,
                    _reasonForHighPriority,
                    Case When _allowUpdateEstimatedAnalysisTime Then _estimatedAnalysisTimeDays Else 0 End,
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
            If char_length(_callingUser) > 0 Then
                CALL alter_entered_by_user ('public', 't_data_analysis_request_updates', 'request_id', _id, _callingUser,
                                            _entryDateColumnName => 'entered', _enteredByColumnName => 'entered_by', _message => _alterEnteredByMessage);
            End If;

            If _batchDefined > 0 Then
                INSERT INTO t_data_analysis_request_batch_ids( request_id, batch_id )
                SELECT _id, batch_id
                FROM Tmp_BatchIDs
            End If;
        End If; -- Add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            SELECT estimated_analysis_time_days
            INTO _currentEstimatedAnalysisTimeDays
            FROM t_data_analysis_request
            WHERE request_id = _id

            BEGIN

                UPDATE t_data_analysis_request
                SET request_name = _requestName,
                    analysis_type = _analysisType,
                    requester_username = _requesterUsername,
                    description = _description,
                    analysis_specifications = _analysisSpecifications,
                    comment = _comment,
                    representative_batch_id = CASE WHEN _batchDefined > 0           THEN _representativeBatchID ELSE Null END,
                    data_pkg_id =             CASE WHEN _dataPackageDefined > 0     THEN _dataPackageID         ELSE Null END,
                    exp_group_id =            CASE WHEN _experimentGroupDefined > 0 THEN _experimentGroupID     ELSE Null END,
                    work_package = _workPackage,
                    requested_personnel = _requestedPersonnel,
                    assigned_personnel = _assignedPersonnel,
                    priority = _priority,
                    reason_for_high_priority = _reasonForHighPriority,
                    estimated_analysis_time_days = CASE WHEN _allowUpdateEstimatedAnalysisTime THEN _estimatedAnalysisTimeDays
                                                   ELSE Estimated_Analysis_Time_Days
                                                   END,
                    State = _stateID,
                    State_Changed = Case When _currentStateID = _stateID Then State_Changed Else CURRENT_TIMESTAMP End,
                    State_Comment = _stateComment,
                    Campaign = _campaign,
                    Organism = _organism,
                    EUS_Proposal_ID = _eusProposalID,
                    Dataset_Count = _datasetCount
                WHERE ID = _id;

            END;

            -- If _callingUser is defined, update entered_by in t_data_analysis_request_updates
            If char_length(_callingUser) > 0 Then
                CALL alter_entered_by_user ('public', 't_data_analysis_request_updates', 'request_id', _id, _callingUser,
                                            _entryDateColumnName => 'entered', _enteredByColumnName => 'entered_by', _message => _alterEnteredByMessage);
            End If;

            If _currentEstimatedAnalysisTimeDays <> _estimatedAnalysisTimeDays And Not _allowUpdateEstimatedAnalysisTime Then
                _msg := 'Not updating estimated analysis time since user does not have permission';
                _message := public.append_to_text(_message, _msg, _delimiter => '; ', _maxlength => 1024);
            End If;

            If _batchDefined > 0 Then
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
                --
                DELETE FROM t_data_analysis_request_batch_ids t
                WHERE t.request_id = _id AND
                      NOT t.batch_id IN (SELECT B.Batch_ID FROM Tmp_BatchIDs B);

            Else
                DELETE FROM t_data_analysis_request_batch_ids
                WHERE request_id = _id;
            End If;

        End If; -- update mode

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

COMMENT ON PROCEDURE public.add_update_data_analysis_request IS 'AddUpdateDataAnalysisRequest';

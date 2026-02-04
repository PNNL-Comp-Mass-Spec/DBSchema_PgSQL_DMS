--
-- Name: create_dataset_svc_center_report(timestamp without time zone, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.create_dataset_svc_center_report(IN _enddate timestamp without time zone, IN _daycount integer DEFAULT 365, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a new service center usage report, adding rows to svc.t_service_use_report
**
**      Looks for datasets that meet the following conditions
**      - Dataset state 3 (Complete)
**      - Acquisition start time on or before the end date (acquired any time on the end date)
**      - Service center report state of 2 (Need to submit to service center) or 4 (Need to refund to service center)
**      - Service type ID between 100 and 113
**      - Dataset rating is not -10, -7, -6, -5, -4, -2, -1, 6, or 7 (Unreviewed, Rerun, Not Released, No Data, Exclude from Service Center, or Method Development)
**
**      Added datasets will have their service center report state changed to 3 (Submitting to service center) or 5 (Refunded to service center)
**
**      See also column svc_center_report_state_id in table t_dataset and table t_dataset_svc_center_report_state
**
**  Arguments:
**    _endDate          Ending date for dataset creation (time of day is ignored)
**    _dayCount         Number of days to look back for new DMS datasets
**    _infoOnly         When true, show the datasets that would be added to the new service center usage report
**    _showDebug        When true, show additional status messages; auto-set to true if _infoOnly is true
**    _message          Status message
**    _returnCode       Return code
**
**  Example usage:
**      CALL create_dataset_svc_center_report ('2025-07-16', _infoOnly => true);
**      CALL create_dataset_svc_center_report ('2025-07-16', _dayCount => 365, _infoOnly => true);
**      CALL create_dataset_svc_center_report ('2025-07-16', 365, _infoOnly => true);
**      CALL create_dataset_svc_center_report (CURRENT_TIMESTAMP::date - Interval '1 day', _dayCount => 365, _infoOnly => true);
**      CALL create_dataset_svc_center_report ('2024-08-13', 5, _infoOnly => false, _showDebug => true);
**
**  Auth:   mem
**  Date:   07/22/2025 mem - Initial release
**          08/06/2025 mem - Update service type IDs to be between 100 and 113 instead of 2 and 9
**                         - For MALDI, use service type ID 104
**          08/07/2025 mem - Table t_service_cost_rate now has 9 service types per cost group
**                         - Determine the total rate per run using column total_per_run in t_service_cost_rate
**                         - Exclude datasets that do not have a requested run with a work package
**          08/20/2025 mem - Reference schema svc instead of cc
**          08/21/2025 mem - Rename procedure
**                         - Use new service center report state column names
**          08/29/2025 mem - Use doe_burdened_rate_per_run instead of total_per_run
**          09/10/2025 mem - Change ticket number from EndDate_DatasetID to EntryID
**          09/17/2025 mem - Exclude datasets with rating -10, -5, -4, -2, -1, 6, or 7
**          09/19/2025 mem - Use renamed column requester_employee_id in t_service_use_report
**                         - Use 'D3E154' for the requester employee ID
**          09/24/2025 mem - Exclude datasets with rating -7 (Rerun, superseded) or -6 (Rerun, good data)
**          10/02/2025 mem - Filter datasets on acquisition start time instead of DMS creation time
**                         - Assure that start date is no earlier than 2025-10-01 (the official start date of the service center)
**          10/29/2025 mem - Round transaction units for MALDI datasets to the nearest tenth of an hour
**          02/03/2026 mem - Change acq_length_minutes to numeric
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _currentLocation text := 'Start';
    _startDate date;
    _beginningOfNextDay date;
    _datasetCount int;
    _logMsg text;
    _matchLoc int;
    _activeCostGroups int;
    _costGroupID int;
    _serviceTypeIDs int;
    _minServiceTypeID int;
    _maxServiceTypeID int;
    _affectedCount int;
    _requesterUsername citext;
    _reportID int;

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
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _currentLocation := 'Validate inputs';

        _endDate    := Coalesce(_endDate, CURRENT_TIMESTAMP::date - Interval '1 day');
        _dayCount   := Coalesce(_dayCount, 7);
        _infoOnly   := Coalesce(_infoOnly, false);
        _showDebug  := Coalesce(_showDebug, false);
        _logErrors  := true;

        If _infoOnly Then
            RAISE INFO '';
            _showDebug := true;
        End If;

        ---------------------------------------------------
        -- Determine the date range
        ---------------------------------------------------

        _currentLocation := 'Determine the date range';

        -- Round down _endDate to the start of the given day
        _endDate := _endDate::date;

        -- Cache the start of the next day after the end date
        _beginningOfNextDay := _endDate + Interval '1 day';

        -- Determine the starting day
        _startDate := _endDate - make_interval(days => _daycount);

        If _startDate < '2025-10-01'::date Then
            _startDate := '2025-10-01'::date;
        End If;

        If _showDebug Then
            RAISE INFO 'Start date:              %', _startDate;
            RAISE INFO 'End date:                %', _endDate::date;
            RAISE INFO 'Next day after end date: %', _beginningOfNextDay;
            RAISE INFO '';
        End If;

        ---------------------------------------------------
        -- Find the service cost group that is currently active
        ---------------------------------------------------

        SELECT COUNT(*) AS active_cost_groups,
               MAX(cost_group_id) AS most_recent_cost_group
        INTO _activeCostGroups, _costGroupID
        FROM svc.t_service_cost_group
        WHERE service_cost_state_id = 2;

        If _activeCostGroups = 0 Then
            _message := 'Active cost group not found in svc.t_service_cost_group (service_cost_state_id = 2); unable to proceed';
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_svc_center_report');
            End If;

            _returnCode = 'U5200';
            RETURN;
        ElsIf _activeCostGroups > 1 Then
            _message := 'There are multiple active cost groups in svc.t_service_cost_group (service_cost_state_id = 2); unable to proceed';
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_svc_center_report');
            End If;

            _returnCode = 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Assure that table t_service_cost_rate has a row for each of the standard service type IDs
        ---------------------------------------------------

        SELECT COUNT(*),
               MIN(service_type_id),
               MAX(service_type_id)
        INTO _serviceTypeIDs, _minServiceTypeID, _maxServiceTypeID
        FROM svc.t_service_cost_rate
        WHERE cost_group_id = _costGroupID;

        If _serviceTypeIDs <> 9 Then
            _message := format('Table svc.t_service_cost_rate has %s service type IDs, but it should have 9; unable to proceed', _serviceTypeIDs);
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_svc_center_report');
            End If;

            _returnCode = 'U5202';
            RETURN;
        ElsIf _minServiceTypeID <> 100 Or _maxServiceTypeID <> 113 Then
            _message := format('Service type IDs in svc.t_service_cost_rate span %s to %s, but they should be 100 to 113; unable to proceed', _minServiceTypeID, _maxServiceTypeID);
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_svc_center_report');
            End If;

            _returnCode = 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Look for datasets with a service center report state of 0 (Undefined) that can be changed to state 2 (Need to submit to service center)
        -- Exclude datasets that do not have a valid work package ('', 'none', 'na', n/a', '(lookup)')
        ---------------------------------------------------

        _currentLocation := 'Change service center report state from 0 to 2 for eligible datasets';

        CREATE TEMP TABLE Tmp_Datasets_to_Update (
            dataset_id int NOT NULL PRIMARY KEY
        );

        If _infoOnly Then
            INSERT INTO Tmp_Datasets_to_Update (dataset_id)
            SELECT DS.dataset_id
            FROM t_dataset DS
                 INNER JOIN t_requested_run RR
                   ON DS.dataset_id = RR.dataset_id
            WHERE DS.dataset_state_id = 3 AND                                               -- Dataset state 3: Complete
                  DS.acq_time_start >= _startDate AND
                  DS.acq_time_start <  _beginningOfNextDay AND
                  NOT DS.dataset_rating_id IN (-10, -7, -6, -5, -4, -2, -1, 6, 7) AND       -- Dataset rating is not Unreviewed, Rerun (Superseded), Rerun (Good Data) Not Released, No Data, Exclude from Service Center, or Method Development
                  DS.svc_center_report_state_id = 0 AND                                     -- Service center report state 0: Undefined
                  DS.service_type_id BETWEEN 100 AND 113 AND                                -- Servce type ID not 0 (Undefined), 1 (None), or 25 (Ambiguous)
                  NOT Trim(Coalesce(RR.work_package, '')) IN ('', 'none', 'na', 'n/a', '(lookup)');
            --
            GET DIAGNOSTICS _datasetCount = ROW_COUNT;

            If _datasetCount = 0 Then
                RAISE INFO 'Every dataset acquired between "% 12:00 am" and "% 11:59:59 pm" already has a non-zero service center report state', _startDate, _endDate::date;
            Else
                RAISE INFO 'Would change the service center report state from 0 (Undefined) to 2 (Need to submit to service center) for % %',
                           _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets');
            End If;
        Else
            UPDATE t_dataset
            SET svc_center_report_state_id = 2
            FROM (SELECT DS.dataset_id
                  FROM t_dataset DS
                       INNER JOIN t_requested_run RR
                         ON DS.dataset_id = RR.dataset_id
                  WHERE DS.dataset_state_id = 3 AND                                             -- Dataset state 3: Complete
                        DS.acq_time_start >= _startDate AND
                        DS.acq_time_start <  _beginningOfNextDay AND
                        NOT DS.dataset_rating_id IN (-10, -7, -6, -5, -4, -2, -1, 6, 7) AND     -- Dataset rating is not Unreviewed, Rerun (Superseded), Rerun (Good Data) Not Released, No Data, Exclude from Service Center, or Method Development
                        DS.svc_center_report_state_id = 0 AND                                   -- Service center report state 0: Undefined
                        DS.service_type_id BETWEEN 100 AND 113 AND                              -- Servce type ID not 0 (Undefined), 1 (None), or 25 (Ambiguous); limit to the range of valid IDs, for safety
                        NOT Trim(Coalesce(RR.work_package, '')) IN ('', 'none', 'na', 'n/a', '(lookup)')
                  ) FilterQ
            WHERE t_dataset.dataset_id = FilterQ.dataset_id;
            --
            GET DIAGNOSTICS _datasetCount = ROW_COUNT;

            If _datasetCount = 0 Then
                If _showDebug Then
                    RAISE INFO 'Every dataset acquired between "% 12:00 am" and "% 11:59:59 pm" already has a non-zero service center report state (or an undefined work package)', _startDate, _endDate::date;
                End If;
            Else
                _logMsg := format('Changed service center report state from 0 to 2 for %s %s acquired between "%s 12:00 am" and "%s 11:59:59 pm"',
                                  _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets'),
                                  _startDate, _endDate::date);

                If _showDebug Then
                    RAISE INFO '%', _logMsg;
                End If;

                CALL post_log_entry('Normal', _logMsg, 'create_dataset_svc_center_report');
            End If;
        End If;

        ---------------------------------------------------
        -- Populate a temporary table with datasets to add to the service center report
        ---------------------------------------------------

        _currentLocation := 'Populate a temporary table with datasets to add to the report';

        CREATE TEMP TABLE Tmp_Datasets_to_Add (
            dataset_id                  int NOT NULL PRIMARY KEY,
            dataset                     citext NOT NULL,
            service_type_id             smallint NOT NULL,
            svc_center_report_state_id  smallint NOT NULL,
            acq_length_minutes          numeric NOT NULL DEFAULT 0,
            charge_code                 citext DEFAULT '' NOT NULL,
            transaction_date            timestamp,
            transaction_units           real,
            transaction_cost_est        real,
            is_held                     citext DEFAULT 'N' NOT NULL,
            comment                     citext DEFAULT ''
        );

        INSERT INTO Tmp_Datasets_to_Add (dataset_id, dataset, service_type_id, svc_center_report_state_id, acq_length_minutes, charge_code, transaction_date, comment)
        SELECT dataset_id,
               dataset,
               service_type_id,
               svc_center_report_state_id,
               CASE WHEN acq_time_start IS NULL OR acq_length_minutes <= 0
                    THEN Coalesce(req_run_acq_length_minutes, 0)
                    ELSE acq_length_minutes
               END,
               charge_code,
               transaction_date,
               dataset AS comment
        FROM ( SELECT DS.dataset_id,
                      DS.dataset,
                      DS.service_type_id,
                      DS.svc_center_report_state_id,
                      DS.acq_time_start,
                      DS.acq_length_minutes,
                      Round(extract(epoch FROM RR.request_run_finish - RR.request_run_start) / 60.0, 2)::numeric AS req_run_acq_length_minutes,
                      RR.work_package AS charge_code,
                      DS.acq_time_start AS transaction_date
               FROM t_dataset DS
                    LEFT OUTER JOIN t_requested_run RR
                      ON DS.dataset_id = RR.dataset_id
                    LEFT OUTER JOIN Tmp_Datasets_to_Update DTU
                      ON DS.dataset_id = DTU.dataset_id
               WHERE DS.dataset_state_id = 3 AND
                     DS.acq_time_start >= _startDate AND
                     DS.acq_time_start <  _beginningOfNextDay AND
                     (DS.svc_center_report_state_id IN (2, 4) OR                -- 2: Need to submit, 4: Need to refund
                     _infoOnly AND NOT DTU.dataset_id IS NULL                   -- Also include datasets that would have had svc_center_report_state_id auto-updated from 0 to 2 (see 'Change service center report state' above)
                     )
             ) FilterQ
        ORDER BY dataset_id;
        --
        GET DIAGNOSTICS _datasetCount = ROW_COUNT;

        If _datasetCount = 0 Then
            RAISE INFO 'Did not find any datasets acquired between "% 12:00 am" and "% 11:59:59 pm" with a service center report state of 2 or 4',
                       -- to_char(_startDate, 'yyyy-mm-dd'),
                       -- to_char(_beginningOfNextDay, 'yyyy-mm-dd');
                       _startDate, _endDate::date;

            DROP TABLE Tmp_Datasets_to_Update;
            DROP TABLE Tmp_Datasets_to_Add;
            RETURN;
        End If;

        _logMsg = format('a new service center report using %s %s that %s a service center report state of 2 (Need to submit) or 4 (Need to refund), '
                       'filtering on dataset_state_id = 3 and acquisition start time between "%s 12:00 am" and "%s 11:59:59 pm"',
                       _datasetCount,
                       check_plural(_datasetCount, 'dataset', 'datasets'),
                       check_plural(_datasetCount, 'has', 'have'),
                       _startDate, _endDate::date);

        If _infoOnly Then
            -- Would create a new service center report using 1473 datasets that have a service center report state of 2 (Need to submit) or 4 (Need to refund), filtering on dataset_state_id = 3 and acquisition start time between 2024-07-30 and 2025-07-31
            _logMsg := format('Would create %s', _logMsg);

            RAISE INFO '%', _logMsg;

            _matchLoc = Position('filtering' IN _logMsg);

            If _matchLoc > 1 Then
                _message := Left(_logMsg, _matchLoc - 3);
            Else
                _message := _logMsg;
            End If;

            DROP TABLE Tmp_Datasets_to_Update;
            DROP TABLE Tmp_Datasets_to_Add;
            RETURN;
        End If;

        If _showDebug Then
            -- Creating a new service center report using 1473 datasets that have a service center report state of 2 (Need to submit) or 4 (Need to refund), filtering on dataset_state_id = 3 and acquisition start time between 2024-07-30 and 2025-07-31
            RAISE INFO 'Creating %', _logMsg;
        End If;

        ---------------------------------------------------
        -- Populate columns transaction_units and transaction_cost_est in Tmp_Datasets_to_Add
        --
        -- For MALDI datasets, the transaction_unit is the run length, in hours, rounded to the nearest tenth of an hour (minimum value 0.1)
        -- For non-MALDI datasets, the transaction unit is one
        --
        -- Column transaction_cost_est is the estimated cost of the run, determined by multiplying the transaction_units by total_rate_per_run
        ---------------------------------------------------

        -- First populate column transaction_units
        --
        UPDATE Tmp_Datasets_to_Add DS
        SET transaction_units = CASE WHEN DS.service_type_id = 104
                                     THEN    -- MALDI dataset, use acq_length_hours for the transaction units
                                         CASE WHEN (DS.acq_length_minutes / 60.0)::numeric(1000, 1) < 0.1
                                              THEN 0.1
                                              ELSE (DS.acq_length_minutes / 60.0)::numeric(1000, 1)
                                         END
                                     ELSE 1  -- Non-MALDI datasets use 1 for the transaction unit
                                END
        FROM ( SELECT service_type_id,
                      doe_burdened_rate_per_run AS total_rate_per_run
               FROM svc.t_service_cost_rate
               WHERE cost_group_id = _costGroupID
             ) CR
        WHERE DS.service_type_id = CR.service_type_id;
        --
        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Defined the transaction_units for % % in the service center report', _affectedCount, check_plural(_affectedCount, 'dataset', 'datasets');
        End If;

        -- Now that transaction_units is defined, populate transaction_units_est
        --
        UPDATE Tmp_Datasets_to_Add DS
        SET transaction_cost_est = (transaction_units * CR.total_rate_per_run)::numeric(1000, 2)::real
        FROM ( SELECT service_type_id,
                      doe_burdened_rate_per_run AS total_rate_per_run
               FROM svc.t_service_cost_rate
               WHERE cost_group_id = _costGroupID
             ) CR
        WHERE DS.service_type_id = CR.service_type_id;

        /*
            -- The following query can be helpful when manually replicating the population of Tmp_Datasets_to_Add

            SELECT ComputeQ.dataset_id,
                   ComputeQ.service_type_id,
                   ComputeQ.total_rate_per_run,
                   ComputeQ.transaction_units,
                   (ComputeQ.transaction_units * ComputeQ.total_rate_per_run)::numeric(1000, 2)::real AS transaction_cost_est
            FROM ( SELECT DS.dataset_id,
                          DS.service_type_id,
                          CR.total_rate_per_run,
                          CASE WHEN DS.service_type_id = 104
                               THEN    -- MALDI dataset, use acq_length_hours for the transaction units
                                   CASE WHEN (DS.acq_length_minutes / 60.0)::numeric(1000, 1) < 0.1
                                        THEN 0.1
                                        ELSE (DS.acq_length_minutes / 60.0)::numeric(1000, 1)
                                   END
                               ELSE 1  -- Non-MALDI datasets use 1 for the transaction unit
                          END AS transaction_units
                   FROM Tmp_Datasets_to_Add DS
                        INNER JOIN ( SELECT service_type_id,
                                            doe_burdened_rate_per_run AS total_rate_per_run
                                     FROM svc.t_service_cost_rate
                                     WHERE cost_group_id = 101       -- This is the value for _costGroupID in FY26
                                   ) CR
                         ON DS.service_type_id = CR.service_type_id
                 ) ComputeQ
            ORDER BY ComputeQ.service_type_id, ComputeQ.dataset_id;
        */

        ---------------------------------------------------
        -- Change the transaction units to a negative value for any datasets with svc_center_report_state_id = 4 (Need to refund to service center)
        ---------------------------------------------------

        UPDATE Tmp_Datasets_to_Add
        SET transaction_units = -ABS(transaction_units)
        WHERE svc_center_report_state_id = 4;

        ---------------------------------------------------
        -- Define the employee ID (username) to associate with the report
        ---------------------------------------------------

        _requesterUsername := 'D3E154';

        If Not Exists (SELECT user_id FROM t_users WHERE username = _requesterUsername AND status = 'Active') Then
            _requesterUsername := CURRENT_USER;
        End If;

        ---------------------------------------------------
        -- Create a new service center report, settings its state to 1=New
        ---------------------------------------------------

        _currentLocation := 'Create a new service center report';

        INSERT INTO svc.t_service_use_report (start_time, end_time, requester_employee_id, report_state_id, cost_group_id)
        VALUES (_startDate, _beginningOfNextDay - Interval '1 millisecond', _requesterUsername, 1, _costGroupID)
        RETURNING report_id
        INTO _reportID;

        ---------------------------------------------------
        -- Add the datasets to table svc.t_service_use
        ---------------------------------------------------

        _currentLocation := format('Add datasets to the new service center report (Report_ID: %s)', _reportID);

        If _showDebug Then
            RAISE INFO '%', _currentLocation;
        End If;

        INSERT INTO svc.t_service_use (report_id, ticket_number,
                                       charge_code, service_type_id,
                                       transaction_date, transaction_units,
                                       is_held, comment, dataset_id,
                                       transaction_cost_est)
        SELECT _reportID,
               format('%s_%s', to_char(_endDate, 'yyyy-mm-dd'), dataset_id) AS ticket_number,  -- We initially define ticket number as EndDate_DatasetID, but it is changed to EntryID below
               charge_code,
               service_type_id,
               transaction_date,
               transaction_units,
               is_held,
               comment,
               dataset_id,
               transaction_cost_est
        FROM Tmp_Datasets_to_Add;
        --
        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Added % % to table t_service_use', _affectedCount, check_plural(_affectedCount, 'row', 'rows');
        End If;

        ---------------------------------------------------
        -- Define ticket number as the Entry_ID in t_service_use
        -- This is required because ticket numbers are limited to seven characters
        ---------------------------------------------------

        UPDATE svc.t_service_use
        SET ticket_number = entry_id::text
        WHERE report_id = _reportID;

        ---------------------------------------------------
        -- Update the service center report state for the datasets in the report
        -- The new state will be either 3 (Submitting to service center) or 5 (Refunding to service center)
        ---------------------------------------------------

        _currentLocation := 'Update service center report state ID for the datasets in the report';

        UPDATE t_dataset DS
        SET svc_center_report_state_id = CASE WHEN LookupQ.svc_center_report_state_id = 4
                                         THEN 5        -- Refunding  to service center
                                         ELSE 3        -- Submitting to service center
                                 END
        FROM ( SELECT dataset_id,
                      svc_center_report_state_id
               FROM Tmp_Datasets_to_Add
             ) LookupQ
        WHERE DS.dataset_id = LookupQ.dataset_id;
        --
        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Update svc_center_report_state_id for % % in table t_dataset', _affectedCount, check_plural(_affectedCount, 'dataset', 'datasets');
        End If;

        ---------------------------------------------------
        -- Change the service center report state to 2 = Active
        ---------------------------------------------------

        _currentLocation := 'Change the service center report state to 2 = active';

        UPDATE svc.t_service_use_report
        SET report_state_id = 2
        WHERE report_id = _reportID;

        ---------------------------------------------------
        -- Log info about the new report
        ---------------------------------------------------

        _logMsg := format('Created service center report %s using %s %s',
                          _reportID, _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets'));

        If _showDebug Then
            RAISE INFO '%', _logMsg;
        End If;

        CALL post_log_entry('Normal', _logMsg, 'create_dataset_svc_center_report');

        _message := _logMsg;

        DROP TABLE Tmp_Datasets_to_Update;
        DROP TABLE Tmp_Datasets_to_Add;
        RETURN;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Current location: %s', _exceptionMessage, _currentLocation);

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

    DROP TABLE IF EXISTS Tmp_Datasets_to_Update;
    DROP TABLE IF EXISTS Tmp_Datasets_to_Add;
END
$$;


ALTER PROCEDURE public.create_dataset_svc_center_report(IN _enddate timestamp without time zone, IN _daycount integer, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


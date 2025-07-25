--
-- Name: create_dataset_cc_report(timestamp without time zone, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.create_dataset_cc_report(IN _enddate timestamp without time zone, IN _daycount integer DEFAULT 365, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a new cost center usage report, adding rows to cc.t_service_use_report
**
**      Looks for datasets that meet the following conditions
**      - Dataset state 3 (Complete)
**      - Created on or before the end date (created any time on the end date)
**      - Cost center report state of 2 (Need to submit to cost center) or 4 (Need to refund to cost center)
**
**      Added datasets will have their cost center report state changed to 3 (Submitted to cost center) or 5 (Refunded to cost center)
**
**      See also column cc_report_state_id in table t_dataset and table t_dataset_cc_report_state
**
**  Arguments:
**    _endDate          Ending date for dataset creation (time of day is ignored)
**    _dayCount         Number of days to look back for new DMS datasets
**    _infoOnly         When true, show the datasets that would be added to the new cost center usage report
**    _showDebug        When true, show additional status messages; auto-set to true if _infoOnly is true
**    _message          Status message
**    _returnCode       Return code
**
**  Example Usage:
**      CALL create_dataset_cc_report('2025-07-16', _infoOnly => true);
**      CALL create_dataset_cc_report('2025-07-16', _dayCount => 365, _infoOnly => true);
**      CALL create_dataset_cc_report('2025-07-16', 365, _infoOnly => true);
**      CALL create_dataset_cc_report(CURRENT_TIMESTAMP::date - INTERVAL '1 day', _dayCount => 365, _infoOnly => true);
**      CALL create_dataset_cc_report('2024-08-13', 5, _infoOnly => false, _showDebug => true);
**
**  Auth:   mem
**  Date:   07/22/2025 mem - Initial release
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
    _activeCostGroups int;
    _costGroupID int;
    _serviceTypeIDs int;
    _minServiceTypeID int;
    _maxServiceTypeID int;
    _affectedCount int;
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

        _endDate    := Coalesce(_endDate, CURRENT_TIMESTAMP::date - INTERVAL '1 day');
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
        _beginningOfNextDay := _endDate + INTERVAL '1 day';

        -- Determine the starting day
        _startDate := _endDate - make_interval(days => _daycount);

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
        FROM cc.t_service_cost_group
        WHERE service_cost_state_id = 2;

        If _activeCostGroups = 0 Then
            _message := 'Active cost group not found in cc.t_service_cost_group (service_cost_state_id = 2); unable to proceed';
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_cc_report');
            End If;

            _returnCode = 'U5200';
            RETURN;
        ElsIf _activeCostGroups > 1 Then
            _message := 'There are multiple active cost groups in cc.t_service_cost_group (service_cost_state_id = 2); unable to proceed';
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_cc_report');
            End If;

            _returnCode = 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Assure that table t_service_cost_rate has a row for each of standard service type IDs
        ---------------------------------------------------

        SELECT COUNT(*),
               MIN(service_type_id),
               MAX(service_type_id)
        INTO _serviceTypeIDs, _minServiceTypeID, _maxServiceTypeID
        FROM cc.t_service_cost_rate
        WHERE cost_group_id = _costGroupID;

        If _serviceTypeIDs <> 8 Then
            _message := format('Table cc.t_service_cost_rate has %s service type IDs, but it should have 8; unable to proceed', _serviceTypeIDs);
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_cc_report');
            End If;

            _returnCode = 'U5202';
            RETURN;
        ElsIf _minServiceTypeID <> 2 Or _maxServiceTypeID <> 9 Then
            _message := format('Service type IDs in cc.t_service_cost_rate span %s to %s, but they should be 2 to 9; unable to proceed', _minServiceTypeID, _maxServiceTypeID);
            RAISE WARNING '%', _infoOnly;

            If Not _infoOnly Then
                CALL post_log_entry('Error', _message, 'create_dataset_cc_report');
            End If;

            _returnCode = 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Look for datasets with a cost center report state of 0 (Undefined) that can be changed to state 2 (Need to submit to cost center)
        ---------------------------------------------------

        _currentLocation := 'Change cost center report state from 0 to 2 for eligible datasets';

        If _infoOnly Then
            SELECT COUNT(*) AS Datasets
            INTO _datasetCount
            FROM t_dataset
            WHERE dataset_state_id = 3 AND                                  -- Dataset state 3: Complete
                  created BETWEEN _startDate AND _beginningOfNextDay AND
                  cc_report_state_id = 0 AND                                -- Cost center report state 0: Undefined
                  service_type_id BETWEEN 2 AND 9;                          -- Servce type ID not 0 (Undefined), 1 (None), or 25 (Ambiguous)

            If _datasetCount = 0 Then
                RAISE INFO 'Every dataset created between % and % already has a non-zero cost center report state', _startDate, _beginningOfNextDay;
            Else
                RAISE INFO 'Would change the cost center report state from 0 (Undefined) to 2 (Need to submit to cost center) for % %',
                           _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets');
            End If;
        Else
            UPDATE t_dataset
            SET cc_report_state_id = 2
            FROM (SELECT dataset_id
                  FROM t_dataset
                  WHERE dataset_state_id = 3 AND                                  -- Dataset state 3: Complete
                        created BETWEEN _startDate AND _beginningOfNextDay AND
                        cc_report_state_id = 0 AND                                -- Cost center report state 0: Undefined
                        service_type_id BETWEEN 2 AND 9                           -- Servce type ID not 0 (Undefined), 1 (None), or 25 (Ambiguous); limit to the range of valid IDs, for safety
                  ) FilterQ
            WHERE t_dataset.dataset_id = FilterQ.dataset_id;

            GET DIAGNOSTICS _datasetCount = ROW_COUNT;

            If _datasetCount = 0 Then
                If _showDebug Then
                    RAISE INFO 'Every dataset created between % and % already has a non-zero cost center report state', _startDate, _beginningOfNextDay;
                End If;
            Else
                _logMsg := format('Changed cost center report state from 0 to 2 for %s %s created between %s and %s',
                                  _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets'),
                                  _startDate, _beginningOfNextDay);

                If _showDebug Then
                    RAISE INFO '%', _logMsg;
                End If;

                CALL post_log_entry('Normal', _logMsg, 'create_dataset_cc_report');
            End If;
        End If;

        ---------------------------------------------------
        -- Populate a temporary table with datasets to add to the cost center report
        ---------------------------------------------------

        _currentLocation := 'Populate a temporary table with datasets to add to the report';

        CREATE TEMP TABLE Tmp_Datasets_to_Add (
            dataset_id          int NOT NULL PRIMARY KEY,
            dataset             citext NOT NULL,
            service_type_id     smallint NOT NULL,
            cc_report_state_id  smallint NOT NULL,
            acq_length_minutes  int NOT NULL DEFAULT 0,
            charge_code         citext DEFAULT '' NOT NULL,
            transaction_date    timestamp,
            transaction_units   real,
            is_held             citext DEFAULT 'N' NOT NULL,
            comment             citext DEFAULT ''
        );

        INSERT INTO Tmp_Datasets_to_Add (dataset_id, dataset, service_type_id, cc_report_state_id, acq_length_minutes, charge_code, transaction_date, comment)
        SELECT dataset_id,
               dataset,
               service_type_id,
               cc_report_state_id,
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
                      DS.cc_report_state_id,
                      DS.acq_time_start,
                      DS.acq_length_minutes,
                      Round(extract(epoch FROM RR.request_run_finish - RR.request_run_start) / 60.0, 0)::int AS req_run_acq_length_minutes,
                      RR.work_package AS charge_code,
                      Coalesce(DS.acq_time_start, DS.Created) AS transaction_date
               FROM t_dataset DS
                    LEFT OUTER JOIN t_requested_run RR
                      ON DS.dataset_id = RR.dataset_id
               WHERE DS.dataset_state_id = 3 AND
                     DS.created BETWEEN _startDate AND _beginningOfNextDay AND
                     DS.cc_report_state_id IN (2, 4)
             ) FilterQ
        ORDER BY dataset_id;

        GET DIAGNOSTICS _datasetCount = ROW_COUNT;

        If _datasetCount = 0 Then
            RAISE INFO 'Did not find any datasets created between % and % with a cost center report state of 2 or 4',
                       -- to_char(_startDate, 'yyyy-mm-dd'),
                       -- to_char(_beginningOfNextDay, 'yyyy-mm-dd');
                       _startDate, _beginningOfNextDay;

            DROP TABLE Tmp_Datasets_to_Add;
            RETURN;
        End If;

        _logMsg = format('a new cost center report for %s %s that %s a cost center report state of 2 (Need to submit) or 4 (Need to refund), '
                       'filtering on dataset_state_id = 3 and dataset created between %s and %s',
                       _datasetCount,
                       check_plural(_datasetCount, 'dataset', 'datasets'),
                       check_plural(_datasetCount, 'has', 'have'),
                       _startDate, _beginningOfNextDay);

        If _infoOnly Then
            RAISE INFO 'Would create %', _logMsg;
            DROP TABLE Tmp_Datasets_to_Add;
            RETURN;
        End If;

        If _showDebug Then
            RAISE INFO 'Creating %', _logMsg;
        End If;

        ---------------------------------------------------
        -- Populate column transaction_units in Tmp_Datasets_to_Add
        --
        -- For MALDI datasets, use acq_length_hours * total_rate_per_run
        -- For non-MALDI datasets, simply use total_rate_per_run
        ---------------------------------------------------

        UPDATE Tmp_Datasets_to_Add DS
        SET transaction_units = CASE WHEN DS.service_type_id = 9
                                     THEN (DS.acq_length_minutes / 60.0 * CR.total_rate_per_run)::numeric(1000, 2)::real    -- MALDI dataset
                                     ELSE CR.total_rate_per_run::real                                                       -- Non-MALDI dataset
                                END
        FROM ( SELECT service_type_id,
                      base_rate_per_run + labor_rate_per_run AS total_rate_per_run
               FROM cc.t_service_cost_rate
               WHERE cost_group_id = _costGroupID
             ) CR
        WHERE DS.service_type_id = CR.service_type_id;

        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Defined the transaction_units for % % in the cost center report', _affectedCount, check_plural(_affectedCount, 'dataset', 'datasets');
        End If;

        /*
            -- The following query can be helpful when manually replicating the population of Tmp_Datasets_to_Add

            SELECT DS.service_type_id,
                   CR.total_rate_per_run,
                   CASE WHEN DS.service_type_id = 9
                        THEN (DS.acq_length_minutes / 60.0 * CR.total_rate_per_run)::numeric(1000, 2)::real   -- For MALDI datasets, use total_rate_per_run times acq_length_hours
                        ELSE CR.total_rate_per_run::real
                   END AS transaction_units
            FROM Tmp_Datasets_to_Add DS
                 INNER JOIN ( SELECT service_type_id,
                                     base_rate_per_run + labor_rate_per_run AS total_rate_per_run
                              FROM cc.t_service_cost_rate
                              WHERE cost_group_id = 100
                            ) CR
                  ON DS.service_type_id = CR.service_type_id
            ORDER BY DS.service_type_id, DS.dataset_id;
        */

        ---------------------------------------------------
        -- Change the transaction units to a negative value for any datasets with cc_report_state_id = 4 (Need to refund to cost center)
        ---------------------------------------------------

        UPDATE Tmp_Datasets_to_Add
        SET transaction_units = -ABS(transaction_units)
        WHERE cc_report_state_id = 4;

        ---------------------------------------------------
        -- Create a new cost center report, settings its state to 1=New
        ---------------------------------------------------

        _currentLocation := 'Create a new cost center report';

        INSERT INTO cc.t_service_use_report(start_time, end_time, requestor_employee_id, report_state_id, cost_group_id)
        VALUES (_startDate, _beginningOfNextDay, current_user, 1, _costGroupID)
        RETURNING report_id
        INTO _reportID;

        ---------------------------------------------------
        -- Add the datasets to table cc.t_service_use
        ---------------------------------------------------

        _currentLocation := format('Add datasets to the new cost center report (Report_ID: %s)', _reportID);

        If _showDebug Then
            RAISE INFO '%', _currentLocation;
        End If;

        INSERT INTO cc.t_service_use (report_id, ticket_number,
                                      charge_code, service_type_id,
                                      transaction_date, transaction_units,
                                      is_held, comment, dataset_id)
        SELECT _reportID,
               format('%s_%s', to_char(_endDate, 'yyyy-mm-dd'), dataset_id) AS ticket_number,
               charge_code,
               service_type_id,
               transaction_date,
               transaction_units,
               is_held,
               comment,
               dataset_id
        FROM Tmp_Datasets_to_Add;

        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Added % % to table t_service_use', _affectedCount, check_plural(_affectedCount, 'row', 'rows');
        End If;

        ---------------------------------------------------
        -- Update the cost center report state for the datasets in the report
        -- The new state will be either 3 (Submitted to cost center) or 5 (Refunded to cost center)
        ---------------------------------------------------

        _currentLocation := 'Update cost center report state ID for the datasets in the report';

        UPDATE t_dataset DS
        SET cc_report_state_id = CASE WHEN LookupQ.cc_report_state_id = 4
                                      THEN 5        -- Refunded
                                      ELSE 3        -- Submitted
                                 END
        FROM ( SELECT dataset_id,
                      cc_report_state_id
               FROM Tmp_Datasets_to_Add
             ) LookupQ
        WHERE DS.dataset_id = LookupQ.dataset_id;

        GET DIAGNOSTICS _affectedCount = ROW_COUNT;

        If _showDebug Then
            RAISE INFO 'Update cc_report_state_id for % % in table t_dataset', _affectedCount, check_plural(_affectedCount, 'dataset', 'datasets');
        End If;

        ---------------------------------------------------
        -- Change the cost center report state to 2 = Active
        ---------------------------------------------------

        _currentLocation := 'Change the cost center report state to 2 = active';

        UPDATE cc.t_service_use_report
        SET report_state_id = 2
        WHERE report_id = _reportID;

        ---------------------------------------------------
        -- Log info about the new report
        ---------------------------------------------------

        _logMsg := format('Created cost center report %s with %s %s',
                          _reportID, _datasetCount, check_plural(_datasetCount, 'dataset', 'datasets'));

        If _showDebug Then
            RAISE INFO '%', _logMsg;
        End If;

        CALL post_log_entry('Normal', _logMsg, 'create_dataset_cc_report');

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

    DROP TABLE IF EXISTS Tmp_Datasets_to_Add;
END
$$;


ALTER PROCEDURE public.create_dataset_cc_report(IN _enddate timestamp without time zone, IN _daycount integer, IN _infoonly boolean, IN _showdebug boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


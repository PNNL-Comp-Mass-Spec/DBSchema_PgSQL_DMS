--
CREATE OR REPLACE PROCEDURE public.update_eus_requested_run_wp
(
    _searchWindowDays int = 30,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the work package for requested runs
**      from EUS projects by looking for other requested runs
**      from the same project that have a work package
**
**      Changes will be logged to T_Log_Entries
**
**  Auth:   mem
**  Date:   12/18/2015 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/18/2022 mem - Add renamed proposal type 'Resource Owner'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _message text := '';
    _entryID int := 0;
    _proposalID text;
    _rrStart int;
    _newWP text;
    _valueList text;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        ----------------------------------------------------------
        -- Validate the inputs
        ----------------------------------------------------------

        _searchWindowDays := Coalesce(_searchWindowDays, 30);
        _infoOnly := Coalesce(_infoOnly, false);

        If _searchWindowDays < 0 Then
            _searchWindowDays := Abs(_searchWindowDays);
        End If;

        If _searchWindowDays < 1 Then
            _searchWindowDays := 1;
        End If;

        If _searchWindowDays > 120 Then
            _searchWindowDays := 120;
        End If;

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_WPInfo (
            Proposal_ID text not null,
            work_package text not null,
            Requests int not null,
            usage_rank int not null
        );

        CREATE INDEX IX_Tmp_WPInfo ON Tmp_WPInfo (Proposal_ID, Work_Package);

        CREATE TEMP TABLE Tmp_ReqRunsToUpdate (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            request_id int not null,
            proposal_id text not null,
            work_package text not null,
            Message text null
        );

        CREATE INDEX IX_Tmp_ReqRunsToUpdate ON Tmp_ReqRunsToUpdate (request_id);

        ----------------------------------------------------------
        -- Find the Proposal_ID to Work_Package mapping for Requested Runs that have a WP defined
        ----------------------------------------------------------
        --
        INSERT INTO Tmp_WPInfo( proposal_id,
                                work_package,
                                Requests,
                                usage_rank )
        SELECT proposal_id,
               work_package,
               Requests,
               Row_Number() OVER ( Partition BY proposal_id ORDER BY Requests DESC ) AS usage_rank
        FROM ( SELECT EUSPro.proposal_id,
                      RR.work_package,
                      COUNT(*) AS Requests
               FROM t_dataset DS
                    INNER JOIN t_requested_run RR
                      ON DS.dataset_id = RR.dataset_id
                    INNER JOIN t_eus_usage_type EUSUsage
                      ON RR.eus_usage_type_id = EUSUsage.request_id
                    INNER JOIN t_eus_proposals EUSPro
                      ON RR.eus_proposal_id = EUSPro.proposal_id
               WHERE DS.created BETWEEN CURRENT_TIMESTAMP - make_interval(days => _searchWindowDays) AND CURRENT_TIMESTAMP AND
                     EUSPro.proposal_type NOT IN
                     ('Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') AND
                     Coalesce(RR.work_package, '') NOT IN ('none', 'na', 'n/a', '')
               GROUP BY EUSPro.proposal_id, work_package
               ) LookupQ;

        If _infoOnly Then
            -- ToDo: Show the data using RAISE INFO
            SELECT *
            FROM Tmp_WPInfo
            ORDER BY Proposal_ID, usage_rank Desc
        End If;

        -- Find requested runs to update
        --
        INSERT INTO Tmp_ReqRunsToUpdate( request_id,
                                         proposal_id,
                                         work_package )
        SELECT RR.request_id,
               EUSPro.proposal_id,
               RR.work_package
        FROM t_dataset DS
             INNER JOIN t_requested_run RR
               ON DS.dataset_id = RR.dataset_id
             INNER JOIN t_eus_usage_type EUSUsage
               ON RR.eus_usage_type_id = EUSUsage.request_id
             INNER JOIN t_eus_proposals EUSPro
               ON RR.eus_proposal_id = EUSPro.proposal_id
             INNER JOIN Tmp_WPInfo
               ON EUSPro.proposal_id = Tmp_WPInfo.proposal_id And usage_rank = 1
        WHERE DS.created BETWEEN CURRENT_TIMESTAMP - make_interval(days => _searchWindowDays) AND CURRENT_TIMESTAMP AND
              EUSPro.proposal_type NOT IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') AND
              Coalesce(RR.work_package, '') IN ('none', 'na', 'n/a', '')
        GROUP BY RR.request_id,
                 EUSPro.proposal_id,
                 RR.work_package
        ORDER BY EUSPro.proposal_id, RR.request_id;

        ----------------------------------------------------------
        -- These tables are used to generate the log message
        -- that describes the requested runs that will be updated
        ----------------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        );

        ----------------------------------------------------------
        -- Loop through the entries in Tmp_ReqRunsToUpdate
        ----------------------------------------------------------

        request_id := '';

        FOR _proposalID, _rrStart IN
            SELECT Proposal_ID,
                   request_id
            FROM Tmp_ReqRunsToUpdate
            WHERE Proposal_ID <> _proposalID
            ORDER BY Entry_ID
        LOOP

            SELECT Work_Package
            INTO _newWP
            FROM Tmp_WPInfo
            WHERE Proposal_ID = _proposalID AND usage_rank = 1;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount <> 1 Then
                _logMessage := 'Logic error; did not find a single match for proposal ' || _proposalID || ' in Tmp_WPInfo';
                Call post_log_entry ('Error', _logMessage , 'Update_EUS_Requested_Run_WP');
                RETURN;
            End If;

            TRUNCATE TABLE Tmp_ValuesByCategory;

            INSERT INTO Tmp_ValuesByCategory (Category, Value)
            SELECT 'RR', request_id
            FROM Tmp_ReqRunsToUpdate
            WHERE Proposal_ID = _proposalID
            ORDER BY request_id;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _infoOnly Then
                _logMessage := 'Updating WP to ' || _newWP || ' for requested';
            Else
                _logMessage := 'Updated WP to ' || _newWP || ' for requested';
            End If;

            If _myRowCount = 1 Then
                _logMessage := _logMessage || ' run ' || Cast(_rRStart as text);
            Else

                SELECT ValueList
                INTO _valueList
                FROM condense_integer_list_to_ranges(_debugMode => false);
                LIMIT 1;

                _logMessage := _logMessage || ' runs ' || _valueList;
            End If;

            UPDATE Tmp_ReqRunsToUpdate
            SET Message = _logMessage
            WHERE Proposal_ID = _proposalID;

            If Not _infoOnly Then

                UPDATE t_requested_run target
                SET work_package = _newWP
                FROM Tmp_ReqRunsToUpdate Src
                WHERE target.request_id = Src.request_id AND
                      Src.Proposal_ID = _proposalID;

                Call post_log_entry ('Normal', _logMessage, 'Update_EUS_Requested_Run_WP');
            End If;

        END LOOP;

        If _infoOnly Then
            ----------------------------------------------------------
            -- Preview what would be updated
            ----------------------------------------------------------
            --
            If Exists (Select * from Tmp_ReqRunsToUpdate) Then

                -- ToDo: Show this data using RAISE INFO

                SELECT Src.*
                FROM Tmp_ReqRunsToUpdate Src
                ORDER BY Src.Proposal_ID, Src.ID;
            Else
                SELECT 'No candidate requested runs were found to update' AS Message
            End If;

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

    DROP TABLE IF EXISTS Tmp_WPInfo;
    DROP TABLE IF EXISTS Tmp_ReqRunsToUpdate;
    DROP TABLE IF EXISTS Tmp_ValuesByCategory;
END
$$;

COMMENT ON PROCEDURE public.update_eus_requested_run_wp IS 'UpdateEUSRequestedRunWP';

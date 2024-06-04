--
-- Name: update_eus_requested_run_wp(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_eus_requested_run_wp(IN _searchwindowdays integer DEFAULT 30, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for requested runs that are associated with an EUS project, but have an undefined work package
**
**      Examine related requested runs to look for a valid work package to use instead of 'none', 'na', 'n/a', or ''
**
**  Arguments:
**    _searchWindowDays     Search window, in days
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   12/18/2015 mem - Initial version
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/18/2022 mem - Add renamed proposal type 'Resource Owner'
**          03/01/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _startDate timestamp;
    _mostRecentProposalID text;
    _proposalID text;
    _firstRequestID int;
    _newWP text;
    _valueList text;
    _logMessage text;
    _matchCount int;

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

    BEGIN
        ----------------------------------------------------------
        -- Validate the inputs
        ----------------------------------------------------------

        _searchWindowDays := Coalesce(_searchWindowDays, 30);
        _infoOnly         := Coalesce(_infoOnly, false);

        If _searchWindowDays < 0 Then
            _searchWindowDays := Abs(_searchWindowDays);
        End If;

        If _searchWindowDays < 1 Then
            _searchWindowDays := 1;
        End If;

        If _searchWindowDays > 240 Then
            _searchWindowDays := 240;
        End If;

        ----------------------------------------------------------
        -- Create some temporary tables
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_WPInfo (
            Proposal_ID text NOT NULL,
            Work_Package text NOT NULL,
            Requests int NOT NULL,
            Usage_Rank int NOT NULL
        );

        CREATE INDEX IX_Tmp_WPInfo ON Tmp_WPInfo (Proposal_ID, Work_Package);

        CREATE TEMP TABLE Tmp_ReqRunsToUpdate (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Request_ID int NOT NULL,
            Proposal_ID text NOT NULL,
            Work_Package text NOT NULL,
            Message text NULL
        );

        CREATE INDEX IX_Tmp_ReqRunsToUpdate ON Tmp_ReqRunsToUpdate (request_id);

        ----------------------------------------------------------
        -- Find the proposal_id to work_package mapping for requested runs that have a WP defined
        ----------------------------------------------------------

        _startDate := CURRENT_DATE - make_interval(days => _searchWindowDays);

        INSERT INTO Tmp_WPInfo (
            Proposal_ID,
            Work_Package,
            Requests,
            Usage_Rank
        )
        SELECT Proposal_ID,
               Work_Package,
               Requests,
               Row_Number() OVER (PARTITION BY proposal_id ORDER BY Requests DESC) AS Usage_Rank
        FROM (SELECT EUSPro.proposal_id,
                     RR.work_package,
                     COUNT(RR.request_id) AS Requests
              FROM t_dataset DS
                   INNER JOIN t_requested_run RR
                     ON DS.dataset_id = RR.dataset_id
                   INNER JOIN t_eus_usage_type EUSUsage
                     ON RR.eus_usage_type_id = EUSUsage.eus_usage_type_id
                   INNER JOIN t_eus_proposals EUSPro
                     ON RR.eus_proposal_id = EUSPro.proposal_id
              WHERE DS.created BETWEEN _startDate AND CURRENT_TIMESTAMP AND
                    NOT EUSPro.proposal_type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') AND
                    NOT Coalesce(RR.work_package, '') IN ('none', 'na', 'n/a', '')
              GROUP BY EUSPro.proposal_id, work_package
             ) LookupQ;

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-11s %-12s %-8s %-10s';

            _infoHead := format(_formatSpecifier,
                                'Proposal_ID',
                                'Work_Package',
                                'Requests',
                                'Usage_Rank'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-----------',
                                         '------------',
                                         '--------',
                                         '----------'
                                        );

            If Exists (SELECT * FROM Tmp_WPInfo) Then
                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Proposal_ID,
                           Work_Package,
                           Requests,
                           Usage_Rank
                    FROM Tmp_WPInfo
                    ORDER BY Proposal_ID, Usage_Rank DESC
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Proposal_ID,
                                        _previewData.Work_Package,
                                        _previewData.Requests,
                                        _previewData.Usage_Rank
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;
            Else
                RAISE INFO 'No requested runs were found matching the criteria:';
                RAISE INFO '  1) Dataset created between % and %', _startDate, Left(public.timestamp_text(CURRENT_TIMESTAMP), 16);
                RAISE INFO '  2) Proposal type not "Proprietary", "Proprietary Public", "Proprietary_Public", or "Resource Owner"';
                RAISE INFO '  3) Work package not "none", "na", or "n/a"';

                DROP TABLE Tmp_WPInfo;
                DROP TABLE Tmp_ReqRunsToUpdate;

                RETURN;
            End If;

        End If;

        -- Find requested runs to update

        INSERT INTO Tmp_ReqRunsToUpdate (
            Request_ID,
            Proposal_ID,
            Work_Package
        )
        SELECT RR.request_id,
               EUSPro.proposal_id,
               RR.work_package
        FROM t_dataset DS
             INNER JOIN t_requested_run RR
               ON DS.dataset_id = RR.dataset_id
             INNER JOIN t_eus_usage_type EUSUsage
               ON RR.eus_usage_type_id = EUSUsage.eus_usage_type_id
             INNER JOIN t_eus_proposals EUSPro
               ON RR.eus_proposal_id = EUSPro.proposal_id
             INNER JOIN Tmp_WPInfo
               ON EUSPro.proposal_id = Tmp_WPInfo.Proposal_ID And Usage_Rank = 1
        WHERE DS.created BETWEEN _startDate AND CURRENT_TIMESTAMP AND
              NOT EUSPro.proposal_type IN ('Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') AND
              Coalesce(RR.work_package, '') IN ('none', 'na', 'n/a', '')
        GROUP BY RR.request_id,
                 EUSPro.proposal_id,
                 RR.work_package
        ORDER BY EUSPro.proposal_id, RR.request_id;

        ----------------------------------------------------------
        -- This table is used to generate the log message
        -- that describes the requested runs that will be updated
        ----------------------------------------------------------

        CREATE TEMP TABLE Tmp_ValuesByCategory (
            Category text,
            Value int
        );

        ----------------------------------------------------------
        -- Loop through the entries in Tmp_ReqRunsToUpdate
        ----------------------------------------------------------

        If _infoOnly Then
            RAISE INFO '';
        End If;

        _mostRecentProposalID := '';

        FOR _proposalID, _firstRequestID IN
            SELECT Proposal_ID,
                   Request_ID
            FROM Tmp_ReqRunsToUpdate
            ORDER BY Entry_ID
        LOOP
            If _proposalID = _mostRecentProposalID Then
                -- The work package for this requested run has already been updated
                CONTINUE;
            End If;

            _mostRecentProposalID := _proposalID;

            SELECT Work_Package
            INTO _newWP
            FROM Tmp_WPInfo
            WHERE Proposal_ID = _proposalID AND Usage_Rank = 1;

            If _infoOnly Then
                RAISE INFO 'Changing work package to % for requested runs with proposal % and a dataset created after %',  _newWP, _proposalID, _startDate::date;
            End If;

            If Not FOUND Then
                _logMessage := format('Logic error; did not find a match for proposal %s and usage rank 1 in Tmp_WPInfo', _proposalID);

                RAISE WARNING '%', _message;
                CALL post_log_entry ('Error', _logMessage , 'Update_EUS_Requested_Run_WP');

                DROP TABLE Tmp_WPInfo;
                DROP TABLE Tmp_ReqRunsToUpdate;
                DROP TABLE Tmp_ValuesByCategory;

                RETURN;
            End If;

            TRUNCATE TABLE Tmp_ValuesByCategory;

            INSERT INTO Tmp_ValuesByCategory (Category, Value)
            SELECT 'RR', Request_ID
            FROM Tmp_ReqRunsToUpdate
            WHERE Proposal_ID = _proposalID
            ORDER BY Request_ID;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _infoOnly Then
                _logMessage := format('Updating WP to %s for requested', _newWP);
            Else
                _logMessage := format('Updated WP to %s for requested', _newWP);
            End If;

            If _matchCount = 1 Then
                _logMessage := format('%s run %s', _logMessage, _firstRequestID);
            Else

                SELECT ValueList
                INTO _valueList
                FROM public.condense_integer_list_to_ranges(_debugMode => false)
                LIMIT 1;

                _logMessage := format('%s runs %s', _logMessage, _valueList);
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

                RAISE INFO '%', _logMessage;
                CALL post_log_entry ('Normal', _logMessage, 'Update_EUS_Requested_Run_WP');
            End If;

        END LOOP;

        If _infoOnly Then
            ----------------------------------------------------------
            -- Preview what would be updated
            ----------------------------------------------------------

            RAISE INFO '';

            If Exists (SELECT * FROM Tmp_ReqRunsToUpdate) Then

                _formatSpecifier := '%-8s %-10s %-11s %-12s %-100s';

                _infoHead := format(_formatSpecifier,
                                    'Entry_ID',
                                    'Request_ID',
                                    'Proposal_ID',
                                    'Work_Package',
                                    'Message'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------',
                                             '----------',
                                             '-----------',
                                             '------------',
                                             '----------------------------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT Src.Entry_ID,
                           Src.Request_ID,
                           Src.Proposal_ID,
                           Src.Work_Package,
                           Src.Message
                    FROM Tmp_ReqRunsToUpdate Src
                    ORDER BY Src.Proposal_ID, Src.Entry_ID
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Entry_ID,
                                        _previewData.Request_ID,
                                        _previewData.Proposal_ID,
                                        _previewData.Work_Package,
                                        _previewData.Message
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            Else
                RAISE INFO 'No candidate requested runs were found to update; criteria:';
                RAISE INFO '  1) Dataset created between % and %', _startDate, Left(public.timestamp_text(CURRENT_TIMESTAMP), 16);
                RAISE INFO '  2) Proposal type not "Proprietary", "Proprietary Public", "Proprietary_Public", or "Resource Owner"';
                RAISE INFO '  3) Work package not "none", "na", or "n/a"';
            End If;

        ElsIf Not Exists (SELECT * FROM Tmp_ReqRunsToUpdate) Then
            RAISE INFO 'No candidate requested runs were found to update';
        End If;

        DROP TABLE Tmp_WPInfo;
        DROP TABLE Tmp_ReqRunsToUpdate;
        DROP TABLE Tmp_ValuesByCategory;

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

    DROP TABLE IF EXISTS Tmp_WPInfo;
    DROP TABLE IF EXISTS Tmp_ReqRunsToUpdate;
    DROP TABLE IF EXISTS Tmp_ValuesByCategory;
END
$$;


ALTER PROCEDURE public.update_eus_requested_run_wp(IN _searchwindowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_eus_requested_run_wp(IN _searchwindowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_eus_requested_run_wp(IN _searchwindowdays integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateEUSRequestedRunWP';


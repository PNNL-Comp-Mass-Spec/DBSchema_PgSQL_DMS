--
-- Name: auto_define_wps_for_eus_requested_runs(integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_define_wps_for_eus_requested_runs(IN _mostrecentmonths integer DEFAULT 12, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for completed requested runs that have an EUS proposal, but for which the work package is 'none'
**
**      Look for other uses of that EUS proposal that have a valid work package.
**      If found, change the WP from 'none' to the new work package
**
**      Preference is given to recently used work packages
**
**  Arguments:
**    _mostRecentMonths     Number of recent months to examine
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   01/29/2016 mem - Initial Version
**          01/26/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryID int := 0;
    _eusProposal citext;
    _workPackage citext;
    _monthsSearched int;
    _requestedRunsToUpdate int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mostRecentMonths := Coalesce(_mostRecentMonths, 12);
    _infoOnly         := Coalesce(_infoOnly, false);

    If _mostRecentMonths < 1 Then
        _mostRecentMonths := 1;
    End If;

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProposalsToCheck (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        EUSProposal text NOT NULL,
        BestWorkPackage text NULL,
        MonthsSearched int NULL
    );

    CREATE INDEX IX_Tmp_ProposalsToCheck ON Tmp_ProposalsToCheck (Entry_ID);

    ---------------------------------------------------
    -- Find proposals with a requested run within the
    -- last _mostRecentMonths and a work package of 'none'
    ---------------------------------------------------

    INSERT INTO Tmp_ProposalsToCheck (EUSProposal)
    SELECT P.proposal_id
    FROM t_eus_proposals P
         INNER JOIN t_requested_run RR
           ON P.proposal_id = RR.eus_proposal_id
    WHERE NOT P.title ILIKE '%P41%' AND
          NOT P.title ILIKE '%NCRR%' AND
          NOT RR.state_name = 'Active' AND
          RR.work_package = 'none' AND
          RR.entered >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
    GROUP BY P.proposal_id;

    ---------------------------------------------------
    -- Process each proposal
    ---------------------------------------------------

    FOR _eusProposal IN
        SELECT EUSProposal
        FROM Tmp_ProposalsToCheck
        ORDER BY Entry_ID
    LOOP
        SELECT work_package, months_searched
        INTO _workPackage, _monthsSearched
        FROM public.get_wp_for_eus_proposal(_eusProposal);

        If FOUND And _workPackage <> 'none' Then
            UPDATE Tmp_ProposalsToCheck
            SET BestWorkPackage = _workPackage,
                MonthsSearched  = _monthsSearched
            WHERE EUSProposal = _eusProposal;
        End If;
    END LOOP;

    ---------------------------------------------------
    -- Populate a new temporary table with the requested runs to update
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestedRunsToUpdate (
        EUSProposal text NOT NULL,
        WorkPackage text NOT NULL,
        RequestedRunID int NOT NULL
    );

    CREATE INDEX IX_Tmp_RequestedRunsToUpdate ON Tmp_RequestedRunsToUpdate (EUSProposal, RequestedRunID);

    INSERT INTO Tmp_RequestedRunsToUpdate (
        EUSProposal,
        WorkPackage,
        RequestedRunID
    )
    SELECT C.EUSProposal,
           C.BestWorkPackage,
           RR.request_id
    FROM Tmp_ProposalsToCheck C
         INNER JOIN t_requested_run RR
           ON RR.eus_proposal_id = C.EUSProposal AND
              (RR.created >= CURRENT_TIMESTAMP - make_interval(months => C.MonthsSearched) OR
               RR.created >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths))
    WHERE C.MonthsSearched < _mostRecentMonths * 2 AND
          RR.work_package = 'none' AND
          Not RR.state_name = 'Active'
    ORDER BY C.EUSProposal;

    If _infoOnly Then

        -- Summarize the updates

        RAISE INFO '';

        _formatSpecifier := '%-8s %-12s %-17s %-15s %-14s %-18s %-120s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'EUS_Proposal',
                            'Best_Work_Package',
                            'Months_Searched',
                            'Requested_Runs',
                            'Requests_To_Update',
                            'Title'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '------------',
                                     '-----------------',
                                     '---------------',
                                     '--------------',
                                     '------------------',
                                     '------------------------------------------------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT C.Entry_ID,
                   C.EUSProposal,
                   C.BestWorkPackage,
                   C.MonthsSearched,
                   COUNT(FilterQ.request_id) AS RequestedRuns,
                   SUM(CASE WHEN FilterQ.work_package = 'none' THEN 1 ELSE 0 END) AS RequestsToUpdate,
                   P.title
            FROM Tmp_ProposalsToCheck C
                 INNER JOIN (SELECT request_id,
                                    request_name,
                                    created,
                                    eus_proposal_id,
                                    work_package
                             FROM t_requested_run RR
                             WHERE request_id IN (SELECT RequestedRunID FROM Tmp_RequestedRunsToUpdate) OR
                                   (eus_proposal_id IN (SELECT EUSProposal FROM Tmp_RequestedRunsToUpdate) AND
                                    RR.created >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
                                   )
                            ) FilterQ
                   ON C.EUSProposal = FilterQ.eus_proposal_id
                 INNER JOIN t_eus_proposals P
                   ON P.proposal_id = C.EUSProposal
            GROUP BY C.Entry_ID, C.EUSProposal, C.BestWorkPackage, C.MonthsSearched, P.title
            ORDER BY SUM(CASE WHEN FilterQ.work_package = 'none' THEN 1 ELSE 0 END) DESC
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.EUSProposal,
                                _previewData.BestWorkPackage,
                                _previewData.MonthsSearched,
                                _previewData.RequestedRuns,
                                _previewData.RequestsToUpdate,
                                _previewData.Title
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        -- Show details of the requested runs associated with the EUS Proposals that we will be updating
        -- This list includes both requested runs with a valid work package, and runs with 'none'

        RAISE INFO '';

        _formatSpecifier := '%-8s %-12s %-17s %-15s %-20s %-16s %-18s %-110s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'EUS_Proposal',
                            'Best_Work_Package',
                            'Months_Searched',
                            'Created',
                            'Requested_Run_ID',
                            'Work_Package',
                            'Request_Name'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '------------',
                                     '-----------------',
                                     '---------------',
                                     '--------------------',
                                     '----------------',
                                     '------------------',
                                     '--------------------------------------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT C.Entry_ID,
                   C.EUSProposal,
                   C.BestWorkPackage,
                   C.MonthsSearched,
                   FilterQ.request_name,
                   public.timestamp_text(FilterQ.Created) AS Created,
                   FilterQ.request_id AS RequestedRunID,
                   CASE
                       WHEN FilterQ.work_package = 'none' THEN format('none --> %s', C.BestWorkPackage)
                       ELSE FilterQ.work_package
                   END AS WorkPackage
            FROM Tmp_ProposalsToCheck C
                 INNER JOIN (SELECT request_id,
                                    request_name,
                                    created,
                                    eus_proposal_id,
                                    work_package
                             FROM t_requested_run RR
                             WHERE request_id IN (SELECT RequestedRunID FROM Tmp_RequestedRunsToUpdate) OR
                                   (eus_proposal_id IN (SELECT EUSProposal FROM Tmp_RequestedRunsToUpdate) AND
                                    RR.created >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
                                   )
                            ) FilterQ
                   ON C.EUSProposal = FilterQ.eus_proposal_id
            ORDER BY C.EUSProposal, request_name
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.EUSProposal,
                                _previewData.BestWorkPackage,
                                _previewData.MonthsSearched,
                                _previewData.Created,
                                _previewData.RequestedRunID,
                                _previewData.WorkPackage,
                                _previewData.Request_Name
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Apply or preview the updates
    ---------------------------------------------------

    FOR _eusProposal, _workPackage, _requestedRunsToUpdate IN
        SELECT EUSProposal,
               WorkPackage,
               COUNT(*)
        FROM Tmp_RequestedRunsToUpdate
        GROUP BY EUSProposal, WorkPackage
        ORDER BY EUSProposal
    LOOP

        _message := format('%s the work package from none to %s for %s requested %s with EUS Proposal %s',
                           CASE WHEN _infoOnly THEN 'Would change' ELSE 'Changed' END,
                           _workPackage,
                           _requestedRunsToUpdate,
                           public.check_plural(_requestedRunsToUpdate, 'run', 'runs'),
                           _eusProposal);

        If _infoOnly Then
            RAISE INFO '%', _message;
        Else
            UPDATE t_requested_run
            SET work_package = _workPackage
            FROM Tmp_RequestedRunsToUpdate U
            WHERE t_requested_run.request_id = U.RequestedRunID AND
                  U.EUSProposal = _eusProposal;

            CALL post_log_entry ('Normal', _message, 'Auto_Define_WPs_For_EUS_Requested_Runs');
        End If;

    END LOOP;

    DROP TABLE Tmp_ProposalsToCheck;
    DROP TABLE Tmp_RequestedRunsToUpdate;
END
$$;


ALTER PROCEDURE public.auto_define_wps_for_eus_requested_runs(IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_define_wps_for_eus_requested_runs(IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_define_wps_for_eus_requested_runs(IN _mostrecentmonths integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AutoDefineWPsForEUSRequestedRuns';


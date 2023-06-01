--
CREATE OR REPLACE PROCEDURE public.auto_define_wps_for_eus_requested_runs
(
    _mostRecentMonths int = 12,
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for completed requested runs that have
**      an EUS proposal but for which the work package is 'none'
**
**      Looks for other uses of that EUS proposal that have
**      a valid work package. If found, changes the WP
**      from 'none' to the new work package
**
**      Preference is given to recently used work packages
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   01/29/2016 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _entryID int := 0;
    _eusProposal text;
    _continue boolean;
    _workPackage text;
    _monthsSearched int;
    _message text;
    _requestedRunsToUpdate int;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mostRecentMonths := Coalesce(_mostRecentMonths, 12);
    _infoOnly := Coalesce(_infoOnly, false);

    If _mostRecentMonths < 1 Then
        _mostRecentMonths := 1;
    End If;

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProposalsToCheck
    (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        EUSProposal text NOT NULL,
        BestWorkPackage text NULL,
        MonthsSearched int NULL
    )

    CREATE INDEX IX_Tmp_ProposalsToCheck ON Tmp_ProposalsToCheck (Entry_ID)

    ---------------------------------------------------
    -- Find proposals with a requested run within the
    -- last _mostRecentMonths and a work package of 'none'
    ---------------------------------------------------
    --
    INSERT INTO Tmp_ProposalsToCheck( EUSProposal )
    SELECT P.proposal_id
    FROM t_eus_proposals P
         INNER JOIN t_requested_run RR
           ON P.proposal_id = RR.eus_proposal_id
    WHERE Not P.title Like '%P41%' AND
          Not P.title Like '%NCRR%' AND
          Not RR.state_name = 'Active' AND
          RR.work_package = 'none' AND
          RR.entered >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
    GROUP BY P.proposal_id;

    ---------------------------------------------------
    -- Process each proposal
    ---------------------------------------------------
    --

    FOR _eusProposal IN
        SELECT EUSProposal
        FROM Tmp_ProposalsToCheck
        ORDER BY Entry_ID
    LOOP
        SELECT work_package, months_searched
        INTO _workPackage, _monthsSearched
        FROM public.get_wp_for_eus_proposal (_eusProposalID);

        If FOUND And _workPackage <> 'none' Then
            UPDATE Tmp_ProposalsToCheck
            SET BestWorkPackage = _workPackage,
                MonthsSearched = _monthsSearched
            WHERE EUSProposal = _eusProposal;
        End If;
    END LOOP;

    ---------------------------------------------------
    -- Populate a new temporary table with the requested runs to update
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_RequestedRunsToUpdate
    (
        EUSProposal text NOT NULL,
        WorkPackage text NOT NULL,
        RequestedRunID int not null
    )

    CREATE INDEX IX_Tmp_RequestedRunsToUpdate ON Tmp_RequestedRunsToUpdate (EUSProposal, RequestedRunID)

    INSERT INTO Tmp_RequestedRunsToUpdate( EUSProposal,
                                            WorkPackage,
                                            RequestedRunID )
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
    ORDER BY C.EUSProposal

    If _infoOnly Then

        -- ToDo: Use Raise Info

        ---------------------------------------------------
        -- Summarize the updates
        ---------------------------------------------------

        SELECT C.Entry_ID,
               C.EUSProposal,
               C.BestWorkPackage,
               C.MonthsSearched,
               COUNT(*) AS RequestedRuns,
               SUM(CASE WHEN FilterQ.work_package = 'none' THEN 1 ELSE 0 END) AS RequestsToUpdate,
               P.title
        FROM Tmp_ProposalsToCheck C
             INNER JOIN ( SELECT request_id,
                                 request_name,
                                 created,
                                 eus_proposal_id,
                                 work_package
                          FROM t_requested_run RR
                          WHERE request_id IN ( SELECT RequestedRunID FROM Tmp_RequestedRunsToUpdate ) OR
                                (eus_proposal_id IN ( SELECT EUSProposal FROM Tmp_RequestedRunsToUpdate ) AND
                                 RR.created >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
                                )
                        ) FilterQ
               ON C.EUSProposal = FilterQ.eus_proposal_id
               INNER JOIN t_eus_proposals P ON P.proposal_id = C.EUSProposal
        GROUP BY C.Entry_ID, C.EUSProposal, C.BestWorkPackage, C.MonthsSearched, P.title
        ORDER BY SUM(CASE WHEN FilterQ.work_package = 'none' THEN 1 ELSE 0 END) desc

        ---------------------------------------------------
        -- Show details of the requested runs associated with the EUS Proposals that we will be updating
        -- This list includes both requested runs with a valid work package, and runs with 'none'
        ---------------------------------------------------

        SELECT C.*,
               FilterQ.request_name,
               FilterQ.Created,
               FilterQ.ID AS RequestedRunID,
               CASE
                   WHEN FilterQ.work_package = 'none' THEN format('none --> %s', C.BestWorkPackage)
                   ELSE FilterQ.work_package
               END AS work_package
        FROM Tmp_ProposalsToCheck C
             INNER JOIN ( SELECT request_id,
                                 request_name,
                                 created,
                                 eus_proposal_id,
                                 work_package
                          FROM t_requested_run RR
                          WHERE request_id IN ( SELECT RequestedRunID FROM Tmp_RequestedRunsToUpdate ) OR
                                (eus_proposal_id IN ( SELECT EUSProposal FROM Tmp_RequestedRunsToUpdate ) AND
                                 RR.created >= CURRENT_TIMESTAMP - make_interval(months => _mostRecentMonths)
                                )
                        ) FilterQ
               ON C.EUSProposal = FilterQ.eus_proposal_id
        ORDER BY C.EUSProposal, request_name;

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

            _message := format('Changed the work package from none to %s for %s requested %s with EUS Proposal %s',
                                _workPackage, _requestedRunsToUpdate, public.check_plural(_requestedRunsToUpdate, 'run', 'runs'), _eusProposal);

            If _infoOnly Then
                RAISE INFO '%', _message;
            Else

                UPDATE t_requested_run
                SET work_package = _workPackage
                FROM t_requested_run RR

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE t_requested_run
                **   SET ...
                **   FROM source
                **   WHERE source.request_id = t_requested_run.request_id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_RequestedRunsToUpdate U
                       ON RR.request_id = U.RequestedRunID
                WHERE U.EUSProposal = _eusProposal

                CALL post_log_entry ('Normal', _message, 'Auto_Define_WPs_For_EUS_Requested_Runs');

            End If;

        End If;
    END LOOP;

    DROP TABLE Tmp_ProposalsToCheck;
    DROP TABLE Tmp_RequestedRunsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_define_wps_for_eus_requested_runs IS 'AutoDefineWPsForEUSRequestedRuns';

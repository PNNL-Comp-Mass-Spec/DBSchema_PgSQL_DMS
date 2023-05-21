--
CREATE OR REPLACE PROCEDURE public.auto_define_superseded_eus_proposals
(
    _infoOnly boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for proposals in T_EUS_Proposals with the same name
**      Auto populates Proposal_ID_AutoSupersede for superseded proposals (if currently null)
**
**  Auth:   mem
**  Date:   08/12/2020 mem - Initial Version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _message text;
    _proposalList text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProposalsToUpdate
    (
        Proposal_ID text NOT NULL,
        Newest_Proposal_ID text NOT NULL
    );

    ---------------------------------------------------
    -- Find proposals that need to be updated
    ---------------------------------------------------
    --
    INSERT INTO Tmp_ProposalsToUpdate( proposal_id, Newest_Proposal_ID )
    SELECT EUP.proposal_id,
           RankQ.proposal_id AS Newest_ID
    FROM t_eus_proposals EUP
         INNER JOIN ( SELECT title,
                             COUNT(*) AS Entries
                      FROM t_eus_proposals
                      GROUP BY title
                      HAVING (COUNT(*) > 1) ) DuplicateQ
           ON EUP.title = DuplicateQ.title
         INNER JOIN ( SELECT title,
                             proposal_id,
                             ROW_NUMBER() OVER ( PARTITION BY title ORDER BY proposal_start_date DESC ) AS StartRank
                      FROM t_eus_proposals ) RankQ
           ON EUP.title = RankQ.title AND
              RankQ.StartRank = 1 AND
              EUP.proposal_id <> RankQ.proposal_id
    WHERE state_id <> 5 AND
          Coalesce(EUP.proposal_id_auto_supersede, '') <> RankQ.proposal_id AND
          EUP.proposal_id_auto_supersede IS NULL
    ORDER BY EUP.proposal_id

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        ---------------------------------------------------
        -- Preview the updates
        ---------------------------------------------------
        --
        SELECT EUP.proposal_id,
               EUP.numeric_id,
               EUP.title,
               EUP.state_id,
               EUP.proposal_start_date,
               EUP.proposal_end_date,
               EUP.proposal_id_auto_supersede,
               UpdatesQ.Newest_Proposal_ID,
               EUP_Newest.proposal_start_date AS Newest_Proposal_Start_Date,
               EUP_Newest.proposal_end_date AS Newest_Proposal_End_Date
        FROM t_eus_proposals EUP
             INNER JOIN Tmp_ProposalsToUpdate UpdatesQ
               ON EUP.proposal_id = UpdatesQ.proposal_id
             INNER JOIN t_eus_proposals EUP_Newest
               ON UpdatesQ.Newest_Proposal_ID = EUP_Newest.proposal_id
        ORDER BY EUP.title;
    Else
        If NOT Exists (SELECT * FROM Tmp_ProposalsToUpdate) Then
            _message := 'No superseded proposals were found; nothing to do';
        Else
            ---------------------------------------------------
            -- Construct a list of the proposals IDs being updated
            ---------------------------------------------------
            --
            _proposalList := '';

            SELECT string_agg(Proposal_ID, ', ' ORDER BY Proposal_ID)
            INTO _proposalList
            FROM Tmp_ProposalsToUpdate;

            ---------------------------------------------------
            -- Populate Proposal_ID_AutoSupersede
            ---------------------------------------------------
            --
            UPDATE t_eus_proposals EUP
            SET proposal_id_auto_supersede = UpdatesQ.Newest_Proposal_ID
            FROM Tmp_ProposalsToUpdate UpdatesQ
            WHERE EUP.Proposal_ID = UpdatesQ.Proposal_ID;
            --
            GET DIAGNOSTICS _updateCount = ROW_COUNT;

            _message := format('Auto-set proposal_id_auto_supersede for %s proposal(s) in t_eus_proposals: %s', _updateCount, _proposalList);

            CALL post_log_entry ('Normal', _message, 'Auto_Define_Superseded_EUS_Proposals');
        End If;

        RAISE INFO '%', _message;
    End If;

    DROP TABLE Tmp_ProposalsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_define_superseded_eus_proposals IS 'AutoDefineSupersededEUSProposals';

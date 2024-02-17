--
-- Name: auto_define_superseded_eus_proposals(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_define_superseded_eus_proposals(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for proposals in t_eus_proposals that have the same name
**      Auto populate proposal_id_auto_supersede for superseded proposals (if currently null)
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   08/12/2020 mem - Initial Version
**          01/26/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _proposalList text;

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

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ProposalsToUpdate (
        Proposal_ID text NOT NULL,
        Newest_Proposal_ID text NOT NULL
    );

    ---------------------------------------------------
    -- Find proposals that need to be updated
    ---------------------------------------------------

    INSERT INTO Tmp_ProposalsToUpdate (Proposal_ID, newest_proposal_id)
    SELECT EUP.proposal_id,
           RankQ.proposal_id AS newest_id
    FROM t_eus_proposals EUP
         INNER JOIN ( SELECT title,
                             COUNT(proposal_id) AS Entries
                      FROM t_eus_proposals
                      GROUP BY title
                      HAVING (COUNT(proposal_id) > 1) ) DuplicateQ
           ON EUP.title = DuplicateQ.title
         INNER JOIN ( SELECT title,
                             proposal_id,
                             Row_Number() OVER (PARTITION BY title ORDER BY proposal_start_date DESC) AS StartRank
                      FROM t_eus_proposals ) RankQ
           ON EUP.title = RankQ.title AND
              RankQ.StartRank = 1 AND
              EUP.proposal_id <> RankQ.proposal_id
    WHERE EUP.state_id <> 5 AND
          Coalesce(EUP.proposal_id_auto_supersede, '') <> RankQ.proposal_id AND
          EUP.proposal_id_auto_supersede IS NULL
    ORDER BY EUP.proposal_id;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-10s %-100s %-8s %-18s %-20s %-20s %-23s %-18s %-26s %-24s';

        _infoHead := format(_formatSpecifier,
                            'Proposal',
                            'Numeric',
                            'Title',
                            'State_ID',
                            'State_Name',
                            'Proposal_Start_Date',
                            'Proposal_End_Date',
                            'Proposal_Auto_Supersede',
                            'Newest_Proposal_ID',
                            'Newest_Proposal_Start_Date',
                            'Newest_Proposal_End_Date'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '----------',
                                     '----------------------------------------------------------------------------------------------------',
                                     '--------',
                                     '------------------',
                                     '--------------------',
                                     '--------------------',
                                     '-----------------------',
                                     '------------------',
                                     '--------------------------',
                                     '------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT EUP.proposal_id,
                   EUP.numeric_id,
                   substring(EUP.title, 1, 100) AS title,
                   EUP.state_id,
                   PSN.state_name,
                   public.timestamp_text(EUP.proposal_start_date) AS proposal_start_date,
                   public.timestamp_text(EUP.proposal_end_date) AS proposal_end_date,
                   EUP.proposal_id_auto_supersede,
                   UpdatesQ.newest_proposal_id,
                   public.timestamp_text(EUP_Newest.proposal_start_date) AS newest_proposal_start_date,
                   public.timestamp_text(EUP_Newest.proposal_end_date) AS newest_proposal_end_date
            FROM t_eus_proposals EUP
                 INNER JOIN t_eus_proposal_state_name PSN
                   ON EUP.state_id = PSN.state_id
                 INNER JOIN Tmp_ProposalsToUpdate UpdatesQ
                   ON EUP.proposal_id = UpdatesQ.proposal_id
                 INNER JOIN t_eus_proposals EUP_Newest
                   ON UpdatesQ.Newest_Proposal_ID = EUP_Newest.proposal_id
            ORDER BY EUP.title
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.proposal_id,
                                _previewData.numeric_id,
                                _previewData.title,
                                _previewData.state_id,
                                _previewData.state_name,
                                _previewData.proposal_start_date,
                                _previewData.proposal_end_date,
                                _previewData.proposal_id_auto_supersede,
                                _previewData.newest_proposal_id,
                                _previewData.newest_proposal_start_date,
                                _previewData.newest_proposal_end_date
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_ProposalsToUpdate;
        RETURN;
    End If;

    If Not Exists (SELECT * FROM Tmp_ProposalsToUpdate) Then
        _message := 'No superseded proposals were found; nothing to do';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_ProposalsToUpdate;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Construct a list of the proposals IDs being updated
    ---------------------------------------------------

    SELECT string_agg(Proposal_ID, ', ' ORDER BY Proposal_ID)
    INTO _proposalList
    FROM Tmp_ProposalsToUpdate;

    ---------------------------------------------------
    -- Populate proposal_id_auto_supersede
    ---------------------------------------------------

    UPDATE t_eus_proposals EUP
    SET proposal_id_auto_supersede = UpdatesQ.Newest_Proposal_ID
    FROM Tmp_ProposalsToUpdate UpdatesQ
    WHERE EUP.Proposal_ID = UpdatesQ.Proposal_ID;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    _message := format('Auto-set proposal_id_auto_supersede for %s proposal(s) in t_eus_proposals: %s', _updateCount, _proposalList);
    RAISE INFO '%', _message;

    CALL post_log_entry ('Normal', _message, 'Auto_Define_Superseded_EUS_Proposals');

    DROP TABLE Tmp_ProposalsToUpdate;
END
$$;


ALTER PROCEDURE public.auto_define_superseded_eus_proposals(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_define_superseded_eus_proposals(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_define_superseded_eus_proposals(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AutoDefineSupersededEUSProposals';


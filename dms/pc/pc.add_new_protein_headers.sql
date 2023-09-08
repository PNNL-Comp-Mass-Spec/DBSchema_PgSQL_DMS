--
-- Name: add_new_protein_headers(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: pc; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE pc.add_new_protein_headers(IN _proteinidstart integer DEFAULT 0, IN _maxproteinstoprocess integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populates pc.t_protein_headers with the first 50 residues of each protein
**      in pc.t_proteins that is not yet in pc.t_protein_headers
**
**  Arguments:
**    _proteinIDStart           If 0, then this will be updated to one more than the maximum Protein_ID value in T_Protein_Headers
**    _maxProteinsToProcess     Set to a value > 0 to limit the number of proteins processed
**    _infoOnly                 When true, preview the proteins that would be processed
**
**  Auth:   mem
**  Date:   04/08/2008
**          02/23/2016 mem - Add set XACT_ABORT on
**          07/20/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
    _insertCount int;
    _proteinIDEnd int;
    _proteinsProcessed int := 0;
    _batchSize int := 100000;
    _callingProcName text;
    _currentLocation text := 'Start';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    _proteinIDStart       := Coalesce(_proteinIDStart, 0);
    _maxProteinsToProcess := Coalesce(_maxProteinsToProcess, 0);
    _infoOnly             := Coalesce(_infoOnly, false);

    BEGIN

        _currentLocation := 'Initialize _proteinIDStart';

        If Coalesce(_proteinIDStart, 0) = 0 Then
            -- Lookup the Maximum protein_id value in pc.t_protein_headers
            -- We'll set _proteinIDStart to that value plus 1
            SELECT MAX(protein_id) + 1
            INTO _proteinIDStart
            FROM pc.t_protein_headers;

            _proteinIDStart := Coalesce(_proteinIDStart, 0);
        End If;

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Initial value for _proteinIDStart: %', _proteinIDStart;
        End If;

        --------------------------------------------------------------
        -- Loop through pc.t_proteins and populate pc.t_protein_headers
        --------------------------------------------------------------

        _currentLocation := 'Iterate through the proteins';

        WHILE true
        LOOP

            SELECT MAX(protein_id)
            INTO _proteinIDEnd
            FROM ( SELECT protein_id
                   FROM pc.t_proteins
                   WHERE protein_id >= _proteinIDStart
                   ORDER BY protein_id
                   LIMIT _batchSize
                 ) LookupQ;

            If Coalesce(_proteinIDEnd, -1) < 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            If _infoOnly Then
                RAISE INFO '% to %', _proteinIDStart, _proteinIDEnd;
                _proteinsProcessed := _proteinsProcessed + _batchSize;
            Else

                INSERT INTO pc.t_protein_headers (protein_id, sequence_head)
                SELECT protein_id, Substring(sequence, 1, 50) AS Sequence_Head
                FROM pc.t_proteins
                WHERE protein_id >= _proteinIDStart AND protein_id <= _proteinIDEnd;
                --
                GET DIAGNOSTICS _insertCount = ROW_COUNT;

                _proteinsProcessed := _proteinsProcessed + _insertCount;

            End If;

            _proteinIDStart := _proteinIDEnd + 1;

            If _maxProteinsToProcess > 0 AND _proteinsProcessed >= _maxProteinsToProcess Then
                -- Break out of the while loop
                EXIT;
            End If;

        END LOOP;

        _currentLocation := 'Done iterating';

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

END
$$;


ALTER PROCEDURE pc.add_new_protein_headers(IN _proteinidstart integer, IN _maxproteinstoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_new_protein_headers(IN _proteinidstart integer, IN _maxproteinstoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: pc; Owner: d3l243
--

COMMENT ON PROCEDURE pc.add_new_protein_headers(IN _proteinidstart integer, IN _maxproteinstoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AddNewProteinHeaders';


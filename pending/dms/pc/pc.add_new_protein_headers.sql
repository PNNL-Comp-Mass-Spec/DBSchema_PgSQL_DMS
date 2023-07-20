--
CREATE OR REPLACE PROCEDURE pc.add_new_protein_headers
(
    _proteinIDStart int = 0,
    _maxProteinsToProcess int = 0,
    _infoOnly int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populates T_Protein_Headers with the first 50 residues of each protein in T_Proteins
**      that is not yet in T_Protein_Headers
**
**  Arguments:
**    _proteinIDStart         If 0, then this will be updated to one more than the maximum Protein_ID value in T_Protein_Headers
**    _maxProteinsToProcess   Set to a value > 0 to limit the number of proteins processed
**
**  Auth:   mem
**  Date:   04/08/2008
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
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

    _proteinIDStart := Coalesce(_proteinIDStart, 0);
    _maxProteinsToProcess := Coalesce(_maxProteinsToProcess, 0);
    _infoOnly := Coalesce(_infoOnly, 0);

    BEGIN

        _currentLocation := 'Initialize _proteinIDStart';

        If Coalesce(_proteinIDStart, 0) = 0 Then
            -- Lookup the Maximum protein_id value in pc.t_protein_headers
            -- We'll set _proteinIDStart to that value plus 1
            SELECT Max(protein_id) + 1
            INTO _proteinIDStart
            FROM pc.t_protein_headers;

            _proteinIDStart := Coalesce(_proteinIDStart, 0);
        End If;

        --------------------------------------------------------------
        -- Loop through pc.t_proteins and populate pc.t_protein_headers
        --------------------------------------------------------------

        _currentLocation := 'Iterate through the proteins';

        WHILE true
        LOOP

            SELECT Max(protein_id)
            INTO _proteinIDEnd
            FROM ( SELECT protein_id
                   FROM pc.t_proteins
                   WHERE protein_id >= _proteinIDStart
                   ORDER BY protein_id
                   LIMIT _batchSize
                 ) LookupQ

            If Coalesce(_proteinIDEnd, -1) < 0 Then
                -- Break out of the while loop
                EXIT;
            End If;

            -- <b>
            If _infoOnly <> 0 Then
                RAISE INFO '% to %', _proteinIDStart, _proteinIDEnd;
                _proteinsProcessed := _proteinsProcessed + _batchSize;
            Else

                INSERT INTO pc.t_protein_headers (protein_id, sequence_head)
                SELECT protein_id, Substring("sequence", 1, 50) AS Sequence_Head
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

COMMENT ON PROCEDURE pc.add_new_protein_headers IS 'AddNewProteinHeaders';

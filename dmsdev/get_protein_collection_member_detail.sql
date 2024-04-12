--
-- Name: get_protein_collection_member_detail(integer, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_protein_collection_member_detail(_id integer, _mode text DEFAULT 'get'::text, _callinguser text DEFAULT ''::text) RETURNS TABLE(protein_collection_id integer, protein_name public.citext, description public.citext, protein_sequence public.citext, monoisotopic_mass double precision, average_mass double precision, residue_count integer, molecular_formula public.citext, protein_id integer, reference_id integer, sha1_hash public.citext, member_id integer, sorting_index integer)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Get detailed information regarding a single protein, using its protein reference ID
**
**      Each unique combo of protein name and protein sequence has a distinct reference ID
**      If multiple protein collections have the same protein reference ID, this function only includes one of those protein collection IDs
**
**      This function called from the Protein Collection Member detail report, for example:
**      https://dms2.pnl.gov/protein_collection_members/show/13363564
**
**  Arguments:
**    _id           Protein reference id, corresponding to reference_id in pc.t_protein_names; this parameter must be named id (see $calling_params->id in Q_model.php on the DMS website)
**    _mode         Ignored, but required for compatibility reasons
**    _callingUser  Username of the calling user (not used by this function)
**
**  Auth:   mem
**  Date:   06/27/2016 mem - Initial version
**          08/03/2017 mem - Add Set NoCount On
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _proteinCollectionInfo record;
    _formattedSequence text;
    _chunkSize int := 10;
    _lineLengthThreshold int := 40;
    _currentLineLength int := 0;
    _startIndex int := 1;
    _sequenceLength int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
BEGIN

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _id   := Coalesce(_id, 0);
        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Retrieve one row of data
        ---------------------------------------------------

        SELECT PCM.Protein_Collection_ID AS ProteinCollectionID,
               PN.Name                   AS ProteinName,
               PN.Description            AS Description,
               P.Sequence                AS ProteinSequence,
               P.Monoisotopic_Mass       AS MonoisotopicMass,
               P.Average_Mass            AS AverageMass,
               P.Length                  AS ResidueCount,
               P.Molecular_Formula       AS MolecularFormula,
               P.Protein_ID              AS ProteinId,
               P.SHA1_Hash               AS Sha1Hash,
               PCM.Member_ID             AS MemberId,
               PCM.Sorting_Index         AS SortingIndex
        INTO _proteinCollectionInfo
        FROM pc.t_protein_collection_members PCM
             INNER JOIN pc.t_proteins P
               ON PCM.Protein_ID = P.Protein_ID
             INNER JOIN pc.t_protein_names PN
               ON PCM.Protein_ID = PN.Protein_ID AND
                  PCM.Original_Reference_ID = PN.Reference_ID
        WHERE PN.reference_id = _id
        LIMIT 1;

        If FOUND Then
            ---------------------------------------------------
            -- Insert spaces and <br> tags into the protein sequence
            ---------------------------------------------------

            _sequenceLength    := char_length(_proteinCollectionInfo.ProteinSequence);
            _formattedSequence := '<pre>';

            WHILE _startIndex <= _sequenceLength
            LOOP
                If _currentLineLength < _lineLengthThreshold Then
                    _formattedSequence := format('%s%s ', _formattedSequence, Substring(_proteinCollectionInfo.ProteinSequence, _startIndex, _chunkSize));
                    _currentLineLength := _currentLineLength + _chunkSize + 1;
                Else
                    If _startIndex + _chunkSize <= _sequenceLength Then
                        _formattedSequence := format('%s%s<br>', _formattedSequence, Substring(_proteinCollectionInfo.ProteinSequence, _startIndex, _chunkSize));
                    Else
                        _formattedSequence := format('%s%s', _formattedSequence, Substring(_proteinCollectionInfo.ProteinSequence, _startIndex, _chunkSize));
                    End If;

                    _currentLineLength := 0;
                End If;

                _startIndex := _startIndex + _chunkSize;

            END LOOP;

            _formattedSequence := format('%s</pre>', _formattedSequence);
        End If;

        ---------------------------------------------------
        -- Return the result
        ---------------------------------------------------

        RETURN QUERY
        SELECT _proteinCollectionInfo.ProteinCollectionID,
               _proteinCollectionInfo.ProteinName,
               _proteinCollectionInfo.Description,
               _formattedSequence::citext,
               _proteinCollectionInfo.MonoisotopicMass,
               _proteinCollectionInfo.AverageMass,
               _proteinCollectionInfo.ResidueCount,
               _proteinCollectionInfo.MolecularFormula,
               _proteinCollectionInfo.ProteinId,
               _id AS Reference_ID,
               _proteinCollectionInfo.Sha1Hash,
               _proteinCollectionInfo.MemberId,
               _proteinCollectionInfo.SortingIndex;

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

        RAISE WARNING '%', _message;
    END;

END
$_$;


ALTER FUNCTION public.get_protein_collection_member_detail(_id integer, _mode text, _callinguser text) OWNER TO d3l243;

--
-- Name: FUNCTION get_protein_collection_member_detail(_id integer, _mode text, _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_protein_collection_member_detail(_id integer, _mode text, _callinguser text) IS 'GetProteinCollectionMemberDetail';


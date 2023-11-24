--
CREATE OR REPLACE FUNCTION public.get_protein_collection_member_detail
(
    _id int,
    _mode text = 'get',
    _callingUser text = ''
)
RETURNS TABLE (
    Protein_Collection_ID int,
    Protein_Name text,
    Description text,
    Protein_Sequence text,
    Monoisotopic_Mass float8,
    Average_Mass float8,
    Residue_Count int,
    Molecular_Formula text,
    Protein_ID int,
    Reference_ID int,
    SHA1_Hash text,
    Member_ID int,
    Sorting_Index int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Gets detailed information regarding a single protein in a protein collection
**
**      This is called from the Protein Collection Member detail report, for example:
**      https://dms2.pnl.gov/protein_collection_members/show/13363564
**
**  Arguments:
**    _id           Protein reference_id; this parameter must be named id (see $calling_params->id in Q_model.php on the DMS website)
**    _mode         Ignored, but required for compatibility reasons
**    _callingUser  Calling user username
**
**  Auth:   mem
**  Date:   06/27/2016 mem - Initial version
**          08/03/2017 mem - Add Set NoCount On
**          12/15/2023 mem - Ported to PostgreSQL
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

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Retrieve one row of data
        ---------------------------------------------------

        SELECT Protein_Collection_ID As ProteinCollectionID,
               Protein_Name As ProteinName,
               Description As Description,
               Protein_Sequence As ProteinSequence,
               Monoisotopic_Mass As MonoisotopicMass,
               Average_Mass As AverageMass,
               Residue_Count As ResidueCount,
               Molecular_Formula As MolecularFormula,
               Protein_ID As ProteinId,
               SHA1_Hash As Sha1Hash,
               Member_ID As MemberId,
               Sorting_Index As SortingIndex
        INTO _proteinCollectionInfo
        FROM pc.v_protein_collection_members
        WHERE Reference_ID = _id
        LIMIT 1;

        If FOUND Then
            ---------------------------------------------------
            -- Insert spaces and <br> tags into the protein sequence
            ---------------------------------------------------

            _sequenceLength := char_length(_proteinCollectionInfo.ProteinSequence;
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
                        _formattedSequence := format('%s%s', _formattedSequence, Substring(_proteinCollectionInfo.ProteinSequence, _startIndex, _chunkSize);
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
               _formattedSequence,
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
$$;

COMMENT ON PROCEDURE public.get_protein_collection_member_detail IS 'GetProteinCollectionMemberDetail';

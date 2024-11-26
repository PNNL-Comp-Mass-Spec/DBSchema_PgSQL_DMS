--
-- Name: get_fasta_file_path(text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fasta_file_path(_fastafilename text, _organismname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the appropriate path to the FASTA file based on file Name and organism Name
**      If the FASTA file name is blank or 'na', return the standalone FASTA path for the given organism
**      Otherwise, look for the file in pc.t_archived_output_files
**      or V_FASTA_File_Paths
**
**  Arguments:
**     _fastaFileName   FASTA file name
**     _organismName    Organism name
**
**  Returns:
**      Path to the directory containing the Fasta file
**
**  Auth:   kja
**  Date:   01/23/2007
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs (Ticket #531)
**          09/11/2015 mem - Now using synonym S_ProteinSeqs_T_Archived_Output_Files
**          06/14/2022 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/20/2024 mem - Ignore case when filtering by file name or organism name
**          01/21/2024 mem - Change data type of function arguments to text
**          09/06/2024 mem - Use new view name, v_fasta_file_paths
**
*****************************************************/
DECLARE
    _filePath citext;
    _fileNamePosition int;
BEGIN
    _filePath := '';

    If Coalesce(_fastaFileName, '') = '' Or _fastaFileName::citext = 'na' Then
        SELECT organism_db_path
        INTO _filePath
        FROM t_organisms
        WHERE organism = _organismName::citext
        LIMIT 1;
    Else
        If Not _fastaFileName ILIKE '%.fasta' Then
            _fastaFileName := _fastaFileName || '.fasta';
        End If;

        SELECT archived_file_path
        INTO _filePath
        FROM pc.t_archived_output_files
        WHERE archived_file_path ILIKE '%' || _fastaFileName || '%'
        LIMIT 1;

        If Coalesce(_filePath, '') = '' Then
            SELECT file_path
            INTO _filePath
            FROM v_fasta_file_paths
            WHERE file_name = _fastaFileName::citext
            LIMIT 1;
        End If;

        _fileNamePosition := strpos(_filePath, _fastaFileName);

        If _fileNamePosition > 0 Then
            _filePath := Substring(_filePath, 1, _fileNamePosition - 1);
        Else
            If Coalesce(_organismName, '') <> '' Then
                SELECT organism_db_path
                INTO _filePath
                FROM t_organisms
                WHERE organism = _organismName::citext
                LIMIT 1;
            End If;

            _filePath := Trim(Coalesce(_filePath, ''));

        End If;
    End If;

    RETURN _filePath;
END
$$;


ALTER FUNCTION public.get_fasta_file_path(_fastafilename text, _organismname text) OWNER TO d3l243;


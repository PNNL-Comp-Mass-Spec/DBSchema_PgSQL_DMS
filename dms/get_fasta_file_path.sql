--
-- Name: get_fasta_file_path(public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fasta_file_path(_fastafilename public.citext, _organismname public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the appropriate path to the FASTA file based on file Name and organism Name
**      If the FASTA file name is blank or 'na', return the legacy path for the given organism
**      Otherwise, look for the file in pc.T_Archived_Output_Files
**      or V_Legacy_FASTA_File_Paths
**
**  Return values: Path to the directory containing the Fasta file
**
**  Auth:   kja
**  Date:   01/23/2007
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs (Ticket #531)
**          09/11/2015 mem - Now using synonym S_ProteinSeqs_T_Archived_Output_Files
**          06/14/2022 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/20/2024 mem - Ignore case when filtering by file name or organism name
**
*****************************************************/
DECLARE
    _filePath citext;
    _fileNamePosition int;
BEGIN
    _filePath := '';

    If Coalesce(_fastaFileName, '') = '' Or _fastaFileName = 'na' Then
        SELECT organism_db_path
        INTO _filePath
        FROM t_organisms
        WHERE organism = _organismName::citext
        LIMIT 1;
    Else
        If Not _fastaFileName ILIKE '%.fasta' Then
            _fastaFileName := _fastaFileName || '.fasta';
        End If;

        SELECT Archived_File_Path
        INTO _filePath
        FROM pc.T_Archived_Output_Files
        WHERE Archived_File_Path ILIKE '%' || _fastaFileName || '%'
        LIMIT 1;

        If Coalesce(_filePath, '') = '' Then
            SELECT File_Path
            INTO _filePath
            FROM v_legacy_fasta_file_paths
            WHERE File_Name = _fastaFileName::citext
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


ALTER FUNCTION public.get_fasta_file_path(_fastafilename public.citext, _organismname public.citext) OWNER TO d3l243;


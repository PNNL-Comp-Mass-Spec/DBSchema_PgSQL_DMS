--
-- Name: get_fasta_file_path(public.citext, public.citext); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fasta_file_path(_fastafilename public.citext, _organismname public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the appropriate path to the FASTA file based on file Name and organism Name
**      If the FASTA file name is blank or 'na', returns the legacy path for the given organism
**      Otherwise, looks for the file in pc.T_Archived_Output_Files
**      or V_Legacy_FASTA_File_Paths
**
**  Return values: Path to the directory containing the Fasta file
**
**  Auth:   kja
**  Date:   01/23/2007
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs (Ticket #531)
**          09/11/2015 mem - Now using synonym S_ProteinSeqs_T_Archived_Output_Files
**          06/14/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _filePath citext;
    _fileNamePosition int;
BEGIN
    _filePath := '';

    IF Coalesce(_fastaFileName, '') = '' Or _fastaFileName = 'na' Then
        SELECT organism_db_path
        INTO _filePath
        FROM t_organisms
        WHERE organism = _organismName
        LIMIT 1;
    Else
        If NOT _fastaFileName LIKE '%.fasta' Then
            _fastaFileName := _fastaFileName || '.fasta';
        End If;

        SELECT Archived_File_Path
        INTO _filePath
        FROM pc.T_Archived_Output_Files
        WHERE Archived_File_Path LIKE '%' || _fastaFileName || '%'
        LIMIT 1;

        If Coalesce(_filePath, '') = '' Then
            SELECT File_Path
            INTO _filePath
            FROM v_legacy_fasta_file_paths
            WHERE File_Name = _fastaFileName
            LIMIT 1;
        End If;

        _fileNamePosition := strpos(_filePath, _fastaFileName);

        IF _fileNamePosition > 0 Then
            _filePath := SUBSTRING(_filePath, 1, _fileNamePosition - 1);
        Else
            If Coalesce(_organismName, '') <> '' Then
                SELECT organism_db_path
                INTO _filePath
                FROM t_organisms
                WHERE organism = _organismName
                LIMIT 1;
            End If;

            _filePath := Coalesce(_filePath, '');

        End If;
    End If;

    RETURN _filePath;

END
$$;


ALTER FUNCTION public.get_fasta_file_path(_fastafilename public.citext, _organismname public.citext) OWNER TO d3l243;


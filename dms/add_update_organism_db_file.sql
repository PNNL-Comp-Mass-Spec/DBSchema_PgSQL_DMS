--
-- Name: add_update_organism_db_file(text, text, integer, bigint, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_organism_db_file(IN _fastafilename text, IN _organismname text, IN _numproteins integer, IN _numresidues bigint, IN _filesizekb integer DEFAULT 0, IN _isdecoy boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing Organism DB file in t_organism_db_file
**
**      Added/updated files will have an auto-defined description that starts with "Auto-created", and will have active set to 0
**
**  Arguments:
**    _fastaFileName    FASTA file name, e.g. 'UniProt_Bacteria_100species_TrypPigBov_Bos_Taurus_2021-02-22.fasta'
**    _organismName     Organism name
**    _numProteins      Number of proteins in the FASTA file
**    _numResidues      Total number of residues in the proteins
**    _fileSizeKB       FASTA file size, in KB
**    _isDecoy          When true, the FASTA file contains both forward and reverse protein sequences
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   01/24/2014 mem - Initial version
**          01/15/2015 mem - Add parameter _fileSizeKB
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          01/15/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          11/14/2024 mem - Add parameter _isDecoy
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _organismID int := 0;
    _existingEntry boolean := false;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _fastaFileName := Trim(Coalesce(_fastaFileName, ''));
    _organismName  := Trim(Coalesce(_organismName, ''));
    _numProteins   := Coalesce(_numProteins, 0);
    _numResidues   := Coalesce(_numResidues, 0);
    _fileSizeKB    := Coalesce(_fileSizeKB, 0);
    _isDecoy       := Coalesce(_isDecoy, false);

    If _fastaFileName = '' Then
        _message := 'FASTA file name must be specified';
        _returnCode := 'U6200';
        RETURN;
    End If;

    If _organismName = '' Then
        _message := 'Organism name must be specified';
        _returnCode := 'U6201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Resolve _organismName to _organismID
    ---------------------------------------------------

    SELECT organism_id
    INTO _organismID
    FROM t_organisms
    WHERE organism = _organismName::citext;

    If Not FOUND Or Coalesce(_organismID, 0) <= 0 Then
        _message := format('Unrecognized organism name: %s', _organismName);
        _returnCode := 'U6202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add/update t_organism_db_file
    ---------------------------------------------------

    If Exists (SELECT file_name FROM t_organism_db_file WHERE file_name = _fastaFileName::citext) Then
        _existingEntry := true;
    End If;

    MERGE INTO t_organism_db_file AS target
    USING (SELECT _fastaFileName AS FileName,
                  _organismID    AS OrganismID,
                  'Auto-created' AS Description,
                  0              AS Active,
                  _numProteins   AS NumProteins,
                  _numResidues   AS NumResidues,
                  _fileSizeKB    AS FileSizeKB,
                  _isDecoy       AS IsDecoy,
                  1 AS Valid
          ) AS Source
    ON (target.file_name = source.FileName)
    WHEN MATCHED THEN
        UPDATE SET
            organism_id = source.OrganismID,
            description = format('%s; updated %s', source.description, public.timestamp_text(CURRENT_TIMESTAMP)),
            active = source.active,
            num_proteins = source.NumProteins,
            num_residues = source.NumResidues,
            file_size_kb = source.FileSizeKB,
            is_decoy     = source.IsDecoy,
            valid        = source.valid
    WHEN NOT MATCHED THEN
        INSERT (file_name,
                organism_id,
                description,
                active,
                num_proteins,
                num_residues,
                file_size_kb,
                is_decoy,
                valid)
        VALUES (source.FileName,
                source.OrganismID,
                source.description,
                source.active,
                source.NumProteins,
                source.NumResidues,
                source.FileSizeKB,
                source.IsDecoy,
                source.Valid);

    If _existingEntry Then
        _message := format('Updated %s in t_organism_db_file', _fastaFileName);
    Else
        _message := format('Added %s to t_organism_db_file', _fastaFileName);
    End If;

END
$$;


ALTER PROCEDURE public.add_update_organism_db_file(IN _fastafilename text, IN _organismname text, IN _numproteins integer, IN _numresidues bigint, IN _filesizekb integer, IN _isdecoy boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;


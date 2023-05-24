--
CREATE OR REPLACE PROCEDURE public.add_update_organism_db_file
(
    _fastaFileName text,
    _organismName text,
    _numProteins int,
    _numResidues bigint,
    _fileSizeKB int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing Legacy Organism DB File in T_Organism_DB_File
**
**  Auth:   mem
**  Date:   01/24/2014 mem - Initial version
**          01/15/2015 mem - Added parameter _fileSizeKB
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          03/31/2021 mem - Expand _organismName to varchar(128)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
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

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If Coalesce(_fastaFileName, '') = '' Then
        _message := '_fastaFileName cannot be blank';
        _returnCode := 'U6200';
        RETURN;
    End If;

    If Coalesce(_organismName, '') = '' Then
        _message := '_organismName cannot be blank';
        _returnCode := 'U6201';
        RETURN;
    End If;

    _numProteins := Coalesce(_numProteins, 0);
    _numResidues := Coalesce(_numResidues, 0);
    _fileSizeKB := Coalesce(_fileSizeKB, 0);

    ---------------------------------------------------
    -- Resolve _organismName to _organismID
    ---------------------------------------------------

    SELECT organism_id
    INTO _organismID
    FROM t_organisms
    WHERE organism = _organismName;

    If Not FOUND Or Coalesce(_organismID, 0) <= 0 Then
        _message := format('Could not find organism in t_organisms: %s', _organismName);
        _returnCode := 'U6202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Add/Update t_organism_db_file
    ---------------------------------------------------
    --

    If Exists (SELECT * FROM t_organism_db_file WHERE file_name = _fastaFileName) Then
        _existingEntry := true;
    End If;

    MERGE INTO t_organism_db_file AS target
    USING ( SELECT _fastaFileName AS FileName,
                _organismID AS Organism_ID,
                'Auto-created' AS Description,
                0 AS Active,
                _numProteins AS NumProteins,
                _numResidues AS NumResidues,
                _fileSizeKB AS FileSizeKB,
                1 AS Valid
          ) AS Source
    ON (target.file_name = source.file_name)
    WHEN MATCHED THEN
        UPDATE SET
            organism_id = source.organism_id,
            description = source.description || '; updated ' || public.timestamp_text(CURRENT_TIMESTAMP),
            active = source.active,
            num_proteins = source.num_proteins,
            num_residues = source.num_residues,
            file_size_kb = source.FileSizeKB,
            valid = source.valid
    WHEN NOT MATCHED THEN
        INSERT (FileName,
                organism_id,
                description,
                active,
                NumProteins,
                NumResidues,
                File_Size_KB,
                Valid)
        VALUES (source.FileName,
                source.organism_id,
                source.description,
                source.active,
                source.NumProteins,
                source.NumResidues,
                source.FileSizeKB,
                source.Valid);

    If _existingEntry Then
        _message := format('Updated %s in t_organism_db_file', _fastaFileName);
    Else
        _message := format('Added %s to t_organism_db_file', _fastaFileName);
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_update_organism_db_file IS 'AddUpdateOrganismDBFile';

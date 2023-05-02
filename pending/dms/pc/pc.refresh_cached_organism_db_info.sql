--
CREATE OR REPLACE PROCEDURE pc.refresh_cached_organism_db_info
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_DMS_Organism_DB_Info in MT_Main
**      However, does not delete extra rows;
**        use RefreshCachedOrganismDBInfo in MT_Main for a full synchronization, including deletes
**
**
**  Auth:   mem
**  Date:   01/24/2014
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _returnCode := '';

    ---------------------------------------------------
    -- Use a MERGE Statement to synchronize T_DMS_Organism_DB_Info with V_Protein_Collection_List_Export
    ---------------------------------------------------
    --

    MERGE MT_Main.dbo.T_DMS_Organism_DB_Info AS target
    USING (SELECT ID, FileName, Organism, Description, Active,
                NumProteins, NumResidues, Organism_ID, OrgFile_RowVersion
        FROM MT_Main.dbo.V_DMS_Organism_DB_File_Import
    ) AS Source ( ID, FileName, Organism, Description, Active,
                    NumProteins, NumResidues, Organism_ID, OrgFile_RowVersion)
    ON (target.ID = source.ID)
    WHEN Matched AND ( target.Cached_RowVersion <> Source.OrgFile_RowVersion) THEN
    UPDATE Set
            FileName = Source.FileName,
            Organism = Source.Organism,
            Description = Coalesce(Source.Description, ''),
            Active = Source.Active,
            NumProteins = Coalesce(Source.NumProteins, 0),
            NumResidues = Coalesce(Source.NumResidues, 0),
            Organism_ID = Source.Organism_ID,
            Cached_RowVersion = Source.OrgFile_RowVersion,
            Last_Affected = CURRENT_TIMESTAMP
    WHEN Not Matched THEN
    INSERT ( ID, FileName, Organism, Description, Active,
                NumProteins, NumResidues, Organism_ID, Cached_RowVersion, Last_Affected)
    VALUES ( Source.ID, Source.FileName, Source.Organism, Source.Description, Source.Active,
                Source.NumProteins, Source.NumResidues, Source.Organism_ID, Source.OrgFile_RowVersion, CURRENT_TIMESTAMP)
    ;

    _returnCode := Cast(_myError As text);
    Return _myError

END
$$;

COMMENT ON PROCEDURE pc.refresh_cached_organism_db_info IS 'RefreshCachedOrganismDBInfo';

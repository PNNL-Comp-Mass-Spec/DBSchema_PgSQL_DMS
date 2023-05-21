--
CREATE OR REPLACE PROCEDURE public.update_organism_list_for_biomaterial
(
    _biomaterialName text,
    _organismList text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates organisms associated with a single biomaterial (cell_culture) item
**
**  Arguments:
**    _biomaterialName   Biomaterial name, aka cell culture
**    _organismList      Comma-separated list of organism names.  Should be full organism name, but can also be short names, in which case AutoResolveOrganismName will try to resolve the short name to a full organsim name
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/06/2018 mem - Fix delete bug in Merge statement
**          03/31/2021 mem - Expand Organism_Name, _unknownOrganism, and _newOrganismName to varchar(128)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _biomaterialID int := 0;
    _entryID int;
    _unknownOrganism text;
    _matchCount int;
    _newOrganismName text;
    _newOrganismID int;
    _list text := '';
    _usageMessage text := '';
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
    -- Resolve biomaterial name to ID
    ---------------------------------------------------
    --
    SELECT Biomaterial_ID
    INTO _biomaterialID
    FROM T_Biomaterial
    WHERE Biomaterial_Name = _biomaterialName;

    If Not FOUND Then
        _message := 'Cannot update organisms for biomaterial: "' || _biomaterialName || '" does not exist';
        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
        RETURN;
    End If;

    If _organismList Is Null Then
        _message := 'Cannot update biomaterial "' || _biomaterialName || '": organism list cannot be null';
        RAISE WARNING '%', _message;
        _returnCode := 'U5202';
        RETURN;
    End If;

    _organismList := Trim(_organismList);

    If _organismList = '' Then
        -- Empty organism list; make sure no rows exist in t_biomaterial_organisms for this biomaterial item
        --
        DELETE FROM t_biomaterial_organisms
        WHERE biomaterial_id = _biomaterialID;

        UPDATE T_Biomaterial
        SET Cached_Organism_List = ''
        WHERE Biomaterial_ID = _biomaterialID;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Create a temp table to hold the list of organism names and IDs for this biomaterial item
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_BiomaterialOrganisms (
        Organism_Name text not null,
        Organism_ID int null,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    ---------------------------------------------------
    -- Parse the comma-separated list of organism names supplied by the user
    ---------------------------------------------------
    --
    INSERT INTO Tmp_BiomaterialOrganisms ( Organism_Name )
    SELECT Item
    FROM public.parse_delimited_list(_organismList) AS Organisms

    ---------------------------------------------------
    -- Resolve the organism ID for the organism names
    ---------------------------------------------------
    --
    UPDATE Tmp_BiomaterialOrganisms
    SET Organism_ID = Org.Organism_ID
    FROM t_organisms Org
    WHERE Tmp_BiomaterialOrganisms.Organism_Name = Org.organism;

    ---------------------------------------------------
    -- Look for entries in Tmp_BiomaterialOrganisms where Organism_Name did not resolve to an organism_id
    -- In case a portion of an organism name was entered, or in case a short name was used,
    -- try-to auto-resolve using the organism column in t_organisms
    ---------------------------------------------------

    FOR _entryID, _unknownOrganism IN
        SELECT EntryID, Organism_Name
        FROM Tmp_BiomaterialOrganisms
        WHERE Organism_ID IS NULL
        ORDER BY EntryID
    LOOP
        _matchCount := 0;

        CALL auto_resolve_organism_name (_unknownOrganism,
                                         _matchCount => _matchCount,            -- Output
                                         _newOrganismName => _newOrganismName,  -- Output
                                         _newOrganismID => _newOrganismID);     -- Output

        If _matchCount = 1 Then
            -- Single match was found; update Organism_Name and Organism_ID in Tmp_BiomaterialOrganisms
            UPDATE Tmp_BiomaterialOrganisms
            SET Organism_Name = _newOrganismName,
                Organism_ID = _newOrganismID
            WHERE EntryID = _entryID;

        End If;
    END LOOP; -- </a>

    ---------------------------------------------------
    -- Error if any of the organism names could not be resolved
    ---------------------------------------------------
    --
    --
    SELECT string_agg('Organism_Name', ', ' ORDER BY Organism_Name)
    INTO _list
    FROM Tmp_BiomaterialOrganisms
    WHERE Organism_ID IS NULL;

    If _list <> '' Then
        _message := 'Could not resolve the following organism names: ' || _list;
        _returnCode := 'U5203';
        DROP TABLE Tmp_BiomaterialOrganisms;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update the organisms using a merge statement
    ---------------------------------------------------
    --
    MERGE INTO t_biomaterial_organisms AS t
    USING ( SELECT _biomaterialID AS Biomaterial_ID,
                   Organism_ID
            FROM Tmp_BiomaterialOrganisms
          ) AS s
    ON (t.biomaterial_id = s.biomaterial_id AND t.organism_id = s.organism_id)
    -- Note: all of the columns in table t_biomaterial_organisms are primary keys or identity columns; there are no updatable columns
    WHEN NOT MATCHED THEN
        INSERT (Biomaterial_ID, Organism_ID)
        VALUES (s.Biomaterial_ID, s.Organism_ID);

    -- Delete rows from t_biomaterial_organisms that have Biomaterial_ID = _biomaterialID and are not in Tmp_BiomaterialOrganisms

    DELETE FROM t_biomaterial_organisms target
    WHERE target.Biomaterial_ID = _biomaterialID AND
          NOT EXISTS (SELECT source.organism_id
                      FROM Tmp_BiomaterialOrganisms source
                      WHERE target.organism_id = source.organism_id
                     );

    ---------------------------------------------------
    -- Update Cached_Organism_List
    ---------------------------------------------------
    --
    UPDATE T_Biomaterial
    SET Cached_Organism_List = get_biomaterial_organism_list(_biomaterialID)
    WHERE Biomaterial_ID = _biomaterialID

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    _usageMessage := 'Biomaterial: ' || _biomaterialName;
    CALL post_usage_log_entry ('Update_Organism_List_For_Biomaterial', _usageMessage);

    DROP TABLE Tmp_BiomaterialOrganisms;
END
$$;

COMMENT ON PROCEDURE public.update_organism_list_for_biomaterial IS 'UpdateOrganismListForBiomaterial';


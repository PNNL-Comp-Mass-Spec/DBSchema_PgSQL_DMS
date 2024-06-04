--
-- Name: update_cached_ncbi_taxonomy(boolean, boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.update_cached_ncbi_taxonomy(_deleteextras boolean DEFAULT true, _infoonly boolean DEFAULT true) RETURNS TABLE(task public.citext, updated_tax_ids integer, new_tax_ids integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data in ont.t_ncbi_taxonomy_cached
**
**  Arguments:
**    _deleteExtras     When true, delete extra rows from ont.t_ncbi_taxonomy_cached
**    _infoOnly         When true, preview updates
**
**  Usage:
**      SELECT * FROM ont.update_cached_ncbi_taxonomy(_deleteExtras => false, _infoOnly => true);
**      SELECT * FROM ont.update_cached_ncbi_taxonomy(_deleteExtras => false, _infoOnly => false);
**
**  Auth:   mem
**  Date:   03/01/2016 mem - Initial version
**          01/06/2022 mem - Implement support for _infoOnly
**          04/07/2022 mem - Ported to PostgreSQL
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Remove redundant parentheses
**          07/11/2023 mem - Use COUNT(NameList.entry_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _insertCount int;
    _deleteCount int;
    _updateCount int;
    _countUpdated int := 0;
    _countAdded int := 0;
    _message text := '';
BEGIN
    _deleteExtras := Coalesce(_deleteExtras, true);
    _infoOnly     := Coalesce(_infoOnly, true);

    If _infoOnly Then
        RETURN QUERY
        SELECT 'Preview updates'::citext as Task,
               SUM(CASE
                       WHEN t.Name <> s.Name OR
                            t.Rank <> s.Rank OR
                            t.Parent_Tax_ID <> s.Parent_Tax_ID OR
                            t.Synonyms <> s.Synonyms THEN 1
                       ELSE 0
                       End)::int AS Updated_Tax_IDs,
               SUM(CASE WHEN t.tax_id IS NULL THEN 1 ELSE 0 END)::int AS New_Tax_IDs
        FROM (SELECT Nodes.tax_id,
                     NodeNames.name,
                     Nodes.rank,
                     Nodes.parent_tax_id,
                     Coalesce(SynonymStats.synonyms, 0) AS synonyms
              FROM ont.t_ncbi_taxonomy_names NodeNames
                   INNER JOIN ont.t_ncbi_taxonomy_nodes Nodes
                     ON NodeNames.tax_id = Nodes.tax_id
                   LEFT OUTER JOIN (SELECT PrimaryName.tax_id,
                                           COUNT(NameList.entry_id) AS synonyms
                                    FROM ont.t_ncbi_taxonomy_names NameList
                                         INNER JOIN ont.t_ncbi_taxonomy_names PrimaryName
                                           ON NameList.tax_id = PrimaryName.tax_id AND
                                              PrimaryName.name_class = 'scientific name'
                                         INNER JOIN ont.t_ncbi_taxonomy_name_class NameClass
                                           ON NameList.name_class = NameClass.name_class
                                    WHERE NameClass.sort_weight BETWEEN 2 AND 19
                                    GROUP BY PrimaryName.tax_id
                                   ) SynonymStats
                     ON Nodes.tax_id = SynonymStats.tax_id
              WHERE NodeNames.name_class = 'scientific name'
             ) AS s
             LEFT OUTER JOIN ont.t_ncbi_taxonomy_cached t
               ON t.tax_id = s.tax_id;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update ont.t_ncbi_taxonomy_cached
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_SourceData (
           tax_id int NOT NULL,
           name citext,
           rank citext,
           parent_tax_id int,
           synonyms int);

    CREATE INDEX IX_Tmp_SourceData ON Tmp_SourceData (tax_id);

    INSERT INTO Tmp_SourceData (
        tax_id,
        name,
        rank,
        parent_tax_id,
        synonyms
    )
    SELECT Nodes.tax_id,
           NodeNames.name,
           Nodes.rank,
           Nodes.parent_tax_id,
           Coalesce(SynonymStats.synonyms, 0) AS synonyms
    FROM ont.t_ncbi_taxonomy_names NodeNames
         INNER JOIN ont.t_ncbi_taxonomy_nodes Nodes
           ON NodeNames.tax_id = Nodes.tax_id
         LEFT OUTER JOIN (SELECT PrimaryName.tax_id,
                                 COUNT(NameList.entry_id) AS synonyms
                          FROM ont.t_ncbi_taxonomy_names NameList
                               INNER JOIN ont.t_ncbi_taxonomy_names PrimaryName
                                 ON NameList.tax_id = PrimaryName.tax_id AND
                                    PrimaryName.name_class = 'scientific name'
                               INNER JOIN ont.t_ncbi_taxonomy_name_class NameClass
                                 ON NameList.name_class = NameClass.name_class
                          WHERE NameClass.sort_weight BETWEEN 2 AND 19
                          GROUP BY PrimaryName.tax_id) SynonymStats
           ON Nodes.tax_id = SynonymStats.tax_id
    WHERE NodeNames.name_class = 'scientific name';
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    RAISE INFO 'Populated Tmp_SourceData with % tax_id rows', _insertCount;

    ---------------------------------------------------
    -- Update existing rows
    ---------------------------------------------------

    UPDATE ont.t_ncbi_taxonomy_cached t
    SET name = s.name,
        rank = s.rank,
        parent_tax_id = s.parent_tax_id,
        synonyms = s.synonyms
    FROM Tmp_SourceData s
    WHERE t.tax_id = s.tax_id AND
          (
            t.name <> s.name OR
            t.rank <> s.rank OR
            t.parent_tax_id <> s.parent_tax_id OR
            t.synonyms <> s.synonyms
          );
    --
    GET DIAGNOSTICS _countUpdated = ROW_COUNT;

    If _countUpdated > 0 Then
        RAISE INFO 'Updated % existing rows', _countUpdated;
    Else
        RAISE INFO 'Existing rows are already up-to-date';
    End If;

    ---------------------------------------------------
    -- Add new rows
    ---------------------------------------------------

    INSERT INTO ont.t_ncbi_taxonomy_cached (tax_id, name, rank, parent_tax_id, synonyms, synonym_list)
    SELECT s.tax_id,
           s.name,
           s.rank,
           s.parent_tax_id,
           s.synonyms,
           '' as synonym_list
    FROM Tmp_SourceData s
         LEFT OUTER JOIN ont.t_ncbi_taxonomy_cached t
           ON s.tax_id = t.tax_id
    WHERE t.tax_id IS NULL;
    --
    GET DIAGNOSTICS _countAdded = ROW_COUNT;

    If _countAdded > 0 Then
        RAISE INFO 'Added % new taxonomy IDs', _countAdded;
    Else
        RAISE INFO 'Did not need to add any new taxonomy IDs';
    End If;

    If _deleteExtras THEN
        DELETE FROM ont.t_ncbi_taxonomy_cached
        WHERE tax_id IN (SELECT t.tax_id
                         FROM ont.t_ncbi_taxonomy_cached t
                              LEFT OUTER JOIN Tmp_SourceData s
                                ON s.tax_id = t.tax_id
                         WHERE s.tax_id IS NULL);
        --
        GET DIAGNOSTICS _deleteCount = ROW_COUNT;

        If _deleteCount > 0 Then
            RAISE INFO 'Deleted % extra taxonomy IDs', _deleteCount;
        Else
            RAISE INFO 'Did not need to find any extra taxonomy IDs to delete';
        End If;
    End If;

    ---------------------------------------------------
    -- Update the Synonym_List column
    ---------------------------------------------------

    UPDATE ont.t_ncbi_taxonomy_cached t
    SET synonym_list = s.synonym_list
    FROM (
        SELECT tax_id,
               ont.get_taxid_synonym_list(TaxIDs.tax_id) AS synonym_list
        FROM ont.t_ncbi_taxonomy_cached AS TaxIDs
        WHERE TaxIDs.synonyms > 0) s
    WHERE t.tax_id = s.tax_id AND
          Coalesce(NULLIF(t.synonym_list, s.synonym_list),
                   NULLIF(s.synonym_list, t.synonym_list)) IS NOT NULL;
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RAISE INFO 'Update synonyms for % taxonomy IDs', _updateCount;
    Else
        RAISE INFO 'Did not need to update any synonym lists';
    End If;

    ---------------------------------------------------
    -- Clear the Synonym_List column for entries with Synonyms = 0
    ---------------------------------------------------

    UPDATE ont.t_ncbi_taxonomy_cached
    SET synonym_list = ''
    WHERE synonyms = 0 AND Coalesce(synonym_list, '') <> '';
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        RAISE INFO 'Cleared the synonyms for % taxonomy IDs', _updateCount;
    Else
        RAISE INFO 'Did not need to clear any synonym lists';
    End If;

    DROP TABLE Tmp_SourceData;

    RETURN QUERY
    SELECT 'Update cached data'::citext as Task,
           _countUpdated,
           _countAdded;
END
$$;


ALTER FUNCTION ont.update_cached_ncbi_taxonomy(_deleteextras boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION update_cached_ncbi_taxonomy(_deleteextras boolean, _infoonly boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.update_cached_ncbi_taxonomy(_deleteextras boolean, _infoonly boolean) IS 'UpdateCachedNCBITaxonomy';


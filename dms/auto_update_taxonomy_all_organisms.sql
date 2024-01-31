--
-- Name: auto_update_taxonomy_all_organisms(boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_update_taxonomy_all_organisms(IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Auto-defines the taxonomy for all organisms, using the NCBI_Taxonomy_ID value defined for each organism
**
**  Arguments:
**    _infoOnly     When true, preview results
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   03/02/2016 mem - Initial version
**          03/31/2021 mem - Expand OrganismName to varchar(128)
**          01/30/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _organismInfo record;
    _organism     record;

    _orgDomain  text;
    _orgKingdom text;
    _orgPhylum  text;
    _orgClass   text;
    _orgOrder   text;
    _orgFamily  text;
    _orgGenus   text;
    _orgSpecies text;
    _orgStrain  text;

    _changedFields text;
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Create a temporary table for previewing the results
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_OrganismsToUpdate (
        Organism_ID int not null,
        Organism_Name text not null,
        NCBI_Taxonomy_ID int not null,
        Old_Domain  text,
        New_Domain  text,
        Old_Kingdom text,
        New_Kingdom text,
        Old_Phylum  text,
        New_Phylum  text,
        Old_Class   text,
        New_Class   text,
        Old_Order   text,
        New_Order   text,
        Old_Family  text,
        New_Family  text,
        Old_Genus   text,
        New_Genus   text,
        Old_Species text,
        New_Species text,
        Old_Strain  text,
        New_Strain  text,
        Changed_Fields text
    );

    ---------------------------------------------------
    -- Loop over the organism entries
    ---------------------------------------------------

    _updateCount := 0;

    FOR _organismInfo IN
        SELECT ncbi_taxonomy_id,
               organism AS Organism_Name,
               organism_id,
               Coalesce(domain, '')  AS Old_Domain,
               Coalesce(kingdom, '') AS Old_Kingdom,
               Coalesce(phylum, '')  AS Old_Phylum,
               Coalesce(class, '')   AS Old_Class,
               Coalesce("order", '') AS Old_Order,
               Coalesce(family, '')  AS Old_Family,
               Coalesce(genus, '')   AS Old_Genus,
               Coalesce(species, '') AS Old_Species,
               Coalesce(strain, '')  AS Old_Strain
        FROM t_organisms
        WHERE NOT ncbi_taxonomy_id IS NULL
        ORDER BY organism_id
    LOOP
        ---------------------------------------------------
        -- Auto-define the taxonomy terms
        ---------------------------------------------------

        _orgDomain  := _organismInfo.Old_Domain;
        _orgKingdom := _organismInfo.Old_Kingdom;
        _orgPhylum  := _organismInfo.Old_Phylum;
        _orgClass   := _organismInfo.Old_Class;
        _orgOrder   := _organismInfo.Old_Order;
        _orgFamily  := _organismInfo.Old_Family;
        _orgGenus   := _organismInfo.Old_Genus;
        _orgSpecies := _organismInfo.Old_Species;
        _orgStrain  := _organismInfo.Old_Strain;

        CALL public.get_taxonomy_value_by_taxonomy_id (
                        _ncbiTaxonomyID => _organismInfo.NCBI_Taxonomy_ID,
                        _orgDomain      => _orgDomain,      -- Output
                        _orgKingdom     => _orgKingdom,     -- Output
                        _orgPhylum      => _orgPhylum,      -- Output
                        _orgClass       => _orgClass,       -- Output
                        _orgOrder       => _orgOrder,       -- Output
                        _orgFamily      => _orgFamily,      -- Output
                        _orgGenus       => _orgGenus,       -- Output
                        _orgSpecies     => _orgSpecies,     -- Output
                        _orgStrain      => _orgStrain,      -- Output
                        _previewResults => false);

        If  _orgDomain  = _organismInfo.Old_Domain  And
            _orgKingdom = _organismInfo.Old_Kingdom And
            _orgPhylum  = _organismInfo.Old_Phylum  And
            _orgClass   = _organismInfo.Old_Class   And
            _orgOrder   = _organismInfo.Old_Order   And
            _orgFamily  = _organismInfo.Old_Family  And
            _orgGenus   = _organismInfo.Old_Genus   And
            _orgSpecies = _organismInfo.Old_Species And
            _orgStrain  = _organismInfo.Old_Strain
        Then
            CONTINUE;
        End If;

        ---------------------------------------------------
        -- New data to preview or store
        ---------------------------------------------------

        _updateCount := _updateCount + 1;

        If Not _infoOnly Then

            UPDATE t_organisms
            SET domain  = _orgDomain,
                kingdom = _orgKingdom,
                phylum  = _orgPhylum,
                class   = _orgClass,
                "order" = _orgOrder,
                family  = _orgFamily,
                genus   = _orgGenus,
                species = _orgSpecies,
                strain  = _orgStrain
            WHERE organism_id = _organismInfo.Organism_ID;

            CONTINUE;
        End If;

        -- Previewing changes; store in Tmp_OrganismsToUpdate

        _changedFields := '';

        If _orgDomain  <> _organismInfo.Old_Domain Then
            _changedFields := format('%s, %s', _changedFields, 'Domain');
        End If;

        If _orgKingdom  <> _organismInfo.Old_Kingdom Then
            _changedFields := format('%s, %s', _changedFields, 'Kingdom');
        End If;

        If _orgPhylum  <> _organismInfo.Old_Phylum Then
            _changedFields := format('%s, %s', _changedFields, 'Phylum');
        End If;

        If _orgClass  <> _organismInfo.Old_Class Then
            _changedFields := format('%s, %s', _changedFields, 'Class');
        End If;

        If _orgOrder  <> _organismInfo.Old_Order Then
            _changedFields := format('%s, %s', _changedFields, 'Order');
        End If;

        If _orgFamily  <> _organismInfo.Old_Family Then
            _changedFields := format('%s, %s', _changedFields, 'Family');
        End If;

        If _orgGenus  <> _organismInfo.Old_Genus Then
            _changedFields := format('%s, %s', _changedFields, 'Genus');
        End If;

        If _orgSpecies  <> _organismInfo.Old_Species Then
            _changedFields := format('%s, %s', _changedFields, 'Species');
        End If;

        If _orgStrain  <> _organismInfo.Old_Strain Then
            _changedFields := format('%s, %s', _changedFields, 'Strain');
        End If;

        -- Remove the leading comma
        _changedFields := Substring(_changedFields, 3, 200);

        INSERT INTO Tmp_OrganismsToUpdate (
            Organism_ID,
            Organism_Name,
            NCBI_Taxonomy_ID,
            Old_Domain,  New_Domain,
            Old_Kingdom, New_Kingdom,
            Old_Phylum,  New_Phylum,
            Old_Class,   New_Class,
            Old_Order,   New_Order,
            Old_Family,  New_Family,
            Old_Genus,   New_Genus,
            Old_Species, New_Species,
            Old_Strain,  New_Strain,
            Changed_Fields
        ) VALUES (
            _organismInfo.Organism_ID,
            _organismInfo.Organism_Name,
            _organismInfo.NCBI_Taxonomy_ID,
            _organismInfo.Old_Domain,  _orgDomain,
            _organismInfo.Old_Kingdom, _orgKingdom,
            _organismInfo.Old_Phylum,  _orgPhylum,
            _organismInfo.Old_Class,   _orgClass,
            _organismInfo.Old_Order,   _orgOrder,
            _organismInfo.Old_Family,  _orgFamily,
            _organismInfo.Old_Genus,   _orgGenus,
            _organismInfo.Old_Species, _orgSpecies,
            _organismInfo.Old_Strain,  _orgStrain,
            _changedFields
        );

    END LOOP;

    If _updateCount = 0 Then
        _message := 'Taxonomy info is already up-to-date for all organisms';
        RAISE INFO '%', _message;

        DROP TABLE Tmp_OrganismsToUpdate;
        RETURN;
    End If;

    _message := format('%s taxonomy info for %s %s',
                       CASE WHEN _infoOnly THEN 'Would update' ELSE 'Updated' END,
                       _updateCount,
                       public.check_plural(_updateCount, 'organism', 'organisms'));

    If Not _infoOnly Then
        RAISE INFO '%', _message;

        CALL post_log_entry ('Normal', _message, 'auto_update_taxonomy_all_organisms');

        DROP TABLE Tmp_OrganismsToUpdate;
        RETURN;
    End If;

    RAISE INFO '';

    _formatSpecifier := '%-11s %-50s %-16s %-15s %-15s %-15s %-15s %-30s %-30s %-30s %-30s %-30s %-30s %-50s %-50s %-30s %-30s %-50s %-50s %-50s %-50s %-50s';

    _infoHead := format(_formatSpecifier,
                        'Organism_ID',
                        'Organism_Name',
                        'NCBI_Taxonomy_ID',
                        'Old_Domain',
                        'New_Domain',
                        'Old_Kingdom',
                        'New_Kingdom',
                        'Old_Phylum',
                        'New_Phylum',
                        'Old_Class',
                        'New_Class',
                        'Old_Order',
                        'New_Order',
                        'Old_Family',
                        'New_Family',
                        'Old_Genus',
                        'New_Genus',
                        'Old_Species',
                        'New_Species',
                        'Old_Strain',
                        'New_Strain',
                        'Changed_Fields'
                       );

    _infoHeadSeparator := format(_formatSpecifier,
                                 '-----------',
                                 '--------------------------------------------------',
                                 '----------------',
                                 '---------------',
                                 '---------------',
                                 '---------------',
                                 '---------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '--------------------------------------------------',
                                 '--------------------------------------------------',
                                 '------------------------------',
                                 '------------------------------',
                                 '--------------------------------------------------',
                                 '--------------------------------------------------',
                                 '--------------------------------------------------',
                                 '--------------------------------------------------',
                                 '--------------------------------------------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT Organism_ID,
               Organism_Name,
               NCBI_Taxonomy_ID,
               Old_Domain,
               New_Domain,
               Old_Kingdom,
               New_Kingdom,
               Old_Phylum,
               New_Phylum,
               Old_Class,
               New_Class,
               Old_Order,
               New_Order,
               Old_Family,
               New_Family,
               Old_Genus,
               New_Genus,
               Substring(Old_Species, 1, 50) AS Old_Species,
               Substring(New_Species, 1, 50) AS New_Species,
               Substring(Old_Strain,  1, 50) AS Old_Strain,
               Substring(New_Strain,  1, 50) AS New_Strain,
               Changed_Fields
        FROM Tmp_OrganismsToUpdate
        ORDER BY Organism_ID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Organism_ID,
                            _previewData.Organism_Name,
                            _previewData.NCBI_Taxonomy_ID,
                            _previewData.Old_Domain,
                            _previewData.New_Domain,
                            _previewData.Old_Kingdom,
                            _previewData.New_Kingdom,
                            _previewData.Old_Phylum,
                            _previewData.New_Phylum,
                            _previewData.Old_Class,
                            _previewData.New_Class,
                            _previewData.Old_Order,
                            _previewData.New_Order,
                            _previewData.Old_Family,
                            _previewData.New_Family,
                            _previewData.Old_Genus,
                            _previewData.New_Genus,
                            _previewData.Old_Species,
                            _previewData.New_Species,
                            _previewData.Old_Strain,
                            _previewData.New_Strain,
                            _previewData.Changed_Fields
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    RAISE INFO '';
    RAISE INFO '%', _message;

    DROP TABLE Tmp_OrganismsToUpdate;
END
$$;


ALTER PROCEDURE public.auto_update_taxonomy_all_organisms(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_update_taxonomy_all_organisms(IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_update_taxonomy_all_organisms(IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AutoUpdateTaxonomyAllOrganisms';


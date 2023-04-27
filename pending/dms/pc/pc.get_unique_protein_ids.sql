--
CREATE OR REPLACE PROCEDURE pc.get_unique_protein_ids
(
    FROM         dbo.T_Protein_Collection_Members
    WHERE     (Protein_Collection_ID = _collection_1)),
    Collection_2(protein_ID, protein_collection_ID) AS
    (SELECT     Protein_ID, Protein_Collection_ID
    FROM          dbo.T_Protein_Collection_Members
    WHERE      (Protein_Collection_ID = _collection_2))
    SELECT     collection_2.protein_ID
    FROM Collection_1
    RIGHT OUTER JOIN Collection_2
    ON Collection_1.Protein_ID = Collection_2.protein_ID
    WHERE (Collection_1.Protein_ID IS NULL)
    END
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Add the parameters for the stored procedure here
    _collection_1 int,
    _collection_2 int
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    WITH Collection_1 AS
END
$$;

COMMENT ON PROCEDURE pc.get_unique_protein_ids IS 'GetUniqueProteinIDs';

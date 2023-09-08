--
CREATE OR REPLACE PROCEDURE public.add_new_freezer
(
    _sourceFreezerTag text = '2240B',
    _newFreezerTag text = '1215A',
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new Freezer to T_Material_Locations
**
**      You must first manually add a row to T_Material_Freezers
**
**  Auth:   mem
**  Date:   04/22/2015 mem - Initial version
**          03/31/2016 mem - Switch to using Freezer tags (and remove parameter _newTagBase)
**          11/13/2017 mem - Skip computed column Tag when copying data
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _insertCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceFreezerTag := Trim(Coalesce(_sourceFreezerTag, ''));
    _newFreezerTag    := Trim(Coalesce(_newFreezerTag, ''));
    _infoOnly         := Coalesce(_infoOnly, true);

    If _sourceFreezerTag = '' Then
        _message := 'Source freezer tag must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _newFreezerTag = '' Then
        _message := 'New freezer tag must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If char_length(_newFreezerTag) < 4 Then
        _message := '_newFreezerTag should be at least 4 characters long, e.g. 1213A';
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Check for existing data
    ---------------------------------------------------

    If Exists (SELECT * FROM t_material_locations WHERE freezer_tag = _newFreezerTag) Then
        _message := format('Cannot add ''%s'' because it already exists in t_material_locations', _newFreezerTag);
        RAISE WARNING '%', _message;

        _returnCode := 'U5205';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM t_material_locations WHERE freezer_tag = _sourceFreezerTag) Then
        _message := format('Source freezer tag not found in t_material_locations: %s', _sourceFreezerTag);
        RAISE WARNING '%', _message;

        _returnCode := 'U5206';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM t_material_freezers WHERE freezer_tag = _newFreezerTag) Then
        _message := format('New freezer tag not found in t_material_freezers: %s', _newFreezerTag);
        RAISE WARNING '%', _message;

        _returnCode := 'U5207';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Cache the new rows in a temporary table
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_T_Material_Locations (
        ID              int PRIMARY KEY GENERATED ALWAYS AS IDENTITY(START WITH 1000 INCREMENT BY 1),
        Freezer_Tag     text NULL,
        Shelf           text NOT NULL,
        Rack            text NOT NULL,
        Row             text NOT NULL,
        Col             text NOT NULL,
        Status          text NOT NULL,
        Barcode         text NULL,
        Comment         text NULL,
        Container_Limit int NOT NULL
    )

    INSERT INTO Tmp_T_Material_Locations( freezer_tag,
                                          shelf,
                                          rack,
                                          row,
                                          col,
                                          status,
                                          barcode,
                                          comment,
                                          container_limit )
    SELECT _newFreezerTag AS New_Freezer_Tag,
           shelf,
           rack,
           row,
           col,
           status,
           barcode,
           comment,
           container_limit
    FROM t_material_locations
    WHERE (freezer_tag = _sourceFreezerTag) AND
          (NOT (location_id IN ( SELECT location_id
                        FROM t_material_locations
                        WHERE (freezer_tag = _sourceFreezerTag) AND
                              (status = 'inactive') AND
                            (col = 'na') )))
    ORDER BY shelf, rack, row, Col

    ---------------------------------------------------
    -- Preview or store the rows
    ---------------------------------------------------

    If _infoOnly Then
        SELECT *
        FROM Tmp_T_Material_Locations
        ORDER BY Shelf, Rack, Row, Col
    Else
        INSERT INTO t_material_locations( freezer_tag,
                                          shelf,
                                          rack,
                                          row,
                                          col,
                                          status,
                                          barcode,
                                          comment,
                                          container_limit )
        SELECT freezer_tag,
               shelf,
               rack,
               row,
               col,
               status,
               barcode,
               comment,
               container_limit
        FROM Tmp_T_Material_Locations
        ORDER BY shelf, rack, row, Col
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        _message := format('Added %s rows to t_material_locations by copying freezer_tag %s',
                            _insertCount, _sourceFreezerTag);

        CALL post_log_entry ('Normal', _message, 'Add_New_Freezer');
    End If;

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    DROP TABLE Tmp_T_Material_Locations;
END
$$;

COMMENT ON PROCEDURE public.add_new_freezer IS 'AddNewFreezer';

INSERT INTO t_material_locations (freezer_tag, shelf, rack, "row", col, status, barcode, "comment", container_limit)
SELECT '1208C' AS freezer_tag, shelf, rack, "row", col, status, barcode, '' AS "comment", container_limit
FROM t_material_locations
WHERE freezer_tag = '1208a' AND
      shelf = '6' AND
      rack IN ('1', '2', '3') AND
      row IN ('1', '2', '3', '4') AND
      col IN ('1', '2', '3', '4', '5')
ORDER BY shelf, rack, row, col;

INSERT INTO t_material_locations (freezer_tag, shelf, rack, "row", col, status, barcode, "comment", container_limit)
SELECT '1208C' AS freezer_tag, shelf, rack, "row", col, 'Active' AS status, barcode, '' AS "comment", 5000 AS container_limit
FROM t_material_locations
WHERE freezer_tag = '1206C' and shelf IN ('2', '3', '4', '5') and col ='na'
ORDER BY shelf, rack, row, col;

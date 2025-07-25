--
-- PostgreSQL manual dump
--

SELECT member, role, path
FROM v_role_members
ORDER BY member, role;

member	role	path
------  ----    ----
dmsreader	readaccess	dmsreader -> readaccess
dmswebuser	readaccess	dmswebuser -> readaccess
dmswebuser	writeaccess	dmswebuser -> writeaccess
"svc-dms"	readaccess	"svc-dms" -> readaccess
"svc-dms"	writeaccess	"svc-dms" -> writeaccess
pgdms	readaccess	pgdms -> readaccess
pgdms	writeaccess	pgdms -> writeaccess
pgwatch2	readaccess	pgwatch2 -> readaccess
lcmsnetuser	readaccess	lcmsnetuser -> readaccess
pceditor	readaccess	pceditor -> readaccess
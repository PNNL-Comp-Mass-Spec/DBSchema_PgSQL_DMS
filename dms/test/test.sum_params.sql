--
-- Name: sum_params(integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.sum_params(_param1 integer DEFAULT 1, _param2 integer DEFAULT 1, _param3 integer DEFAULT 1, _param4 integer DEFAULT 1, _param5 integer DEFAULT 1, _param6 integer DEFAULT 1, _param7 integer DEFAULT 1, _param8 integer DEFAULT 1, _param9 integer DEFAULT 1, _param10 integer DEFAULT 1, _param11 integer DEFAULT 1, _param12 integer DEFAULT 1, _param13 integer DEFAULT 1, _param14 integer DEFAULT 1, _param15 integer DEFAULT 1, _param16 integer DEFAULT 1, _param17 integer DEFAULT 1, _param18 integer DEFAULT 1, _param19 integer DEFAULT 1, _param20 integer DEFAULT 1, _param21 integer DEFAULT 1, _param22 integer DEFAULT 1, _param23 integer DEFAULT 1, _param24 integer DEFAULT 1, _param25 integer DEFAULT 1, _param26 integer DEFAULT 1, _param27 integer DEFAULT 1, _param28 integer DEFAULT 1, _param29 integer DEFAULT 1, _param30 integer DEFAULT 1, _param31 integer DEFAULT 1, _param32 integer DEFAULT 1, _param33 integer DEFAULT 1, _param34 integer DEFAULT 1, _param35 integer DEFAULT 1, _param36 integer DEFAULT 1, _param37 integer DEFAULT 1, _param38 integer DEFAULT 1, _param39 integer DEFAULT 1, _param40 integer DEFAULT 1, _param41 integer DEFAULT 1, _param42 integer DEFAULT 1, _param43 integer DEFAULT 1, _param44 integer DEFAULT 1, _param45 integer DEFAULT 1, _param46 integer DEFAULT 1, _param47 integer DEFAULT 1, _param48 integer DEFAULT 1, _param49 integer DEFAULT 1, _param50 integer DEFAULT 1, _param51 integer DEFAULT 1, _param52 integer DEFAULT 1, _param53 integer DEFAULT 1, _param54 integer DEFAULT 1, _param55 integer DEFAULT 1, _param56 integer DEFAULT 1, _param57 integer DEFAULT 1, _param58 integer DEFAULT 1, _param59 integer DEFAULT 1, _param60 integer DEFAULT 1, _param61 integer DEFAULT 1, _param62 integer DEFAULT 1, _param63 integer DEFAULT 1, _param64 integer DEFAULT 1, _param65 integer DEFAULT 1, _param66 integer DEFAULT 1, _param67 integer DEFAULT 1, _param68 integer DEFAULT 1, _param69 integer DEFAULT 1, _param70 integer DEFAULT 1, _param71 integer DEFAULT 1, _param72 integer DEFAULT 1, _param73 integer DEFAULT 1, _param74 integer DEFAULT 1, _param75 integer DEFAULT 1, _param76 integer DEFAULT 1, _param77 integer DEFAULT 1, _param78 integer DEFAULT 1, _param79 integer DEFAULT 1, _param80 integer DEFAULT 1, _param81 integer DEFAULT 1, _param82 integer DEFAULT 1, _param83 integer DEFAULT 1, _param84 integer DEFAULT 1, _param85 integer DEFAULT 1, _param86 integer DEFAULT 1, _param87 integer DEFAULT 1, _param88 integer DEFAULT 1, _param89 integer DEFAULT 1, _param90 integer DEFAULT 1, _param91 integer DEFAULT 1, _param92 integer DEFAULT 1, _param93 integer DEFAULT 1, _param94 integer DEFAULT 1, _param95 integer DEFAULT 1, _param96 integer DEFAULT 1, _param97 integer DEFAULT 1, _param98 integer DEFAULT 1, _param99 integer DEFAULT 1, _param100 integer DEFAULT 1) RETURNS TABLE(total integer, count_positive integer, count_negative integer, count_zero integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Demonstrates the feasibility of a procedure with 100 parameters
**      Sums the parameter values
**      Also counts the number of parameters that are positive, negative, or zero
**
**      Based on a SQL Server article at https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/crazy-number-of-parameters-and-a-challenge/
**      The article demonstrates that SQL Server allows up to 2100 parameters on a procedure
**      In contrast, PostgreSQL has a 100 parameter limit (though this can be increased by recompiling PostgreSQL)
**      The alternative is to use an array parameter
**
**  Arguments:
**    _param1 through _param100     Numbered parameters
**
**  Example usage:
**      SELECT * FROM test.sum_params();
**      SELECT * FROM test.sum_params(-5, -6, -7, 0, 0, 0);
**
**  Auth:   mem
**  Date:   02/24/2025 mem - Initial version
**
*****************************************************/
DECLARE
    _sum int;
    _countPositive int;
    _countNegative int;
    _countZero int;
    _paramNum int;
    _sql text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
BEGIN
    BEGIN
        -----------------------------------------------------------
        -- Compute the sum of the parameter values
        -----------------------------------------------------------

        SELECT _param1 + _param2 + _param3 + _param4 + _param5 + _param6 + _param7 + _param8 + _param9 + _param10 + _param11 + _param12 + _param13 + _param14 + _param15 + _param16 + _param17 + _param18 + _param19 + _param20 + _param21 + _param22 + _param23 + _param24 + _param25 + _param26 + _param27 + _param28 + _param29 + _param30 + _param31 + _param32 + _param33 + _param34 + _param35 + _param36 + _param37 + _param38 + _param39 + _param40 + _param41 + _param42 + _param43 + _param44 + _param45 + _param46 + _param47 + _param48 + _param49 + _param50 + _param51 + _param52 + _param53 + _param54 + _param55 + _param56 + _param57 + _param58 + _param59 + _param60 + _param61 + _param62 + _param63 + _param64 + _param65 + _param66 + _param67 + _param68 + _param69 + _param70 + _param71 + _param72 + _param73 + _param74 + _param75 + _param76 + _param77 + _param78 + _param79 + _param80 + _param81 + _param82 + _param83 + _param84 + _param85 + _param86 + _param87 + _param88 + _param89 + _param90 + _param91 + _param92 + _param93 + _param94 + _param95 + _param96 + _param97 + _param98 + _param99 + _param100
        INTO _sum;

        -----------------------------------------------------------
        -- Count the number of values that are positive, negative, or zero
        -----------------------------------------------------------

        SELECT SUM(CASE WHEN _param1 > 0 THEN 1 ELSE 0 END + CASE WHEN _param2 > 0 THEN 1 ELSE 0 END + CASE WHEN _param3 > 0 THEN 1 ELSE 0 END + CASE WHEN _param4 > 0 THEN 1 ELSE 0 END + CASE WHEN _param5 > 0 THEN 1 ELSE 0 END + CASE WHEN _param6 > 0 THEN 1 ELSE 0 END + CASE WHEN _param7 > 0 THEN 1 ELSE 0 END + CASE WHEN _param8 > 0 THEN 1 ELSE 0 END + CASE WHEN _param9 > 0 THEN 1 ELSE 0 END + CASE WHEN _param10 > 0 THEN 1 ELSE 0 END + CASE WHEN _param11 > 0 THEN 1 ELSE 0 END + CASE WHEN _param12 > 0 THEN 1 ELSE 0 END + CASE WHEN _param13 > 0 THEN 1 ELSE 0 END + CASE WHEN _param14 > 0 THEN 1 ELSE 0 END + CASE WHEN _param15 > 0 THEN 1 ELSE 0 END + CASE WHEN _param16 > 0 THEN 1 ELSE 0 END + CASE WHEN _param17 > 0 THEN 1 ELSE 0 END + CASE WHEN _param18 > 0 THEN 1 ELSE 0 END + CASE WHEN _param19 > 0 THEN 1 ELSE 0 END + CASE WHEN _param20 > 0 THEN 1 ELSE 0 END + CASE WHEN _param21 > 0 THEN 1 ELSE 0 END + CASE WHEN _param22 > 0 THEN 1 ELSE 0 END + CASE WHEN _param23 > 0 THEN 1 ELSE 0 END + CASE WHEN _param24 > 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param25 > 0 THEN 1 ELSE 0 END + CASE WHEN _param26 > 0 THEN 1 ELSE 0 END + CASE WHEN _param27 > 0 THEN 1 ELSE 0 END + CASE WHEN _param28 > 0 THEN 1 ELSE 0 END + CASE WHEN _param29 > 0 THEN 1 ELSE 0 END + CASE WHEN _param30 > 0 THEN 1 ELSE 0 END + CASE WHEN _param31 > 0 THEN 1 ELSE 0 END + CASE WHEN _param32 > 0 THEN 1 ELSE 0 END + CASE WHEN _param33 > 0 THEN 1 ELSE 0 END + CASE WHEN _param34 > 0 THEN 1 ELSE 0 END + CASE WHEN _param35 > 0 THEN 1 ELSE 0 END + CASE WHEN _param36 > 0 THEN 1 ELSE 0 END + CASE WHEN _param37 > 0 THEN 1 ELSE 0 END + CASE WHEN _param38 > 0 THEN 1 ELSE 0 END + CASE WHEN _param39 > 0 THEN 1 ELSE 0 END + CASE WHEN _param40 > 0 THEN 1 ELSE 0 END + CASE WHEN _param41 > 0 THEN 1 ELSE 0 END + CASE WHEN _param42 > 0 THEN 1 ELSE 0 END + CASE WHEN _param43 > 0 THEN 1 ELSE 0 END + CASE WHEN _param44 > 0 THEN 1 ELSE 0 END + CASE WHEN _param45 > 0 THEN 1 ELSE 0 END + CASE WHEN _param46 > 0 THEN 1 ELSE 0 END + CASE WHEN _param47 > 0 THEN 1 ELSE 0 END + CASE WHEN _param48 > 0 THEN 1 ELSE 0 END + CASE WHEN _param49 > 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param50 > 0 THEN 1 ELSE 0 END + CASE WHEN _param51 > 0 THEN 1 ELSE 0 END + CASE WHEN _param52 > 0 THEN 1 ELSE 0 END + CASE WHEN _param53 > 0 THEN 1 ELSE 0 END + CASE WHEN _param54 > 0 THEN 1 ELSE 0 END + CASE WHEN _param55 > 0 THEN 1 ELSE 0 END + CASE WHEN _param56 > 0 THEN 1 ELSE 0 END + CASE WHEN _param57 > 0 THEN 1 ELSE 0 END + CASE WHEN _param58 > 0 THEN 1 ELSE 0 END + CASE WHEN _param59 > 0 THEN 1 ELSE 0 END + CASE WHEN _param60 > 0 THEN 1 ELSE 0 END + CASE WHEN _param61 > 0 THEN 1 ELSE 0 END + CASE WHEN _param62 > 0 THEN 1 ELSE 0 END + CASE WHEN _param63 > 0 THEN 1 ELSE 0 END + CASE WHEN _param64 > 0 THEN 1 ELSE 0 END + CASE WHEN _param65 > 0 THEN 1 ELSE 0 END + CASE WHEN _param66 > 0 THEN 1 ELSE 0 END + CASE WHEN _param67 > 0 THEN 1 ELSE 0 END + CASE WHEN _param68 > 0 THEN 1 ELSE 0 END + CASE WHEN _param69 > 0 THEN 1 ELSE 0 END + CASE WHEN _param70 > 0 THEN 1 ELSE 0 END + CASE WHEN _param71 > 0 THEN 1 ELSE 0 END + CASE WHEN _param72 > 0 THEN 1 ELSE 0 END + CASE WHEN _param73 > 0 THEN 1 ELSE 0 END + CASE WHEN _param74 > 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param75 > 0 THEN 1 ELSE 0 END + CASE WHEN _param76 > 0 THEN 1 ELSE 0 END + CASE WHEN _param77 > 0 THEN 1 ELSE 0 END + CASE WHEN _param78 > 0 THEN 1 ELSE 0 END + CASE WHEN _param79 > 0 THEN 1 ELSE 0 END + CASE WHEN _param80 > 0 THEN 1 ELSE 0 END + CASE WHEN _param81 > 0 THEN 1 ELSE 0 END + CASE WHEN _param82 > 0 THEN 1 ELSE 0 END + CASE WHEN _param83 > 0 THEN 1 ELSE 0 END + CASE WHEN _param84 > 0 THEN 1 ELSE 0 END + CASE WHEN _param85 > 0 THEN 1 ELSE 0 END + CASE WHEN _param86 > 0 THEN 1 ELSE 0 END + CASE WHEN _param87 > 0 THEN 1 ELSE 0 END + CASE WHEN _param88 > 0 THEN 1 ELSE 0 END + CASE WHEN _param89 > 0 THEN 1 ELSE 0 END + CASE WHEN _param90 > 0 THEN 1 ELSE 0 END + CASE WHEN _param91 > 0 THEN 1 ELSE 0 END + CASE WHEN _param92 > 0 THEN 1 ELSE 0 END + CASE WHEN _param93 > 0 THEN 1 ELSE 0 END + CASE WHEN _param94 > 0 THEN 1 ELSE 0 END + CASE WHEN _param95 > 0 THEN 1 ELSE 0 END + CASE WHEN _param96 > 0 THEN 1 ELSE 0 END + CASE WHEN _param97 > 0 THEN 1 ELSE 0 END + CASE WHEN _param98 > 0 THEN 1 ELSE 0 END + CASE WHEN _param99 > 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param100 > 0 THEN 1 ELSE 0 END) AS CountPositive,
               SUM(CASE WHEN _param1 < 0 THEN 1 ELSE 0 END + CASE WHEN _param2 < 0 THEN 1 ELSE 0 END + CASE WHEN _param3 < 0 THEN 1 ELSE 0 END + CASE WHEN _param4 < 0 THEN 1 ELSE 0 END + CASE WHEN _param5 < 0 THEN 1 ELSE 0 END + CASE WHEN _param6 < 0 THEN 1 ELSE 0 END + CASE WHEN _param7 < 0 THEN 1 ELSE 0 END + CASE WHEN _param8 < 0 THEN 1 ELSE 0 END + CASE WHEN _param9 < 0 THEN 1 ELSE 0 END + CASE WHEN _param10 < 0 THEN 1 ELSE 0 END + CASE WHEN _param11 < 0 THEN 1 ELSE 0 END + CASE WHEN _param12 < 0 THEN 1 ELSE 0 END + CASE WHEN _param13 < 0 THEN 1 ELSE 0 END + CASE WHEN _param14 < 0 THEN 1 ELSE 0 END + CASE WHEN _param15 < 0 THEN 1 ELSE 0 END + CASE WHEN _param16 < 0 THEN 1 ELSE 0 END + CASE WHEN _param17 < 0 THEN 1 ELSE 0 END + CASE WHEN _param18 < 0 THEN 1 ELSE 0 END + CASE WHEN _param19 < 0 THEN 1 ELSE 0 END + CASE WHEN _param20 < 0 THEN 1 ELSE 0 END + CASE WHEN _param21 < 0 THEN 1 ELSE 0 END + CASE WHEN _param22 < 0 THEN 1 ELSE 0 END + CASE WHEN _param23 < 0 THEN 1 ELSE 0 END + CASE WHEN _param24 < 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param25 < 0 THEN 1 ELSE 0 END + CASE WHEN _param26 < 0 THEN 1 ELSE 0 END + CASE WHEN _param27 < 0 THEN 1 ELSE 0 END + CASE WHEN _param28 < 0 THEN 1 ELSE 0 END + CASE WHEN _param29 < 0 THEN 1 ELSE 0 END + CASE WHEN _param30 < 0 THEN 1 ELSE 0 END + CASE WHEN _param31 < 0 THEN 1 ELSE 0 END + CASE WHEN _param32 < 0 THEN 1 ELSE 0 END + CASE WHEN _param33 < 0 THEN 1 ELSE 0 END + CASE WHEN _param34 < 0 THEN 1 ELSE 0 END + CASE WHEN _param35 < 0 THEN 1 ELSE 0 END + CASE WHEN _param36 < 0 THEN 1 ELSE 0 END + CASE WHEN _param37 < 0 THEN 1 ELSE 0 END + CASE WHEN _param38 < 0 THEN 1 ELSE 0 END + CASE WHEN _param39 < 0 THEN 1 ELSE 0 END + CASE WHEN _param40 < 0 THEN 1 ELSE 0 END + CASE WHEN _param41 < 0 THEN 1 ELSE 0 END + CASE WHEN _param42 < 0 THEN 1 ELSE 0 END + CASE WHEN _param43 < 0 THEN 1 ELSE 0 END + CASE WHEN _param44 < 0 THEN 1 ELSE 0 END + CASE WHEN _param45 < 0 THEN 1 ELSE 0 END + CASE WHEN _param46 < 0 THEN 1 ELSE 0 END + CASE WHEN _param47 < 0 THEN 1 ELSE 0 END + CASE WHEN _param48 < 0 THEN 1 ELSE 0 END + CASE WHEN _param49 < 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param50 < 0 THEN 1 ELSE 0 END + CASE WHEN _param51 < 0 THEN 1 ELSE 0 END + CASE WHEN _param52 < 0 THEN 1 ELSE 0 END + CASE WHEN _param53 < 0 THEN 1 ELSE 0 END + CASE WHEN _param54 < 0 THEN 1 ELSE 0 END + CASE WHEN _param55 < 0 THEN 1 ELSE 0 END + CASE WHEN _param56 < 0 THEN 1 ELSE 0 END + CASE WHEN _param57 < 0 THEN 1 ELSE 0 END + CASE WHEN _param58 < 0 THEN 1 ELSE 0 END + CASE WHEN _param59 < 0 THEN 1 ELSE 0 END + CASE WHEN _param60 < 0 THEN 1 ELSE 0 END + CASE WHEN _param61 < 0 THEN 1 ELSE 0 END + CASE WHEN _param62 < 0 THEN 1 ELSE 0 END + CASE WHEN _param63 < 0 THEN 1 ELSE 0 END + CASE WHEN _param64 < 0 THEN 1 ELSE 0 END + CASE WHEN _param65 < 0 THEN 1 ELSE 0 END + CASE WHEN _param66 < 0 THEN 1 ELSE 0 END + CASE WHEN _param67 < 0 THEN 1 ELSE 0 END + CASE WHEN _param68 < 0 THEN 1 ELSE 0 END + CASE WHEN _param69 < 0 THEN 1 ELSE 0 END + CASE WHEN _param70 < 0 THEN 1 ELSE 0 END + CASE WHEN _param71 < 0 THEN 1 ELSE 0 END + CASE WHEN _param72 < 0 THEN 1 ELSE 0 END + CASE WHEN _param73 < 0 THEN 1 ELSE 0 END + CASE WHEN _param74 < 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param75 < 0 THEN 1 ELSE 0 END + CASE WHEN _param76 < 0 THEN 1 ELSE 0 END + CASE WHEN _param77 < 0 THEN 1 ELSE 0 END + CASE WHEN _param78 < 0 THEN 1 ELSE 0 END + CASE WHEN _param79 < 0 THEN 1 ELSE 0 END + CASE WHEN _param80 < 0 THEN 1 ELSE 0 END + CASE WHEN _param81 < 0 THEN 1 ELSE 0 END + CASE WHEN _param82 < 0 THEN 1 ELSE 0 END + CASE WHEN _param83 < 0 THEN 1 ELSE 0 END + CASE WHEN _param84 < 0 THEN 1 ELSE 0 END + CASE WHEN _param85 < 0 THEN 1 ELSE 0 END + CASE WHEN _param86 < 0 THEN 1 ELSE 0 END + CASE WHEN _param87 < 0 THEN 1 ELSE 0 END + CASE WHEN _param88 < 0 THEN 1 ELSE 0 END + CASE WHEN _param89 < 0 THEN 1 ELSE 0 END + CASE WHEN _param90 < 0 THEN 1 ELSE 0 END + CASE WHEN _param91 < 0 THEN 1 ELSE 0 END + CASE WHEN _param92 < 0 THEN 1 ELSE 0 END + CASE WHEN _param93 < 0 THEN 1 ELSE 0 END + CASE WHEN _param94 < 0 THEN 1 ELSE 0 END + CASE WHEN _param95 < 0 THEN 1 ELSE 0 END + CASE WHEN _param96 < 0 THEN 1 ELSE 0 END + CASE WHEN _param97 < 0 THEN 1 ELSE 0 END + CASE WHEN _param98 < 0 THEN 1 ELSE 0 END + CASE WHEN _param99 < 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param100 < 0 THEN 1 ELSE 0 END) AS CountNegative,
               SUM(CASE WHEN _param1 = 0 THEN 1 ELSE 0 END + CASE WHEN _param2 = 0 THEN 1 ELSE 0 END + CASE WHEN _param3 = 0 THEN 1 ELSE 0 END + CASE WHEN _param4 = 0 THEN 1 ELSE 0 END + CASE WHEN _param5 = 0 THEN 1 ELSE 0 END + CASE WHEN _param6 = 0 THEN 1 ELSE 0 END + CASE WHEN _param7 = 0 THEN 1 ELSE 0 END + CASE WHEN _param8 = 0 THEN 1 ELSE 0 END + CASE WHEN _param9 = 0 THEN 1 ELSE 0 END + CASE WHEN _param10 = 0 THEN 1 ELSE 0 END + CASE WHEN _param11 = 0 THEN 1 ELSE 0 END + CASE WHEN _param12 = 0 THEN 1 ELSE 0 END + CASE WHEN _param13 = 0 THEN 1 ELSE 0 END + CASE WHEN _param14 = 0 THEN 1 ELSE 0 END + CASE WHEN _param15 = 0 THEN 1 ELSE 0 END + CASE WHEN _param16 = 0 THEN 1 ELSE 0 END + CASE WHEN _param17 = 0 THEN 1 ELSE 0 END + CASE WHEN _param18 = 0 THEN 1 ELSE 0 END + CASE WHEN _param19 = 0 THEN 1 ELSE 0 END + CASE WHEN _param20 = 0 THEN 1 ELSE 0 END + CASE WHEN _param21 = 0 THEN 1 ELSE 0 END + CASE WHEN _param22 = 0 THEN 1 ELSE 0 END + CASE WHEN _param23 = 0 THEN 1 ELSE 0 END + CASE WHEN _param24 = 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param25 = 0 THEN 1 ELSE 0 END + CASE WHEN _param26 = 0 THEN 1 ELSE 0 END + CASE WHEN _param27 = 0 THEN 1 ELSE 0 END + CASE WHEN _param28 = 0 THEN 1 ELSE 0 END + CASE WHEN _param29 = 0 THEN 1 ELSE 0 END + CASE WHEN _param30 = 0 THEN 1 ELSE 0 END + CASE WHEN _param31 = 0 THEN 1 ELSE 0 END + CASE WHEN _param32 = 0 THEN 1 ELSE 0 END + CASE WHEN _param33 = 0 THEN 1 ELSE 0 END + CASE WHEN _param34 = 0 THEN 1 ELSE 0 END + CASE WHEN _param35 = 0 THEN 1 ELSE 0 END + CASE WHEN _param36 = 0 THEN 1 ELSE 0 END + CASE WHEN _param37 = 0 THEN 1 ELSE 0 END + CASE WHEN _param38 = 0 THEN 1 ELSE 0 END + CASE WHEN _param39 = 0 THEN 1 ELSE 0 END + CASE WHEN _param40 = 0 THEN 1 ELSE 0 END + CASE WHEN _param41 = 0 THEN 1 ELSE 0 END + CASE WHEN _param42 = 0 THEN 1 ELSE 0 END + CASE WHEN _param43 = 0 THEN 1 ELSE 0 END + CASE WHEN _param44 = 0 THEN 1 ELSE 0 END + CASE WHEN _param45 = 0 THEN 1 ELSE 0 END + CASE WHEN _param46 = 0 THEN 1 ELSE 0 END + CASE WHEN _param47 = 0 THEN 1 ELSE 0 END + CASE WHEN _param48 = 0 THEN 1 ELSE 0 END + CASE WHEN _param49 = 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param50 = 0 THEN 1 ELSE 0 END + CASE WHEN _param51 = 0 THEN 1 ELSE 0 END + CASE WHEN _param52 = 0 THEN 1 ELSE 0 END + CASE WHEN _param53 = 0 THEN 1 ELSE 0 END + CASE WHEN _param54 = 0 THEN 1 ELSE 0 END + CASE WHEN _param55 = 0 THEN 1 ELSE 0 END + CASE WHEN _param56 = 0 THEN 1 ELSE 0 END + CASE WHEN _param57 = 0 THEN 1 ELSE 0 END + CASE WHEN _param58 = 0 THEN 1 ELSE 0 END + CASE WHEN _param59 = 0 THEN 1 ELSE 0 END + CASE WHEN _param60 = 0 THEN 1 ELSE 0 END + CASE WHEN _param61 = 0 THEN 1 ELSE 0 END + CASE WHEN _param62 = 0 THEN 1 ELSE 0 END + CASE WHEN _param63 = 0 THEN 1 ELSE 0 END + CASE WHEN _param64 = 0 THEN 1 ELSE 0 END + CASE WHEN _param65 = 0 THEN 1 ELSE 0 END + CASE WHEN _param66 = 0 THEN 1 ELSE 0 END + CASE WHEN _param67 = 0 THEN 1 ELSE 0 END + CASE WHEN _param68 = 0 THEN 1 ELSE 0 END + CASE WHEN _param69 = 0 THEN 1 ELSE 0 END + CASE WHEN _param70 = 0 THEN 1 ELSE 0 END + CASE WHEN _param71 = 0 THEN 1 ELSE 0 END + CASE WHEN _param72 = 0 THEN 1 ELSE 0 END + CASE WHEN _param73 = 0 THEN 1 ELSE 0 END + CASE WHEN _param74 = 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param75 = 0 THEN 1 ELSE 0 END + CASE WHEN _param76 = 0 THEN 1 ELSE 0 END + CASE WHEN _param77 = 0 THEN 1 ELSE 0 END + CASE WHEN _param78 = 0 THEN 1 ELSE 0 END + CASE WHEN _param79 = 0 THEN 1 ELSE 0 END + CASE WHEN _param80 = 0 THEN 1 ELSE 0 END + CASE WHEN _param81 = 0 THEN 1 ELSE 0 END + CASE WHEN _param82 = 0 THEN 1 ELSE 0 END + CASE WHEN _param83 = 0 THEN 1 ELSE 0 END + CASE WHEN _param84 = 0 THEN 1 ELSE 0 END + CASE WHEN _param85 = 0 THEN 1 ELSE 0 END + CASE WHEN _param86 = 0 THEN 1 ELSE 0 END + CASE WHEN _param87 = 0 THEN 1 ELSE 0 END + CASE WHEN _param88 = 0 THEN 1 ELSE 0 END + CASE WHEN _param89 = 0 THEN 1 ELSE 0 END + CASE WHEN _param90 = 0 THEN 1 ELSE 0 END + CASE WHEN _param91 = 0 THEN 1 ELSE 0 END + CASE WHEN _param92 = 0 THEN 1 ELSE 0 END + CASE WHEN _param93 = 0 THEN 1 ELSE 0 END + CASE WHEN _param94 = 0 THEN 1 ELSE 0 END + CASE WHEN _param95 = 0 THEN 1 ELSE 0 END + CASE WHEN _param96 = 0 THEN 1 ELSE 0 END + CASE WHEN _param97 = 0 THEN 1 ELSE 0 END + CASE WHEN _param98 = 0 THEN 1 ELSE 0 END + CASE WHEN _param99 = 0 THEN 1 ELSE 0 END +
                   CASE WHEN _param100 = 0 THEN 1 ELSE 0 END) AS CountZero
        INTO _countPositive,_countNegative, _countZero;

        RETURN QUERY
        SELECT _sum,
               _countPositive,
               _countNegative,
               _countZero;
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        RAISE WARNING '%', _message;
    END;
END
$$;


ALTER FUNCTION test.sum_params(_param1 integer, _param2 integer, _param3 integer, _param4 integer, _param5 integer, _param6 integer, _param7 integer, _param8 integer, _param9 integer, _param10 integer, _param11 integer, _param12 integer, _param13 integer, _param14 integer, _param15 integer, _param16 integer, _param17 integer, _param18 integer, _param19 integer, _param20 integer, _param21 integer, _param22 integer, _param23 integer, _param24 integer, _param25 integer, _param26 integer, _param27 integer, _param28 integer, _param29 integer, _param30 integer, _param31 integer, _param32 integer, _param33 integer, _param34 integer, _param35 integer, _param36 integer, _param37 integer, _param38 integer, _param39 integer, _param40 integer, _param41 integer, _param42 integer, _param43 integer, _param44 integer, _param45 integer, _param46 integer, _param47 integer, _param48 integer, _param49 integer, _param50 integer, _param51 integer, _param52 integer, _param53 integer, _param54 integer, _param55 integer, _param56 integer, _param57 integer, _param58 integer, _param59 integer, _param60 integer, _param61 integer, _param62 integer, _param63 integer, _param64 integer, _param65 integer, _param66 integer, _param67 integer, _param68 integer, _param69 integer, _param70 integer, _param71 integer, _param72 integer, _param73 integer, _param74 integer, _param75 integer, _param76 integer, _param77 integer, _param78 integer, _param79 integer, _param80 integer, _param81 integer, _param82 integer, _param83 integer, _param84 integer, _param85 integer, _param86 integer, _param87 integer, _param88 integer, _param89 integer, _param90 integer, _param91 integer, _param92 integer, _param93 integer, _param94 integer, _param95 integer, _param96 integer, _param97 integer, _param98 integer, _param99 integer, _param100 integer) OWNER TO d3l243;


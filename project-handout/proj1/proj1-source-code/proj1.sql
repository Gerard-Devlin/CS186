-- Before running drop any existing views
DROP VIEW IF EXISTS q0;

DROP VIEW IF EXISTS q1i;

DROP VIEW IF EXISTS q1ii;

DROP VIEW IF EXISTS q1iii;

DROP VIEW IF EXISTS q1iv;

DROP VIEW IF EXISTS q2i;

DROP VIEW IF EXISTS q2ii;

DROP VIEW IF EXISTS q2iii;

DROP VIEW IF EXISTS q3i;

DROP VIEW IF EXISTS q3ii;

DROP VIEW IF EXISTS q3iii;

DROP VIEW IF EXISTS q4i;

DROP VIEW IF EXISTS q4ii;

DROP VIEW IF EXISTS q4iii;

DROP VIEW IF EXISTS q4iv;

DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era) AS -- SELECT 1 -- replace this line
SELECT
  MAX(era)
FROM
  pitching;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear) AS
SELECT
  namefirst,
  namelast,
  birthyear
FROM
  People P
WHERE
  P.weight > 300;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear) AS
SELECT
  namefirst,
  namelast,
  birthyear
FROM
  People P
WHERE
  P.namefirst LIKE '% %'
ORDER BY
  P.namefirst ASC,
  P.namelast ASC;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count) AS
SELECT
  birthyear,
  AVG(height),
  COUNT (*)
FROM
  People
GROUP BY
  birthyear
ORDER BY
  birthyear ASC;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count) AS
SELECT
  birthyear,
  AVG(height),
  COUNT(*)
FROM
  People
GROUP BY
  birthyear
HAVING
  AVG(height) > 70;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid) AS
SELECT
  P.namefirst,
  P.namelast,
  H.playerid,
  H.yearid
FROM
  halloffame H,
  People P
WHERE
  H.playerid = P.playerid
  AND H.inducted LIKE 'Y'
ORDER BY
  H.yearid DESC,
  H.playerid ASC;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid) AS
SELECT
  q2i.namefirst,
  q2i.namelast,
  q2i.playerid,
  S.schoolid,
  q2i.yearid
FROM
  q2i,
  CollegePlaying CP,
  Schools S
WHERE
  S.schoolState LIKE 'CA'
  AND q2i.playerid = CP.playerid
  AND CP.schoolid = S.schoolid
ORDER BY
  q2i.yearid DESC,
  S.schoolid ASC,
  q2i.playerid ASC;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid) AS
SELECT
  q2i.playerid,
  q2i.namefirst,
  q2i.namelast,
  schoolid
FROM
  q2i
  LEFT JOIN CollegePlaying CP ON q2i.playerid = CP.playerid
ORDER BY
  q2i.playerid DESC,
  schoolid ASC;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg) AS
SELECT
  P.playerid,
  namefirst,
  namelast,
  yearid,
  1.0 *(H - H2B - H3B - HR + 2 * H2B + 3 * H3B + 4 * HR) / AB AS slg
FROM
  People P
  INNER JOIN batting B ON B.playerid = P.playerid
WHERE
  AB > 50
ORDER BY
  slg DESC,
  yearid ASC,
  P.playerid ASC
LIMIT
  10;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg) AS
SELECT
  P.playerid,
  P.namefirst,
  P.namelast,
  1.0 * SUM(
    (H - H2B - H3B - HR + 2 * H2B + 3 * H3B + 4 * HR)
  ) / SUM(AB) AS lslg
FROM
  People P
  INNER JOIN batting B ON B.playerid = P.playerid
GROUP BY
  P.playerid,
  -- must group by to sum a single person's lslg
  P.namefirst,
  P.namelast
HAVING
  SUM(AB) > 50
ORDER BY
  lslg DESC,
  P.playerid ASC
LIMIT
  10;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg) AS
SELECT
  P.namefirst,
  P.namelast,
  1.0 * SUM(
    (H - H2B - H3B - HR + 2 * H2B + 3 * H3B + 4 * HR)
  ) / SUM(AB) AS lslg
FROM
  People P
  JOIN batting B ON B.playerid = P.playerid
GROUP BY
  P.playerid,
  -- important to groupy by playerid bcs there might be same names
  P.namefirst,
  P.namelast
HAVING
  SUM(AB) > 50
  AND lslg >(
    SELECT
      1.0 * SUM(
        (H - H2B - H3B - HR + 2 * H2B + 3 * H3B + 4 * HR)
      ) / SUM(AB)
    FROM
      batting B
    WHERE
      B.playerid = 'mayswi01'
  );

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg) AS
SELECT
  S.yearid,
  MIN(salary),
  MAX(salary),
  AVG(salary)
FROM
  salaries S
GROUP BY
  S.yearid
ORDER BY
  S.yearid ASC;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count) AS WITH bounds AS (
  SELECT
    MIN(salary) AS minsal,
    MAX(salary) AS maxsal,
    (MAX(salary) - MIN(salary)) / 10.0 AS width
  FROM
    salaries
  WHERE
    yearid = 2016
),
bins AS (
  SELECT
    CASE
      WHEN CAST((s.salary - b.minsal) / b.width AS INT) >= 9 THEN 9
      ELSE CAST((s.salary - b.minsal) / b.width AS INT)
    END AS binid
  FROM
    salaries s
    CROSS JOIN bounds b
  WHERE
    s.yearid = 2016
),
counts AS (
  SELECT
    binid,
    COUNT(*) AS cnt
  FROM
    bins
  GROUP BY
    binid
)
SELECT
  bi.binid,
  b.minsal + bi.binid * b.width AS low,
  CASE
    WHEN bi.binid = 9 THEN b.maxsal
    ELSE b.minsal + (bi.binid + 1) * b.width
  END AS high,
  COALESCE(c.cnt, 0) AS count
FROM
  binids bi
  CROSS JOIN bounds b
  LEFT JOIN counts c ON bi.binid = c.binid
ORDER BY
  bi.binid;

;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff) AS
SELECT
  I.yearid,
  I.min - II.min,
  I.max - II.max,
  I.avg - II.avg
FROM
  q4i I
  JOIN q4i II ON I.yearid = II.yearid + 1
GROUP BY
  I.yearid;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid) AS
SELECT
  P.playerid,
  P.namefirst,
  P.namelast,
  salary,
  yearid
FROM
  salaries S
  JOIN People P ON S.playerid = P.playerid
WHERE
  S.yearid IN(2000, 2001)
  AND S.salary =(
    SELECT
      MAX(salary)
    FROM
      salaries
    WHERE
      S.yearid = yearid
  );

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
SELECT
  ASF.teamid,
  MAX(S.salary) - MIN(S.salary)
FROM
  allstarfull ASF
  JOIN salaries S ON ASF.playerid = S.playerid
  AND ASF.teamid = S.teamid
  AND ASF.yearid = S.yearid -- must be same team same year same person bcs one person might transfer to different teams in different years
WHERE
  S.yearid = 2016
GROUP BY
  ASF.teamid;
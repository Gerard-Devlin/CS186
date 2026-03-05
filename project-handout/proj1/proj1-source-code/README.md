```bash
sqlite3 lahman.db
```

```sql
.help
.table
.schema halloffme
```

```bash
python test.py -q 2i
```

---

# SQL Notes – Common Mistakes and Key Points (CS186 Project 1)

## 1. JOIN Syntax Errors

### Mistake
Mixing comma joins and explicit JOIN syntax.

Incorrect:
```sql
FROM salaries S, JOIN People P ON S.playerid = P.playerid
````

### Correct

Use **either** comma style **or** explicit JOIN syntax (recommended).

```sql
FROM salaries S
JOIN People P ON S.playerid = P.playerid
```

### Key Rule

Do **not mix** `,` joins with `JOIN ... ON`.

---

# 2. Joining on Too Few Conditions

### Mistake

Joining tables only by `playerid`.

Example mistake:

```sql
JOIN salaries S ON ASF.playerid = S.playerid
```

### Problem

Players appear in:

* multiple **years**
* multiple **teams**

This produces incorrect matches.

### Correct Join

```sql
JOIN salaries S
  ON ASF.playerid = S.playerid
 AND ASF.yearid = S.yearid
 AND ASF.teamid = S.teamid
```

### Rule

Always ensure the join uniquely identifies the intended rows.

---

# 3. Forgetting Required Filters

### Mistake

Not restricting queries to required years.

Example requirement:

```
Only consider year = 2016
```

### Correct

```sql
WHERE ASF.yearid = 2016
```

### Rule

Always check problem statements for **year filters**.

---

# 4. Using Player-Level Differences Instead of Aggregate Differences

### Mistake (Task 4iii)

Comparing salaries of the same player across years.

Example:

```sql
S1.salary - S2.salary
```

### Problem

The question asks for **league statistics differences**, not player differences.

### Correct Approach

1. Compute yearly aggregates.
2. Compare aggregates between years.

Example structure:

```sql
WITH yearly_salary AS (
  SELECT yearid,
         MIN(salary) AS min_salary,
         MAX(salary) AS max_salary,
         AVG(salary) AS avg_salary
  FROM salaries
  GROUP BY yearid
)
SELECT ...
```

---

# 5. Understanding Argmax Queries

### Task Example

Find players with **maximum salary in each year**.

### Correct Pattern

```sql
SELECT ...
FROM salaries S
WHERE S.salary = (
  SELECT MAX(S2.salary)
  FROM salaries S2
  WHERE S2.yearid = S.yearid
)
```

### Key Idea

Find rows where:

```
value = MAX(value)
```

---

# 6. Handling Histogram Bins (Task 4ii)

### Key Formula

To assign bins:

```
binid = floor((salary - min_salary) / width)
```

SQLite implementation:

```sql
CAST((salary - min_salary) / width AS INT)
```

### Important Edge Case

Maximum salary may produce:

```
binid = 10
```

But valid bins are:

```
0–9
```

### Fix

```sql
CASE
  WHEN binid >= 9 THEN 9
  ELSE binid
END
```

---

# 7. Handling Empty Histogram Bins

### Problem

Some bins may contain **zero rows**.

### Incorrect

Using only:

```sql
GROUP BY binid
```

This skips empty bins.

### Correct

Use the provided `binids` table.

```
binids LEFT JOIN counts
```

And replace NULL with 0:

```sql
COALESCE(count, 0)
```

---

# 8. Integer Division vs Floating Point

### Mistake

Using integer division accidentally.

Example:

```sql
(MAX - MIN) / 10
```

This produces integer results.

### Correct

```sql
(MAX - MIN) / 10.0
```

### Rule

Use `.0` to force floating point division.

---

# 9. Ambiguous Column Names

### Mistake

Using columns without table aliases.

Example:

```sql
SELECT playerid
```

### Problem

Column exists in multiple tables.

### Correct

```sql
SELECT S.playerid
```

### Rule

Always qualify columns in joins.

---

# 10. Understanding CTE (WITH Clause)

### Purpose

Create temporary result tables inside a query.

Example:

```sql
WITH bounds AS (
  SELECT MIN(salary), MAX(salary)
  FROM salaries
)
SELECT *
FROM bounds;
```

### Equivalent Concept

```
Temporary table inside a query
```

---

# 11. SQL Execution Order Reminder

Logical execution order:

```
FROM
JOIN
WHERE
GROUP BY
HAVING
SELECT
ORDER BY
LIMIT
```

This explains why:

```
HAVING filters groups
WHERE filters rows
```

---

# Key Takeaways

1. Always check **join conditions carefully**.
2. Apply **year filters explicitly**.
3. Understand **aggregation vs row-level calculations**.
4. Handle **edge cases** (empty bins, max values).
5. Use **table aliases consistently**.
6. Be careful with **integer division**.
7. Use `LEFT JOIN` when results must include missing groups.

-- Question: the "best-paid majors" ranking is a decision tool.
-- How many graduates is each number actually built on?
--
-- Data: FiveThirtyEight "college-majors/recent-grads.csv" (US Census ACS, CC BY 4.0)
-- One row per major. Sample_size = survey respondents behind the row.
-- Rule of thumb used here: fewer than 30 respondents = too thin to rank on.

-- name: headline_top10
-- The ranking everyone quotes: top 10 by median pay (the dataset's own Rank).
SELECT
    Rank                                AS rank_headline,
    Major,
    Median                              AS median_pay,
    Sample_size                         AS respondents,
    Sample_size < 30                    AS too_thin
FROM grads
ORDER BY Rank
LIMIT 10;

-- name: reliable_top10
-- Same question, two fixes: drop majors under 30 respondents,
-- and pay for unemployment risk (median pay x share of graduates employed).
WITH scored AS (
    SELECT
        Rank,
        Major,
        Median,
        Sample_size,
        Median * (1 - Unemployment_rate) AS expected_pay
    FROM grads
    WHERE Sample_size >= 30
)
SELECT
    RANK() OVER (ORDER BY expected_pay DESC) AS rank_reliable,
    Major,
    round(expected_pay)                       AS expected_pay,
    Sample_size                               AS respondents,
    Rank                                      AS rank_headline
FROM scored
ORDER BY rank_reliable
LIMIT 10;

-- name: overlap
-- How many of the headline top 10 survive?
WITH h AS (SELECT Major FROM grads ORDER BY Rank LIMIT 10),
     r AS (
         SELECT Major
         FROM grads
         WHERE Sample_size >= 30
         ORDER BY Median * (1 - Unemployment_rate) DESC
         LIMIT 10
     )
SELECT
    count(*)                               AS survive,
    (SELECT count(*) FROM h) - count(*)    AS dropped
FROM h JOIN r USING (Major);

-- name: thin_share
-- How common is the problem across all 173 majors?
SELECT
    count(*)                                  AS majors,
    count(*) FILTER (WHERE Sample_size < 30)  AS under_30,
    round(100.0 * count(*) FILTER (WHERE Sample_size < 30) / count(*)) AS pct_under_30
FROM grads;

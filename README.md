# 📊 Cumulative_Table_Design

Data modeling your data in a cumulative fashion helps aggregate 📈 data over time, typically at specific grains (📅 daily, 📆 weekly, 📅 yearly). It optimizes performance for analytical queries requiring pre-aggregated data, such as trends or summaries over time.

# **Cumulative Table Design for NBA Player Statistics** 🏀

## **Overview** 🏆

This project demonstrates a **cumulative table design (CTD)** for tracking player statistics across seasons using 🐘 PostgreSQL. The design maintains 📜 historical data while incrementally updating the cumulative table with new season data. This approach optimizes 💻 performance, reduces 🧮 computational costs, and ensures data consistency.

### Key Features 🌟:

- Use of **custom data types** 🏗️ for structured storage.
- **Arrays** 🧩 to store historical data efficiently.
- Incremental updates 🔄 to append new season data.
- Easy querying of 📊 trends and 📈 improvements without costly `GROUP BY`.
- Robust indexing 📚 for faster data retrieval.
- Scalable 💪 design for long-term analytics.
- Support for **multi-season comparisons** 📊.

---

## **Table of Contents** 📚

- [📊 Cumulative_Table_Design](#cumulative_table_design)
- [🏀 Cumulative Table Design for Player Statistics](#cumulative-table-design-for-player-statistics)
  - [🏆 Overview](#overview)
  - [📚 Table of Contents](#table-of-contents)
  - [✨ Key Features](#key-features)
  - [🏗️ Schema Design](#schema-design)
  - [🔄 Incremental Updates](#incremental-updates)
  - [🔍 Key Query](#key-query)
  - [📜 Explanation](#explanation)
  - [🧩 Unnesting Arrays](#unnesting-arrays)
  - [📜 Detailed Analysis](#detailed-analysis)
  - [📊 Importance of Cumulative Tables](#importance-of-cumulative-tables)
  - [🚀 Effectiveness of Cumulative Tables](#effectiveness-of-cumulative-tables)
  - [⚙️ Pre-Aggregation Techniques](#pre-aggregation-techniques)
  - [✅ Advantages](#advantages)
  - [❌ Disadvantages](#disadvantages)
  - [💡 Final Thoughts](#final-thoughts)

---

## **Key Features** ✨

1. **Custom Data Types** 🏗️:
   - `season_stats`: Stores season-specific metrics like points, assists, rebounds, and weight.
   - `scoring_class`: Categorizes players based on performance (e.g., 'star', 'good').

2. **Incremental Updates** 🔄:
   - Combines past data 📜 with new records, ensuring complete and accurate player histories.

3. **Efficient Querying** 🔍:
   - Queries past performance and trends using minimal computational power.

4. **Historical Analysis** 📉:
   - Enables multi-season 📊 trend analysis, performance improvement tracking, and 🏆 player classification.

5. **Indexing Support** 🔍:
   - Robust indexing ensures quick retrieval for analytical queries.

6. **Multi-Season Analysis** 📅:
   - Compare and analyze player performance across multiple seasons with minimal performance impact.

---

## **Schema Design** 🏗️

### Custom Data Types 🧱:
```sql
CREATE TYPE season_stats AS (
    season INTEGER,
    pts REAL,
    ast REAL,
    reb REAL,
    weight INTEGER
);
```
```sql
CREATE TYPE scoring_class AS ENUM ('star', 'good', 'average', 'bad');
```

### Players Table 📋:
```sql
CREATE TABLE players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_number TEXT,
    season_stats season_stats[], -- Array of structured season stats
    scoring_class scoring_class, -- Performance category
    years_since_last_season INTEGER, -- Inactivity tracker
    current_season INTEGER, -- Current season tracker
    PRIMARY KEY (player_name, current_season)
);
```

---

## **Incremental Updates** 🔄

### Key Query 🧠:
```sql
INSERT INTO players
WITH yesterday AS (
    SELECT * FROM players WHERE current_season = 2000
),
today AS (
    SELECT * FROM player_seasons WHERE season = 2001
)
SELECT 
    COALESCE(t.player_name, y.player_name),
    COALESCE(t.height, y.height),
    COALESCE(t.college, y.college),
    COALESCE(t.country, y.country),
    COALESCE(t.draft_year, y.draft_year),
    COALESCE(t.draft_number, y.draft_number),

    CASE 
        WHEN y.season_stats IS NULL THEN ARRAY[ROW(t.season, t.pts, t.ast, t.reb, t.weight)::season_stats]
        ELSE y.season_stats || ARRAY[ROW(t.season, t.pts, t.ast, t.reb, t.weight)::season_stats]
    END AS season_stats,

    CASE 
        WHEN t.season IS NOT NULL THEN 
            CASE 
                WHEN t.pts > 20 THEN 'star'
                WHEN t.pts > 15 THEN 'good'
                WHEN t.pts > 10 THEN 'average'
                ELSE 'bad'
            END::scoring_class
        ELSE y.scoring_class
    END AS scoring_class,

    CASE 
        WHEN t.season IS NOT NULL THEN 0
        ELSE y.years_since_last_season + 1
    END AS years_since_last_season,

    COALESCE(t.season, y.current_season + 1) AS current_season
FROM today t 
FULL OUTER JOIN yesterday y 
ON t.player_name = y.player_name;
```

---

## **Unnesting Arrays** 🧩

```sql
WITH unnested AS (
    SELECT player_name, UNNEST(season_stats)::season_stats AS season_stats
    FROM players 
    WHERE current_season = 2001 AND player_name = 'Michael Jordan'
)
SELECT player_name, (season_stats::season_stats).* FROM unnested;
```

---

## **Conclusion** 🎯

### **Importance of Cumulative Tables in Data Modeling** 📊
Cumulative tables are a cornerstone of efficient data modeling, enabling seamless tracking of historical data while supporting incremental updates. They allow organizations to:
- **Monitor trends** over time with ease.
- **Perform advanced analytics** by combining past and present data.
- **Optimize performance** for large datasets by reducing query complexity.

![Cumulative Table Design](Season_stats_cumulative.png)

By pre-aggregating data into cumulative snapshots, cumulative tables ensure faster query execution and reduced computational overhead, making them indispensable for high-performance analytics.

---

### **Effectiveness of Cumulative Tables** 🚀
Cumulative table design is highly effective for:
- **Reducing Query Complexity**: Pre-aggregated data eliminates the need for repetitive joins or complex aggregations during query execution.
- **Improving Query Performance**: Arrays and pre-computed metrics enable faster retrieval of insights, even for large datasets.
- **Maintaining Historical Data**: Historical records are preserved while allowing incremental updates, ensuring data integrity over time.



---

### **Pre-Aggregation: How to Achieve It** ⚙️
Pre-aggregation involves summarizing raw data into meaningful metrics at predefined intervals (e.g., daily, weekly, monthly). This process simplifies querying and improves performance. Steps to achieve pre-aggregation include:
1. **Define the Grain**: Decide the level of detail (e.g., one row per user per day).
2. **Build Daily Metrics Tables**: Aggregate raw events into daily summaries using SQL functions like `SUM()` or `COUNT()`.
3. **Incremental Updates**: Use techniques like `FULL OUTER JOIN` to combine new data with historical records incrementally.
4. **Use Arrays for Efficiency**: Store historical metrics in arrays to enable fast calculations for different timeframes (e.g., last 7 days or 30 days).
5. **Automate Pipelines**: Tools like Airflow or dbt can automate the process of updating cumulative tables regularly.

---

### **Advantages of Cumulative Tables** ✅
1. **Performance Optimization**:
   - Reduces I/O and compute costs by avoiding repeated aggregations.
   - Enables faster queries by leveraging pre-computed metrics.
2. **Scalability**:
   - Handles large datasets effectively by summarizing raw data into manageable snapshots.
3. **Historical Insights**:
   - Preserves historical data for trend analysis and comparisons over time.
4. **Flexibility in Analysis**:
   - Supports dynamic queries (e.g., last 7 days, last month) using array slicing or aggregation functions.

---

### **Disadvantages of Cumulative Tables** ❌
1. **Storage Overhead**:
   - Storing pre-aggregated snapshots can consume more storage compared to raw data, especially when arrays grow large.
2. **Complexity in Updates**:
   - Incremental updates require careful implementation to ensure consistency and avoid duplication.
3. **Loss of Granularity**:
   - Pre-aggregated data may lack the fine-grained detail available in raw datasets, limiting certain types of analysis.
4. **Maintenance Effort**:
   - Requires regular updates through automated pipelines or manual intervention.

---

### **Final Thoughts** 💡
Cumulative table design is a powerful modeling technique that balances performance, scalability, and historical accuracy. While it introduces some complexity in terms of storage and maintenance, its benefits far outweigh the drawbacks for most analytical workloads. By leveraging pre-aggregation and incremental updates effectively:
- Organizations can unlock faster insights 🔍,
- Reduce costs 💰,
- And maintain a consistent approach to data modeling across teams 🤝.

This makes cumulative tables an essential tool for any modern data engineering or analytics pipeline! 🎉



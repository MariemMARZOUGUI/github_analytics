# GitHub Analytics dbt Project (BEN AMAR Yasmine, MARZOUGUI Mariem)
Welcome to our dbt project!

## Overview
This project implements a **dbt data pipeline** for analyzing GitHub repository activity.
The pipeline follows a layered architecture:
* **Bronze layer**: raw ingested data
* **Silver layer**: cleaned and standardized staging models
* **Gold layer**: analytical models used for reporting and scoring repositories

To improve performance, some **silver models were adapted to run in incremental mode**, allowing the pipeline to process only new or updated data instead of reprocessing the entire dataset at each execution.

# Incremental Adaptation of Silver Models
Two Silver models were modified to use **dbt incremental materialization**: 'stg_commits' and 'stg_issues'
This reduces processing time and improves pipeline efficiency.

## 1. Model: 'stg_commits'

**Strategy:** 'append'
The append strategy inserts only new rows.
Git commits are **immutable**, meaning they cannot be modified after creation.
Therefore, existing commits never change and only **new commits need to be added**.

**Incremental column**: author_date: This timestamp identifies when the commit was created and allows dbt to detect new commits.

**Incremental filter**
```
{% if is_incremental() %}
where author_date > (select max(author_date) from {{ this }})
{% endif %}
```

This ensures that during incremental runs, only commits newer than the latest stored commit are processed.
No 'unique_key' is required because existing rows are never updated.

## 2. Model: 'stg_issues'
**Strategy:** 'merge'
The merge strategy performs an **upsert**: update rows if they already exist and insert rows if they are new
Unlike commits, GitHub issues can change over time. For example, an issue may move from **open --> closed**, or its metadata may be updated.

**Incremental column**: issue_updated_at: This column represents the latest modification time of the issue.

**Incremental filter**
```
{% if is_incremental() %}
and issue_updated_at > (select max(issue_updated_at) from {{ this }})
{% endif %}
```

**Unique key**:issue_id: This identifier uniquely represents each issue and allows dbt to correctly update existing rows.

# Reflection Questions
### Can a commit be modified after the fact?
No. A Git commit is immutable once it is created.
Because commits never change, the append strategy is sufficient, we only need to insert new commits.

### An issue can change state (open --> closed). How is this handled?
Issues can evolve over time, so existing records must sometimes be updated.
This is handled using the merge incremental strategy, which updates rows when 'issue_id' already exists and inserts new rows otherwise. The 'updated_at' timestamp is used to detect changes.

### Should the Gold layer also be incremental?
In most cases, the gold layer should not be incremental. Gold models usually contain aggregations, joins between multiple Silver tables and calculated metrics.
Making them incremental may cause **inconsistent aggregations or incorrect metrics**.
For this reason, they are generally fully rebuilt at each run while the silver layer manages incremental processing.

## Result
Using incremental models improves the pipeline by:
* reducing computation time
* avoiding full data reprocessing
* allowing scalable data transformations

### Using the starter project
Try running the following commands:
- dbt run
- dbt test

### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

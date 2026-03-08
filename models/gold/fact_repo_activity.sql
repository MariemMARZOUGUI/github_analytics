{{ config(materialized='table') }}

with daily_commits as (
    select
        repo_id,
        date(author_date) as activity_date,
        count(*) as commits_count,
        count(distinct author_login) as unique_committers
    from {{ ref('stg_commits') }}
    group by repo_id, date(author_date)
),

daily_prs as (

    select
        repo_id,
        date(pr_created_at) as activity_date,
        count(*) as prs_opened,
        sum(case when pr_merged_at is not null then 1 else 0 end) as prs_merged,
        avg(
            case 
                when pr_closed_at is not null 
                then extract(epoch from (pr_closed_at - pr_created_at))/3600 
            end
        ) as avg_pr_close_hours
    from {{ ref('stg_pull_requests') }}
    group by repo_id, date(pr_created_at)

),

daily_issues as (

    select
        repo_id,
        date(issue_created_at) as activity_date,
        count(*) as issues_opened,
        sum(case when issue_closed_at is not null then 1 else 0 end) as issues_closed,
        avg(
            case
                when issue_closed_at is not null
                then extract(epoch from (issue_closed_at - issue_created_at))/3600
            end
        ) as avg_issue_close_hours
    from {{ ref('stg_issues') }}
    group by repo_id, date(issue_created_at)

),

all_dates as (

    select repo_id, activity_date from daily_commits
    union
    select repo_id, activity_date from daily_prs
    union
    select repo_id, activity_date from daily_issues

)

select

    d.repo_id,
    d.activity_date,

    -- commits
    c.commits_count,
    c.unique_committers,

    -- pull requests
    p.prs_opened,
    p.prs_merged,
    p.avg_pr_close_hours,

    -- issues
    i.issues_opened,
    i.issues_closed,
    i.avg_issue_close_hours,

    -- date dimension key
    cast(strftime(d.activity_date, '%Y%m%d') as integer) as date_id

from all_dates d

left join daily_commits c
    on d.repo_id = c.repo_id
    and d.activity_date = c.activity_date

left join daily_prs p
    on d.repo_id = p.repo_id
    and d.activity_date = p.activity_date

left join daily_issues i
    on d.repo_id = i.repo_id
    and d.activity_date = i.activity_date
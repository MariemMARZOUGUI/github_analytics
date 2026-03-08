{{ config(materialized='table') }}

with recent_activity as (

    select
        repo_id,

        sum(commits_count) filter (
            where activity_date >= current_date - interval '30 day'
        ) as commits_30d,

        sum(prs_merged) filter (
            where activity_date >= current_date - interval '30 day'
        ) as merged_prs_30d,

        sum(unique_committers) filter (
            where activity_date >= current_date - interval '30 day'
        ) as contributors_30d,

        avg(avg_pr_close_hours) filter (
            where activity_date >= current_date - interval '30 day'
        ) as avg_pr_close_hours,

        sum(prs_opened) as total_prs,
        sum(prs_merged) as merged_prs,

        sum(issues_opened) as total_issues,
        sum(issues_closed) as closed_issues

    from {{ ref('fact_repo_activity') }}
    group by repo_id

),

base_metrics as (

    select
        r.repo_id,
        r.owner_login,
        r.stars_count,
        r.forks_count,

        a.*

    from {{ ref('dim_repository') }} r
    left join recent_activity a
        on r.repo_id = a.repo_id

),

ranked as (

    select
        *,

        ntile(10) over (order by commits_30d desc) as rank_activity,

        ntile(10) over (order by avg_pr_close_hours asc) as rank_responsiveness,

        ntile(10) over (
            order by (stars_count + forks_count) desc
        ) as rank_community

    from base_metrics

),

scored as (

    select
        *,

        rank_activity * 100.0 / 10 as score_activity,
        rank_responsiveness * 100.0 / 10 as score_responsiveness,
        rank_community * 100.0 / 10 as score_community

    from ranked

)

select
    repo_id,
    owner_login,

    score_activity,
    score_responsiveness,
    score_community,

    (
        score_activity * 0.4 +
        score_responsiveness * 0.3 +
        score_community * 0.3
    ) as score_global,

    rank() over (
        order by (
            score_activity * 0.4 +
            score_responsiveness * 0.3 +
            score_community * 0.3
        ) desc
    ) as ranking

from scored
order by ranking
limit 10
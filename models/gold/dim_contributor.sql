{{ config(
    materialized = 'table'
) }}

with commits as (

    select
        author_login as login,
        repo_id,
        author_date as activity_date
    from {{ ref('stg_commits') }}

),

pull_requests as (

    select
        user_login as login,
        repo_id,
        pr_created_at as activity_date
    from {{ ref('stg_pull_requests') }}

),

all_activities as (

    select * from commits
    union all
    select * from pull_requests

),

filtered as (

    select *
    from all_activities
    where login != 'Unknown'

),

aggregated as (

    select
        login as contributor_id,
        MIN(activity_date) as first_contribution_at,
        COUNT(DISTINCT repo_id) as repos_contributed_to,
        COUNT(*) as total_activities
    from filtered
    group by login

)

select * from aggregated
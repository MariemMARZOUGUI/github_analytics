-- models / silver / stg_repositories . sql
{{ config(
    materialized = 'view'
) }}

with source as (
    select * 
    from {{ source('bronze', 'raw_repositories') }}
),

cleaned as (
    select
        full_name as repo_id,
        owner_login as owner_login,
        license_name as license_name,
        default_branch as default_branch,
        CAST(created_at AS TIMESTAMP) AS created_at,
        CAST(updated_at AS TIMESTAMP) AS updated_at,
        CAST(pushed_at AS TIMESTAMP) AS pushed_at,
        CAST(stargazers_count AS INTEGER) AS stars_count,
        CAST(forks_count AS INTEGER) AS forks_count,
        cast(open_issues_count as integer) as open_issues_count,
        cast(watchers_count as integer) as watchers_count,
        cast(network_count as integer) as network_count,
        cast(subscribers_count as integer) as subscribers_count,
        cast(size as integer) as size,
        COALESCE(description, 'No description') AS description,
        COALESCE(language, 'Unknown') AS language,
        (CURRENT_DATE - CAST(created_at AS DATE)) AS repo_age_days,
        has_wiki as has_wiki, 
        has_pages as has_pages,
        CAST(archived AS BOOLEAN) AS archived

    from source
    where archived = FALSE
)

select * from cleaned
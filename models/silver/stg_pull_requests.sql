-- models/silver/stg_pull_requests.sql


{{ config(
    materialized='view'
) }}


with source as (
    select *
    from {{ source('bronze','raw_pull_requests') }}
),


cleaned as (
    select
        pr_number::integer as pr_number,
        repo_full_name as repo_id,
        coalesce(user_login, 'unknown') as user_login,
        cast(created_at as timestamp) as pr_created_at,
        cast(closed_at as timestamp) as pr_closed_at,
        cast(updated_at as timestamp) as pr_updated_at,
        cast(merged_at as timestamp) as pr_merged_at,
        coalesce(draft, false) as is_draft,
        state as pr_state,
        (merged_at is not null) as is_merged
    from source
    where pr_number is not null
),


with_time as (
    select
        *,
        case
            when pr_merged_at is not null then
                extract(epoch from pr_merged_at - pr_created_at)/3600
            when pr_merged_at is null and pr_closed_at is not null then
                extract(epoch from pr_closed_at - pr_created_at)/3600
            else null
        end as time_to_close_hours
    from cleaned
)


select *
from with_time
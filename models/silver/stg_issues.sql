{{ config(
    materialized='incremental',
    schema='silver',
    unique_key='issue_id',
    incremental_strategy='merge'
) }}

with source as (

    select *
    from {{ source('bronze','raw_issues') }}

),

cleaned as (

    select
        repo_full_name as repo_id,
        cast(issue_number as integer) as issue_id,
        cast(created_at as timestamp) as issue_created_at,
        cast(updated_at as timestamp) as issue_updated_at,
        cast(closed_at as timestamp) as issue_closed_at,
        cast(is_pull_request as boolean) as is_pull_request,
        state as issue_state

    from source
    where issue_number is not null

),

with_time as (

    select
        *,
        case
            when issue_updated_at is not null then
                extract(epoch from issue_updated_at - issue_created_at)/3600
            when issue_updated_at is null and issue_closed_at is not null then
                extract(epoch from issue_closed_at - issue_created_at)/3600
            else null
        end as time_to_close_hours

    from cleaned

)

select *
from with_time
where is_pull_request = false

{% if is_incremental() %}

and issue_updated_at >
(
    select max(issue_updated_at)
    from {{ this }}
)

{% endif %}
{{ config(
    materialized='incremental',
    schema='silver',
    incremental_strategy='append'
) }}

with source as (

    select *
    from {{ source('bronze','raw_commits') }}

),

cleaned as (

    select
        sha as commit_sha,
        repo_full_name as repo_id,
        coalesce(author_login,'No Author') as author_login,
        cast(author_date as timestamp) as author_date,
        cast(committer_date as timestamp) as committer_date,
        extract(dow from author_date) as day_of_week,
        extract(hour from author_date) as hour_of_day,
        substring(message from 1 for 200) as message

    from source
    where sha is not null

)

select *
from cleaned

{% if is_incremental() %}

where author_date >
(
    select max(author_date)
    from {{ this }}
)

{% endif %}
{{ config(materialized='table') }}


with date_spine as (
    select
        unnest(generate_series(
            current_date - interval '5 years',
            current_date,
            interval '1 day'
        ))::date as full_date
),


enriched as (
    select
        cast(strftime('%Y%m%d', full_date) as integer) as date_id,
        full_date,
        extract(year from full_date) as year,
        extract(month from full_date) as month,
        extract(week from full_date) as week_of_year,
        extract(dow from full_date) as day_of_week,
        strftime('%A', full_date) as day_name,
        strftime('%B', full_date) as month_name,
        case when extract(dow from full_date) in (0,6) then true else false end as is_weekend,
        extract(quarter from full_date) as quarter
    from date_spine
)


select *
from enriched
order by full_date
# delete   FROM `chaingraph-318604.ethereum_tags.aave_flashloan_user` where 1=1;
# create or replace table `chaingraph-318604.ethereum_tags.aave_flashloan_user` as
# insert into `chaingraph-318604.ethereum_tags.aave_flashloan_user`
with transactions_subset as
(
    select 
        block_timestamp,
        `hash` as transaction_hash,
        from_address
    from
        `bigquery-public-data.crypto_ethereum.transactions`
    where true
        # and DATE(block_timestamp) <= '2021-07-15'
        and DATE(block_timestamp) = DATE_ADD(@run_date, INTERVAL -1 DAY)
)
,
tmp_v1_flashloan_users as
(
    select distinct 
        transaction_hash
    from
        `blockchain-etl.ethereum_aave.LendingPool_event_FlashLoan`
    where true
        # and DATE(block_timestamp) <= '2021-07-15'
        and DATE(block_timestamp) = DATE_ADD(@run_date, INTERVAL -1 DAY)
)
,
tmp_v2_flashloan_users as
(
    select distinct 
        transaction_hash
    from
        `blockchain-etl.ethereum_aave.LendingPool_v2_event_FlashLoan`
    where true
        # and DATE(block_timestamp) <= '2021-07-15'
        and DATE(block_timestamp) = DATE_ADD(@run_date, INTERVAL -1 DAY)
)
,
tmp_flashloan_users as
(
    select * from tmp_v1_flashloan_users 
    union distinct 
    select * from tmp_v2_flashloan_users 
)
,
tmp_addr_ts_tag as
(
    select 
        a.from_address as address,
        min(a.block_timestamp) as tx_timestamp,
        'AAVE flashloan user' as tag
    from
    (
        transactions_subset a
        join
        tmp_flashloan_users b
        on a.transaction_hash = b.transaction_hash
    )
    group by address
)
select
    address_a as address,
    tx_timestamp,
    tag
from
(
    select
        a.address as address_a,
        b.address as address_b,
        a.tx_timestamp as tx_timestamp,
        a.tag as tag
    from 
    (
        tmp_addr_ts_tag a
        left join 
        `chaingraph-318604.ethereum_tags.aave_flashloan_user` b
        on a.address = b.address
    )
)
where address_b is null

# -------------------------- #
# Get historic data
# -------------------------- #
# select distinct * from tmp_addr_ts_tag

;

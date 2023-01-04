#![deny(rust_2018_idioms)]

use ic_cdk_macros::{init, post_upgrade, pre_upgrade, query, update};

#[init]
pub fn init() {
    ic_cdk::println!("init");
}

#[post_upgrade]
pub fn post_upgrade() {
    ic_cdk::println!("post_upgrade");
}

#[pre_upgrade]
pub fn pre_upgrade() {
    ic_cdk::println!("pre_upgrade");
}

#[query]
pub fn some_query() {
    ic_cdk::println!("some_query");
}

#[update]
pub async fn some_update() {
    ic_cdk::println!("some_update");
}

#[test]
fn test_foo() {
    assert!(true);
}

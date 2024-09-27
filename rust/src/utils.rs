use lazy_static::lazy_static;
use std::collections::hash_map::DefaultHasher;
use std::hash::Hasher;
use tokio::sync::{Mutex, MutexGuard};

lazy_static! {
    static ref HASH_LOCK: Vec<Mutex::<()>> = {
        let mut mutex_vec: Vec<Mutex<()>> = vec![];
        for _ in 0..64 {
            mutex_vec.push(Mutex::<()>::new(()));
        }
        mutex_vec
    };
}

pub(crate) async fn hash_lock(url: &String) -> MutexGuard<'static, ()> {
    let mut s = DefaultHasher::new();
    s.write(url.as_bytes());
    HASH_LOCK[s.finish() as usize % HASH_LOCK.len()]
        .lock()
        .await
}

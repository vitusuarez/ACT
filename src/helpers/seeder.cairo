use core::poseidon::{PoseidonTrait, HashState};
use core::hash::HashStateTrait;

use crate::constants::{SEED_WEEK_SECONDS, SEED_OFFSET_SECONDS};

pub mod Seeder {
    use super::*;
    
    #[inline]
    pub fn reseed(lhs: felt252, rhs: felt252) -> felt252 {
        let state: HashState = PoseidonTrait::new();
        let state = state.update(lhs);
        let state = state.update(rhs);
        state.finalize()
    }

    #[inline]
    pub fn compute_id(time: u64) -> felt252 {
        ((time + SEED_OFFSET_SECONDS) / SEED_WEEK_SECONDS).into()
    }
}
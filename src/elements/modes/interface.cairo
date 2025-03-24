use crate::types::monster::Monster;
use crate::types::role::Role;

pub trait ModeTrait {
    fn monster(seed: felt252) -> Monster;
    fn role(seed: felt252, player_role: Role) -> Role;
}
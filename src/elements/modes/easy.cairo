use crate::types::monster::Monster;
use crate::types::role::{Role, RoleTrait};

#[inline]
pub fn monster(seed: felt252) -> Monster {
    let luck: u256 = seed.into() % 100;
    if luck < 20 {
        Monster::None
    } else if luck < 25 {
        Monster::Boss
    } else if luck < 35 {
        Monster::Elite
    } else {
        Monster::Common
    }
}

#[inline]
pub fn role(seed: felt252, player_role: Role) -> Role {
    let luck: u256 = seed.into() % 100;
    if luck < 20 {
        Role::Fire
    } else if luck < 40 {
        Role::Water
    } else if luck < 60 {
        Role::Earth
    } else if luck < 80 {
        Role::Air
    } else {
        player_role.strength()
    }
}
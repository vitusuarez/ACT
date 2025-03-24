use crate::types::monster::Monster;
use crate::types::role::{Role, RoleTrait};
use crate::elements::modes::interface::ModeTrait;

impl Hard of ModeTrait {
    #[inline]
    fn monster(seed: felt252) -> Monster {
        let luck: u256 = seed.into() % 100;
        if luck < 5 {
            Monster::None
        } else if luck < 25 {
            Monster::Boss
        } else if luck < 60 {
            Monster::Elite
        } else {
            Monster::Common
        }
    }

    #[inline]
    fn role(seed: felt252, player_role: Role) -> Role {
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
            player_role.weakness()
        }
    }
}
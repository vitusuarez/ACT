use core::traits::Into;
#[cfg(test)]
use core::debug::PrintTrait;
use crate::elements::roles;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum Role {
    None,
    Fire,
    Water,
    Earth,
    Air,
}

#[generate_trait]
pub impl RoleImpl of RoleTrait {
    #[inline]
    fn weakness(self: Role) -> Role {
        match self {
            Role::None => Role::None,
            Role::Fire => roles::fire::weakness(self),
            Role::Water => roles::water::weakness(self),
            Role::Earth => roles::earth::weakness(self),
            Role::Air => roles::air::weakness(self),
        }
    }

    #[inline]
    fn strength(self: Role) -> Role {
        match self {
            Role::None => Role::None,
            Role::Fire => roles::fire::strength(self),
            Role::Water => roles::water::strength(self),
            Role::Earth => roles::earth::strength(self),
            Role::Air => roles::air::strength(self),
        }
    }

    #[inline]
    fn received_damage(self: Role, role: Role, damage: u8) -> u8 {
        let role_id: u8 = self.into();
        if role_id == self.weakness().into() {
            damage * 2
        } else if role_id == self.strength().into() {
            damage / 2
        } else {
            damage
        }
    }
}

impl IntoRoleFelt252 of Into<Role, felt252> {
    #[inline(always)]
    fn into(self: Role) -> felt252 {
        match self {
            Role::None => 'NONE',
            Role::Fire => 'FIRE',
            Role::Water => 'WATER',
            Role::Earth => 'EARTH',
            Role::Air => 'AIR',
        }
    }
}

impl IntoRoleU8 of Into<Role, u8> {
    #[inline(always)]
    fn into(self: Role) -> u8 {
        match self {
            Role::None => 0,
            Role::Fire => 1,
            Role::Water => 2,
            Role::Earth => 3,
            Role::Air => 4,
        }
    }
}

impl IntoU8Role of Into<u8, Role> {
    #[inline(always)]
    fn into(self: u8) -> Role {
        let card: felt252 = self.into();
        match card {
            0 => Role::None,
            1 => Role::Fire,
            2 => Role::Water,
            3 => Role::Earth,
            4 => Role::Air,
            _ => Role::None,
        }
    }
}

#[cfg(test)]
impl RolePrint of PrintTrait<Role> {
    #[inline(always)]
    fn print(self: Role) {
        let felt: felt252 = self.into();
        felt.print();
    }
}
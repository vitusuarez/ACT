use crate::types::role::Role;

#[inline]
pub fn weakness(role: Role) -> Role {
    Role::Water
}

#[inline]
pub fn strength(role: Role) -> Role {
    Role::Air
}
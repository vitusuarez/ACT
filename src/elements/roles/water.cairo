use crate::types::role::Role;
use crate::elements::roles::interface::RoleTrait;

impl Water of RoleTrait {
    #[inline]
    fn weakness(role: Role) -> Role {
        Role::Earth
    }

    #[inline]
    fn strength(role: Role) -> Role {
        Role::Fire
    }
}
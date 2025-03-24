use crate::types::role::Role;
use crate::elements::roles::interface::RoleTrait;

impl Air of RoleTrait {
    #[inline]
    fn weakness(role: Role) -> Role {
        Role::Fire
    }

    #[inline]
    fn strength(role: Role) -> Role {
        Role::Earth
    }
}
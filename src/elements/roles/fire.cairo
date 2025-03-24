use crate::types::role::Role;
use crate::elements::roles::interface::RoleTrait;

impl Fire of RoleTrait {
    #[inline]
    fn weakness(role: Role) -> Role {
        Role::Water
    }

    #[inline]
    fn strength(role: Role) -> Role {
        Role::Air
    }
}
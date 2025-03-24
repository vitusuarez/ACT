use crate::types::role::Role;
use crate::elements::roles::interface::RoleTrait;

impl Earth of RoleTrait {
    #[inline]
    fn weakness(role: Role) -> Role {
        Role::Air
    }

    #[inline]
    fn strength(role: Role) -> Role {
        Role::Water
    }
}
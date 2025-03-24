use crate::types::role::Role;

pub trait RoleTrait {
    fn weakness(role: Role) -> Role;
    fn strength(role: Role) -> Role;
}
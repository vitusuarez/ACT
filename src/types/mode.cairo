use core::traits::Into;
use core::debug::PrintTrait;

// Using direct imports for this module
use super::monster::Monster;
use super::role::Role;
use crate::elements::modes;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum Mode {
    None,
    Easy,
    Medium,
    Hard,
}

#[generate_trait]
impl ModeImpl of ModeTrait {
    #[inline]
    fn monster(self: Mode, seed: felt252) -> Monster {
        match self {
            Mode::None => Monster::None,
            Mode::Easy => modes::easy::Easy::monster(seed),
            Mode::Medium => modes::medium::Medium::monster(seed),
            Mode::Hard => modes::hard::Hard::monster(seed),
        }
    }

    #[inline]
    fn role(self: Mode, seed: felt252, player_role: Role) -> Role {
        match self {
            Mode::None => Role::None,
            Mode::Easy => modes::easy::Easy::role(seed, player_role),
            Mode::Medium => modes::medium::Medium::role(seed, player_role),
            Mode::Hard => modes::hard::Hard::role(seed, player_role),
        }
    }
}

impl IntoModeFelt252 of Into<Mode, felt252> {
    #[inline(always)]
    fn into(self: Mode) -> felt252 {
        match self {
            Mode::None => 'NONE',
            Mode::Easy => 'EASY',
            Mode::Medium => 'MEDIUM',
            Mode::Hard => 'HARD',
        }
    }
}

impl IntoModeU8 of Into<Mode, u8> {
    #[inline(always)]
    fn into(self: Mode) -> u8 {
        match self {
            Mode::None => 0,
            Mode::Easy => 1,
            Mode::Medium => 2,
            Mode::Hard => 3,
        }
    }
}

impl IntoU8Mode of Into<u8, Mode> {
    #[inline(always)]
    fn into(self: u8) -> Mode {
        let card: felt252 = self.into();
        match card {
            0 => Mode::None,
            1 => Mode::Easy,
            2 => Mode::Medium,
            3 => Mode::Hard,
            _ => Mode::None,
        }
    }
}

impl ModePrint of PrintTrait<Mode> {
    #[inline(always)]
    fn print(self: Mode) {
        let felt: felt252 = self.into();
        felt.print();
    }
}
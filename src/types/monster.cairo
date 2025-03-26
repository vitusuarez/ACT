use core::traits::Into;
#[cfg(test)]
use core::debug::PrintTrait;
use crate::elements::monsters;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum Monster {
    None,
    Common,
    Elite,
    Boss,
}

#[generate_trait]
pub impl MonsterImpl of MonsterTrait {
    #[inline]
    fn damage(self: Monster) -> u8 {
        match self {
            Monster::None => 0,
            Monster::Common => monsters::common::damage(),
            Monster::Elite => monsters::elite::damage(),
            Monster::Boss => monsters::boss::damage(),
        }
    }

    #[inline]
    fn health(self: Monster) -> u8 {
        match self {
            Monster::None => 0,
            Monster::Common => monsters::common::health(),
            Monster::Elite => monsters::elite::health(),
            Monster::Boss => monsters::boss::health(),
        }
    }

    #[inline]
    fn reward(self: Monster) -> u16 {
        match self {
            Monster::None => 0,
            Monster::Common => monsters::common::reward(),
            Monster::Elite => monsters::elite::reward(),
            Monster::Boss => monsters::boss::reward(),
        }
    }
}

impl IntoMonsterFelt252 of Into<Monster, felt252> {
    #[inline]
    fn into(self: Monster) -> felt252 {
        match self {
            Monster::None => 'NONE',
            Monster::Common => 'COMMON',
            Monster::Elite => 'ELITE',
            Monster::Boss => 'BOSS',
        }
    }
}

impl IntoMonsterU8 of Into<Monster, u8> {
    #[inline]
    fn into(self: Monster) -> u8 {
        match self {
            Monster::None => 0,
            Monster::Common => 1,
            Monster::Elite => 2,
            Monster::Boss => 3,
        }
    }
}

impl IntoU8Monster of Into<u8, Monster> {
    #[inline]
    fn into(self: u8) -> Monster {
        let card: felt252 = self.into();
        match card {
            0 => Monster::None,
            1 => Monster::Common,
            2 => Monster::Elite,
            3 => Monster::Boss,
            _ => Monster::None,
        }
    }
}

#[cfg(test)]
impl MonsterPrint of PrintTrait<Monster> {
    #[inline]
    fn print(self: Monster) {
        let felt: felt252 = self.into();
        felt.print();
    }
}
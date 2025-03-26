// Constants
const DAMAGE: u8 = 15;
const HEALTH: u8 = 30;
const REWARD: u16 = 15;

#[inline]
pub fn damage() -> u8 {
    DAMAGE
}

#[inline]
pub fn health() -> u8 {
    HEALTH
}

#[inline]
pub fn reward() -> u16 {
    REWARD
}
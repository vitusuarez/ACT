// Constants
const DAMAGE: u8 = 10;
const HEALTH: u8 = 20;
const REWARD: u16 = 10;

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
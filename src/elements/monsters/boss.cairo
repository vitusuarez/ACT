// Constants
const DAMAGE: u8 = 25;
const HEALTH: u8 = 50;
const REWARD: u16 = 35;

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
//! Store struct and component management methods.

// Dojo imports

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Models imports

use rpg::models::index::{Player, Dungeon};

// Structs

#[derive(Copy, Drop)]
struct Store {
    world: IWorldDispatcher,
}

// Implementations

#[generate_trait]
impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: IWorldDispatcher) -> Store {
        Store { world: world }
    }

    #[inline]
    fn get_state(self: Store, player_id: felt252) -> (Player, Dungeon) {
        let world = self.get_world();
        let player: Player = world.read_model(player_id);
        let dungeon: Dungeon = world.read_model(player_id);
        (player, dungeon)
    }

    #[inline]
    fn get_player(self: Store, player_id: felt252) -> Player {
        let world = self.get_world();
        world.read_model(player_id)
    }

    #[inline]
    fn get_dungeon(self: Store, player_id: felt252) -> Dungeon {
        let world = self.get_world();
        world.read_model(player_id)
    }

    #[inline]
    fn set_state(self: Store, player: Player, dungeon: Dungeon) {
        let mut world = self.get_world();
        world.write_model(@player);
        world.write_model(@dungeon);
    }

    #[inline]
    fn set_player(self: Store, player: Player) {
        let mut world = self.get_world();
        world.write_model(@player);
    }

    #[inline]
    fn set_dungeon(self: Store, dungeon: Dungeon) {
        let mut world = self.get_world();
        world.write_model(@dungeon);
    }

    #[inline]
    fn get_world(self: Store) -> dojo::world::WorldStorage {
        self.world(@"rpg")
    }
}

#[cfg(test)]
mod tests {
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::testing::{set_contract_address, set_caller_address};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use dojo::model::Model;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDef, ContractDefTrait};

    use crate::models::index;
    use crate::types::role::Role;
    use crate::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    // Constants
    fn PLAYER() -> ContractAddress {
        starknet::contract_address_const::<'PLAYER'>()
    }

    const PLAYER_NAME: felt252 = 'PLAYER';

    #[derive(Drop)]
    struct Systems {
        actions: IActionsDispatcher,
    }

    #[derive(Drop)]
    struct Context {
        player_id: felt252,
        player_name: felt252,
    }

    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "rpg",
            resources: [
                TestResource::Model(crate::models::index::player::TEST_CLASS_HASH),
                TestResource::Model(crate::models::index::dungeon::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
            ].span()
        }
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"rpg", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"rpg")].span())
        ].span()
    }

    fn spawn_game() -> (IWorldDispatcher, Systems, Context) {
        // [Setup] World
        let ndef = namespace_def();
        let world = spawn_test_world([ndef].span());
        
        // Sync permissions and initializations
        let world_mut = WorldStorageTest::world_mut(world);
        world_mut.sync_perms_and_inits(contract_defs());

        // [Setup] Systems
        let contract_address = world_mut.dns(@"actions").unwrap().0;
        let systems = Systems {
            actions: IActionsDispatcher { contract_address },
        };
        
        // [Setup] Context
        set_contract_address(PLAYER());
        systems.actions.spawn(PLAYER_NAME, Role::Water.into());
        let context = Context { player_id: PLAYER().into(), player_name: PLAYER_NAME };

        // [Return]
        (world, systems, context)
    }
}
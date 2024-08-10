/// Module: v3dex
module v3dex::v3dex {
    use std::option;
    use std::type_name::{get, TypeName};
    use sui::transfer;
    use sui::balance::{Self, Supply};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};

    use deepbook::clob_v2::{Self as clob, Pool};
    use deepbook::custodian_v2::AccountCap;

    use dex::eth::ETH;
    use dex::usdc::USDC;

    struct DEX has drop {}

    struct Data<phantom CoinType> has store {
        cap: TreasuryCap<CoinType>,
        /*
        * This table will store user address => last epoch minted
        * this is to make sure that users can only mint tokens once per epoch
        */
        faucet_lock: Table<address, u64>
    }

    // This is an object because it has the key ability and a UID
    struct Storage has key {
        id: UID,
        dex_supply: Supply<DEX>,
        swaps: Table<address, u64>,
        account_cap: AccountCap,
        client_id: u64
    }

    #[allow(unused_function)]
    // This function only runs at deployment
    fun init(witness: DEX, ctx: &mut TxContext) { 
        let (treasury_cap, metadata) = coin::create_currency<DEX>(
                witness, 
                9, 
                b"DEX",
                b"DEX Coin", 
                b"Coin of SUI DEX", 
                option::none(), 
                ctx
            );

        // Share the metadata with sui network and make it immutable
        transfer::public_freeze_object(metadata);    


        // We share the Storage object with the Sui Network so everyone can pass to functions as a reference
        // We transform the Treasury Cap into a Supply so this module can mint the DEX token
        transfer::share_object(Storage { 
            id: object::new(ctx), 
            dex_supply: coin::treasury_into_supply(treasury_cap), 
            swaps: table::new(ctx),
            // We will store the deployer account_cap here to be able to refill the pool
            account_cap: clob::create_account(ctx),
            client_id: CLIENT_ID
        });
    }
}

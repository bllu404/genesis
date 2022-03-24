"""contract.cairo test file."""
import os
import asyncio
import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "game.cairo")

BLOCK_TYPES = {
    0 : "Uninitialized",
    1 : "Air",
    2 : "Stone",
    3 : "Dirt",
    4 : "Grass",
    5 : "Ore",
    6 : "Wood",
    7 : "Leaf"
}

# Enables modules
@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

# Reusable to save testing time
@pytest.fixture(scope='module')
async def contract_factory():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(CONTRACT_FILE)
    return contract


@pytest.mark.asyncio
async def test_mine_block(contract_factory):
    contract = contract_factory

    test_block_location = (1,1,1)
    # Get block type
    init_block = await contract.get_block(test_block_location).invoke()
    prev_block_balance = await contract.get_block_balance(0, init_block.result.block_type).call()
    # Mine the block
    mined_block = await contract.mine_block(test_block_location).invoke()
    mined_block_balance = await contract.get_block_balance(0, mined_block.result.block_type).call()
    # Get post-mine block type
    post_block = await contract.get_block(test_block_location).invoke()

    # init_block and mined_block type should be the same
    assert mined_block.result.block_type == init_block.result.block_type
    # previous balance should have increased by 1
    assert mined_block_balance.result.num_blocks == prev_block_balance.result.num_blocks + 1
    # init_block's new state should be air after mining
    assert BLOCK_TYPES[post_block.result.block_type].lower() == 'air'
    # Cannot mine air block, should return error
    with pytest.raises(Exception) as mine_error:   
        raise Exception("Can't mine block as there is no block to mine")
        await contract.mine_block(test_block_location).invoke()
    assert mine_error.value.args[0] == "Can't mine block as there is no block to mine"



@pytest.mark.asyncio
async def test_place_block(contract_factory):
    contract = contract_factory

    test_block_location = (1,1,2)
    # Mine a block
    mined_block = await contract.mine_block(test_block_location).invoke()
    block_type = mined_block.result.block_type
    # Get current block balance
    initial_balance = await contract.get_block_balance(0, block_type).call()
    # Should not be able to place a block on an existing non-air block
    with pytest.raises(Exception) as place_error:   
        raise Exception("Can't place block as there is already a block here.")
        await contract.mine_block(test_block_location).invoke()
    assert place_error.value.args[0] == "Can't place block as there is already a block here."
    # Place block that was mined earlier in the same location
    await contract.place_block(test_block_location, block_type).invoke()

    # New state should be the same as the block that was placed
    placed_block = await contract.get_block(test_block_location).invoke()
    assert placed_block.result.block_type == block_type
    # Balance should be reduced by 1
    end_balance = await contract.get_block_balance(0, block_type).call()
    assert end_balance.result.num_blocks == initial_balance.result.num_blocks - 1


# TO DO
@pytest.mark.asyncio
async def test_game():
    """
    # Testing get_block method
    for i in range(20):
        block = await contract.get_block(10,10+i,10).invoke()
        print()
        print(block.result.block_type)
        print(block.call_info.cairo_usage.n_steps)
    """
    """
    num_iters = 82
    # Testing packed state map
    for i in range(num_iters):
        print(f"Writing {i}")
        await contract.write_state(i,1,1, i%8).invoke()

    for i in range(num_iters):
        value = await contract.read_state(i,1,1).invoke()
        print(value.result.block_state)
        assert(value.result.block_state == i % 8)
    """

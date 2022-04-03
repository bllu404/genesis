"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "game.cairo")


block_types = {
    0 : "Uninitialized",
    1 : "Air",
    2 : "Stone",
    3 : "Dirt",
    4 : "Grass",
    5 : "Ore",
    6 : "Wood",
    7 : "Leaf"
}
@pytest.mark.asyncio
async def test_game():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

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
    '''
    print("Basic Game Logic")
    block = await contract.get_block(1,1,1).invoke()
    mine = await contract.mine_block(1,1,1).invoke()
    block2 = await contract.get_block(1,1,1).invoke()
    place = await contract.place_block(1,1,1, 2).invoke()
    block3 = await contract.get_block(1,1,1).invoke()
    print(block_types[block.result.block_type])
    print(block_types[block2.result.block_type])
    print(block_types[block3.result.block_type])'''

    print("Getting multiple blocks at once")
    blocks = await contract.get_blocks(1,1,90, 20).invoke()
    print(blocks.result.block_states)


    
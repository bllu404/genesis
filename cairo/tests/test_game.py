"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "game.cairo")


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
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
    
    write = await contract.write_state(1,1,1, 1).invoke()
    read = await contract.read_state(1,1,1).invoke()
    print(f"Write steps: {write.call_info.cairo_usage.n_steps}")
    print(f"Read steps: {read.call_info.cairo_usage.n_steps}")
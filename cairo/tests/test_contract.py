"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "generator.cairo")


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_terrain_generator():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    """
    # Testing generate_block method
    for i in range(20):
        block = await contract.generate_block(10,10+i,10).call()
        print()
        print(block.result.block_type)
        print(block.call_info.cairo_usage.n_steps)


    # Testing get_block method
    for i in range(20):
        block = await contract.get_block(10,10+i,10).call()
        print()
        print(block.result.block_type)
        print(block.call_info.cairo_usage.n_steps)
    """

    # Testing packed state map
    for i in range(5):
        print(f"Writing {i}")
        await contract.write_state(1,1,i, i%8).invoke()

    for i in range(5):
        value = await contract.read_state(1,1,i).call()
        print(value.result.block_state)
        #assert(value.result.block_state == i % 8)
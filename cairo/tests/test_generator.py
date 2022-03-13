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
    '''
    # Testing generate_block method
    for i in range(20):
        block = await contract.generate_block(10,10+i,10).invoke()
        print()
        print(block.result.block_type)
        print(block.call_info.cairo_usage.n_steps)
    '''

    block = await contract.generate_block(10,10,100).invoke()
    print(block.result.block_type)
    print(block.call_info.cairo_usage.n_steps)
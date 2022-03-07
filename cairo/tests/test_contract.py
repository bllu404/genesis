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
    """Test increase_balance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    for i in range(20):
        block = await contract.get_block(10,10+i,10).call()
        print()
        print(block.result.block_type)
        print(block.call_info.cairo_usage.n_steps)

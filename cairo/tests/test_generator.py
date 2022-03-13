import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from matplotlib import pyplot as plt

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
    plt.axes()
    colors = ["#03b1fc", "#696969", "#703307", "#347812", "#f5c011"]
    # Testing generate_block method
    for i in range(20):
        for j in range(20):
            block = await contract.generate_block(i,10,85+j).invoke()
            #print()
            #print(block.result.block_type)
            #print(block.call_info.cairo_usage.n_steps)
            square = plt.Rectangle((5*i,5*j), 5, 5, fc=colors[block.result.block_type - 1])
            plt.gca().add_patch(square)
    
    plt.axis('scaled')
    plt.savefig('terrain.png')
    '''
    block = await contract.generate_block(10,10,100).invoke()
    print(block.result.block_type)
    print(block.call_info.cairo_usage.n_steps)
    '''
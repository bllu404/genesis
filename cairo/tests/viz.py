"""contract.cairo test file."""
import os
import asyncio
import pytest
from starkware.starknet.testing.starknet import Starknet
import matplotlib.pyplot as plt

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
async def test_create_viz(contract_factory):
    contract = contract_factory

    plt.axes()
    colors = ["#03b1fc", "#696969", "#703307", "#347812", "#f5c011"]

    BLOCKS_PER_CALL = 20

    for i in range(20):
        blocks = (await contract.get_blocks(i,1,1, BLOCKS_PER_CALL).invoke()).result.block_states
        print(blocks)
        for j in range(BLOCKS_PER_CALL):
            square = plt.Rectangle((5*i,5*j), 5, 5, fc=colors[blocks[j] - 1])
            plt.gca().add_patch(square)
    
    plt.axis('scaled')
    plt.savefig('terrain.png')

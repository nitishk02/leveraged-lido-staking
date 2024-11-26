```markdown
# **Leveraged Lido Vault**

A smart contract that implements leveraged Lido staking using Aave's credit delegation and Uniswap for swapping USDC to ETH. It allows lenders to delegate their borrowing power, borrowers to deposit collateral, and create leveraged staking positions while ensuring lender safety through health factor monitoring.

---

## **Features**

- **Credit Delegation**: Lenders can delegate borrowing power with specific terms (amount, minimum health factor).
- **Leveraged Staking**: Borrowers can deposit collateral, borrow against it, and stake ETH on Lido with leverage.
- **Health Factor Monitoring**: Tracks both borrower and lender health factors to prevent liquidation risks.
- **USDC to ETH Swap**: Uses Uniswap for efficient token swapping.

---

## **Setup Instructions**

### **1. Prerequisites**

- **Foundry**: Ensure Foundry is installed. If not, install it using:
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```
- **Node.js**: Install Node.js (v14 or higher) for dependency management.
- **Anvil**: A local Ethereum node for testing. This comes with Foundry.

### **2. Clone the Repository**

Clone the project repository:
```bash
git clone https://github.com/your-repo/leveraged-lido-vault.git
cd leveraged-lido-vault
```

### **3. Install Dependencies**

Install the required dependencies:
```bash
forge install OpenZeppelin/openzeppelin-contracts uniswap/v2-periphery
```

---

## **Running the Project**

### **1. Start a Mainnet Fork**

Start a mainnet fork using Anvil:
```bash
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY
```

- Replace `YOUR_ALCHEMY_API_KEY` with your Alchemy (or Infura) API key.
- Note the pre-funded accounts and private keys displayed by Anvil.

### **2. Deploy the Contract**

Deploy the `LeveragedLidoVault` contract to the fork:
```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast \
  --private-key YOUR_PRIVATE_KEY
```

- Replace `YOUR_PRIVATE_KEY` with the private key of one of Anvil's pre-funded accounts.

### **3. Verify Deployment**

Check if the contract was deployed successfully:
```bash
cast code 0xYourDeployedContractAddress --rpc-url http://127.0.0.1:8545
```

---

## **Testing the Project**

### **1. Delegate Borrowing Power**

Run the `delegateBorrowingPower` function:
```bash
cast send --private-key YOUR_PRIVATE_KEY 0xYourDeployedContractAddress \
    "delegateBorrowingPower(uint256,uint256)" 500000000 1100000000000000000 \
    --rpc-url http://127.0.0.1:8545
```

- `500000000`: Delegating 500 USDC.
- `1100000000000000000`: Minimum health factor (1.1).

Verify the delegation:
```bash
cast call 0xYourDeployedContractAddress \
    "lenders(address)(uint256,uint256,uint256)" \
    0xYourWalletAddress --rpc-url http://127.0.0.1:8545
```

---

### **2. Deposit Collateral**

1. Approve the contract to spend USDC:
   ```bash
   cast send --private-key YOUR_PRIVATE_KEY $USDC_ADDRESS \
       "approve(address,uint256)" 0xYourDeployedContractAddress 1000000000 \
       --rpc-url http://127.0.0.1:8545
   ```

2. Deposit collateral:
   ```bash
   cast send --private-key YOUR_PRIVATE_KEY 0xYourDeployedContractAddress \
       "depositCollateral(uint256)" 1000000000 \
       --rpc-url http://127.0.0.1:8545
   ```

3. Verify the collateral:
   ```bash
   cast call 0xYourDeployedContractAddress \
       "positions(address)(uint256,uint256)" 0xYourWalletAddress \
       --rpc-url http://127.0.0.1:8545
   ```

---

### **3. Open Leveraged Position**

Run the `openLeveragedPosition` function:
```bash
cast send --private-key YOUR_PRIVATE_KEY 0xYourDeployedContractAddress \
    "openLeveragedPosition()" \
    --rpc-url http://127.0.0.1:8545
```

Verify the borrower's position:
```bash
cast call 0xYourDeployedContractAddress \
    "positions(address)(uint256,uint256)" 0xYourWalletAddress \
    --rpc-url http://127.0.0.1:8545
```

---

### **4. Check Health Factor**

Check the health factor to ensure lender and borrower safety:
```bash
cast call 0xYourDeployedContractAddress \
    "getHealthFactor()(uint256)" \
    --rpc-url http://127.0.0.1:8545
```

---

## **Running Tests**

Write comprehensive tests in the `test` folder, then run them using:
```bash
forge test --fork-url http://127.0.0.1:8545 -vvvv
```

---

## **Project Structure**

```
leveraged-lido-vault/
├── src/
│   ├── LeveragedLidoVault.sol       # Main contract
├── script/
│   ├── Deploy.s.sol                 # Deployment script
├── test/
│   ├── LeveragedLidoVault.t.sol     # Test cases
├── remappings.txt                   # Remapping for dependencies
├── foundry.toml                     # Foundry configuration
```

---

## **Completion Checklist**

| **Requirement**                       | **Status** | **Notes**                               |
|---------------------------------------|------------|-----------------------------------------|
| Credit delegation management          | ✅          | `delegateBorrowingPower` implemented    |
| Leveraged position creation           | ✅          | Includes collateral deposit and staking |
| Health factor monitoring              | ✅          | Ensures lender safety                   |
| USDC to ETH swap                      | ✅          | Uses Uniswap for token swaps            |
| Lido staking                          | ✅          | Calls Lido’s `submit` function          |

---
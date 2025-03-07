# 🚀 Rupio – INR-Pegged Stablecoin & DeFi Ecosystem  

Rupio is a **fully decentralized stablecoin system**, pegged to **1 INR**, powered by overcollateralized vaults and governed by **RupioDAO**. This monorepo contains all core components, including smart contracts, frontend, and deployment configurations.  

## 📂 Monorepo Structure  

```
rupio/
│── contracts/    # Solidity smart contracts for RUPI stablecoin & vaults  
│── frontend/     # Next.js frontend for user interactions  
│── README.md     # You are here  
```

Each directory has its own README with further details.

## 🌟 Overview  

### ⚖️ **RUPIO – The INR-Pegged Stablecoin**  
- **Mintable against collateralized assets**  
- **Overcollateralized vault system** to maintain INR peg  
- **Non-custodial & governed by smart contracts**  

### 🏦 **Vault System**  
- **Deposit collateral** to mint RUPI  
- **Automated liquidations** for undercollateralized positions  
- **Interest rate & stability fee adjustments via governance**  

### 🗳️ **RupioDAO – Decentralized Governance**  
- Community-driven **parameter adjustments & upgrades**  
- **On-chain voting system** to manage risk & monetary policies  
- **Decentralized treasury & stability mechanisms**  

### 🌉 **Multi-Chain Support & Optimized Transactions**  
- **Built on Optimism L2** for low gas fees  
- **Integrations with DeFi lending protocols**  
- **Future cross-chain functionality via LayerZero**  

## 🔧 Getting Started  

### Clone the Repository  
```sh
git clone https://github.com/your-org/rupio.git  
cd rupio  
```

### Install Dependencies  
```sh
forge install  
```

### Run the Contracts (Foundry)  
```sh
cd contracts  
forge build  
forge test  
```

### Start the Frontend (Next.js)  
```sh
cd frontend  
pnpm dev  
```

For full instructions, check the **README** inside each respective directory.

## 🔒 Security & Audits  

- **Smart contract audits** to ensure safety  
- **Non-custodial architecture** with transparent governance  
- **Emergency shutdown & liquidation safeguards**  

## 📜 License  

This project is **open-source** under the **MIT License**.  

---

For further details, explore the [contracts](contracts/README.md) and [frontend](frontend/README.md) directories. 🚀  

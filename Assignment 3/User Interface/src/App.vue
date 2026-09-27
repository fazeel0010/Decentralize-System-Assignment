<template>
  <div id="app">
    <!-- Header -->
    <header class="header">
      <div class="header-container">
        <router-link to="/" class="brand">NFT Store</router-link>
        <button @click="handleConnectWallet" class="wallet-btn" :class="{ connected: walletAddress }">
          {{ walletButtonText }}
        </button>
      </div>
    </header>

    <!-- Navigation -->
    <nav class="navbar">
      <router-link to="/" class="nav-link">NFT Asset Store</router-link>
      <router-link to="/createNFT" class="nav-link">Create NFT Asset</router-link>
    </nav>

    <!-- Page Content -->
    <main class="main-content">
      <router-view />
    </main>

    <!-- Footer -->
    <footer class="footer">
      <p>NFT Asset Store • Sepolia Testnet</p>
    </footer>
  </div>
</template>

<script>
import { connectWallet } from "./web3";

export default {
  name: "App",

  data() {
    return {
      walletAddress: null,
    };
  },

  computed: {
    // Displays Connect Wallet or the shortened connected wallet address.
    walletButtonText() {
      if (!this.walletAddress) {
        return "Connect Wallet";
      }

      return this.walletAddress; 
      //return `${this.walletAddress.slice(0, 6)}...${this.walletAddress.slice(-4)}`;
    },
  },

  methods: {
    // Connects MetaMask and stores the connected wallet address.
    async handleConnectWallet() {
      try {
        const wallet = await connectWallet();

        if (wallet && wallet.address) {
          this.walletAddress = wallet.address;
        }
      } catch (error) {
        return;
      }
    },

    // Checks whether a MetaMask wallet is already connected.
    async checkConnectedWallet() {
      try {
        if (!window.ethereum) {
          return;
        }

        const accounts = await window.ethereum.request({ method: "eth_accounts" });

        if (accounts.length > 0) {
          this.walletAddress = accounts[0];
        }
      } catch (error) {
        return;
      }
    },
  },

  // Checks the wallet and listens for MetaMask account changes.
  mounted() {
    this.checkConnectedWallet();

    if (window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts) => {
        if (accounts.length > 0) {
          this.walletAddress = accounts[0];
        } else {
          this.walletAddress = null;
        }
      });
    }
  },
};
</script>

<style>
* {
  box-sizing: border-box;
}

html,
body,
#app {
  margin: 0;
  padding: 0;
  width: 100%;
  min-height: 100vh;
}

body {
  background: #0b1120;
  color: #f8fafc;
  font-family: Arial, Helvetica, sans-serif;
}

#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.header {
  width: 100%;
  background: #111827;
  border-bottom: 1px solid #1f2937;
}

.header-container {
  width: 100%;
  max-width: 1200px;
  min-height: 76px;
  margin: 0 auto;
  padding: 0 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Logo */
.brand {
  color: #f8fafc;
  text-decoration: none;
  font-size: 1.55rem;
  font-weight: 700;
}

/* Wallet Button */
.wallet-btn {
  padding: 11px 18px;
  background: #14b8a6;
  color: #042f2e;
  border: none;
  border-radius: 8px;
  font-size: 0.92rem;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s ease;
}

.wallet-btn:hover {
  background: #2dd4bf;
  transform: translateY(-1px);
}

.wallet-btn.connected {
  background: #134e4a;
  color: #5eead4;
  border: 1px solid #14b8a6;
}

/* Navigation */
.navbar {
  width: 100%;
  min-height: 54px;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 40px;
  background: #0f172a;
  border-bottom: 1px solid #1e293b;
}

.nav-link {
  position: relative;
  padding: 17px 4px;
  color: #94a3b8;
  text-decoration: none;
  font-size: 0.98rem;
  font-weight: 600;
  transition: 0.2s ease;
}

.nav-link:hover {
  color: #5eead4;
}

.nav-link.router-link-active {
  color: #2dd4bf;
}

.nav-link.router-link-active::after {
  content: "";
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 2px;
  background: #2dd4bf;
  border-radius: 2px;
}

/* Main Content */
.main-content {
  width: 100%;
  max-width: 1200px;
  flex: 1;
  margin: 0 auto;
  padding: 40px 28px;
}

/* Footer */
.footer {
  width: 100%;
  padding: 18px;
  background: #0f172a;
  border-top: 1px solid #1e293b;
  color: #64748b;
  text-align: center;
  font-size: 0.85rem;
}

/* Mobile */
@media (max-width: 650px) {
  .header-container {
    min-height: 68px;
    padding: 0 15px;
  }

  .brand {
    font-size: 1.2rem;
  }

  .wallet-btn {
    padding: 9px 11px;
    font-size: 0.78rem;
  }

  .navbar {
    gap: 25px;
  }

  .nav-link {
    font-size: 0.9rem;
  }

  .main-content {
    padding: 28px 15px;
  }
}
</style>
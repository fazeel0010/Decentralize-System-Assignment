<template>
  <div class="marketplace">
    <div class="marketplace-header">
      <div>
        <h2>NFT Asset Store</h2>
        <p>Explore, list and purchase digital assets.</p>
      </div>

      <button class="refresh-btn" @click="loadNFTs" :disabled="loading">
        {{ loading ? "Loading..." : "Refresh" }}
      </button>
    </div>

    <div v-if="loading" class="loading">Loading NFTs...</div>

    <div v-else-if="nfts.length === 0" class="empty-state">
      <h3>No NFTs Found</h3>
      <p>Create your first NFT from the Create NFT page.</p>
    </div>

    <div v-else class="nft-list">
      <div v-for="nft in nfts" :key="nft.id" class="nft-card">
        <div class="image-container">
          <img v-if="nft.image" :src="nft.image" alt="NFT Image" class="nft-image" />
          <div v-else class="image-placeholder">No Image</div>

          <span class="status-badge" :class="nft.forSale ? 'sale' : 'not-sale'">
            {{ nft.forSale ? "For Sale" : "Not Listed" }}
          </span>
        </div>

        <div class="nft-content">
          <h3>{{ nft.title }}</h3>

          <div class="details">
            <p><span>Token ID</span><strong>#{{ nft.id }}</strong></p>
            <p><span>Rarity</span><strong>{{ nft.rarity }}</strong></p>
            <p><span>Traits</span><strong>{{ nft.traits }}</strong></p>
            <p><span>Initial Price</span><strong>{{ nft.initialPrice }} ETH</strong></p>
            <p><span>Sale Price</span><strong>{{ nft.sellingPrice }} ETH</strong></p>
          </div>

          <div class="owner-section">
            <span>Owner</span>
            <strong>{{ shortAddress(nft.owner) }}</strong>
          </div>

          <!-- Owner can enter a price and list an unlisted NFT. -->
          <div v-if="isOwner(nft) && !nft.forSale" class="action-section">
            <input v-model="nft.listingPrice" type="number" min="0" step="0.001" placeholder="Selling price (ETH)" class="price-input" />
            <button class="primary-btn" @click="putForSale(nft)">Put For Sale</button>
          </div>

          <!-- Owner can remove a listed NFT from sale. -->
          <button v-if="isOwner(nft) && nft.forSale" class="remove-btn" @click="removeFromSale(nft.id)">Remove From Sale</button>

          <!-- Other users can purchase a listed NFT. -->
          <button v-if="!isOwner(nft) && nft.forSale" class="buy-btn" @click="purchaseAsset(nft)">Buy for {{ nft.sellingPrice }} ETH</button>

          <!-- Shows when another user's NFT is not listed. -->
          <div v-if="!isOwner(nft) && !nft.forSale" class="unavailable">Not currently for sale</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import { connectWallet, getContract } from "../web3";
import { ethers } from "ethers";
import axios from "axios";

export default {
  name: "Marketplace",

  data() {
    return {
      nfts: [],
      loading: true,
      userAddress: null,
    };
  },

  async mounted() {
    await this.loadNFTs();
  },

  methods: {
    // Converts an IPFS URI into the Pinata gateway URL.
    getIPFSUrl(uri) {
      if (!uri) return "";

      if (uri.startsWith("ipfs://")) {
        const cid = uri.replace("ipfs://", "");
        return `https://chocolate-eligible-raccoon-298.mypinata.cloud/ipfs/${cid}`;
      }

      return uri;
    },

    // Shortens a wallet address for display in the interface.
    shortAddress(address) {
      if (!address) return "";

      return `${address.slice(0, 6)}...${address.slice(-4)}`;
    },

    // Checks whether the connected wallet owns the NFT.
    isOwner(nft) {
      if (!this.userAddress || !nft.owner) return false;

      return nft.owner.toLowerCase() === this.userAddress.toLowerCase();
    },

    // Loads all NFT assets and their IPFS metadata from the contract.
    async loadNFTs() {
      try {
        this.loading = true;
        this.nfts = [];

        const { signer } = await connectWallet();
        this.userAddress = await signer.getAddress();

        const contract = await getContract(signer);
        const total = await contract.totalAssets();
        const totalAssets = Number(total);
        const assets = [];

        for (let tokenId = 1; tokenId <= totalAssets; tokenId++) {
          try {
            const asset = await contract.getAssetDetails(tokenId);
            const owner = await contract.ownerOf(tokenId);

            let metadata = null;
            let image = "";

            try {
              const metadataURL = this.getIPFSUrl(asset.metadataURI);
              const response = await axios.get(metadataURL);

              metadata = response.data;
              image = metadata.image ? this.getIPFSUrl(metadata.image) : "";
            } catch (error) {
              metadata = null;
              image = "";
            }

            assets.push({
              id: tokenId,
              title: asset.title || metadata?.name || `NFT #${tokenId}`,
              image,
              rarity: asset.rarity,
              traits: asset.traits,
              initialPrice: ethers.formatEther(asset.initialPrice),
              sellingPrice: ethers.formatEther(asset.sellingPrice),
              sellingPriceWei: asset.sellingPrice,
              creator: asset.creator,
              forSale: asset.forSale,
              owner,
              listingPrice: ethers.formatEther(asset.sellingPrice),
            });
          } catch (error) {
            continue;
          }
        }

        this.nfts = assets;
      } catch (error) {
        this.nfts = [];
      } finally {
        this.loading = false;
      }
    },

    // Lists an owned NFT for sale at the entered selling price.
    async putForSale(nft) {
      try {
        if (!nft.listingPrice || Number(nft.listingPrice) <= 0) {
          alert("Please enter a valid selling price.");
          return;
        }

        const { signer } = await connectWallet();
        const contract = await getContract(signer);
        const priceInWei = ethers.parseEther(String(nft.listingPrice));
        const transaction = await contract.putForSale(nft.id, priceInWei);

        await transaction.wait();

        alert("NFT listed successfully!");

        await this.loadNFTs();
      } catch (error) {
        alert("Unable to list NFT.");
      }
    },

    // Removes an owned NFT from the marketplace.
    async removeFromSale(tokenId) {
      try {
        const { signer } = await connectWallet();
        const contract = await getContract(signer);
        const transaction = await contract.removeFromSale(tokenId);

        await transaction.wait();

        alert("NFT removed from sale.");

        await this.loadNFTs();
      } catch (error) {
        alert("Unable to remove NFT from sale.");
      }
    },

    // Checks the buyer balance and purchases the selected NFT.
    async purchaseAsset(nft) {
      try {
        const { signer } = await connectWallet();
        const contract = await getContract(signer);
        const asset = await contract.getAssetDetails(nft.id);

        const buyerAddress = await signer.getAddress();
        const balance = await signer.provider.getBalance(buyerAddress);
        const nftPrice = asset.sellingPrice;

        if (balance <= nftPrice) {
          alert(`Insufficient Balance!\n\nNFT Price: ${ethers.formatEther(nftPrice)} ETH\nYour Balance: ${Number(ethers.formatEther(balance)).toFixed(4)} ETH\n\nYou need additional Sepolia ETH to purchase this NFT and pay gas fees.`);
          return;
        }

        await contract.purchaseAsset.staticCall(nft.id, { value: nftPrice });

        const estimatedGas = await contract.purchaseAsset.estimateGas(nft.id, { value: nftPrice });
        const transaction = await contract.purchaseAsset(nft.id, { value: nftPrice, gasLimit: estimatedGas * 2n });

        await transaction.wait();

        alert("NFT purchased successfully!");

        await this.loadNFTs();
      } catch (error) {
        const message = `${error?.message || ""} ${error?.info?.error?.message || ""}`.toLowerCase();

        if (error?.code === "INSUFFICIENT_FUNDS" || message.includes("insufficient funds")) {
          alert("Insufficient balance. You need enough Sepolia ETH for the NFT price and gas fee.");
          return;
        }

        alert("Unable to purchase NFT.");
      }
    },
  },
};
</script>




<style scoped>
.marketplace {
  width: 100%;
}

.marketplace-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
}

.marketplace-header h2 {
  margin: 0 0 6px;
  color: #f8fafc;
  font-size: 1.7rem;
}

.marketplace-header p {
  margin: 0;
  color: #94a3b8;
}

.refresh-btn {
  padding: 10px 17px;
  background: #1e293b;
  color: #cbd5e1;
  border: 1px solid #334155;
  border-radius: 7px;
  cursor: pointer;
}

.loading,
.empty-state {
  padding: 60px 20px;
  text-align: center;
  color: #94a3b8;
}

.empty-state {
  background: #111827;
  border: 1px solid #1e293b;
  border-radius: 12px;
}

.empty-state h3 {
  color: #f8fafc;
}

.nft-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 22px;
}

.nft-card {
  overflow: hidden;
  background: #111827;
  border: 1px solid #1e293b;
  border-radius: 12px;
  transition: 0.2s;
}

.nft-card:hover {
  transform: translateY(-3px);
  border-color: #334155;
}

.image-container {
  position: relative;
  width: 100%;
  height: 230px;
  background: #0f172a;
}

.nft-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #64748b;
}

.status-badge {
  position: absolute;
  top: 12px;
  right: 12px;
  padding: 6px 9px;
  border-radius: 5px;
  font-size: 0.72rem;
  font-weight: 700;
}

.status-badge.sale {
  background: #134e4a;
  color: #5eead4;
}

.status-badge.not-sale {
  background: #1e293b;
  color: #94a3b8;
}

.nft-content {
  padding: 18px;
}

.nft-content h3 {
  margin: 0 0 17px;
  color: #f8fafc;
  font-size: 1.2rem;
}

.details {
  margin-bottom: 16px;
}

.details p {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin: 9px 0;
  color: #94a3b8;
  font-size: 0.85rem;
}

.details strong {
  color: #e2e8f0;
}

.owner-section {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  margin-bottom: 13px;
  border-top: 1px solid #1e293b;
  color: #94a3b8;
  font-size: 0.82rem;
}

.owner-section strong {
  color: #5eead4;
}

.action-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.price-input {
  width: 100%;
  padding: 10px 11px;
  background: #0f172a;
  color: white;
  border: 1px solid #334155;
  border-radius: 6px;
  outline: none;
}

.price-input:focus {
  border-color: #14b8a6;
}

.primary-btn,
.buy-btn,
.remove-btn {
  width: 100%;
  padding: 11px;
  border: none;
  border-radius: 6px;
  font-weight: 700;
  cursor: pointer;
}

.primary-btn,
.buy-btn {
  background: #14b8a6;
  color: #042f2e;
}

.primary-btn:hover,
.buy-btn:hover {
  background: #2dd4bf;
}

.remove-btn {
  background: #1e293b;
  color: #fca5a5;
  border: 1px solid #475569;
}

.remove-btn:hover {
  background: #334155;
}

.unavailable {
  padding: 10px;
  background: #0f172a;
  color: #64748b;
  text-align: center;
  border-radius: 6px;
  font-size: 0.85rem;
}

@media (max-width: 600px) {
  .marketplace-header {
    align-items: flex-start;
    gap: 15px;
    flex-direction: column;
  }

  .nft-list {
    grid-template-columns: 1fr;
  }
}
</style>
<template>
  <div class="mint-page">
    <div class="mint-container">
      <div class="mint-header">
        <h2>Create New NFT Asset</h2>
        <p>Create your digital asset and store its metadata on IPFS.</p>
      </div>

      <div class="form-group">
        <label>NFT Title</label>
        <input v-model="nft.title" type="text" placeholder="Enter NFT title" class="input-box" />
      </div>

      <div class="form-group">
        <label>Traits</label>
        <input v-model="nft.traits" type="text" placeholder="e.g. Speed, Strength" class="input-box" />
      </div>

      <div class="form-group">
        <label>Rarity</label>
        <input v-model="nft.rarity" type="text" placeholder="e.g. Rare, Legendary" class="input-box" />
      </div>

      <div class="form-group">
        <label>Initial Price (ETH)</label>
        <input v-model="nft.price" type="number" min="0" step="0.001" placeholder="e.g. 0.01" class="input-box" />
      </div>

      <div class="form-group">
        <label>NFT Image</label>

        <div class="file-box">
          <input type="file" accept="image/*" @change="handleFileUpload" class="file-input" />

          <p v-if="nft.file" class="file-name">
            Selected: {{ nft.file.name }}
          </p>
        </div>
      </div>

      <button @click="createNFT" class="mint-btn" :disabled="isMinting">
        {{ isMinting ? "Creating NFT..." : "Create NFT" }}
      </button>

      <p v-if="mintStatus" class="status" :class="{ error: hasError }">
        {{ mintStatus }}
      </p>
    </div>
  </div>
</template>

<script>
import { connectWallet, getContract } from "../web3";
import axios from "axios";
import { ethers } from "ethers";

export default {
  name: "Mint",

  data() {
    return {
      nft: { title: "", traits: "", rarity: "", price: "", file: null },
      mintStatus: "",
      isMinting: false,
      hasError: false,
    };
  },

  methods: {
    // Stores the selected NFT image.
    handleFileUpload(event) {
      const file = event.target.files[0];

      if (file) {
        this.nft.file = file;
      }
    },

    // Uploads the NFT image and metadata to IPFS using Pinata.
    async uploadToIPFS() {
      if (!this.nft.file) {
        throw new Error("Please select an NFT image.");
      }

      const fileName = this.nft.file.name.split(".")[0];
      const formData = new FormData();

      formData.append("file", this.nft.file);

      const imageResponse = await axios.post("https://api.pinata.cloud/pinning/pinFileToIPFS", formData, {
        headers: { "Content-Type": "multipart/form-data", pinata_api_key: "YOUR_PINATA_API_KEY", pinata_secret_api_key: "YOUR_PINATA_SECRET_KEY" },
      });

      const imageCID = imageResponse.data.IpfsHash;
      const imageURI = `ipfs://${imageCID}`;

      const metadata = {
        name: this.nft.title,
        description: `NFT Asset Store digital asset - ${this.nft.title}`,
        image: imageURI,
        attributes: [
          { trait_type: "Traits", value: this.nft.traits },
          { trait_type: "Rarity", value: this.nft.rarity },
        ],
      };

      const metadataBlob = new Blob([JSON.stringify(metadata)], { type: "application/json" });
      const metadataFormData = new FormData();

      metadataFormData.append("file", metadataBlob, `${fileName}.json`);

      const metadataResponse = await axios.post("https://api.pinata.cloud/pinning/pinFileToIPFS", metadataFormData, {
        headers: { "Content-Type": "multipart/form-data", pinata_api_key: "YOUR_PINATA_API_KEY", pinata_secret_api_key: "YOUR_PINATA_SECRET_KEY" },
      });

      const metadataCID = metadataResponse.data.IpfsHash;

      return `ipfs://${metadataCID}`;
    },

    // Validates the form and creates the NFT on the blockchain.
    async createNFT() {
      this.hasError = false;

      if (!this.nft.title.trim()) {
        this.mintStatus = "Please enter an NFT title.";
        this.hasError = true;
        return;
      }

      if (!this.nft.rarity.trim()) {
        this.mintStatus = "Please enter NFT rarity.";
        this.hasError = true;
        return;
      }

      if (!this.nft.traits.trim()) {
        this.mintStatus = "Please enter NFT traits.";
        this.hasError = true;
        return;
      }

      if (!this.nft.price || Number(this.nft.price) <= 0) {
        this.mintStatus = "Initial price must be greater than zero.";
        this.hasError = true;
        return;
      }

      if (!this.nft.file) {
        this.mintStatus = "Please select an NFT image.";
        this.hasError = true;
        return;
      }

      try {
        this.isMinting = true;
        this.mintStatus = "Uploading image and metadata to IPFS...";

        const metadataURI = await this.uploadToIPFS();

        this.mintStatus = "Connecting to wallet...";

        const { signer } = await connectWallet();
        const contract = await getContract(signer);
        const initialPrice = ethers.parseEther(String(this.nft.price));

        this.mintStatus = "Please confirm the transaction in MetaMask...";

        const transaction = await contract.createAsset(this.nft.title, metadataURI, this.nft.rarity, this.nft.traits, initialPrice);

        this.mintStatus = "Transaction submitted. Waiting for confirmation...";

        await transaction.wait();

        this.mintStatus = "NFT created successfully!";
        this.hasError = false;

        this.nft = { title: "", traits: "", rarity: "", price: "", file: null };
      } catch (error) {
        this.hasError = true;

        if (error.code === 4001) {
          this.mintStatus = "Transaction was rejected in MetaMask.";
        } else {
          this.mintStatus = "Error creating NFT. Check the console for details.";
        }
      } finally {
        this.isMinting = false;
      }
    },
  },
};
</script>



<style scoped>
.mint-page {
  width: 100%;
  display: flex;
  justify-content: center;
  padding: 15px 0 40px;
}

.mint-container {
  width: 100%;
  max-width: 560px;
  background: #111827;
  border: 1px solid #1e293b;
  border-radius: 14px;
  padding: 32px;
  box-shadow: 0 10px 35px rgba(0, 0, 0, 0.25);
}

/* Header */
.mint-header {
  text-align: left;
  margin-bottom: 28px;
}

.mint-header h2 {
  margin: 0 0 8px;
  color: #f8fafc;
  font-size: 1.65rem;
}

.mint-header p {
  margin: 0;
  color: #94a3b8;
  font-size: 0.92rem;
  line-height: 1.5;
}

/* Form */
.form-group {
  width: 100%;
  margin-bottom: 18px;
  text-align: left;
}

.form-group label {
  display: block;
  margin-bottom: 7px;
  color: #cbd5e1;
  font-size: 0.88rem;
  font-weight: 600;
}

/* Inputs */
.input-box {
  width: 100%;
  padding: 12px 14px;
  background: #0f172a;
  color: #f8fafc;
  border: 1px solid #334155;
  border-radius: 7px;
  font-size: 0.95rem;
  outline: none;
  transition: 0.2s;
}

.input-box::placeholder {
  color: #64748b;
}

.input-box:focus {
  border-color: #14b8a6;
  box-shadow: 0 0 0 2px rgba(20, 184, 166, 0.12);
}

/* File */
.file-box {
  width: 100%;
  padding: 12px;
  background: #0f172a;
  border: 1px dashed #475569;
  border-radius: 7px;
}

.file-input {
  width: 100%;
  color: #94a3b8;
  font-size: 0.88rem;
}

.file-input::file-selector-button {
  margin-right: 12px;
  padding: 8px 12px;
  background: #1e293b;
  color: #e2e8f0;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.file-input::file-selector-button:hover {
  background: #334155;
}

.file-name {
  margin: 10px 0 0;
  color: #5eead4;
  font-size: 0.8rem;
}

/* Create Button */
.mint-btn {
  width: 100%;
  margin-top: 6px;
  padding: 13px;
  background: #14b8a6;
  color: #042f2e;
  border: none;
  border-radius: 7px;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  transition: 0.2s;
}

.mint-btn:hover:not(:disabled) {
  background: #2dd4bf;
  transform: translateY(-1px);
}

.mint-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Status */
.status {
  margin: 18px 0 0;
  padding: 11px 12px;
  background: rgba(20, 184, 166, 0.1);
  color: #5eead4;
  border: 1px solid rgba(20, 184, 166, 0.25);
  border-radius: 6px;
  font-size: 0.88rem;
  text-align: center;
}

.status.error {
  background: rgba(239, 68, 68, 0.1);
  color: #fca5a5;
  border-color: rgba(239, 68, 68, 0.25);
}

/* Mobile */
@media (max-width: 600px) {
  .mint-container {
    padding: 22px 18px;
  }

  .mint-header h2 {
    font-size: 1.4rem;
  }
}
</style>
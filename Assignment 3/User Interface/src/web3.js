import { ethers } from "ethers";
import nftStoreABI from "./NFTAssetStore.json";

const nftStoreAddress = "0x83216BA405c520bA8D479E283fd81E4a6e0A5E0d";

// User 1 API Keys
export const pinataApiKey = "d79cae6dd714851af346";
export const pinataSecretKey = "1dcbd8225bf717c078eae38e55a65b8ef0d682368c225514b10ab5f03e10adfb";

// User 2 API Keys 
//export const pinataApiKey = "a23cae6sd724841af143";
// export const pinataSecretKey = "2ddba8325cf718c078eae38e55a65b8ef0d6823s8c125514210sb5c02e40aaca";

// Connects MetaMask and returns the provider, signer, and wallet address.
export async function connectWallet() {
  try {
    if (typeof window.ethereum === "undefined") {
      alert("MetaMask is required to connect your wallet. Please install it to continue.");
      throw new Error("MetaMask wallet is not available");
    }

    await window.ethereum.request({ method: "eth_requestAccounts" });

    const web3Provider = new ethers.BrowserProvider(window.ethereum);
    const walletSigner = await web3Provider.getSigner();
    const walletAddress = await walletSigner.getAddress();

    return { provider: web3Provider, signer: walletSigner, address: walletAddress };
  } catch (error) {
    console.error("Wallet connection error:", error);
    alert("Unable to connect to MetaMask. Please check your wallet and try again.");
  }
}


// Creates and returns an instance of the NFTAssetStore smart contract.
export async function getContract(walletSigner) {
  return new ethers.Contract(nftStoreAddress, nftStoreABI, walletSigner);
}
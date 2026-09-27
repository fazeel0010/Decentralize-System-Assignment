import { createRouter, createWebHistory } from "vue-router";
import NFTAssetStore from "./components/NFTAssetStore.vue";
import CreateNFT from "./components/CreateNFT.vue";

const routes = [
  { path: "/", component: NFTAssetStore },
  { path: "/createNft", component: CreateNFT },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

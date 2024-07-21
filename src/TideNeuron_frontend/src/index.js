import { AuthClient } from "@dfinity/auth-client";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory, canisterId } from "../../declarations/TideNeuron_backend";

let actor;

async function init() {
  // Create an AuthClient
  const authClient = await AuthClient.create();

  // Event listener for the login button
  document.getElementById("loginButton").addEventListener("click", async () => {
    await authClient.login({
      identityProvider: "https://nfid.one/authenticate",
      onSuccess: () => {
        handleAuthenticated(authClient);
      },
    });
  });

  // Check if already authenticated
  if (await authClient.isAuthenticated()) {
    handleAuthenticated(authClient);
  }
}

async function handleAuthenticated(authClient) {
  // Get the authenticated identity
  const identity = authClient.getIdentity();
  
  // Create a new HttpAgent with the authenticated identity
  const agent = new HttpAgent({ identity });

  // Fetch root key if running locally (necessary for local development only)
  if (process.env.DFX_NETWORK === "local") {
    await agent.fetchRootKey();
  }

  // Create an actor to interact with the canister using the authenticated agent
  actor = Actor.createActor(idlFactory, { agent, canisterId });

  // Update the UI with the authenticated principal
  const principal = identity.getPrincipal().toText();
  const divisable = 100000000;
  document.getElementById("loginButton").style.display = "none";
  document.getElementById("userPrincipal").innerText ="User Principal:" + await actor.getUserPrincipal();
  document.getElementById("TDNSupply").innerText = await actor.tdnSupply() /// divisable + " TDN";
  document.getElementById("TDNBalance").innerText = await actor.tdnBalanceOfUser()// / divisable + " TDN";
  document.getElementById("TDXSupply").innerText = await actor.tdxSupply() /// divisable + " TDX";
  document.getElementById("TDXBalance").innerText = await actor.tdxBalanceOfUser(); /// divisable + " TDX";
  document.getElementById("ICPBalance").innerText = await actor.icpBalanceOfUser() /// divisable + " ICP";
};

document.getElementById('refreshBalances').addEventListener("click", async () => {
  document.getElementById("TDXBalance").innerText = await actor.tdxBalanceOfUser(); /// divisable + " TDX";
  document.getElementById("TDNBalance").innerText = await actor.tdnBalanceOfUser() /// divisable + " TDN";
  document.getElementById("TDNSupply").innerText = await actor.tdnSupply() /// divisable + " TDN";
  document.getElementById("TDXSupply").innerText = await actor.tdxSupply() /// divisable + " TDX";
  document.getElementById("ICPBalance").innerText = await actor.icpBalanceOfUser() /// divisable + " ICP";  
});

document.getElementById("cyclicalStaking").addEventListener("click", async () => {
  var tdnAmount = document.getElementById('tdn-amount').value;
  var tdnBalance = await actor.tdnBalanceOfUser();
  if(tdnAmount < tdnBalance & tdnAmount > 0) {
      alert('Staking ' + tdnAmount + ' TDN');
      await actor.cyclicalStaking(tdnAmount)
      // Here, you can add the logic for the cyclical staking process
      // For example, make an API call to your backend or smart contract
  } else {
      alert('Please enter a valid amount to stake');
  }
});

init();

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
  //const principal = identity.getPrincipal().toText();
  //document.getElementById("loginButton").style.display = "none";
  //document.getElementById("cyclicalStakingNav").style.display = "none";
  document.getElementById("userPrincipal").innerText ="User Principal:" + await actor.getUserPrincipal();
  document.getElementById("TDNSupply").innerText = await actor.tdnSupplyToDisplay();
  document.getElementById("TDNBalance").innerText = await actor.tdnBalanceOfUserToDisplay();
  document.getElementById("TDXSupply").innerText = await actor.tdxSupplyToDisplay();
  document.getElementById("TDXBalance").innerText = await actor.tdxBalanceOfUserToDisplay();
  document.getElementById("ICPBalance").innerText = await actor.icpBalanceOfUserToDisplay();
};

document.getElementById('refreshBalances').addEventListener("click", async () => {
  document.getElementById("TDXBalance").innerText = await actor.tdxBalanceOfUserToDisplay();
  document.getElementById("TDNBalance").innerText = await actor.tdnBalanceOfUserToDisplay();
  document.getElementById("TDNSupply").innerText = await actor.tdnSupplyToDisplay();
  document.getElementById("TDXSupply").innerText = await actor.tdxSupplyToDisplay();
  document.getElementById("ICPBalance").innerText = await actor.icpBalanceOfUserToDisplay();  
});

document.getElementById("cyclicalStaking").addEventListener("click", async () => {
  var tdnAmount = Number(document.getElementById('tdn-amount').value);
  var tdnBalance = await actor.tdnBalanceOfUser();
  console.log(typeof tdnAmount);
  if(tdnAmount < tdnBalance && tdnAmount > 0 && Number.isInteger(tdnAmount)) {
      alert('Staking ' + tdnAmount + ' TDN');
      var result = await actor.cyclicalStaking(tdnAmount)
      console.log(result)
      // Here, you can add the logic for the cyclical staking process
      // For example, make an API call to your backend or smart contract
  } else {
      alert('Please enter a valid amount to stake');
  }
});

init();

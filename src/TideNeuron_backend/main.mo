// src/MintingCanister.mo
import Principal "mo:base/Principal";
import Result "mo:base/Result";
//import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Float "mo:base/Float";

actor {
    type Result<A,B> = Result.Result<A,B>;

    type Account = {
        owner: Principal;
        subaccount: ?Blob
    };

    type Error = {
        #InsufficientBalance;
        #Unauthorized;
        #InvalidAccount;
        #InvalidAmount;
    };
    
    let backendAccount : Account = {
        owner = Principal.fromText("5s5gd-eiaaa-aaaas-aabda-cai");
        subaccount = null;
    };

    public type TransferArg = {
        to : Account;
        fee : ?Nat;
        memo : ?Blob;
        from_subaccount : ?Blob;
        created_at_time : ?Nat64;
        amount : Nat;
    };

    public type ICPResult = { #Ok : Nat; #Err : TransferError };
    public type TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
      
    let tdn : actor {
        icrc1_total_supply : shared () -> async Nat;
        icrc1_balance_of : shared (account: Account) -> async Nat;
        icrc1_mint: shared (account: Account, amount: Nat) -> async Result<(), Error>;
        icrc1_burn : shared (account: Account, amount: Nat) -> async Result<(), Error>;
        icrc1_transfer: shared (from: Account, to: Account, amount: Nat)-> async Result<(), Error>; 
    } = actor ("47tcn-laaaa-aaaas-aabeq-cai");

    let tdx : actor {
        icrc1_total_supply : shared () -> async Nat;
        icrc1_balance_of : shared (account: Account) -> async Nat;
        icrc1_mint: shared (account: Account, amount: Nat) -> async Result<(), Error>;
        icrc1_burn : shared (account: Account, amount: Nat) -> async Result<(), Error>;
        icrc1_transfer: shared (from: Account, to: Account, amount: Nat)-> async Result<(), Error>; 
    } = actor ("4ysez-gyaaa-aaaas-aabea-cai");

    let icp : actor {
        icrc1_total_supply : shared query () -> async Nat;
        icrc1_balance_of : shared query Account -> async Nat;
        icrc1_transfer : shared TransferArg -> async ICPResult;
    } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

   public shared ({ caller }) func getUserPrincipal (): async Principal {
        return caller
   };

    var phase1 : Bool = true;
    var phase1MintingPercentage : Nat = 90;
    var phase2MintingPercentage : Nat = 200;

    public func getPhase (): async Bool {
        return phase1;
    };

    public func switchPhase (): async Bool {
        phase1 := switch(phase1){
            case(true){false};
            case(false){true};
        };
        return phase1;
    };

    public func getPhase1MintingPercentage (): async Nat {
        return phase1MintingPercentage;
    };

    public shared ({ caller }) func changephase1MintingPercentage (newPercentage : Nat): async Nat {
        if(newPercentage > 100){
            return  phase1MintingPercentage;
        };
        if(caller == backendAccount.owner){
        phase1MintingPercentage := newPercentage;
        };

        return phase1MintingPercentage;
    };

    public func getPhase2MintingPercentage (): async Nat {
        return phase2MintingPercentage;
    };

    public shared ({ caller }) func changephase2MintingPercentage (newPercentage : Nat): async Nat {
        if(newPercentage < 110){
            return  phase2MintingPercentage;
        };
        if(caller == backendAccount.owner){
            phase2MintingPercentage := newPercentage;
        };
        return phase2MintingPercentage;
    };

    public func icpSupply (): async Nat {
        return await icp.icrc1_total_supply();
    };

    public func icpSupplyToDisplay (): async Text {
        let balance: Nat = await icp.icrc1_total_supply();
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " ICP";
    };

    public func icpBalance (account: Account): async Nat {
        return await icp.icrc1_balance_of(account);
    };

    public shared ({ caller }) func icpBalanceOfUser (): async Nat {
        let userAccount : Account = {
            owner = caller;
            subaccount = null;
        };
        return await icp.icrc1_balance_of(userAccount);
    };

    public shared ({ caller }) func icpBalanceOfUserToDisplay (): async Text {
        let userAccount : Account = {
            owner = caller;
            subaccount = null;
        };
        let balance: Nat = await icp.icrc1_balance_of(userAccount);
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " ICP";
    };

    func transferICP (transfer : TransferArg): async ICPResult {
        return await icp.icrc1_transfer(transfer);
    };

    public func tdnSupply (): async Nat {
        return await tdn.icrc1_total_supply();
    };

    public func tdnSupplyToDisplay (): async Text {
        let balance: Nat = await tdn.icrc1_total_supply();
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " TDN";
    };

    public func tdnBalanceOfBackendAccount (): async Nat {
        return await tdn.icrc1_balance_of(backendAccount);
    };

    public shared ({ caller }) func tdnBalanceOfUser (): async Nat{
        let userAccount = {
            owner = caller;
            subaccount = null;
        };
        return await tdn.icrc1_balance_of(userAccount);
    };

     public shared ({ caller }) func tdnBalanceOfUserToDisplay (): async Text {
        let userAccount : Account = {
            owner = caller;
            subaccount = null;
        };
        let balance: Nat = await tdn.icrc1_balance_of(userAccount);
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " TDN";
    };

    public func tdnMint (amount: Nat): async Result<(), Error>{
        return await tdn.icrc1_mint(backendAccount, amount);
    };

    public func tdnBurn (amount: Nat): async Result<(), Error>{
        return await tdn.icrc1_burn(backendAccount, amount);
    };

    public func tdnTransfer (to: Account, amount: Nat): async Result<(), Error>{
        return await tdn.icrc1_transfer(backendAccount, to, amount);
    };

    public func tdxSupply (): async Nat {
        return await tdx.icrc1_total_supply();
    };

     public func tdxSupplyToDisplay (): async Text {
        let balance: Nat = await tdx.icrc1_total_supply();
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " TDX";
    };

    public func tdxBalanceofBackendAccount (): async Nat {
        return await tdx.icrc1_balance_of(backendAccount);
    };

    public shared ({ caller }) func tdxBalanceOfUser (): async Nat {
        let userAccount = {
            owner = caller;
            subaccount = null;
        };
        return await tdx.icrc1_balance_of(userAccount);
    };

     public shared ({ caller }) func tdxBalanceOfUserToDisplay (): async Text {
        let userAccount : Account = {
            owner = caller;
            subaccount = null;
        };
        let balance: Nat = await tdx.icrc1_balance_of(userAccount);
        var no :Float= Float.fromInt(balance);
        no := no/100000000;
        return Float.toText(no) # " TDX";
    };

    public func tdxMint (amount: Nat): async Result<(), Error>{
        return await tdx.icrc1_mint(backendAccount, amount);
    };

    public func tdxBurn (amount: Nat): async Result<(), Error>{
        return await tdx.icrc1_burn(backendAccount, amount);
    };

    public func tdxTransfer (to: Account, amount: Nat): async Result<(), Error>{
        return await tdx.icrc1_transfer(backendAccount, to, amount);
    };

    public shared ({ caller }) func cyclicalStaking (amount: Nat): async Result<(), Error>{
        let userAccount : Account = {
            owner = caller;
            subaccount = null;
        };
        //Attempt to burn the tokens the user stakes
        let transferFromUser = await tdn.icrc1_transfer(userAccount, backendAccount, amount);

        switch(transferFromUser){
            case(#ok ){
            ignore await tdn.icrc1_burn(backendAccount, amount);
                //assuming same value for all three tokens, TDN, TDX and ICP - otherwise you need to recieve the value of TDN compared to TDX and ICP so you know how much TDX to mint and how many ICP to send to the user 
                ignore await tdx.icrc1_mint(backendAccount, amount);
                //Returning the same number of TDX to the user as they staked - enabling it to become cyclical
                ignore await tdx.icrc1_transfer(backendAccount,userAccount,amount);
                //Creating transferArg for the transfer of ICP
                let transfer : TransferArg = {
                    to = userAccount;
                    fee = null;
                    memo = null;
                    from_subaccount = null;
                    created_at_time = null;
                    amount = Nat.div(amount, 10);
                };
                //To transfer ICP to the user
                ignore await transferICP(transfer);
                //Calculating the amount of TDN to mint and then sell for ICP
                var tdnAmountToMintAndTrade: Nat = switch(phase1){
                    case(true){Nat.div(Nat.mul(amount, phase1MintingPercentage), 100)};
                    case(_){Nat.div(Nat.mul(amount, phase2MintingPercentage), 100)}
                };
                //Minting that amount of TDN
                ignore await tdn.icrc1_mint(backendAccount,tdnAmountToMintAndTrade);
                //logic to handle swap here
                //logic to handle sending the ICP to the 8 year neuron here
                return #ok();
            };
            case(#err error){
                return #err(error);
            };     
        };
    };

}

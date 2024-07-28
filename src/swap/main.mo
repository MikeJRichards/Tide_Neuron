import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";

actor {
    public type Account = {
        owner: Principal;
        subaccount: ?Blob
    };

    public type Balance = Nat;
    public type TxIndex = Nat;
    public type Timestamp = Nat64;
    public type Subaccount = Blob;

    public type TransferError = {
        #GenericError : { message : Text; error_code : Nat };
        #TemporarilyUnavailable;
        #BadBurn : { min_burn_amount : Balance };
        #Duplicate : { duplicate_of : TxIndex };
        #BadFee : { expected_fee : Balance };
        #CreatedInFuture : { ledger_time : Timestamp };
        #TooOld;
        #InsufficientFunds : { balance : Balance };
    };

    public type DepositArgs = { 
        fee : Nat; 
        token : Text; 
        amount : Nat 
    };

    public type SwapArgs = {
        amountIn : Text;
        zeroForOne : Bool;
        amountOutMinimum : Text;
    };

    type WithdrawArgs = { 
        fee : Nat; 
        token : Text; 
        amount : Nat 
    };

    public type Result = { 
        #ok : Nat; 
        #err : Error 
    };

    public type Error = {
        #CommonError;
        #InternalError : Text;
        #UnsupportedToken : Text;
        #InsufficientFunds;
    };

    public type TransferResult = { 
        #Ok : TxIndex; 
        #Err : TransferError 
    };

    public type TransferArgs = {
        to : Account;
        fee : ?Balance;
        memo : ?Blob;
        from_subaccount : ?Subaccount;
        created_at_time : ?Nat64;
        amount : Balance;
    };

    let exe : actor {
        icrc1_balance_of: query Account -> async Nat;
        icrc1_transfer : shared TransferArgs -> async TransferResult;
    } = actor("rh2pm-ryaaa-aaaan-qeniq-cai");

    let icpExeSwap : actor {
        quote : shared query SwapArgs -> async Result;
        deposit : shared DepositArgs -> async Result;
        swap : shared SwapArgs -> async Result;
        withdraw : shared WithdrawArgs -> async Result;
    } = actor("dlfvj-eqaaa-aaaag-qcs3a-cai");

    public func principalToBlob(p: Principal): async Blob {
        var arr: [Nat8] = Blob.toArray(Principal.toBlob(p));
        var defaultArr: [var Nat8] = Array.init<Nat8>(32, 0);
        defaultArr[0] := Nat8.fromNat(arr.size());
        var ind: Nat = 0;
        while (ind < arr.size() and ind < 32) {
            defaultArr[ind + 1] := arr[ind];
            ind := ind + 1;
        };
        return Blob.fromArray(Array.freeze(defaultArr));
    };

    public shared ({ caller }) func getUserPrincipal (): async Principal {
        return caller
   };

    public func getExeBalance(owner: Principal): async Nat {
        let account : Account = {
            owner;
            subaccount = null;
        };
        return await exe.icrc1_balance_of(account);
    };

    public func getDepositBalance(): async Nat {
        let subaccount1 = await principalToBlob(Principal.fromText("dlfvj-eqaaa-aaaag-qcs3a-cai"));
        let swapAccount : Account = {
            owner = Principal.fromText("dlfvj-eqaaa-aaaag-qcs3a-cai");
            subaccount = ?subaccount1;
        };
        return await exe.icrc1_balance_of(swapAccount);
    };

    public func sendEXEforExchange(amount: Nat): async TransferResult {
        let subaccount1 = await principalToBlob(Principal.fromText("4ew6i-ryaaa-aaaas-aabga-cai"));
        let swapAccount : Account = {
            owner = Principal.fromText("dlfvj-eqaaa-aaaag-qcs3a-cai");
            subaccount = ?subaccount1;
        };
        let transfer : TransferArgs = {
            amount;
            created_at_time = null;
            fee = ?100000;
            from_subaccount = null;
            memo = null;
            to = swapAccount;
        };
        return await exe.icrc1_transfer(transfer);
    };

    public func quoteIcpExeSwap(amountIn: Text): async Result {
        let swapquote : SwapArgs = {
            amountIn;
            zeroForOne = true;
            amountOutMinimum = "0";
        };
        return await icpExeSwap.quote(swapquote);
    };

    public func sendDepositEXE(amount: Nat): async Result {
        let deposit : DepositArgs = { 
            fee = 100000; 
            token = "rh2pm-ryaaa-aaaan-qeniq-cai"; 
            amount;
        };
        Debug.print("Attempting to deposit EXE: " # Nat.toText(amount) # " to icpExeSwap canister");
        return await icpExeSwap.deposit(deposit);
    };

    public func swapEXE(amount: Text): async Result {
        let swapArg : SwapArgs = {
            amountIn = amount; 
            zeroForOne = true;
            amountOutMinimum = "0";
        };
        return await icpExeSwap.swap(swapArg);
    };

    public func withdrawICPafterSwap(amount: Nat): async Result {
        let withdraw : WithdrawArgs = {
            fee = 10000; 
            token = "ryjl3-tyaaa-aaaaa-aaaba-cai"; 
            amount;
        };
        return await icpExeSwap.withdraw(withdraw);
    };

    // Add logging for each step
    public func swapExeForIcp(initialExeAmount: Nat): async Result {
        var result : Nat = 0;
        let balance = await getExeBalance(Principal.fromText("4ew6i-ryaaa-aaaas-aabga-cai"));
        if(initialExeAmount > balance){
            return  #err(#InsufficientFunds);
        };
        //transfer
        ignore await sendEXEforExchange(initialExeAmount);
        //deposit
        let depositResult = await sendDepositEXE(initialExeAmount);
        switch(depositResult){
            case(#ok(amount)){result := amount};
            case(#err(error)){return #err(error)}
        };
        //swap
        let swapResult = await swapEXE(Nat.toText(result));
        switch(swapResult){
            case(#ok(amount)){result := amount};
            case(#err(error)){return #err(error)};
        };
        //withdraw
        let withdrawResult = await withdrawICPafterSwap(result);
        switch(withdrawResult){
            case(#ok(amount)){return #ok(amount)};
            case(#err(error)){return #err(error)};
        };
    };
}

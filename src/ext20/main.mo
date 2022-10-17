/*
ERC20 - note the following:
-No notifications (can be added)
-All tokenids are ignored
-You can use the canister address as the token id
-Memo is ignored
-No transferFrom (as transfer includes a from field)
*/
import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
//Get the path right
import AID "../motoko/util/AccountIdentifier";
import ExtCore "../motoko/ext/Core";
import ExtCommon "../motoko/ext/Common";
import ExtAllowance "../motoko/ext/Allowance";

import Ledger "../motoko/icp/Ledger";
import LedgerC "../motoko/icp/LedgerCandid";
import XDR "../motoko/icp/XDR";

actor class erc20_token() = this {
  
  private let ledger  : Ledger.Interface  = actor(Ledger.CANISTER_ID);
  private let ledgerC : LedgerC.Interface = actor("rrkah-fqaaa-aaaaa-aaaaq-cai");
  private let cycles  : XDR.Interface     = actor(XDR.CANISTER_ID);

  // Types
  type AccountIdentifier = ExtCore.AccountIdentifier;
  type SubAccount = ExtCore.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type Extension = ExtCore.Extension;
  type CommonError = ExtCore.CommonError;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  type AllowanceRequest = ExtAllowance.AllowanceRequest;
  type ApproveRequest = ExtAllowance.ApproveRequest;
  type Metadata = ExtCommon.Metadata;
  
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/allowance"];
  
  //Tokenomics
  private var init_name: Text = "Tutorial Token";
  private var init_symbol: Text = "TT";
  private var init_decimals: Nat8 = 10;
  private var init_supply: ExtCore.Balance = 1000000000000000;
  
  //State work
  private stable var _balancesState : [(AccountIdentifier, Balance)] = [];
  private var _balances : HashMap.HashMap<AccountIdentifier, Balance> = HashMap.fromIter(_balancesState.vals(), 0, AID.equal, AID.hash);
  private var _allowances = HashMap.HashMap<AccountIdentifier, HashMap.HashMap<Principal, Balance>>(1, AID.equal, AID.hash);
  private stable var initiated: Bool = false;

  //State functions
  system func preupgrade() {
    _balancesState := Iter.toArray(_balances.entries());
    //Allowances are not stable, they are lost during upgrades...
  };
  system func postupgrade() {
    _balancesState := [];
  };
  
    //Initial state - could set via class setter
  private stable let METADATA : Metadata = #fungible({
    name = init_name;
    symbol = init_symbol;
    decimals = init_decimals;
    metadata = null;
  }); 
  private stable var _supply : Balance  = init_supply;

  private func principalId() : Principal {
      return Principal.fromActor(this);
  };

  public func init() {
    if (initiated == false) {
      Debug.print(debug_show("this happenmed"));
      _balances.put(AID.fromPrincipal(principalId(), null), _supply);
    };

    initiated := true;
  };

  private func ownerAuthorized(owner: AccountIdentifier, spender: AccountIdentifier, amount: Nat, caller: Principal): Bool {
      if (AID.equal(owner, spender) == false) {
        //Operator is not owner, so we need to validate here
        switch (_allowances.get(owner)) {
          case (?owner_allowances) {
            switch (owner_allowances.get(caller)) {
              case (?spender_allowance) {
                if (spender_allowance < amount) {
                  return false;
                } else {
                  var spender_allowance_new : Balance = spender_allowance - amount;
                  owner_allowances.put(caller, spender_allowance_new);
                  _allowances.put(owner, owner_allowances);
                  return true;
                };
              };
              case (_) {
                return false;
              };
            };
          };
          case (_) {
            return false;
          };
        };
      };

      return false;
  };

  private func ptransfer (owner: AccountIdentifier, receiver: AccountIdentifier, amount: Nat, caller: Principal): TransferResponse {
    switch (_balances.get(owner)) {
      case (?owner_balance) {
        if (owner_balance >= amount) {
          
          var owner_balance_new : Balance = owner_balance - amount;
          _balances.put(owner, owner_balance_new);
          var receiver_balance_new = switch (_balances.get(receiver)) {
            case (?receiver_balance) {
                receiver_balance + amount;
            };
            case (_) {
                amount;
            };
          };
          _balances.put(receiver, receiver_balance_new);
          return #ok(amount);
        } else {
          return #err(#InsufficientBalance);
        };
      };
      case (_) {
        return #err(#InsufficientBalance);
      };
    };

  };

    public shared(msg) func mint(accountId: AccountIdentifier): async TransferResponse {
    let ownerBalance = _balances.get(accountId);
    if (ownerBalance == null) {
      return ptransfer(AID.fromPrincipal(principalId(), null), accountId, 1000000, msg.caller);
    } else {
     return #err(#Other("Already Minted"));
    };
  };

  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    let owner = ExtCore.User.toAID(request.from);
    let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    let receiver = ExtCore.User.toAID(request.to);
    if (ownerAuthorized(owner, spender, request.amount, msg.caller) == false) {
      return #err(#Unauthorized(spender));
    };

    return ptransfer(owner, receiver, request.amount, msg.caller);
  };
  
  public shared(msg) func approve(request: ApproveRequest) : async () {
    let owner = AID.fromPrincipal(msg.caller, request.subaccount);
    switch (_allowances.get(owner)) {
      case (?owner_allowances) {
        owner_allowances.put(request.spender, request.allowance);
        _allowances.put(owner, owner_allowances);
      };
      case (_) {
        var temp = HashMap.HashMap<Principal, Balance>(1, Principal.equal, Principal.hash);
        temp.put(request.spender, request.allowance);
        _allowances.put(owner, temp);
      };
    };
  };

  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  
  public query func balance(request : BalanceRequest) : async BalanceResponse {
    let aid = ExtCore.User.toAID(request.user);
    switch (_balances.get(aid)) {
      case (?balance) {
        return #ok(balance);
      };
      case (_) {
        return #ok(0);
      };
    }
  };

  public query func supply(token : TokenIdentifier) : async Result.Result<Balance, CommonError> {
    #ok(_supply);
  };

  public func contractPrincipal() : async Result.Result<Principal, CommonError> {
    #ok(Principal.fromActor(this));
  };
  
  public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
    #ok(METADATA);
  };
  
  //Internal cycle management - good general case
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance();
  };

}
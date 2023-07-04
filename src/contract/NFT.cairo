#[contract]
mod AitchNFT {

    // IMPORTS
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use traits::{Into, TryInto};
    use starknet::Zeroable;


    // STORAGE
    struct Storage {
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        token_owner: LegacyMap<u256, ContractAddress>,
        allowance_for_all: LegacyMap<(ContractAddress, ContractAddress), bool>,
        allowance: LegacyMap<(u256, ContractAddress), ContractAddress>,
    }


    // EVENTS
    #[event]
    fn Transfer(sender: ContractAddress, to: ContractAddress, tokenId: u256){}

    #[event]
    fn Approval(owner: ContractAddress, approved: ContractAddress, tokenId: u256){}

    #[event]
    fn ApprovalForAll(owner: ContractAddress, operator: ContractAddress, approved: bool){}




    // FUNCTIONS

    
    #[constructor]
    fn constructor(_name: felt252, _symbol: felt252, _owner: ContractAddress, total_supply: u256) {

        name::write(_name);
        symbol::write(_symbol);
        owner::write(_owner);
        total_supply::write(total_supply);

    }

    #[view]
    fn ownerOf(_tokenId: u256) -> ContractAddress {
        token_owner::read(_tokenId)
    }



    #[view]
    fn balanceOf(_address: ContractAddress) -> u256 {
        balances::read(_address)
    }

    

    
    #[external]
    fn approve(_to: ContractAddress, _tokenId: u256) {
        let caller = get_caller_address();
        assert(ownerOf(_tokenId) == caller, 'Invalid owner'); 
        allowance::write((_tokenId, caller), _to);
        Approval(caller, _to, _tokenId);
    }


    
    // Gives _to approval to send all caller's tokens
    #[external]
    fn setApprovalForAll(_to: ContractAddress, approved: bool) {
        let caller: ContractAddress = get_caller_address();
        allowance_for_all::write((caller, _to), true);
        ApprovalForAll(caller, _to, true);
    }


    #[view]
    fn getApproved(_tokenId: u256, _owner: ContractAddress) -> ContractAddress {
        allowance::read((_tokenId, _owner))
    }



    // Check if operator is approved for all tokens
    #[view]
    fn isApprovedForAll(owner: ContractAddress, operator: ContractAddress) -> bool {
        allowance_for_all::read((owner, operator))
    }

    
    #[external]
    fn transferFrom(sender: ContractAddress, to: ContractAddress, tokenId: u256) {
        let exists = _exists(tokenId);
        let caller = get_caller_address();
        assert(exists & _isApprovedOrOwner(caller, tokenId), 'Not permitted');
        _transferFrom(sender, to, tokenId);
    }


   //Internal Functions
    #[internal]
    fn _transferFrom(sender: ContractAddress, to: ContractAddress, tokenId: u256) {
        balances::write(sender, balances::read(sender) - 1);
        balances::write(to, balances::read(to) + 1);
        token_owner::write(tokenId, to);
    }



    //verifies token availability
    #[internal]
    fn _exists(tokenId: u256) -> bool {
        if 
            tokenId <= total_supply::read() 
            &
            token_owner::read(tokenId) != Zeroable::zero() 
        {
            return true;
        } 
        else 
        {
            return false;
        }
    }


    // Approval verification
    #[internal]
    fn _isApprovedOrOwner(spender: ContractAddress, tokenId: u256) -> bool {
        let _owner = token_owner::read(tokenId);

        if 
            spender == _owner | allowance_for_all::read((_owner, spender)) | allowance::read((tokenId, _owner)) == spender
        {
            return true;
        } 
        else 
        {
            return false;
        }
    }
        

    // Mint function
    #[external]
    fn mint(to: ContractAddress, tokenId: u256) {
        let caller = get_caller_address();
        assert(caller == owner::read(), 'Not owner');
        assert(
            tokenId <= total_supply::read() & token_owner::read(tokenId) == Zeroable::zero(), 
            'Invalid mint'
        );
        _transferFrom(Zeroable::zero(), to, tokenId);
    }


    // Burn function
    #[external]
    fn burn(_owner: ContractAddress, tokenId: u256) {
        let caller = get_caller_address();
        assert(
            _isApprovedOrOwner(caller, tokenId) & _owner == token_owner::read(tokenId), 'Not permitted'
        );

        _transferFrom(caller, Zeroable::zero(), tokenId);
    }

}
// nft 강화시 해당 컨트랙트로
// mapping(string => miningPower) public MP; 저장됩니다.
// 매핑의 키값은 컨트랙트주소 + 토큰넘버 입니다. 타입은 스트링 입니다.
//
// 예) 0x000000000000000000000000000000000000000000 15번 토큰 마이닝파워는?
// 예) 0x00000000000000000000000000000000000000000015

pragma solidity ^0.5.6;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract OwnerRole {
    using Roles for Roles.Role;

    event OwnerAdded(address indexed account);
    event OwnerRemoved(address indexed account);

    Roles.Role private _owners;

    constructor() internal {
        _addOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(
            isOwner(msg.sender),
            "OwnerRole: caller does not have the Owner role"
        );
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return _owners.has(account);
    }

    function addOwner(address account) public onlyOwner {
        _addOwner(account);
    }

    function renounceOwner() public {
        _removeOwner(msg.sender);
    }

    function _addOwner(address account) internal {
        _owners.add(account);
        emit OwnerAdded(account);
    }

    function _removeOwner(address account) internal {
        _owners.remove(account);
        emit OwnerRemoved(account);
    }
}

contract dataBase is OwnerRole {
    struct miningPower {
        string _tokenId;
        uint256 _power;
    }

    mapping(string => miningPower) public MP;

    function setPower(
        string memory _contract_addr,
        string memory _tokenId,
        uint256 _power
    ) public onlyOwner {
        string memory mappingId = appendString(_contract_addr, _tokenId);
        MP[mappingId]._tokenId = _tokenId;
        MP[mappingId]._power = _power;
    }

    function appendString(string memory _a, string memory _b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_a, _b));
    }

    function viewPower(string memory _addr_tokenId)
        public
        view
        returns (string memory, uint256)
    {
        return (MP[_addr_tokenId]._tokenId, MP[_addr_tokenId]._power);
    }
}
